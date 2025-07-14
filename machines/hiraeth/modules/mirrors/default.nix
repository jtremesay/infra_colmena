{ pkgs, ... }:
{

  imports = [
    ./archlinux.nix
  ];

  systemd.tmpfiles.rules = [
    "d /srv/http/mirrors 0755 root root -"
  ];

  services.caddy.virtualHosts."mirrors.jtremesay.org" = {
    extraConfig = ''
      root * /srv/http/mirrors
      file_server browse
    '';
  };

}
