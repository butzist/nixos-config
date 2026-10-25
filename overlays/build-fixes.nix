_: {
  nixpkgs.overlays = [
    (_final: prev: {
      # azure-cli pulls in fabric, which nixpkgs marks broken because invoke 3
      # is not supported upstream yet (https://github.com/fabric/fabric/issues/2376).
      # Pin invoke to the 2.x line so fabric (and paramiko) stay consistent
      # instead of allowing broken packages globally.
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (_pyFinal: pyPrev: {
            invoke = pyPrev.invoke.overridePythonAttrs (_: {
              version = "2.2.0";
              src = pyPrev.fetchPypi {
                pname = "invoke";
                version = "2.2.0";
                hash = "sha256-7my7EBrxqFnH/oTyomTAWQILDLf+NTX5QkMAq1aPa9U=";
              };
            });
          })
        ];
    })
  ];
}
