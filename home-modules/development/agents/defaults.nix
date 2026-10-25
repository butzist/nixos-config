{
  # System-wide defaults layered under per-user and explicit agent config.
  opencodeConfig = {
    model = "qwen3.6-35b-a3b";
    compaction = {
      auto = true;
      prune = true;
      reserved = 10000;
    };
    provider.FreeToken = {
      npm = "@ai-sdk/openai-compatible";
      name = "FreeToken (local)";
      options.baseURL = "http://localhost:1919/v1";
      models."qwen3.6-35b-a3b" = {
        name = "Qwen3.6-35B-A3B (local)";
        tool_call = true;
        # Stay well under the server's window (opencode undercounts).
        limit = {
          context = 40 * 1024;
          output = 8 * 1024;
        };
        options = {
          temperature = 1.0;
          top_p = 0.95;
          top_k = 64;
        };
      };
    };
  };
}
