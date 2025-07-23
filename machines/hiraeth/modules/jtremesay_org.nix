{ ... }:
{
  services.caddy.virtualHosts."jtremesay.org" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:8081
    '';
  };
}
