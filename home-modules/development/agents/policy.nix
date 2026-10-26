{
  pkgs,
  agent-toolbox,
  herdrPackage,
  rtkShell,
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
  crush ? {},
  pi ? {},
}: let
  inherit (pkgs) lib;
  atb = agent-toolbox;

  opencodeFile = import ./opencode.nix {inherit pkgs rtkShell;};
  crushFile = import ./crush.nix {inherit pkgs;};
  piFile = import ./pi.nix {inherit pkgs rtkShell;};

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

  herdrEnv = atb.lib.extras.herdrEnv {enable = herdr;};

  # Herdr's OpenCode plugin is agent-specific, so it is prepared here rather
  # than in the toolbox (which only forwards the generic Herdr environment).
  herdrOpencodePlugin =
    pkgs.runCommand "herdr-opencode-plugins" {
      nativeBuildInputs = [herdrPackage];
    } ''
      mkdir -p home/.config/opencode
      HOME=$TMPDIR/home XDG_CONFIG_HOME=$TMPDIR/home/.config \
        ${lib.getExe herdrPackage} integration install opencode >/dev/null
      mkdir -p $out
      cp -a home/.config/opencode/. $out/
    '';

  opencodeHerdrPermissions = c:
    lib.optionals herdr [
      (c.wrap-entry (entry: ''
        mkdir -p "$HOME/.config/opencode"
        cp -r --no-preserve=mode,ownership ${herdrOpencodePlugin}/. "$HOME/.config/opencode/"
        chmod -R u+w "$HOME/.config/opencode"
        ${entry}
      ''))
    ];

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
      # Generic fallback: agents that spawn `$SHELL -c` (but have no explicit
      # shell setting) still get rtk. Agents with their own shell config use
      # that instead; crush ignores SHELL and uses its embedded bash.
      (c.set-env "SHELL" "${rtkShell}/bin/rtk-shell")
    ]
    ++ herdrEnv.permissions c
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

  # Base for the agents that need browser/clipboard helpers in the jail.
  defaultInteractivePermissions = c:
    atb.lib.defaultPermissions c
    ++ [(c.add-pkg-deps [pkgs.xdg-utils])];

  # opencode-specific: auto-approve reads of everything visible inside the jail.
  allowAllReads = config:
    lib.recursiveUpdate config {
      permission = {
        external_directory = {"*" = "allow";};
        read = {"*" = "allow";};
      };
    };

  opencodeConfig = opencode.config or {};
  opencodeAllowAllReads = opencode.allowAllReads or true;

  jailedOpencodeConfig =
    if opencodeAllowAllReads
    then allowAllReads opencodeConfig
    else opencodeConfig;

  opencodeExtraPackages = extraPackages ++ (opencode.extraPackages or []);
  crushExtraPackages = extraPackages ++ (crush.extraPackages or []);
  piExtraPackages = extraPackages ++ (pi.extraPackages or []);

  mkOpencodePackage = config:
    opencodeFile.mkPackage {
      inherit config;
      package = opencode.package or pkgs.opencode;
      extraPackages = opencodeExtraPackages;
    };

  mkCrushPackage = config:
    crushFile.mkPackage {
      inherit config;
      colors = crush.colors or null;
      package = crush.package or pkgs.crush;
      extraPackages = crushExtraPackages;
    };

  mkPiPackage = piFile.mkPackage {
    settings = pi.settings or {};
    models = pi.models or {};
    colors = pi.colors or null;
    polarity = pi.polarity or "dark";
    extraPackages = piExtraPackages;
    package = pi.package or pkgs.pi-coding-agent;
    inherit herdr herdrPackage;
  };

  mkOpencodeAgent = config:
    atb.lib.mkAgent {
      name = "opencode";
      package = mkOpencodePackage config;
      envFromFile = opencode.envFromFile or {};
    };

  mkCrushAgent = config:
    atb.lib.mkAgent {
      name = "crush";
      package = mkCrushPackage config;
      envFromFile = crush.envFromFile or {};
    };

  piAgent = atb.lib.mkAgent {
    name = "pi";
    package = mkPiPackage;
    envFromFile = pi.envFromFile or {};
  };

  opencodePermissions = c:
    defaultInteractivePermissions c
    ++ defaultSharedPermissions c
    ++ opencodeHerdrPermissions c
    ++ resolvePermissions (opencode.permissions or []) c;

  # Crush reports its state to Herdr natively; only the shared Herdr env is
  # needed. It runs commands through its embedded bash, so no rtk shell.
  crushPermissions = c:
    defaultInteractivePermissions c
    ++ defaultSharedPermissions c
    ++ resolvePermissions (crush.permissions or []) c;

  # Pi reports through the integration extension baked into the package.
  piPermissions = c:
    defaultInteractivePermissions c
    ++ defaultSharedPermissions c
    ++ resolvePermissions (pi.permissions or []) c;

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

  crushConfig = crush.config or {};
  crushAgent = mkCrushAgent crushConfig;

  jailedCrush = withGhToken {
    name = "crush";
    package = crushAgent.makeJailedWith {
      name = "crush";
      permissions = crushPermissions;
    };
    exe = "crush";
  };

  freeCrush = withGhToken {
    name = "crush-free";
    package = crushAgent.free;
    exe = "crush-free";
  };

  jailedPi = withGhToken {
    name = "pi";
    package = piAgent.makeJailedWith {
      name = "pi";
      permissions = piPermissions;
    };
    exe = "pi";
  };

  freePi = withGhToken {
    name = "pi-free";
    package = piAgent.free;
    exe = "pi-free";
  };
in {
  inherit jailedOpencode freeOpencode jailedCrush freeCrush jailedPi freePi;
  opencode = jailedOpencode;
  crush = jailedCrush;
  pi = jailedPi;
  "opencode-free" = freeOpencode;
  "crush-free" = freeCrush;
  "pi-free" = freePi;
  packages = [jailedOpencode freeOpencode jailedCrush freeCrush jailedPi freePi];
}
