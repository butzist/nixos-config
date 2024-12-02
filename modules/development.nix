{pkgs, ...}: {
  imports = [
  ];

  home.packages = with pkgs; [
    nodejs_20

    python312
    poetry
    python312Packages.pip
    python312Packages.virtualenv

    go-mockery

    rustup
    wasm-pack
    wasm-bindgen-cli
    mold
    lldb
    clang

    figlet
    pre-commit
  ];

  programs = {
    go = {
      enable = true;
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
