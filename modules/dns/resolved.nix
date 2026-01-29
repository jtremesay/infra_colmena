{ config, ... }:
{
  networking = {
    nameservers = [
      # https://www.joindns4.eu
      "86.54.11.100#unfiltered.joindns4.eu"
      "86.54.11.200#unfiltered.joindns4.eu"
      "2a13:1001::86:54:11:100#unfiltered.joindns4.eu"
      "2a13:1001::86:54:11:200#unfiltered.joindns4.eu"
    ];
  };

  services.resolved = {
    enable = true;
    dnsovertls = "true";
    dnssec = "true";
    domains = [ "~." ];
  };
}
