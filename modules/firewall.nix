{ ... }:
{
  networking = {
    firewall = {
      enable = true;
      trustedInterfaces = [
        "lo"
        "tailscale0"
      ];
    };
    nftables.enable = true;
  };
}
