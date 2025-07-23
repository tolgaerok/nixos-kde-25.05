{ config, pkgs, ... }:

{
  nixpkgs.config.allowBroken = true;

  environment.systemPackages = with pkgs; [
    # ----------------------------------------------------------------------------
    # KDE PIM + akonadi support
    # ----------------------------------------------------------------------------
    kdePackages.akonadi
    kdePackages.akonadi-calendar
    kdePackages.akonadi-calendar-tools
    kdePackages.akonadi-contacts
    kdePackages.akonadi-import-wizard
    kdePackages.akonadi-search
    kdePackages.calendarsupport
    kdePackages.kaccounts-integration
    kdePackages.kaccounts-providers
    kdePackages.kaddressbook

    kdePackages.kdepim-addons

    kdePackages.kdepim-runtime
    kdePackages.kmail-account-wizard
    kdePackages.kontact
    kdePackages.korganizer
    kdePackages.kpimtextedit
    kdePackages.kwallet
    kdePackages.kwalletmanager

    kdePackages.kwallet-pam

    kdePackages.libkdepim
    kdePackages.pimcommon
    kdePackages.signon-kwallet-extension
    # kdePackages.signond
    libsForQt5.akonadi
    libsForQt5.akonadi-calendar
    libsForQt5.akonadi-calendar-tools
    libsForQt5.akonadi-contacts
    libsForQt5.akonadi-import-wizard
    libsForQt5.akonadi-mime
    libsForQt5.akonadi-notes
    libsForQt5.akonadi-search
    libsForQt5.akonadiconsole
    libsForQt5.kaddressbook

    libsForQt5.kwallet-pam

    # libsForQt5.kdepim-addons

    libsForQt5.kdepim-runtime
    libsForQt5.kmail-account-wizard
    libsForQt5.korganizer
    libsForQt5.pimcommon
    libsForQt5.signond
    libsignon-glib
    pimsync
    rPackages.pim
  ];
}
