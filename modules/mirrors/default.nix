{ config, lib, ... }:
let
  cfg = config.slaanesh.mirrors;
in
{
  options.slaanesh.mirrors = {
    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for the mirrors service";
      default = "mirrors.jtremesay.org";
    };
  };

  imports = [
    ./archlinux.nix
  ];

  config = {

    systemd.tmpfiles.rules = [
      "d /srv/http/mirrors 0755 root root -"
    ];

    services.caddy.virtualHosts."${cfg.host}" = {
      extraConfig = ''
        root * /srv/http/mirrors
        file_server browse
      '';
    };
  };
}
