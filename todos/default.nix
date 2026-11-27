# NixOS module: deferred-upgrade warnings become normal config.warnings, so
# `nixos-rebuild` prints them without any shell script or extra command.
{
  lib,
  pkgs,
  ...
}: let
  checks = import ./checks.nix {
    inherit lib pkgs;
  };
  messages = map (check: check.message) (lib.filter (check: check.when) checks);
in {
  options.todos.messages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    internal = true;
    description = "Deferred-upgrade warnings currently due.";
  };

  config = {
    todos.messages = messages;
    warnings = messages;
  };
}
