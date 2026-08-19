{ config, lib, ... }:
let
  users = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
  secretsDir = ../secrets/users;
  mkSshSecrets = username:
    let
      ageFile = secretsDir + "/${username}/id_ed25519.age";
      homeDir = config.users.users.${username}.home;
    in
    if builtins.pathExists ageFile then {
      "users/${username}/id_ed25519" = {
        file = ageFile;
        mode = "0400";
        owner = username;
        path = "${homeDir}/.ssh/id_ed25519";
      };
    } else {};
in
{
  age.secrets = lib.foldl' (acc: user: acc // mkSshSecrets user) {} users;
}
