{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    vscode

    kubectl
    k9s
    terraform
    terragrunt
    helm

    microsoft-edge

    fnm
  ];

  programs = {
    go = {
      enable = true;
      goPath = "go";
      goPrivate = [ "gitlab.com/datahow" ];
    };

    k9s.enable = true;
  };
}
