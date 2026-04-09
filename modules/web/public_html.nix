{ config, lib, ... }:
let
  cfg = config.slaanesh.public_html;
in
{
  options.slaanesh.public_html = {
    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for the public_html service";
      default = "users.jtremesay.org";
    };
  };

  config = {
    services.caddy.virtualHosts."http://${cfg.host}:8000" = {
      extraConfig = ''
        root * /srv/http/public_html
        file_server browse
      '';
    };

    slaanesh.caddy.reverseProxies."${cfg.host}" = "127.0.0.1:8000";

    systemd.tmpfiles.rules = [
      "d /srv/http 0755 root root -"
    ]
    ++ lib.flatten (
      lib.mapAttrsToList (name: user: [
        "d /srv/http/public_html/${name} 0755 ${name} ${user.group}"
        "L+ /home/${name}/public_html - ${name} ${user.group} - /srv/http/public_html/${name}"
      ]) (lib.filterAttrs (name: user: user.isNormalUser && user.createHome) config.users.users)
    );
  };
}
