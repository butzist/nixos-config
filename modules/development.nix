{pkgs, ...}: {
  imports = [
  ];

  home.packages = with pkgs; [
    nodejs_20

    python312
    poetry
    python312Packages.pip
    python312Packages.virtualenv

    unstable.rustup
    unstable.wasm-pack
    unstable.wasm-bindgen-cli
    unstable.mold
  ];

  programs = {
    go = {
      enable = true;
      package = pkgs.unstable.go;
    };
  };

  home.file = {
    ".cargo/config.toml".text = ''
      [target.x86_64-unknown-linux-gnu]
      linker = "clang"
      rustflags = ["-C", "link-arg=--ld-path=mold"]
    '';
  };
}
