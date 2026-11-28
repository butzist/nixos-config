# Local derivations live here as ordinary Nix files; they are not patches.
# Expose them as sources.customPkgs.<name> from shared-modules/sources.nix.
{pkgs, ...}: {
  # myTool = pkgs.callPackage ./my-tool.nix {};
  mcpls = pkgs.callPackage ./mcpls.nix {};
}
