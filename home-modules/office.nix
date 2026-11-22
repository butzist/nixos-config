{pkgs, ...}: {
  # Document and image tooling shared by the desktop users.
  home.packages = with pkgs; [
    _stable.libreoffice

    hunspell
    hunspellDicts.de_CH
    hunspellDicts.de_DE
    hunspellDicts.en_US
    hunspellDicts.fr-any
    hunspellDicts.pl_PL

    _stable.inkscape
    pdfcraft
    # photocraft replaces gimp for image editing.
    photocraft
  ];
}
