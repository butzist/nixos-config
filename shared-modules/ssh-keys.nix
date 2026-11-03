{ config, lib, ... }:
let
  secretsDir = ../secrets/users;
  pubkeyUsers =
    lib.filterAttrs
    (name: _: builtins.pathExists (secretsDir + "/${name}/id_ed25519.pub"))
    (builtins.readDir secretsDir);
  authorizedKeysFor = username: [
    (lib.removeSuffix "\n" (builtins.readFile (secretsDir + "/${username}/id_ed25519.pub")))
  ];
  hmUsers = config.home-manager.users or (config.home-manager.darwinUsers or {});
  ageUsers =
    lib.filterAttrs
    (name: _: builtins.pathExists (secretsDir + "/${name}/id_ed25519.age"))
    (builtins.readDir secretsDir);
  users = lib.attrNames (lib.filterAttrs (name: _: builtins.hasAttr name hmUsers) ageUsers);
  mkSshSecrets = username: let
    ageFile = secretsDir + "/${username}/id_ed25519.age";
    homeDir = config.users.users.${username}.home;
  in
    if builtins.pathExists ageFile
    then {
      "users/${username}/id_ed25519" = {
        file = ageFile;
        mode = "0400";
        owner = username;
        path = "${homeDir}/.ssh/id_ed25519";
      };
    }
    else {};
in {
  age.secrets = lib.foldl' (acc: user: acc // mkSshSecrets user) {} users;

  users.users =
    lib.mapAttrs
    (
      username: _:
        { openssh.authorizedKeys.keys = authorizedKeysFor username; }
    )
    (lib.filterAttrs (name: _: builtins.hasAttr name hmUsers) pubkeyUsers);
}
