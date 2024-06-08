{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    vscode

    kubectl
    terraform
    terragrunt
    helm

    microsoft-edge

    fnm
  ];

  programs = {
    go = { enable = true;
      goPath = "go";
      goPrivate = [ "gitlab.com/datahow" ];
    };
  };
}
