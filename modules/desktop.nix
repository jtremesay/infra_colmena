{ pkgs, ... }:
{
  # Configure keymap
  services.xserver.xkb = {
    layout = "fr";
    variant = "bepo";
  };

  # Programs
  programs.firefox.enable = true;

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  #services.xserver.enable = false;

  # Enable Display Manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin = {
    enable = true;
    user = "jtremesay";
  };

  environment.systemPackages = with pkgs; [
    vscode
  ];
}
