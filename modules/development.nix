{ config, lib, pkgs, ... }:

{
  imports = [
    ./neovim/neovim.nix
  ];

  home.packages = with pkgs; [
    nodejs_20
    go

    python312
    poetry
    python312Packages.pip
    python312Packages.virtualenv

    rustc
    rustc-wasm32
    wasm-pack
    wasm-bindgen-cli
    cargo
    rust-analyzer
    clippy
    rustfmt
    clang
    mold
  ];


  home.file = {
    ".cargo/config.toml".text = ''
      [target.x86_64-unknown-linux-gnu]
      linker = "clang"
      rustflags = ["-C", "link-arg=--ld-path=mold"]
    '';
  };
}
