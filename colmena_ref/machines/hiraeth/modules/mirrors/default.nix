{ pkgs, ... }:
{

  imports = [
    ./archlinux.nix
  ];

  systemd.tmpfiles.rules = [
    "d /srv/http/mirrors 0755 root root -"
  ];

  services.caddy.virtualHosts."http://mirrors.jtremesay.org:8000" = {
    extraConfig = ''
      root * /srv/http/mirrors
      file_server browse
    '';
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers."mirrors" = {
        rule = "Host(`mirrors.jtremesay.org`)";
        service = "mirrors";
        entryPoints = [ "https" ];
        tls.certResolver = "le";
      };

      services."mirrors" = {
        loadBalancer = {
          servers = [
            { url = "http://127.0.0.1:8000"; }
          ];
        };
      };
    };
  };
}
