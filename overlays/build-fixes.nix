_: {
  nixpkgs.overlays = [
    (_final: prev: {
      hyprlandPlugins.hy3 = prev.hyprlandPlugins.hy3.overrideAttrs (_old: {
        src = prev.fetchFromGitHub {
          owner = "outfoxxed";
          repo = "hy3";
          tag = "hl0.49.0";
          hash = "sha256-dYxkdbg6yj8HhuBkCmklMQVR17N7P32R8ir7b7oNxm4=";
        };
      });
    })
  ];
}
