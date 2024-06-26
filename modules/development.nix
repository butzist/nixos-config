{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  home.packages = with pkgs; [
    nodejs_20
    unstable.go

    python312
    poetry
    python312Packages.pip
    python312Packages.virtualenv

    unstable.rustup
    unstable.wasm-pack
    unstable.wasm-bindgen-cli
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
