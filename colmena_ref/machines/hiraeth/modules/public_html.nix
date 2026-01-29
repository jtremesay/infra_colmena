{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.caddy.virtualHosts."http://users.jtremesay.org:8000" = {
    extraConfig = ''
      root * /srv/http/public_html
      file_server browse
    '';
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers."users" = {
        rule = "Host(`users.jtremesay.org`)";
        service = "users";
        entryPoints = [ "https" ];
        tls.certResolver = "le";
      };

      services."users" = {
        loadBalancer = {
          servers = [
            { url = "http://127.0.0.1:8000"; }
          ];
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/http 0755 root root -"
  ]
  ++ lib.flatten (
    lib.mapAttrsToList (name: user: [
      "d /srv/http/public_html/${name} 0755 ${name} ${user.group}"
      "L+ /home/${name}/public_html - ${name} ${user.group} - /srv/http/public_html/${name}"
    ]) (lib.filterAttrs (name: user: user.isNormalUser && user.createHome) config.users.users)
  );
}
