# Work's wallpaper: fetched from the hospital site and pinned by hash so the
# binary stays out of the repo but rebuilds are reproducible.
{pkgs, ...}:
pkgs.fetchurl {
  name = "kispi-spital-treppe.webp";
  url = "https://www.kispi.uzh.ch/sites/default/files/styles/default/public/img/Neubau-Eroeffnung-Akutspital-Kunst_Treppe_(C)barboraprekopova_9869.jpg.webp";
  hash = "sha256-buZdMvSMYqamMW6H19hOclnr+XgNY49kq5zf1EZZWzo=";
}
