{ config, pkgs, lib, user, ... }:

{
  # ssh-keygen -t rsa -b 4096 -f /home/tolga/.ssh/id_rsa -N ""
  # sudo nixos-rebuild switch
  # systemctl daemon-reload
  # systemctl restart mnt-SSH_QNAP.mount
  # systemctl status mnt-SSH_QNAP.mount
  # systemctl status refresh-mnt-SSH_QNAP.service --no-pager

  # sudo umount -lf /mnt/SSH_QNAP

  # ######### QNAP ##############
  # 1st get ssh-keys from nixos box: # ssh-keygen -y -f /etc/secrets/qnap-key
  # mkdir -p /root/.ssh
  # chmod 700 /root/.ssh
  # echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcIa1/IET3oLuu8nSZ6V1T7TKVe4cxIyZACd4U+q/F/NzJ3dUXELjgIxLC3QD6q5ISmTo0Z9shovSbRAPj/7VG92C1V18BDa4qq5DBMHuaDGOdpA4ah9RwQTs7CCLty54gUMRulZYofkmUN32O3GtmdwYzKbxL3AcxVoZuU2vBxjeBRxn8Rb6+zLqWoixRukdutVm6bDakv5QNGEYNnPYEDWMuNgVbhodf/btthplPsf/J9g7UYKDd4FhLsmuuCdYPukzscSqZbY18dd/hyn/bIlWGL6eIx65/u/rLx8o/D66i1hJBy/QBuk3tZxCqpXhdXOXgPhWkuSixV8q5zdBASH/cIUccVi7UFBmkHtG2FbBHCgtVL4IZsBkgjL7TjKN3P6hmlLVwiRJOn0JJffPmeGGXkP9u3CfF4m3MxinIk3MmHT6pcDspMEa06N8dR92tmwA3KPfBDy/ZmWNvO8xU823vz4v8Gb7SYn3MCVSfnb0mUiiecQTFH1aOTbABn2+HkcPDCxjmhFlAkYqK7bY4XRnKpj3z6VrLAwP90ykHiLLQHCkn/8cYVyQyAoihgLIFOVdo/FL/RepIZszaG0rfUKw6r5qr1Y1PJNmDHGdTclXUpUYzSxbgNPUjuIXol+U7F6DqUc/ucTt6yRtEVcpNJxvfKKPxXw4yL4uWKd/uoQ== tolga@G4800-NIXOS' >> /root/.ssh/authorized_keys
  # chmod 600 /root/.ssh/authorized_keys

  # write private key into my /etc/secrets
  environment.etc."secrets/qnap-key".text =
    builtins.readFile /home/tolga/.ssh/id_rsa;
  environment.etc."secrets/qnap-key".mode = "0600";

  # write known_hosts into my /etc/secrets
  environment.etc."secrets/known_hosts".text = ''
    192.168.0.17 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAo7l5goUdtZ073PR9qym8GW9k/bW3iFSKKNrI1T5rc9RrVo4XuP3yE/xlEQ6vK6jkI0Rvf8hBxI7zCKQ0qNn03BJcjZGbT+v0twMo/T781ZEQIEdOt6Wxzg2M0JjHk4PlqdvjX4Rwz7rmsyVNzYxGsQALXYt2X12xVVyuZq9dEwNDtB8OncMB/4yj/WAlMPF84XeSjGT6QGxg2JlalJZ9xWb0cTHIFeyprVfoBKV13O4R/IDZQ8f1vGIluFymDswWRQgABU/FC+L8C81bT0V+UndXhKg18Babgnj3hEWm6J8e7RpjtH8GBHZiFNeZxkrfPn6IlF5qoEmTGN5UJcTThQ==
  '';

  environment.etc."secrets/known_hosts".mode = "0644";

  # ----------------------------------------------- #
  # SSHFS into QNAP using sshfs
  # ----------------------------------------------- #
  fileSystems."/mnt/SSH_QNAP" = {
    device = "admin@192.168.0.17:/";
    fsType = "fuse.sshfs";
    options = [
      "IdentityFile=/etc/secrets/qnap-key"
      "ServerAliveInterval=15"
      "StrictHostKeyChecking=yes"
      "UserKnownHostsFile=/etc/secrets/known_hosts"
      "_netdev"
      "allow_other"
      "gid=100"
      "reconnect"
      "uid=1000"
      "x-systemd.after=network-online.target"
      "x-systemd.requires=network-online.target"
      "x-systemd.mount-timeout=3s"
      "x-systemd.device-timeout=1s"
      # "nofail"
    ];
    neededForBoot = false;
  };

  systemd.services."refresh-mnt-SSH_QNAP" = {
    description = "Refresh My SSH QNAP mount after boot";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "mnt-SSH_QNAP.automount" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl daemon-reload";
      ExecStartPost =
        "${pkgs.systemd}/bin/systemctl restart mnt-SSH_QNAP.mount";
      RemainAfterExit = false;
    };
  };

  systemd.services.kill-qnap-mount = {
    description = "Force-unmount SSH QNAP at shutdown";
    before = [ "umount.target" "shutdown.target" ];
    wantedBy = [ "shutdown.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStart = "${pkgs.utillinux}/bin/umount -lf /mnt/SSH_QNAP";
      TimeoutStopSec = "3s";
    };
  };

}
