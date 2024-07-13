{pkgs, ...}: {
  home.packages = with pkgs; [
    unstable.vscode

    kubectl
    terraform
    terragrunt
    helm

    unstable.microsoft-edge

    fnm
  ];

  programs = {
    go = {
      goPath = "go";
      goPrivate = ["gitlab.com/datahow"];
    };

    k9s = {
      enable = true;
      package = pkgs.unstable.k9s;
    };
  };
}
