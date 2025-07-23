{ config, pkgs, lib, username, ...

}:

with lib;

{
  #---------------------------------------------------------------------
  # Install necessary packages
  #---------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    OVMFFull
    adwaita-icon-theme
    kvmtool
    libvirt
    qemu
    qemu-user
    qemu-utils
    qemu_full
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
    virtualbox
    win-spice
    win-virtio
  ];

  #---------------------------------------------------------------------
  # Manage the virtualisation services : Libvirt stuff
  #---------------------------------------------------------------------
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";

      qemu = {
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
      };
    };

    spiceUSBRedirection.enable = true;
  };

  environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];

  services.spice-vdagentd.enable = true;
  systemd.services.libvirtd.restartIfChanged = false;
  
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "${username}" ];

  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.dragAndDrop = true;

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 10;
      memorySize = 12000;
    };

    docker = {
      enable = false;
      enableOnBoot = false;
      autoPrune = { enable = true; };
      members = [
        "${username}"

      ];
    };
  };
}
