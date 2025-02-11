_: {
  nixpkgs.overlays = [
    (_final: prev: {
      basedpyright = prev.basedpyright.overrideAttrs {
        dontCheckForBrokenSymlinks = true;
      };
      lldb = prev.lldb.overrideAttrs {
        dontCheckForBrokenSymlinks = true;
      };
    })
  ];
}
