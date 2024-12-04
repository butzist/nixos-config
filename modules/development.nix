{pkgs, ...}: {
  imports = [
  ];

  home.packages = with pkgs; [
    nodejs_20

    python313
    poetry
    python313Packages.pip
    python313Packages.virtualenv

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
