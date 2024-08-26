{
  plugins.lsp.servers = {
    terraformls = {enable = true;};
    helm-ls = {enable = true;};
  };

  plugins.conform-nvim = {
    formattersByFt = {
      terraform = ["terraform_fmt"];
    };

    formatters = {};
  };

  plugins.helm.enable = true;

  autoGroups = {
    filetypes = {};
  };

  files."ftdetect/terraformft.lua".autoCmd = [
    {
      group = "filetypes";
      event = ["BufRead" "BufNewFile"];
      pattern = ["*.tf" " *.tfvars" " *.hcl"];
      command = "set ft=terraform";
    }
  ];
}
