{ config, ... }:
{
  networking = {
    nat = {
      enable = true;
      enableIPv6 = true;
      internalInterfaces = [
        # NixOS containers
        "ve-+"
      ];
    };

    nftables = {
      tables = {
        nat = {
          content = ''
            chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                oifname "${config.networking.nat.externalInterface}" masquerade
            }
          '';
          family = "ip";
        };
      };
    };

  };
}
