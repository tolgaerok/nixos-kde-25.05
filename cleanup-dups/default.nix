{

  # -----------------------------------------------
  # cleanup section
  # -----------------------------------------------
  nixpkgs.overlays = [
    (self: super: {
      signond = super.signond.overrideAttrs (old: {
        postInstall = ''
          rm -rf $out/share/doc/signon-plugins*
          rm -rf $out/share/examples/signon-plugins*
          rm -rf $out/share/icons/hicolor/*
          ${old.postInstall or ""}
        '';
      });

    })
  ];
}

