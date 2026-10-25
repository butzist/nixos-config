{
  pkgs,
  name,
  defaultPackage,
  direnv ? true,
}: let
  inherit (pkgs) lib;

  # Load the project's dev shell before entering the jail. The jail only needs
  # the resulting PATH and environment; store paths are already under /nix.
  direnvBlock = lib.optionalString direnv ''
    if [ -f "$root/.envrc" ]; then
      export FLAKE_ROOT="''${FLAKE_ROOT:-$root}"
      exec ${lib.getExe pkgs.direnv} exec "$root" ${lib.getExe pkgs.bash} -c '
        export AGENTS_FROM_DIRENV=1
        export AGENTS_DEVSHELL_PATH="$PATH"
        exec "$0" "$@"
      ' ${defaultPackage}/bin/${name} "$@"
    fi
  '';
in
  pkgs.writeShellScriptBin name ''
    root="''${FLAKE_ROOT:-$PWD}"
    ${direnvBlock}
    exec ${defaultPackage}/bin/${name} "$@"
  ''
