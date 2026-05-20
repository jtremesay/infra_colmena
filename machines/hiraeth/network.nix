{ config, ... }:
{
  networking = {
    interfaces = {
      eno1 = {
        ipv4.addresses = [
          {
            address = "145.239.67.56";
            prefixLength = 24;
          }
        ];

        ipv6.addresses = [
          {
            address = "2001:41d0:303:3638::1";
            prefixLength = 128;
          }
        ];
      };
    };

    defaultGateway = {
      address = "145.239.67.254";
      interface = "eno1";
    };

    defaultGateway6 = {
      address = "2001:41d0:0303:36ff:00ff:00ff:00ff:00ff";
      interface = "eno1";
    };
  };
}
