{ pkgs, ... }:
{
  users.users.jtremesay = {
    isNormalUser = true;
    description = " jtremesay";
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGm5JRotZU5S8CIeY6UBRc6sVVw22lHHEHRHdwUXBJa jtremesay@nemo"
    ];
  };

  home-manager.users.jtremesay = {
    home = {
      stateVersion = "25.05";
      packages = with pkgs; [
      ];
    };

    programs.git.settings.user = {
      name = "Jonathan Tremesaygues";
      email = "jonathan.tremesaygues@slaanesh.org";
    };
  };
}
