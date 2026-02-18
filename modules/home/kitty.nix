_: {
  programs.kitty = {
    enable = true;
    settings = {
      copy_on_select = "clipboard";
      clear_all_shortcuts = "yes";
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";
      confirm_os_window_close = 0;
      dynamic_background_opacity = true;
      enable_audio_bell = false;
      window_padding_width = 10;
      background_blur = 5;
    };
    keybindings = {
      "cmd+alt+h" = "previous_tab";
      "cmd+alt+l" = "next_tab";
      "cmd+alt+t" = "new_tab";
      "cmd+c" = "copy_to_clipboard";
      "cmd+v" = "paste_from_clipboard";
    };
  };
}
