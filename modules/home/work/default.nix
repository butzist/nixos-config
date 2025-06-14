{
  pkgs,
  isDarwin,
  ...
}: {
  imports = [
    ./vscode.nix
    ./k9s.nix
  ];

  home.packages = with pkgs;
    [
      remmina

      # devops
      kubectl
      terraform
      terragrunt
      kubernetes-helm
      minio-client
      sops
      (azure-cli.withExtensions [])

      # devops docs
      pre-commit
      helm-docs

      # http testing
      bombardier
      slowhttptest

      # language tools
      fnm
    ]
    ++ (
      if isDarwin
      then []
      else [
        msedge.microsoft-edge
      ]
    );

  programs = {
    go = {
      goPath = "go";
      goPrivate = ["gitlab.com/datahow"];
    };

    poetry = {
      enable = true;
      settings = {
        virtualenvs.create = true;
        virtualenvs.in-project = true;
      };
    };
  };
}
