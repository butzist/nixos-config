{pkgs, ...}: {
  imports = map (cfg: {programs.nixvim = cfg;}) (import ./config);

  programs.nixvim = {
    enable = true;
  };
}
