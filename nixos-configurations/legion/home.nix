{
  pkgs,
  lib,
  ...
}: let
  # The NVIDIA driver occasionally fails to train a DisplayPort link at
  # GDM/boot (see "Unable to read EDID for display device DP-0" in the kernel
  # log), leaving one external monitor dark even though Hyprland reports it as
  # active. Cycling DPMS forces a link retrain (the same effect as toggling the
  # monitor off/on in the display settings).
  dpms-retrain = pkgs.writeShellScriptBin "dpms-retrain" ''
    sleep 1
    for name in $(${pkgs.hyprland}/bin/hyprctl monitors | ${pkgs.gawk}/bin/awk '/^Monitor / {print $2}'); do
      case "$name" in
        DP-*)
          ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = "off", monitor = "'"$name"'" })'
          sleep 1
          ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = "on", monitor = "'"$name"'" })'
          ;;
      esac
    done
  '';
in {
  wayland.windowManager.hyprland.settings = {
    # NOTE: Hyprland matches `desc:` against the monitor description as a
    # PREFIX (not substring), so the full EDID-derived description must be
    # used. These are stable across boots unlike the connector names (which
    # have been observed to change, e.g. eDP-1 <-> eDP-2).
    monitor = [
      {
        output = "desc:Samsung Display Corp. ATNA60HS03-0";
        mode = "2560x1600";
        position = "0x0";
        scale = "1.333333";
      }
      {
        output = "desc:HP Inc. HP E24i G4 6CM406371S";
        mode = "1920x1200";
        position = "1920x0";
        scale = "1";
      }
      {
        output = "desc:HP Inc. HP E24i G4 6CM40635HR";
        mode = "1920x1200";
        position = "3840x0";
        scale = "1";
      }
    ];

    on = {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"${dpms-retrain}/bin/dpms-retrain\")\nend")
      ];
    };
  };

  # opencode: use the local llama.cpp instance
  xdg.configFile."opencode/opencode.jsonc".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "llama.cpp/qwen3.5-9b";
    provider."llama.cpp" = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama.cpp (local)";
      options.baseURL = "http://localhost:11434/v1";
      models = {
        "qwen3.5-9b" = {
          name = "Qwen3.5-9B (local)";
          tool_call = true;
          # Keep the client budget well under llama-server's 64k window: opencode
          # undercounts tokens and used to send prompts that exceeded the old 48k
          # server window ("context exceeded" from llama.cpp). A smaller output
          # leaves room for generation plus a tokenizer-overshoot margin.
          limit = {
            context = 40 * 1024;
            output = 8 * 1024;
          };
          options = {
            temperature = 1.0;
            top_p = 0.95;
            top_k = 64;
          };
        };
      };
    };

    compaction = {
      auto = true;
      prune = true;
      reserved = 10000;
    };
  };

  programs.brave.commandLineArgs = [
    "--disable-features=VaapiVideoEncoder"
  ];
}
