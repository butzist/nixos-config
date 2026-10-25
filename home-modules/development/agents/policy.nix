{
  pkgs,
  agent-toolbox,
  extraPackages ? [],
  env ? {},
  fwdEnv ? [],
  sharedPermissions ? [],
  nvidia ? true,
  ghToken ? true,
  flakeRoot ? true,
  herdr ? true,
  direnv ? true,
  persistHome ? true,
  opencode ? {},
  goose ? {},
}: let
  inherit (pkgs) lib;
  atb = agent-toolbox;

  resolvePermissions = value: c:
    if lib.isFunction value
    then value c
    else value;

  nvidiaDevices = [
    "/dev/nvidia0"
    "/dev/nvidia1"
    "/dev/nvidia2"
    "/dev/nvidia3"
    "/dev/nvidiactl"
    "/dev/nvidia-uvm"
    "/dev/nvidia-uvm-tools"
    "/dev/nvidia-modeset"
    "/dev/nvidia-caps"
  ];

  herdrHelper = atb.lib.extras.herdr {
    enable = herdr;
    package = pkgs.herdr;
  };

  defaultSharedPermissions = c:
    lib.optionals persistHome (atb.lib.extras.persistHomePermissions c)
    ++ lib.optionals flakeRoot (atb.lib.extras.flakeRootPermissions c)
    ++ atb.lib.extras.gitPermissions c
    ++ atb.lib.extras.jailHome c
    ++ [
      (c.unsafe-add-raw-args "--ro-bind-try \"$HOME/.config/gh\" \"$JAIL_HOME/.config/gh\"")
      (c.unsafe-add-raw-args "--bind-try \"$HOME/.cargo\" \"$JAIL_HOME/.cargo\"")
      (c.readonly "/nix")
      (c.try-readwrite "/nix/var/nix/daemon-socket")
      (c.try-readonly "/nix/var/nix/db")
      (c.readonly "/run/current-system")
      (c.runtime-deep-ro-bind (c.noescape "/run/opengl-driver"))
      (c.runtime-deep-ro-bind (c.noescape "/run/opengl-driver-32"))
      (c.add-path "/run/current-system/sw/bin")
      # Nix inside the jail has no writable store: use the host daemon, and
      # trust the system CA bundle for fetches.
      (c.set-env "NIX_REMOTE" "daemon")
      (c.set-env "NIX_SSL_CERT_FILE" "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt")
      (c.set-env "SSL_CERT_FILE" "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt")
    ]
    ++ herdrHelper.permissions c
    ++ lib.optionals ghToken [
      (c.try-fwd-env "GH_TOKEN")
    ]
    ++ lib.optionals nvidia [
      (c.try-readonly "/proc/driver/nvidia")
      (c.try-readonly "/sys/class/drm")
      (c.try-readwrite "/dev/shm")
      (c.unsafe-add-raw-args "--dev-bind-try /dev/dri /dev/dri")
    ]
    ++ lib.optionals nvidia (
      map (dev: c.unsafe-add-raw-args "--dev-bind-try ${c.escape dev} ${c.escape dev}") nvidiaDevices
    )
    ++ lib.optionals direnv (atb.lib.extras.devshellPermissions c)
    ++ map (name: c.try-fwd-env name) fwdEnv
    ++ map (name: c.set-env name env.${name}) (builtins.attrNames env)
    ++ resolvePermissions sharedPermissions c;

  opencodeConfig = lib.recursiveUpdate atb.lib.defaultOpencodeConfig (opencode.config or {});
  opencodeAllowAllReads = opencode.allowAllReads or true;

  jailedOpencodeConfig =
    if opencodeAllowAllReads
    then atb.lib.extras.allowAllReads opencodeConfig
    else opencodeConfig;

  opencodeExtraPackages = extraPackages ++ (opencode.extraPackages or []);
  gooseExtraPackages = extraPackages ++ (goose.extraPackages or []);

  mkOpencodePackage = config: let
    package = opencode.package or null;
  in
    atb.lib.mkOpencode {
      inherit config;
      package =
        if package == null
        then pkgs.opencode
        else package;
      extraPackages = opencodeExtraPackages;
    };

  mkGoosePackage = config:
    atb.lib.mkGoose (
      {
        inherit config;
        extraPackages = gooseExtraPackages;
      }
      // lib.optionalAttrs ((goose.package or null) != null) {
        package = goose.package;
      }
    );

  mkOpencodeAgent = config:
    atb.lib.mkAgent {
      name = "opencode";
      package = mkOpencodePackage config;
      envFromFile = opencode.envFromFile or {};
    };

  mkGooseAgent = config:
    atb.lib.mkAgent {
      name = "goose";
      package = mkGoosePackage config;
      envFromFile = goose.envFromFile or {};
    };

  opencodePermissions = c:
    atb.lib.defaultOpencodePermissions c
    ++ defaultSharedPermissions c
    ++ herdrHelper.opencodePermissions c
    ++ resolvePermissions (opencode.permissions or []) c;

  goosePermissions = c:
    atb.lib.defaultGoosePermissions c
    ++ defaultSharedPermissions c
    ++ [
      (c.try-fwd-env "GOOSE_PROVIDER")
      (c.try-fwd-env "GOOSE_MODEL")
    ]
    ++ resolvePermissions (goose.permissions or []) c;

  # `gh auth token` runs on the host (outside the jail) and the value is
  # forwarded with try-fwd-env, so it never enters the store.
  withGhToken = {
    name,
    package,
    exe,
  }:
    if ghToken
    then
      pkgs.writeShellScriptBin name ''
        if [ -z "''${GH_TOKEN:-}" ]; then
          GH_TOKEN="$(${lib.getExe pkgs.gh} auth token 2>/dev/null || true)"
          if [ -n "$GH_TOKEN" ]; then
            export GH_TOKEN
          fi
        fi
        exec ${package}/bin/${exe} "$@"
      ''
    else package;

  jailedOpencodeAgent = mkOpencodeAgent jailedOpencodeConfig;
  freeOpencodeAgent = mkOpencodeAgent opencodeConfig;

  jailedOpencode = withGhToken {
    name = "opencode";
    package = jailedOpencodeAgent.makeJailedWith {
      name = "opencode";
      permissions = opencodePermissions;
    };
    exe = "opencode";
  };

  freeOpencode = withGhToken {
    name = "opencode-free";
    package = freeOpencodeAgent.free;
    exe = "opencode-free";
  };

  gooseConfig = lib.recursiveUpdate atb.lib.defaultGooseConfig (goose.config or {});
  gooseAgent = mkGooseAgent gooseConfig;

  jailedGoose = withGhToken {
    name = "goose";
    package = gooseAgent.makeJailedWith {
      name = "goose";
      permissions = goosePermissions;
    };
    exe = "goose";
  };

  freeGoose = withGhToken {
    name = "goose-free";
    package = gooseAgent.free;
    exe = "goose-free";
  };
in {
  inherit jailedOpencode freeOpencode jailedGoose freeGoose;
  opencode = jailedOpencode;
  goose = jailedGoose;
  "opencode-free" = freeOpencode;
  "goose-free" = freeGoose;
  packages = [jailedOpencode jailedGoose freeOpencode freeGoose];
}
