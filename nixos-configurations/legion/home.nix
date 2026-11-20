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
  # One screen config for every session on this host (Umbriel, Hyprland,
  # sway); kanshi.nix replaces the old per-compositor monitor configs.
  imports = [./kanshi.nix];

  wayland.windowManager.hyprland.settings = {
    on = {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"${dpms-retrain}/bin/dpms-retrain\")\nend")
      ];
    };
  };

  programs.brave.commandLineArgs = [
    "--disable-features=VaapiVideoEncoder"
  ];
}
