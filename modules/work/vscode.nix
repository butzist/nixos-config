{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = with pkgs.vscode-extensions;
        [
          bierner.markdown-mermaid
          gitlab.gitlab-workflow
          humao.rest-client
          ms-vscode-remote.remote-containers
          ms-vsliveshare.vsliveshare
          streetsidesoftware.code-spell-checker
          usernamehw.errorlens
          vscodevim.vim
          dbaeumer.vscode-eslint
          ms-python.python
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "banner-comments";
            publisher = "heyimfuzz";
            version = "0.4.3";
            sha256 = "1x6smhjzbhw1h8g8x4s9b440dsfnbbb5zy93smnppz03y478vl2f";
          }
          {
            name = "uuid-generator";
            publisher = "netcorext";
            version = "0.0.5";
            sha256 = "01mhzmc8ck2rk8nr9pqgkp2qk508ssx8asis27ll9vjmw38liiys";
          }
        ];
      userSettings = {
        "[json]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "[jsonc]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "[vue]" = {
          "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
        };
        "[javascript]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "[javascript][typescript][vue]" = {
          "editor.codeActionsOnSave" = {
            "source.organizeImports" = "never";
            "source.fixAll" = "explicit";
            "source.fixAll.eslint" = "explicit";
          };
        };
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
          "source.fixAll" = "explicit";
          "source.fixAll.eslint" = "explicit";
        };
        "editor.formatOnSave" = true;
        "eslint.format.enable" = true;
        "eslint.validate" = [
          "javascript"
          "typescript"
          "javascriptreact"
          "vue"
        ];
        "eslint.workingDirectories" = [
          {
            "mode" = "auto";
          }
        ];
        "eslint.lintTask.enable" = true;
        "editor.fontLigatures" = true;
        "editor.bracketPairColorization.enabled" = true;
        "git.autofetch" = true;
        "git.enableSmartCommit" = true;
        "git.mergeEditor" = true;
        "liveshare.authenticationProvider" = "Microsoft";
        "terminal.integrated.inheritEnv" = false;
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "liveshare.launcherClient" = "visualStudioCode";
        "settingsSync.ignoredExtensions" = [
          "ms-vsliveshare.vsliveshare"
        ];
        "errorLens.excludeBySource" = [
          "cSpell"
        ];
        "banner-comments.h1" = "Standard";
        "editor.renderWhitespace" = "trailing";
        "workbench.editor.empty.hint" = "hidden";
        "workbench.startupEditor" = "none";
        "vim.leader" = "<space>";
      };
    };
  };
}
