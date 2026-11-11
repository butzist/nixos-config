{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.security.secureBoot;

  # Names in `luksDevices` that are not actually defined as an initrd LUKS
  # device. Computed here so the assertion can name them.
  missing = lib.filter (name: !(config.boot.initrd.luks.devices ? ${name})) cfg.luksDevices;

  # TPM2 enrollment is per-volume and must happen from a boot whose Secure Boot
  # state and pcrlock policy are already final, so it stays a manual command
  # rather than a systemd service. This script only exists so the device list
  # lives in one place instead of being copied into the runbook. Extra arguments
  # are forwarded to systemd-cryptenroll (e.g. --wipe-slot=tpm2 to replace a
  # stale slot after the TPM was cleared).
  enroll = pkgs.writeShellApplication {
    name = "secure-boot-enroll";
    runtimeInputs = [config.systemd.package];
    text = ''
      policy=/var/lib/systemd/pcrlock.json
      if [ ! -r "$policy" ]; then
        echo "secure-boot-enroll: $policy is missing." >&2
        echo "Boot once with Secure Boot enabled and the current generation first." >&2
        exit 1
      fi

      ${lib.concatMapStrings (name: ''
          echo "==> ${name} (${config.boot.initrd.luks.devices.${name}.device})"
          systemd-cryptenroll \
            --tpm2-device=auto \
            --tpm2-pcrlock="$policy" \
            "$@" \
            ${lib.escapeShellArg config.boot.initrd.luks.devices.${name}.device}
        '')
        cfg.luksDevices}
    '';
  };
in {
  # Imported unconditionally: the module is inert unless security.secureBoot.enable
  # is set, and keeping the option tree stable means a host can flip the switch
  # without the option disappearing mid-evaluation.
  imports = [inputs.lanzaboote.nixosModules.default];

  options.security.secureBoot = {
    enable = lib.mkEnableOption ''
      Lanzaboote Secure Boot (signed UKIs). When disabled this module installs
      plain systemd-boot instead, so exactly one loader is active either way
    '';

    pkiBundle = lib.mkOption {
      type = lib.types.externalPath;
      default = "/var/lib/sbctl";
      description = ''
        Directory holding the sbctl PKI (db/KEK/PK). Created by
        `sbctl create-keys`; back it up. If it is lost the already-signed images
        keep booting, but nothing new can be signed until the keys are recreated
        and re-enrolled.
      '';
    };

    configurationLimit = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = ''
        Generations kept on the ESP. Measured boot cannot exceed 4:
        systemd-pcrlock refuses more than 8 variants per PCR, and PCR 4 is
        (2 bootloader variants x N generations). Generations above the limit
        are removed from the ESP, so they are not bootable while measured boot
        is on.
      '';
    };

    luksDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["luks-01234567-89ab-cdef-0123-456789abcdef"];
      description = ''
        Optional. Names of `boot.initrd.luks.devices` entries that should be
        unlocked by the TPM2 pcrlock policy instead of the passphrase.

        This only adds `tpm2-device=auto` to the generated crypttab and turns on
        measured boot; it never removes the passphrase keyslot, so a refused
        TPM always falls back to the passphrase prompt. Leave empty on hosts
        without an encrypted root (or to enable Secure Boot first and enroll
        later): nothing here requires LUKS to exist.
      '';
    };

    measuredBoot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.luksDevices != [];
        defaultText = lib.literalExpression "security.secureBoot.luksDevices != []";
        description = ''
          Build a systemd-pcrlock policy so the TPM can release LUKS keys. Can be
          enabled without listing devices, e.g. to enroll manually later.
        '';
      };

      pcrs = lib.mkOption {
        type = lib.types.listOf (lib.types.enum [0 1 2 3 4 7]);
        default = [4 7];
        description = ''
          PCRs locked by systemd-pcrlock. PCR 4 covers the whole UKI (stub,
          kernel, initrd, cmdline) because the firmware measures the entire PE
          binary; PCR 7 is the Secure Boot state. 11 and 12 are not selectable
          and would be wrong anyway: 11 duplicates PCR 4 and changes every
          rebuild, 12 is never extended when the cmdline is embedded in the UKI.
        '';
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = !cfg.enable || missing == [];
        message = ''
          security.secureBoot.luksDevices references unknown initrd LUKS
          device(s): ${lib.concatStringsSep ", " missing}.
          Use the attribute names from boot.initrd.luks.devices.
        '';
      }
      {
        assertion = !(cfg.enable && cfg.measuredBoot.enable) || cfg.configurationLimit <= 4;
        message = ''
          Measured boot requires security.secureBoot.configurationLimit <= 4
          (systemd-pcrlock cannot express more than 8 PCR 4 variants).
        '';
      }
    ];

    boot = {
      # Boot UI, independent of which loader is active.
      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "splash"
        "intremap=on"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];

      # plymouth, showing after LUKS unlock
      plymouth = {
        enable = true;
        font = "${pkgs.hack-font}/share/fonts/truetype/Hack-Regular.ttf";
        logo = "${pkgs.nixos-icons}/share/icons/hicolor/128x128/apps/nix-snowflake.png";
      };

      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

      loader = {
        # Loader selection: the option is the switch. Never set
        # boot.loader.systemd-boot.enable in a host, or the two definitions clash.
        systemd-boot.enable = !cfg.enable;
        efi.canTouchEfiVariables = lib.mkDefault true;
      };

      lanzaboote = lib.mkIf cfg.enable {
        enable = true;
        inherit (cfg) pkiBundle configurationLimit;
        measuredBoot = {
          inherit (cfg.measuredBoot) enable pcrs;
        };
      };

      # Only makes systemd-cryptsetup try the token; the passphrase keyslot is
      # untouched and remains the fallback.
      initrd.luks.devices = lib.mkIf cfg.enable (lib.genAttrs cfg.luksDevices (_: {
        crypttabExtraOpts = ["tpm2-device=auto"];
      }));
    };

    security.tpm2.enable = cfg.enable && cfg.measuredBoot.enable;

    environment.systemPackages =
      lib.optional cfg.enable pkgs.sbctl
      ++ lib.optional (cfg.enable && cfg.luksDevices != []) enroll;
  };
}
