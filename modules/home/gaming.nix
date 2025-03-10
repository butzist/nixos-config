{pkgs, ...}: {
  home.packages = with pkgs; [
    steam
    (heroic.override {
      extraPkgs = pkgs: [
        pkgs.gamescope
      ];
    })
  ];
}
