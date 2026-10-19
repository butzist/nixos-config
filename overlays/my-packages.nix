_: {
  nixpkgs.overlays = [
    (_final: prev: {
      goose-cli = prev.stdenvNoCC.mkDerivation {
        pname = "goose-cli";
        version = "1.55.0";

        # Prebuilt musl release binary: statically linked, so no compile and no
        # patchelf/lib fixups (unlike the gnu asset, which pulls in OpenSSL etc).
        src = prev.fetchurl {
          url = "https://github.com/aaif-goose/goose/releases/download/v1.55.0/goose-x86_64-unknown-linux-musl.tar.gz";
          hash = "sha256-+t4Ue9XrwCDs6gVFOwkFOX8euwHuPeLzZ4VwxcNQLtc=";
        };

        sourceRoot = ".";
        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall
          install -Dm755 goose $out/bin/goose
          runHook postInstall
        '';

        meta = {
          description = "An open source AI agent CLI";
          homepage = "https://github.com/aaif-goose/goose";
          license = prev.lib.licenses.asl20;
          mainProgram = "goose";
          platforms = ["x86_64-linux"];
        };
      };
    })
  ];
}
