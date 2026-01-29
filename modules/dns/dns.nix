{ config, ... }:
{
  networking = {
    nameservers = [
      # https://www.joindns4.eu
      "86.54.11.100"
      "86.54.11.200"
      "2a13:1001::86:54:11:100"
      "2a13:1001::86:54:11:200"
    ];
  };
}
