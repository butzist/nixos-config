# REA (rea-agents) is not in nixpkgs yet. This started from the pending package
# in https://github.com/NixOS/nixpkgs/pull/574658, except that the also-unmerged
# `installAgentSkills` hook (NixOS/nixpkgs#558216) is inlined as a plain copy.
# Local addition: the prebuilt `tsrs` build tool has to be patchelf'd so it can
# run in the sandbox.
# Drop this file and use `pkgs.rea` once both PRs land.
{
  lib,
  stdenv,
  autoPatchelfHook,
  buildNpmPackage,
  fetchFromGitHub,
  installShellFiles,
  makeWrapper,
  nix-update-script,
  nodejs_26,
  procps,
  versionCheckHook,
}:
buildNpmPackage (finalAttrs: {
  pname = "rea";
  version = "6.8.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "morluto";
    repo = "rea";
    tag = "rea-agents-${finalAttrs.version}";
    hash = "sha256-2ADn3U3lvUoB4tCEpzO0rMfYE4sis+5uBiEazcp0gpI=";
  };

  npmDepsHash = "sha256-3WPXD+qm5WVfrTEvepKwX5RZBfbLBcPB0uDmKIx4MR8=";

  # frida (optional dependency) installs a platform binary via
  # prebuild-install, which cannot work in the sandbox. None of the other
  # dependencies have install scripts.
  npmFlags = ["--ignore-scripts"];

  npmBuildScript = "compile";
  postBuild = "node scripts/generate-skill-metadata.mjs";

  # engines: ^22.23.4 || ^24.22.1 || >=26.12.1
  nodejs = nodejs_26;

  nativeBuildInputs =
    [installShellFiles]
    ++ lib.optionals stdenv.hostPlatform.isLinux [autoPatchelfHook makeWrapper];

  # The build tool tsrs ships a prebuilt generic-glibc binary as an optional
  # platform dependency; patch it (and any other native dep) before the build
  # phase runs it.
  preBuild = lib.optionalString stdenv.hostPlatform.isLinux ''
    autoPatchelf node_modules
  '';

  # The lockfile also carries the musl builds of these platform binaries; they
  # are never loaded on a glibc host, so do not try to resolve musl's libc.
  autoPatchelfIgnoreMissingDeps =
    lib.optional stdenv.hostPlatform.isLinux "libc.musl-${stdenv.hostPlatform.parsed.cpu.name}.so.1";

  buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;

  postInstall =
    ''
      # Without its platform binary the frida JS binding fails at load time
      # with a misleading error; remove it so that frida reports as missing.
      rm -rf "$out/lib/node_modules/rea-agents/node_modules/frida"

      # Where installAgentSkills would install the bundled workflow skill.
      install -d "$out/share/skills/rea"
      cp -RLT skills/reverse-engineer-anything "$out/share/skills/rea/reverse-engineer-anything"
    ''
    + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      "$out/bin/rea" completions bash > rea.bash
      "$out/bin/rea" completions fish > rea.fish
      "$out/bin/rea" completions nushell > rea.nu
      "$out/bin/rea" completions zsh > rea.zsh
      installShellCompletion rea.{bash,fish,nu,zsh}
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      # Upstream requires a procps-compatible ps on PATH for Linux
      # owned-process analysis; macOS uses /bin/ps and its own helpers.
      wrapProgram "$out/bin/rea" --prefix PATH : ${lib.makeBinPath [procps]}
      wrapProgram "$out/bin/rea-agents" --prefix PATH : ${lib.makeBinPath [procps]}
    '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [versionCheckHook];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Reverse engineer anything from your terminal or agent with one CLI and MCP server";
    homepage = "https://github.com/morluto/rea";
    changelog = "https://github.com/morluto/rea/releases/tag/rea-agents-${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "rea";
    maintainers = with lib.maintainers; [luochen1990];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
