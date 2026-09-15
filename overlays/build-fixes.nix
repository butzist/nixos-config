_: {
  nixpkgs.overlays = [
    (_final: prev: {
      goose-cli = prev.goose-cli.overrideAttrs (
        _oldAttrs: (let
          version = "1.50.0";
          rev = "a23a8cd5b138954bc8962cba623c2d8ecd375512";
        in rec {
          inherit version;
          src = prev.fetchFromGitHub {
            inherit rev;
            owner = "aaif-goose";
            repo = "goose";
            hash = "sha256-FyFULyaR3fcshPb19bT4oWdGLK9D6Oq0Z/8T72BceLU=";
          };
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-gveK0npiDiJUC3b+BPi2dO8TRgH5KwRCE6njZo3R1cg=";
          };
          doCheck = false;
        })
      );
    })
  ];
}
