_: {
  nixpkgs.overlays = [
    (_final: prev: {
      goose-cli = prev.goose-cli.overrideAttrs (
        _oldAttrs: (let
          version = "1.52.0";
          rev = "302b60806639ea9f0ae8f053f49f8bf0e88b26f4";
        in rec {
          inherit version;
          src = prev.fetchFromGitHub {
            inherit rev;
            owner = "aaif-goose";
            repo = "goose";
            hash = "sha256-JowCy5d/qvYW0a4Nx9DGw4uD2/CQZfCLE0qqoJlJZFA=";
          };
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-t5TYJgVXQvAxAXE/EaTrogV3YexxmCV35VXncBzrTxk=";
          };
          doCheck = false;
        })
      );
    })
  ];
}
