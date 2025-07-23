{ ... }:
{
  networking = {
    firewall = {
      enable = true;
      trustedInterfaces = [
        "lo"
      ];
    };
    nftables = {
      enable = true;
    };
  };
}
