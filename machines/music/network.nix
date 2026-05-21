{ config, ... }:
{
  sops.secrets = {
    "wifi" = {
      owner = "wpa_supplicant";
      group = "wpa_supplicant";
      mode = "0400";
    };
  };

  networking = {
    wireless = {
      enable = true;
      secretsFile = config.sops.secrets."wifi".path;
      networks = {
        "SFR_C6B1".pskRaw = "ext:SFR_C6B1";
      };
    };

    interfaces = {
      wlan0 = {
        ipv4.addresses = [
          {
            address = "192.168.1.50";
            prefixLength = 24;
          }
        ];

        ipv6.addresses = [
          {
            address = "2a02:8434:66ee:7001::50";
            prefixLength = 64;
          }
        ];
      };
    };

    defaultGateway = {
      address = "192.168.1.1";
      interface = "wlan0";
    };

    defaultGateway6 = {
      address = "2a02:8434:66ee:7001:b69d:fdff:fe0a:c6b1";
      interface = "wlan0";
    };
  };
}
