{
  pkgs,
  isDarwin,
  ...
}: {
  imports = [
    ./nvf-avante.nix
    ./vscode.nix
  ];

  home.packages = with pkgs;
    [
      remmina

      # devops
      kubectl
      terraform
      stable.terragrunt
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
        security.microsoft-edge
      ]
    );

  programs = {
    go = {
      env = {
        GOPRIVATE = ["gitlab.com/datahow"];
      };
    };

    poetry = {
      enable = true;
      settings = {
        virtualenvs.create = true;
        virtualenvs.in-project = true;
      };
    };

    k9s.enable = true;
  };
}
