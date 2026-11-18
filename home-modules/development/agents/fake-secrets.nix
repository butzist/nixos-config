{pkgs}: let
  # Committed stub of the private secrets/ submodule, built as the
  # `fake-secrets` flake package and bound over secrets/ in the agent jails by
  # .envrc. It exists for two reasons:
  #  - agents must not read the real (encrypted) secret material, and
  #  - the flake still has to evaluate there: ssh-keys.nix does readDir on
  #    secrets/users, the per-user sensitive.nix provides the git identity,
  #    and the age.secrets paths must exist.
  #
  # Nix copies submodule content only for `?submodules=1`, and only when the
  # path is a git repository (a plain directory makes it fetch the URL from
  # .gitmodules instead), so the stub is committed into a throwaway repo. The
  # files below are the ones the modules reference; nothing in it is a usable
  # credential.
  #
  # libgit2 refuses a repository owned by another uid, and store paths belong to
  # root, so the output also carries a git config that marks the mount safe.
  # It is only bound to the jail's ~/.gitconfig, never used on the host.
  users = [
    "adam"
    "mirj"
    "games"
    "work"
  ];
in
  pkgs.runCommand "fake-secrets" {
    nativeBuildInputs = [pkgs.git];
    # Pin the commit metadata so the store path does not change per build.
    GIT_AUTHOR_DATE = "2000-01-01T00:00:00Z";
    GIT_COMMITTER_DATE = "2000-01-01T00:00:00Z";
    GIT_CONFIG_NOSYSTEM = "1";
    GIT_CONFIG_GLOBAL = "/dev/null";
  } ''
    export HOME="$TMPDIR"

    mkdir -p "$out"
    git init -q -b main "$out/secrets"

    for user in ${builtins.concatStringsSep " " users}; do
      mkdir -p "$out/secrets/users/$user"
      printf '{ name = "Fake %s"; email = "%s@example.invalid"; }\n' "$user" "$user" \
        > "$out/secrets/users/$user/sensitive.nix"
    done

    # Referenced unconditionally as age.secrets files, so they only need to
    # exist; nothing in the jail ever decrypts them.
    mkdir -p "$out/secrets/users/work" "$out/secrets/tailscale"
    for file in \
      users/work/gpg-private.asc.age \
      users/work/opencode-go-token.txt.age \
      users/work/greenpt-ai-token.txt.age \
      tailscale/oauth.age; do
      printf 'not a real age file\n' > "$out/secrets/$file"
    done

    git -C "$out/secrets" add -A
    git -C "$out/secrets" -c user.name=fake -c user.email=fake@example.invalid -c commit.gpgsign=false \
      commit -qm "fake secrets"

    printf '[safe]\n\tdirectory = *\n' > "$out/gitconfig"
  ''
