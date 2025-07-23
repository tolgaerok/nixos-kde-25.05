{ config, pkgs, lib, username, ... }:

with lib;

{
  # ------------------------------------------------------------
  # System-wide packages for virtualization and related tools
  # ------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # OVMFFull
    # qemu
    # qemu-user
    # qemu_full
    # virtualbox
    adwaita-icon-theme
    kvmtool
    libvirt
    qemu-utils
    qemu_kvm
    qtemu
    spice
    spice-gtk
    spice-protocol
    spice-vdagent
    swtpm
    uefi-run
    virglrenderer
    virt-manager
    virt-viewer
    win-spice
    win-virtio
  ];

  # ------------------------------------------------------------
  # Virtualization services and settings
  # ------------------------------------------------------------
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    qemu = {
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMF.fd ];
      };
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.virtualbox = {
    host = {
      enable = false;
      enableExtensionPack = false;
    };
    guest = {
      enable = false;
      dragAndDrop = false;
    };
  };

  # ------------------------------------------------------------
  # VM defaults for cores and RAM (Not official option, may be custom)
  # ------------------------------------------------------------
  virtualisation.vmVariant = {
    virtualisation = {
      cores = 10;
      memorySize = 12000;
    };

    docker = {
      enable = false;
      enableOnBoot = false;
      autoPrune = { enable = true; };
      members = [ username ];
    };
  };

  # ------------------------------------------------------------
  # Environment session variable for libvirt URI
  # ------------------------------------------------------------
  environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";

  # ------------------------------------------------------------
  # Enable spice vdagent daemon service
  # ------------------------------------------------------------
  services.spice-vdagentd.enable = true;

  # ------------------------------------------------------------
  # Don’t restart libvirtd service automatically on rebuild changes
  # ------------------------------------------------------------
  systemd.services.libvirtd.restartIfChanged = false;

  # ------------------------------------------------------------
  # Add user to virtualbox users group for device access
  # ------------------------------------------------------------
  users.extraGroups.vboxusers.members = [ username ];
}
