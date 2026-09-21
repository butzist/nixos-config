{ lib, ... }: let
  inherit (builtins) genList head length;

  # bind "key" { actions; } - collapse a single action, use _children for several
  bind = key: actions: {
    "bind \"${key}\"" =
      if length actions == 1 then head actions else { _children = actions; };
  };

  # merge a list of single-key bind attrsets into one mode block
  binds = bindings: lib.foldl' (acc: b: acc // b) {} bindings;

  # common action targets
  lock = {SwitchToMode = "locked";};
  unlock = {SwitchToMode = "normal";};
  enter = mode: {SwitchToMode = mode;};

  # run actions, then return to locked
  bindLock = key: actions: bind key (actions ++ [lock]);

  # the passthrough Alt Super shortcuts available while locked
  super = key: "Alt Super ${key}";
  focusOrTab = dir: {MoveFocusOrTab = dir;};
  focus = dir: {MoveFocus = dir;};
  superBinds = [
    (bind (super "h") [(focusOrTab "left")])
    (bind (super "l") [(focusOrTab "right")])
    (bind (super "j") [(focus "down")])
    (bind (super "k") [(focus "up")])
    (bind (super "left") [(focusOrTab "left")])
    (bind (super "right") [(focusOrTab "right")])
    (bind (super "down") [(focus "down")])
    (bind (super "up") [(focus "up")])
    (bind (super "+") [{Resize = "Increase";}])
    (bind (super "=") [{Resize = "Increase";}])
    (bind (super "-") [{Resize = "Decrease";}])
    (bind (super "[") [{PreviousSwapLayout = {};}])
    (bind (super "]") [{NextSwapLayout = {};}])
    (bind (super "f") [{ToggleFloatingPanes = {};}])
    (bind (super "i") [{MoveTab = "left";}])
    (bind (super "o") [{MoveTab = "right";}])
    (bind (super "p") [{NewPane = {};}])
    (bind (super "t") [{NewTab = {};}])
  ];

  # single-key sub-mode entries from normal
  modeKeys = {
    p = "pane";
    t = "tab";
    n = "resize";
    h = "move";
    s = "scroll";
    o = "session";
  };

  # LaunchOrFocusPlugin "<name>" { floating true; move_to_focused_tab true; }
  plugin = name: {
    LaunchOrFocusPlugin = {
      _args = [name];
      _children = [
        {floating = true;}
        {move_to_focused_tab = true;}
      ];
    };
  };

  # keys to strip from zellij's built-in keymap
  unbindKeys = [
    "Alt left"
    "Alt down"
    "Alt up"
    "Alt right"
    "Alt +"
    "Alt -"
    "Alt ="
    "Alt ["
    "Alt ]"
    "Alt f"
    "Alt h"
    "Alt i"
    "Alt j"
    "Alt k"
    "Alt l"
    "Alt n"
    "Alt p"
    "Alt t"
    "Alt o"
    "Ctrl p"
    "Ctrl n"
    "Ctrl t"
    "Ctrl s"
    "Ctrl o"
    "Ctrl h"
    "Ctrl b"
  ];
in {
  programs.zellij = {
    enable = true;

    settings = {
      show_startup_tips = false;
      default_mode = "locked";

      keybinds = {
        locked = {_props = {clear-defaults = true;};} // binds ([
          (bind "Ctrl g" [unlock])
        ] ++ superBinds);

        normal = binds (
          [
            (bind "q" [{Quit = {};}])
            (bind "Esc" [lock])
          ]
          ++ lib.mapAttrsToList (key: mode: bind key [(enter mode)]) modeKeys
        );

        shared_except = {_args = ["normal" "locked"];} // bind "Esc" [lock];

        pane = binds [
          (bindLock "n" [{NewPane = {};}])
          (bindLock "d" [{NewPane = "down";}])
          (bindLock "r" [{NewPane = "right";}])
          (bindLock "s" [{NewPane = "stacked";}])
          (bindLock "x" [{CloseFocus = {};}])
          (bindLock "f" [{ToggleFocusFullscreen = {};}])
          (bindLock "Shift f" [{ToggleFocusNoUiFullscreen = {};}])
          (bindLock "z" [{TogglePaneFrames = {};}])
          (bindLock "w" [{ToggleFloatingPanes = {};}])
          (bindLock "e" [{TogglePaneEmbedOrFloating = {};}])
          (bindLock "i" [{TogglePanePinned = {};}])
        ];

        tab = binds (
          [
            (bindLock "n" [{NewTab = {};}])
            (bindLock "x" [{CloseTab = {};}])
            (bindLock "s" [{ToggleActiveSyncTab = {};}])
            (bindLock "b" [{BreakPane = {};}])
            (bindLock "]" [{BreakPaneRight = {};}])
            (bindLock "[" [{BreakPaneLeft = {};}])
          ]
          ++ map (n: bindLock (toString n) [{GoToTab = n;}]) (genList (x: x + 1) 9)
        );

        session = binds [
          (bindLock "]" [{FocusHostSession = {};}])
          (bindLock "[" [{FocusGuestSession = {};}])
          (bindLock "f" [{ToggleHostFullscreen = {};}])
          (bindLock "w" [(plugin "session-manager")])
          (bindLock "c" [(plugin "configuration")])
          (bindLock "p" [(plugin "plugin-manager")])
          (bindLock "a" [(plugin "zellij:about")])
          (bindLock "s" [(plugin "zellij:share")])
          (bindLock "l" [(plugin "zellij:layout-manager")])
        ];

        unbind = unbindKeys;
      };
    };
  };
}