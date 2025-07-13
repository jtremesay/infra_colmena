{ config, ... }:
{
  sops.secrets.borgmatic = { };

  services.borgmatic = {
    enable = true;
    settings = {
      constants = {
        hostname = config.networking.hostName;
      };
      source_directories = [
        "/etc"
        "/home"
      ];
      repositories = [
        {
          label = "sway";
          path = "ssh://sway/./borg-repository";
        }
      ];
      exclude_patterns = [
        "/home/*/.cache/"
      ];
      encryption_passcommand = "cat ${config.sops.secrets.borgmatic.path}";
      retries = 3;
      retry_wait = 10;
      keep_hourly = 24;
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 12;
    };
  };

  home-manager.users.root.programs.ssh.matchBlocks = {
    sway = {
      hostname = "u456662.your-storagebox.de";
      user = "u456662";
      port = 23;
    };
  };
}
