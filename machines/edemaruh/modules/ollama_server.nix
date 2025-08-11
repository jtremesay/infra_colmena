{ ... }:
{
  # Ollama CUDA
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    loadModels = [
      "cogito:8b"
      "deepseek-r1:8b"
      "gemma3:4b"
      "gemma3n:e4b"
      "granite3.3:8b"
      "mistral:7b"
      "phi4-mini:3.8b"
      "phi4-mini-reasoning:3.8b"
      "qwen3:8b"
    ];
    host = "0.0.0.0";
  };
}
