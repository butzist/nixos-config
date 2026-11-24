{
  inputs,
  pkgs,
  ...
}: let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};

  # Add-on IDs from rycee's firefox-addons, reused for the policies below.
  ids = {
    vimiumC = "vimium-c@gdh1995.cn";
    ublock = "uBlock0@raymondhill.net";
    protonPass = "78272b6fa58f4a1abaac99321d503a20@proton.me";
  };
in {
  imports = [inputs.zen-browser.homeModules.twilight];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    # Both the default toolbar placement and the per-add-on "Run in Private
    # Windows" toggle are only settable through policies, not prefs. Keep the
    # icons in the extensions panel instead of pinned to the address bar.
    # Zen hides the panel button by default; keep it reachable.
    policies.ExtensionSettings = {
      "${ids.vimiumC}" = {
        default_area = "menupanel";
        private_browsing = false;
      };
      "${ids.ublock}" = {
        default_area = "menupanel";
        private_browsing = false;
      };
      "${ids.protonPass}" = {
        default_area = "menupanel";
        private_browsing = false;
      };
    };

    profiles.default = {
      settings = {
        # Everything the first-run dialog asks for is declared here, so a
        # fresh profile does not need to be clicked through.
        "zen.welcome-screen.seen" = true;

        # Zen defaults to hiding it, but a toggle in an existing profile
        # persists; pin the toolbar off for fresh and existing profiles.
        "browser.toolbars.bookmarks.visibility" = "never";

        # HM links the XPIs into the profile; Firefox otherwise leaves every
        # sideloaded add-on disabled until it is enabled by hand.
        "extensions.autoDisableScopes" = 0;

        # Keep add-ons pinned to the versions in this flake instead of
        # pulling whatever AMO serves at the time.
        "extensions.update.autoUpdateDefault" = false;

        # The add-on icons move to the extensions panel; expose its button.
        "zen.theme.hide-unified-extensions-button" = false;

        # Proton Pass replaces Firefox's password manager; stop offering to
        # save logins in the browser.
        "signon.rememberSignons" = false;
      };

      search = {
        force = true; # Zen replaces the generated file on each launch.
        default = "google";
      };

      extensions = {
        packages = [
          addons.vimium-c
          addons.ublock-origin
          addons.proton-pass
        ];

        # Lists from zen-browser-flake's examples/04b-extensions-rycee.nix.
        # `force` writes uBO's storage.js on each switch and disables
        # ExtensionStorageIDB for this profile, which hides other add-ons'
        # IndexedDB state. Use managed storage instead if that ever matters.
        settings = {
          "${ids.ublock}" = {
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
    };
  };

  # The module cannot detect profiles and write to them at the same time.
  stylix.targets.zen-browser = {
    enable = true;
    profileNames = ["default"];
  };
}
