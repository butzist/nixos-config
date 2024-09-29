{pkgs, ...}: {
  imports = [
    ./vscode.nix
    ./k9s.nix
  ];

  home.packages = with pkgs; [
    unstable.microsoft-edge
    remmina

    # devops
    kubectl
    terraform
    terragrunt
    kubernetes-helm
    minio-client
    (azure-cli.withExtensions [])

    # devops docs
    pre-commit
    helm-docs

    # http testing
    bombardier
    slowhttptest

    # language tools
    fnm
  ];

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
