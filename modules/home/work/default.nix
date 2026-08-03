{pkgs, ...}: {
  imports = [];

  home.packages = with pkgs; [
    remmina

    # devops
    kubectl
    kubernetes-helm
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
  ];

  programs = {
    poetry = {
      enable = true;
      package = pkgs._stable.poetry;
      settings = {
        virtualenvs.create = true;
        virtualenvs.in-project = true;
      };
    };

    k9s.enable = true;
  };
}
