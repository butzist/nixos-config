{
  pkgs,
  isDarwin,
  ...
}: {
  imports =
    if isDarwin
    then []
    else [./rust-mold.nix];

  home.packages = with pkgs; [
    # js
    nodejs_20
    bun
    deno

    # python
    python313
    _stable.poetry
    uv
    ruff
    python313Packages.pip
    python313Packages.virtualenv

    # go
    go-mockery

    # rust
    rustup
    cargo-nextest
    cargo-watch
    cargo-binstall
    cargo-binutils
    wasm-pack
    wasm-bindgen-cli
    lldb
    clang

    # build
    gnumake
    just
    pre-commit
    watchexec

    # assistants
    _bleeding.opencode
  ];

  programs = {
    git = {
      enable = true;

      settings = {
        help = {
          autocorrect = "prompt";
        };
        branch = {
          sort = "-committerdate";
        };
        tag = {
          sort = "version:refname";
        };
        init = {
          defaultBranch = "main";
        };
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };
        commit = {
          verbose = true;
        };
        fetch = {
          prune = true;
          pruneTags = true;
          all = true;
        };
        push = {
          default = "simple";
          autoSetupRemote = true;
          followTags = true;
        };
        pull = {
          rebase = true;
        };
        submodule = {
          recurse = true;
        };
        rebase = {
          autoSquash = true;
          autoStash = true;
          updateRefs = true;
        };
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        merge = {
          conflictstyle = "zdiff3";
        };
      };
    };
    go = {
      enable = true;
    };
  };
}
