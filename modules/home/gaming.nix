{pkgs, ...}: {
  home.packages = with pkgs; [
    steam
    (_stable.heroic.override {
      extraPkgs = pkgs: [
        pkgs.gamescope
      ];
    })
  ];
}
