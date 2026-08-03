{
  pkgs,
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
          hyprctl dispatch dpms off "$name"
          sleep 1
          hyprctl dispatch dpms on "$name"
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
      "desc:Samsung Display Corp. ATNA60HS03-0, 2560x1600, 0x0, 1.333333"
      "desc:HP Inc. HP E24i G4 6CM406371S, 1920x1200, 1920x0, 1"
      "desc:HP Inc. HP E24i G4 6CM40635HR, 1920x1200, 3840x0, 1"
    ];

    exec-once = [
      "${dpms-retrain}/bin/dpms-retrain"
    ];
  };
}
