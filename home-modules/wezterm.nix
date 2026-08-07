_: {
  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    extraConfig =
      /*
      lua
      */
      ''
        local a = wezterm.action;
        return {
          disable_default_key_bindings = true;
          keys = {
            { key = 'h', mods = 'CMD|ALT', action = a.ActivateTabRelative(-1) },
            { key = 'j', mods = 'CMD|ALT', action = a.ActivatePaneDirection 'Prev' },
            { key = 'k', mods = 'CMD|ALT', action = a.ActivatePaneDirection 'Next' },
            { key = 'l', mods = 'CMD|ALT', action = a.ActivateTabRelative(1) },
            { key = 'h', mods = 'CMD|ALT|SHIFT', action = a.SplitPane { direction = 'Left' } },
            { key = 'j', mods = 'CMD|ALT|SHIFT', action = a.SplitPane { direction = 'Down' } },
            { key = 'k', mods = 'CMD|ALT|SHIFT', action = a.SplitPane { direction = 'Up' } },
            { key = 'l', mods = 'CMD|ALT|SHIFT', action = a.SplitPane { direction = 'Right' } },
            { key = 't', mods = 'CMD|ALT', action = a.SpawnTab 'CurrentPaneDomain' },
            { key = 'c', mods = 'CMD', action = a.CopyTo 'ClipboardAndPrimarySelection' },
            { key = 'v', mods = 'CMD', action = a.PasteFrom 'Clipboard' },
          },
        }
      '';
  };
}
