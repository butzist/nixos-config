{
  pkgs,
  lib,
  ...
}: {
  # mold's cargo config targets a Linux linker
  config = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    home.packages = with pkgs; [
      mold
    ];

    home.file = {
      ".cargo/config.toml".text = ''
        [target.x86_64-unknown-linux-gnu]
        linker = "clang"
        rustflags = ["-C", "link-arg=--ld-path=mold"]
      '';
    };
  };
}
