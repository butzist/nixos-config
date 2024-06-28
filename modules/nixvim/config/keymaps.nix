{
  globals.mapleader = " ";

  keymaps = [
    {
      mode = ["i" "x" "n" "s"];
      key = "<C-s>";
      action = "<cmd>w<cr><esc>";
      options = {desc = "Save File";};
    }
    {
      mode = ["i" "n"];
      key = "<esc>";
      action = "<cmd>noh<cr><esc>";
      options = {desc = "Escape and Clear hlsearch";};
    }
    {
      mode = "n";
      key = "<leader>ur";
      action = "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>";
      options = {desc = "Redraw / Clear hlsearch / Diff Update";};
    }
    {
      mode = "n";
      key = "n";
      action = "'Nn'[v:searchforward].'zv'";
      options = {expr = true; desc = "Next Search Result";};
    }
    {
      mode = "x";
      key = "n";
      action = "'Nn'[v:searchforward]";
      options = {expr = true; desc = "Next Search Result";};
    }
    {
      mode = "o";
      key = "n";
      action = "'Nn'[v:searchforward]";
      options = {expr = true; desc = "Next Search Result";};
    }
    {
      mode = "n";
      key = "N";
      action = "'nN'[v:searchforward].'zv'";
      options = {expr = true; desc = "Prev Search Result";};
    }
    {
      mode = "x";
      key = "N";
      action = "'nN'[v:searchforward]";
      options = {expr = true; desc = "Prev Search Result";};
    }
    {
      mode = "o";
      key = "N";
      action = "'nN'[v:searchforward]";
      options = {expr = true; desc = "Prev Search Result";};
    }
    {
      mode = "n";
      key = "<leader>cd";
      action = "vim.diagnostic.open_float";
      options = {desc = "Line Diagnostics";};
    }
    {
      mode = "n";
      key = "]d";
      action = "diagnostic_goto(true)";
      options = {desc = "Next Diagnostic";};
    }
    {
      mode = "n";
      key = "[d";
      action = "diagnostic_goto(false)";
      options = {desc = "Prev Diagnostic";};
    }
    {
      mode = "n";
      key = "]e";
      action = "diagnostic_goto(true 'ERROR')";
      options = {desc = "Next Error";};
    }
    {
      mode = "n";
      key = "[e";
      action = "diagnostic_goto(false 'ERROR')";
      options = {desc = "Prev Error";};
    }
    {
      mode = "n";
      key = "]w";
      action = "diagnostic_goto(true 'WARN')";
      options = {desc = "Next Warning";};
    }
    {
      mode = "n";
      key = "[w";
      action = "diagnostic_goto(false 'WARN')";
      options = {desc = "Prev Warning";};
    }
    {
      mode = "n";
      key = "<leader>qq";
      action = "<cmd>qa<cr>";
      options = {desc = "Quit All";};
    }
    {
      mode = "t";
      key = "<esc><esc>";
      action = "<c-\\><c-n>";
      options = {desc = "Enter Normal Mode";};
    }
    {
      mode = "n";
      key = "<leader>ww";
      action = "<C-W>p";
      options = {desc = "Other Window"; remap = true;};
    }
    {
      mode = "n";
      key = "<leader>wd";
      action = "<C-W>c";
      options = {desc = "Delete Window"; remap = true;};
    }
    {
      mode = "n";
      key = "<leader>w-";
      action = "<C-W>s";
      options = {desc = "Split Window Below"; remap = true;};
    }
    {
      mode = "n";
      key = "<leader>w|";
      action = "<C-W>v";
      options = {desc = "Split Window Right"; remap = true;};
    }
  ];
}

