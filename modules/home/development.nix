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
    nodejs_20
    bun
    deno

    python313
    poetry
    python313Packages.pip
    python313Packages.virtualenv

    go-mockery

    rustup
    cargo-nextest
    cargo-watch
    wasm-pack
    wasm-bindgen-cli
    lldb
    clang

    gnumake
    figlet
    pre-commit
    watchexec
  ];

  programs = {
    git = {
      enable = true;

      extraConfig = {
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
