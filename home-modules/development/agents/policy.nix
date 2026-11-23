{
  pkgs,
  atb,
  herdrPackage,
  herdrAuthProxy,
  rtkShell,
  extraPackages ? [],
  env ? {},
  fwdEnv ? [],
  sharedPermissions ? [],
  nvidia ? true,
  ghToken ? true,
  flakeRoot ? true,
  herdr ? true,
  collie ? false,
  colliePlugin ? null,
  direnv ? true,
  persistHome ? true,
  opencode ? {},
  opencodeThemeFile,
}: let
  inherit (pkgs) lib;

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

  # Herdr's socket API has no authentication. agent-toolbox's herdrAuth extras
  # mask the real sockets, bind only the proxy's JWT-gated auth socket into the
  # jail, keep a pane token minted by `herdr-auth agent spawn`, and replace any
  # other inherited bootstrap/operator token with a fresh orchestrator token
  # scoped to the current directory and workspace. The jail may grant only
  # report_status/read_own_pane/wait_own_output, and only to opencode agents.
  herdrAuthPermissions = c:
    (atb.extras.herdrAuth {
      inherit herdrAuthProxy;
      enable = herdr;
      agentKinds = ["opencode"];
    })
    .permissions
    c;

  # Herdr owns the OpenCode integration and versions its plugin/config assets
  # with the binary. Run Herdr's installer in the jail home so the files match
  # this Herdr build instead of copying a store snapshot.
  opencodeHerdrPermissions = c:
    lib.optionals herdr [
      (c.wrap-entry (entry: ''
        mkdir -p "''${JAIL_HOME:-$HOME}/.config/opencode"
        ${herdrPackage}/bin/herdr integration install opencode >/dev/null
        ${entry}
      ''))
    ];

  # Jailed homes have no copy of the host's ~/.config/opencode. Link the store
  # theme straight into the jail instead: /nix is already bound read-only, so
  # this needs no extra bwrap mount. ln -sfn keeps it idempotent for persisted
  # homes, and the link always points at the current generated theme.
  opencodeThemePermissions = c: [
    (c.wrap-entry (entry: ''
      mkdir -p "''${JAIL_HOME:-$HOME}/.config/opencode/themes"
      ${pkgs.coreutils}/bin/ln -sfn ${opencodeThemeFile} "''${JAIL_HOME:-$HOME}/.config/opencode/themes/stylix.json"
      ${entry}
    ''))
  ];

  # Collie keeps its persistent state in ~/.local/state/collie (pairing tokens,
  # push subscriptions, audit log). The plugin looks for its Unix socket in
  # ~/.local/state/collie by default (XDG_STATE_HOME is cleared inside the
  # jail), and jails read-only-bind that directory over the tmpfs home. HOME
  # may be the persisted $FLAKE_ROOT/.home, so the destination follows
  # JAIL_HOME rather than the host's HOME. Set COLLIE_STATE_DIR to the same
  # absolute path explicitly so the plugin does not rely on the fallback.
  opencodeColliePermissions = c:
    lib.optionals collie [
      # StateDirectory creates this on the host, but only once Collie starts;
      # make it now so the bind mount below succeeds even before then.
      (c.add-runtime ''
        install -d -m 700 "$HOME/.local/state/collie"
      '')
      (c.try-ro-bind
        (c.noescape "\"$HOME/.local/state/collie\"")
        (c.noescape "\"$JAIL_HOME/.local/state/collie\""))
      (c.set-env "COLLIE_STATE_DIR" (c.noescape "\"$JAIL_HOME/.local/state/collie\""))
      # The store is already bound read-only, so link the plugin from the
      # Collie package instead of copying it into the jail home.
      (c.wrap-entry (entry: ''
        mkdir -p "''${JAIL_HOME:-$HOME}/.config/opencode/plugins"
        ${pkgs.coreutils}/bin/ln -sfn ${colliePlugin} "''${JAIL_HOME:-$HOME}/.config/opencode/plugins/collie-opencode-bridge.js"
        ${entry}
      ''))
    ];

  defaultSharedPermissions = c:
    lib.optionals persistHome (atb.extras.persistHomePermissions c)
    ++ lib.optionals flakeRoot (atb.extras.flakeRootPermissions c)
    ++ atb.extras.gitPermissions c
    ++ atb.extras.jailHome c
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
      # shell setting) still get rtk. opencode has its own `shell` setting and
      # uses that instead.
      (c.set-env "SHELL" "${rtkShell}/bin/rtk-shell")
    ]
    ++ herdrAuthPermissions c
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
    ++ lib.optionals direnv (atb.extras.devshellPermissions c)
    ++ map (name: c.try-fwd-env name) fwdEnv
    ++ map (name: c.set-env name env.${name}) (builtins.attrNames env)
    ++ resolvePermissions sharedPermissions c;

  # Base for the agents that need browser/clipboard helpers in the jail.
  defaultInteractivePermissions = c:
    atb.defaultPermissions c
    ++ [(c.add-pkg-deps [pkgs.xdg-utils])];

  # opencode-specific: auto-approve reads of everything visible inside the jail.
  # V2 uses an ordered `permissions` array; these rules are appended after the
  # built-in defaults, so `read = *` also overrides the default `*.env` prompt.
  allowAllReads = config:
    config
    // {
      permissions =
        (config.permissions or [])
        ++ [
          {
            action = "external_directory";
            resource = "*";
            effect = "allow";
          }
          {
            action = "read";
            resource = "*";
            effect = "allow";
          }
        ];
    };

  opencodeConfig = opencode.config or {};
  opencodeAllowAllReads = opencode.allowAllReads or true;

  # Jail-only servers are layered under the shared config so the user can
  # still override or disable them from `agents.opencode.config`.
  opencodeJailedConfig = lib.recursiveUpdate opencode.jailedConfig opencodeConfig;

  jailedOpencodeConfig =
    if opencodeAllowAllReads
    then allowAllReads opencodeJailedConfig
    else opencodeJailedConfig;

  opencodeExtraPackages = extraPackages ++ (opencode.extraPackages or []);

  mkOpencodePackage = config:
    opencode.mkPackage {
      opencodeConfig = config;
      package = opencode.package;
      extraPackages = opencodeExtraPackages;
    };

  mkOpencodeAgent = config:
    atb.mkAgent {
      name = "opencode";
      package = mkOpencodePackage config;
      envFromFile = opencode.envFromFile or {};
    };

  opencodePermissions = c:
    defaultInteractivePermissions c
    ++ defaultSharedPermissions c
    ++ opencodeHerdrPermissions c
    ++ opencodeThemePermissions c
    ++ opencodeColliePermissions c
    ++ resolvePermissions (opencode.permissions or []) c;

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
in {
  inherit jailedOpencode freeOpencode;
  opencode = jailedOpencode;
  "opencode-free" = freeOpencode;
  packages = [jailedOpencode freeOpencode];
}
