{ config, lib, pkgs, ... }:

{
  imports = [
    ./neovim/neovim.nix
  ];

  home.packages = with pkgs; [
    nodejs_20
    unstable.go

    python312
    poetry
    python312Packages.pip
    python312Packages.virtualenv

    unstable.rustc
    unstable.rustc-wasm32
    unstable.wasm-pack
    unstable.wasm-bindgen-cli
    unstable.cargo
    unstable.rust-analyzer
    unstable.clippy
    unstable.rustfmt
    unstable.clang
    unstable.mold
  ];


  home.file = {
    ".cargo/config.toml".text = ''
      [target.x86_64-unknown-linux-gnu]
      linker = "clang"
      rustflags = ["-C", "link-arg=--ld-path=mold"]
    '';
  };
}
