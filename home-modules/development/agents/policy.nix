{
  pkgs,
  agent-toolbox,
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

  # Herdr's socket API has no authentication. Jailed agents get only the
  # proxy's JWT-gated auth socket; the real socket (and ~/.config/herdr) never
  # enters the jail. A pane created by `herdr-auth agent spawn` already carries
  # an agent JWT in its environment; that token is kept. Any other inherited
  # token is the proxy's bootstrap token (or another operator token): it is
  # replaced with a fresh orchestrator token scoped to the current directory and
  # workspace, and never forwarded into the jail.
  herdrAuthPermissions = c:
    lib.optionals herdr [
      (c.add-runtime ''
        HERDR_AUTH_SOCKET="''${HERDR_AUTH_SOCKET:-}"
        if [ -z "$HERDR_AUTH_SOCKET" ]; then
          if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
            HERDR_AUTH_SOCKET="$XDG_RUNTIME_DIR/herdr-auth-proxy/auth.sock"
          else
            HERDR_AUTH_SOCKET="''${XDG_STATE_HOME:-$HOME/.local/state}/herdr-auth-proxy/auth.sock"
          fi
        fi

        # FLAKE_ROOT can be the home directory, so herdr's real sockets may be
        # visible in the jail through that bind. Always mask every known real
        # socket with /dev/null (a bind-mount is not a socket, so connect()
        # still fails); only the proxy's auth socket below is left reachable.
        herdr_config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/herdr"
        herdr_sockets=(
          "$herdr_config_dir/herdr.sock"
          "$herdr_config_dir/herdr-client.sock"
        )
        if [ -n "''${HERDR_SESSION:-}" ]; then
          herdr_sockets+=(
            "$herdr_config_dir/sessions/$HERDR_SESSION/herdr.sock"
            "$herdr_config_dir/sessions/$HERDR_SESSION/herdr-client.sock"
          )
        fi
        if [ -n "''${HERDR_SOCKET_PATH:-}" ]; then
          herdr_sockets+=("$HERDR_SOCKET_PATH")
          case "$HERDR_SOCKET_PATH" in
            *.sock) herdr_sockets+=("''${HERDR_SOCKET_PATH%.sock}-client.sock") ;;
          esac
        fi
        if [ -n "''${HERDR_CLIENT_SOCKET_PATH:-}" ]; then
          herdr_sockets+=("$HERDR_CLIENT_SOCKET_PATH")
        fi
        declare -A masked_herdr_sockets=()
        for socket in "''${herdr_sockets[@]}"; do
          if [ -z "$socket" ] || [ "$socket" = "$HERDR_AUTH_SOCKET" ] || [ -n "''${masked_herdr_sockets[$socket]:-}" ]; then
            continue
          fi
          masked_herdr_sockets[$socket]=1
          RUNTIME_ARGS+=(--ro-bind-try /dev/null "$socket")
        done

        if [ -S "$HERDR_AUTH_SOCKET" ]; then
          # Reuse only a pane-bound agent token. Decode without trusting the
          # payload: it still has to pass the proxy's signature check.
          jwt_role=""
          if [ -n "''${HERDR_AUTH_JWT:-}" ]; then
            jwt_role="$(printf '%s' "$HERDR_AUTH_JWT" | ${pkgs.jq}/bin/jq -Rr 'split(".")[1] | @base64d | fromjson | .role // empty' 2>/dev/null || true)"
            export HERDR_AUTH_JWT
          fi
          if [ "$jwt_role" != "agent" ]; then
            # The bootstrap token has no cwd/workspace of its own; an
            # orchestrator minted from it must name both. Use the agent's
            # current directory (mount-cwd binds it into the jail) and the
            # workspace the pane belongs to.
            #
            # Orchestrator tokens default to agent_grants=["report_status"], so
            # without this perm the jailed orchestrator can only spawn agents
            # that report status: an agent could not read its own pane or wait
            # for its own output. Raise the cap explicitly; child spawns still
            # have to request the grants they want (and are intersected with
            # this list). `wait_own_status` does not exist — the grantable name
            # is `wait_own_output`.
            herdr_cwd="$PWD"
            if [ -d "$herdr_cwd" ]; then
              herdr_cwd="$(cd "$herdr_cwd" && pwd -P)" || herdr_cwd=""
            else
              herdr_cwd=""
            fi
            if [ -n "$herdr_cwd" ] && [ -n "''${HERDR_WORKSPACE_ID:-}" ]; then
              HERDR_AUTH_JWT="$(${herdrAuthProxy}/bin/herdr-auth --socket "$HERDR_AUTH_SOCKET" token mint \
                --role orchestrator \
                --sub "''${HERDR_PANE_ID:-''${USER:-orchestrator}}" \
                --cwd "$herdr_cwd" \
                --workspace "$HERDR_WORKSPACE_ID" \
                --perm '{"agent_grants":["report_status","read_own_pane","wait_own_output"],"agent_kinds":["opencode"]}' \
                2>/dev/null | ${pkgs.jq}/bin/jq -r '.token // empty' 2>/dev/null || true)"
            fi
            if [ -z "''${HERDR_AUTH_JWT:-}" ]; then
              unset HERDR_AUTH_JWT
            fi
          fi
          install -d "$JAIL_HOME/.local/state/herdr-auth-proxy"
          RUNTIME_ARGS+=(
            --bind "$HERDR_AUTH_SOCKET" "$JAIL_HOME/.local/state/herdr-auth-proxy/auth.sock"
            --setenv HERDR_SOCKET_PATH "$JAIL_HOME/.local/state/herdr-auth-proxy/auth.sock"
            --setenv HERDR_AUTH_SOCKET "$JAIL_HOME/.local/state/herdr-auth-proxy/auth.sock"
          )
          if [ -n "''${HERDR_AUTH_JWT:-}" ]; then
            RUNTIME_ARGS+=(--setenv HERDR_AUTH_JWT "$HERDR_AUTH_JWT")
          fi
        fi
      '')
      (c.try-fwd-env "HERDR_ENV")
      (c.try-fwd-env "HERDR_PANE_ID")
      (c.try-fwd-env "HERDR_WORKSPACE_ID")
      (c.try-fwd-env "HERDR_TAB_ID")
      (c.try-fwd-env "HERDR_BIN_PATH")
    ];

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
      # The store is already bound read-only; copying leaves a real file that
      # Herdr's later `chmod -R u+w` can safely make writable in the jail home.
      (c.wrap-entry (entry: ''
        mkdir -p "$HOME/.config/opencode/plugins"
        cp -f ${colliePlugin} "$HOME/.config/opencode/plugins/collie-opencode-bridge.js"
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
    ++ opencodeColliePermissions c
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
