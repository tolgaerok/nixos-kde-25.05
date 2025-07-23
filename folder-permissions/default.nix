{ config, lib, user, username, users, ... }:

{
  systemd = {

    # ----------------------------------------------------------------------
    # Create needed folders with permissions from global function username
    # ----------------------------------------------------------------------
    tmpfiles.rules = [
      "D! /tmp 1777 root root 0"
      "d /etc/secrets 0775 root root -"
      "d /home 0755 root root -"
      "d /home/${username} 0775 ${username} users -"
      "d /home/${username}/Documents/MEGA 0775 ${username} users -"
      "d /home/${username}/Public 0775 ${username} users -"
      "d /home/${username}/Share1 0775 ${username} users -"
      "d /home/${username}/Share2 0775 ${username} users -"
      "d /home/${username}/lost+found 0775 ${username} users -"
      "d /mnt/SSH_QNAP 0755 ${username} users -"
      "d /var/lib/samba/usershares 1770 root usershares -"
      "d /var/spool/samba 1777 root root -"
    ];

  };
}
