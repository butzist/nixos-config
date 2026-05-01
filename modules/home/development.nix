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
    nodejs_24
    bun
    deno

    # python
    python314
    uv
    ruff
    python314Packages.pip
    python314Packages.virtualenv

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
    opencode
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
