{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    rsync
  ];

  systemd = {
    timers.mirror_archlinux_sync = {
      wantedBy = [ "timers.target" ];
      unitConfig = {
        Description = "Arch Linux Mirror Sync Timer";
      };
      timerConfig = {
        OnBootSec = "5min";
        OnUnitInactiveSec = "1h";
        units = [ "mirror_archlinux_sync.service" ];
      };
    };

    services.mirror_archlinux_sync = {
      unitConfig = {
        Description = "Arch Linux Mirror Sync Service";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.rsync}/bin/rsync -rtlvH --delete-after --delay-updates --safe-links rsync://rsync.cyberbits.eu/archlinux/ /srv/http/mirrors/archlinux";
      };
    };
  };
}
