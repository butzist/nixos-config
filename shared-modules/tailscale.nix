/*
Tailscale client that self-enrols with the fleet OAuth client secret.

`secrets/tailscale/oauth.age` holds an OAuth client secret (`auth_keys: write`
scope), which tailscale accepts directly as an auth key. Every host registers
as its `networking.hostName` and stays in the tailnet (`ephemeral = false`),
so nothing is needed beyond the secret: reach nodes by name over tailscale0,
which is treated as a trusted interface.

Tailscale's own SSH server is off; remote shells go to the host's sshd, which is
reachable over tailscale0 only (see nixos-modules/base.nix).

One-time control-plane setup: an OAuth client tagged `tag:nix` (OAuth enrolment
must advertise one of the client's own tags) and that tag in `tagOwners`. The
ACLs must allow `tcp:22` to `tag:nix`. The `tailscaleSSH` policy toggle is
unused and can be switched off.
*/
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;

  oauthAge = ../secrets/tailscale/oauth.age;
in {
  config = mkIf (builtins.pathExists oauthAge) {
    age.secrets.tailscale-oauth = {
      file = oauthAge;
      mode = "0400";
    };

    services.tailscale = {
      enable = true;
      openFirewall = true; # inbound UDP 41641, for peer-to-peer without DERP
      authKeyFile = config.age.secrets.tailscale-oauth.path;
      authKeyParameters.ephemeral = false;
      extraSetFlags = ["--ssh=false"];
      extraUpFlags = [
        "--hostname=${config.networking.hostName}"
        "--advertise-tags=tag:nix"
      ];
    };

    systemd.services.tailscaled-autoconnect = {
      after = ["agenix.service"];
      wants = ["agenix.service"];
    };

    # Tailscale's own ACLs gate the tailnet, so serve on tailscale0 without
    # per-host firewall port rules.
    networking.firewall.trustedInterfaces = ["tailscale0"];
  };
}
