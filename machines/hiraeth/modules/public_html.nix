{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.caddy.virtualHosts."hiraeth.jtremesay.org" = {
    extraConfig = ''
      handle_path /~* {
        root * /srv/http
        file_server browse
      }
    '';
  };

  systemd.tmpfiles.rules =
    [
      "d /srv/http 0755 root root -"
    ]
    ++ lib.flatten (
      lib.mapAttrsToList (name: user: [
        "d /srv/http/${name} 0755 ${name} ${user.group}"
        "L+ /home/${name}/public_html - ${name} ${user.group} - /srv/http/${name}"
      ]) (lib.filterAttrs (name: user: user.isNormalUser && user.createHome) config.users.users)
    );
}
