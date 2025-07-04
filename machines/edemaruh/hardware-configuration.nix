# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices = {
    edemaruh-root0 = {
      allowDiscards = true;
      bypassWorkqueues = true;
      device = "/dev/disk/by-uuid/d877e088-cc10-45df-adcb-2816d6583d48";
    };
    edemaruh-root1 = {
      allowDiscards = true;
      bypassWorkqueues = true;
      device = "/dev/disk/by-uuid/3efe6021-955a-4114-96cd-4c8574f8114d";
    };
    edemaruh-swap0 = {
      allowDiscards = true;
      bypassWorkqueues = true;
      device = "/dev/disk/by-uuid/0ff517d8-ed40-470a-9a37-d7b08ecc01fc";
    };
    edemaruh-swap1 = {
      allowDiscards = true;
      bypassWorkqueues = true;
      device = "/dev/disk/by-uuid/a402ee92-14e5-4955-9dd9-ed492b17289e";
    };
  };

  boot.swraid = {
    enable = true;
    mdadmConf = ''
      ARRAY /dev/md0 level=raid1 num-devices=2 metadata=1.2 UUID=241bb635:07b33e02:b0ddfee9:78b13d26 devices=/dev/mapper/edemaruh-root0,/dev/mapper/edemaruh-root1
      MAILADDR root@localhost
    '';
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/698afd35-6f6e-4d07-8d6f-9c673abcb5a6";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7954-3ABA";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    { device = "/dev/mapper/edemaruh-swap0"; }
    { device = "/dev/mapper/edemaruh-swap1"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
