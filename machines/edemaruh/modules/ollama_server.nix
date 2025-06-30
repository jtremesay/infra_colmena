{ ... }:
{
  # Ollama CUDA
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    loadModels = [
      "cogito:3b"
      "cogito:8b"
      "cogito:14b"
      "cogito:32b"
      "gemma3:1b"
      "gemma3:4b"
      "gemma3:12b"
      "gemma3:27b"
      "gemma3n:e2b"
      "gemma3n:e4b"
      "granite3.3:2b"
      "granite3.3:8b"
      "llama4:16x17b"
      "mistral-small3.2:24b"
      "phi4:14b"
      "phi4-reasoning:14b"
      "phi4-mini:3.8b"
      "phi4-mini-reasoning:3.8b"
      "qwen3:0.6b"
      "qwen3:1.7b"
      "qwen3:4b"
      "qwen3:8b"
      "qwen3:14b"
      "qwen3:30b"
      "qwen3:32b"
    ];
    host = "0.0.0.0";
  };
}
