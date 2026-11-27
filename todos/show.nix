# Helper for `just todos` / `just todo <name>`: collect messages from every
# NixOS configuration without forcing a system build. Pass null for all names.
name: cfgs: let
  all = builtins.concatLists (map (cfg: cfg.config.todos.messages) (builtins.attrValues cfgs));
  prefix = "TODO(${toString name}):";
  hasPrefix = s: builtins.substring 0 (builtins.stringLength prefix) s == prefix;
  chosen =
    if name == null
    then all
    else builtins.filter hasPrefix all;
  unique = builtins.attrNames (
    builtins.listToAttrs (map (msg: {
        name = msg;
        value = null;
      })
      chosen)
  );
in
  builtins.concatStringsSep "\n" unique
