{ ... }:

{

  #---------------------------------------------------------------------
  # Various modules outside of nixos, custom additions
  #---------------------------------------------------------------------

  imports = [    
    # ./apple-fonts
    # ./openRGB
    ./appimage-registration   # Credits to Brian Francisco
    ./custom-pkgs             # personal coded scriptBin's
    ./iphone/iphone.nix
    ./smart-drv-mon
    ./vm
    ./system-tweaks/storage-tweaks/SSD

  ];

}
