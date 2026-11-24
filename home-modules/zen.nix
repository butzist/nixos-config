{
  inputs,
  pkgs,
  ...
}: let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [inputs.zen-browser.homeModules.twilight];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    profiles.default.extensions = {
      packages = [
        addons.vimium-c
        addons.ublock-origin
        addons.proton-pass
      ];

      # Lists from zen-browser-flake's examples/04b-extensions-rycee.nix.
      # `force` writes uBO's storage.js on each switch and disables
      # ExtensionStorageIDB for this profile, which hides other add-ons'
      # IndexedDB state. Use managed storage instead if that ever matters.
      settings."uBlock0@raymondhill.net" = {
        force = true;
        settings.selectedFilterLists = [
          "user-filters"
          "ublock-filters"
          "ublock-badware"
          "ublock-privacy"
          "ublock-unbreak"
        ];
      };
    };
  };

  # The module cannot detect profiles and write to them at the same time.
  stylix.targets.zen-browser = {
    enable = true;
    profileNames = ["default"];
  };
}
