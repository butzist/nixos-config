# The agent-toolbox mcpls package ships a prebuilt binary with a /lib64 ELF
# interpreter, which cannot run on NixOS. Patch it with autoPatchelf so the
# MCP/LSP bridge starts both on the host and inside the agent jails.
{pkgs, ...}:
pkgs.mcpls.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.autoPatchelfHook];
  buildInputs = (old.buildInputs or []) ++ [pkgs.stdenv.cc.cc.lib];
})
