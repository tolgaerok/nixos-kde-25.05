{ config, pkgs, lib, ... }:

{
  # -----------------------------------------------------------
  # My personal wifi settings
  # -----------------------------------------------------------

  environment.systemPackages = with pkgs; [ agenix ];

  networking.networkmanager.enable = true;

  networking.networkmanager.connections = {
    "OPTUS_DADS_5GHz" = {
      uuid = "5e21e583-db22-440f-874a-252ebd8ba2ac";
      type = "wifi";
      interfaceName = "wlp3s0";
      wifi = {
        ssid = "OPTUS_DADS_5GHz";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk =
          "9a3d16c8a27fa64b34647aa3433d2fcae1a7a2c6c4cd3cef8c37a48813f3796c";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };
}

nmcli connection add type wifi \
  ifname wlp3s0 \
  con-name "OPTUS_DADS_5GHz" \
  ssid "OPTUS_DADS_5GHz" \
  wifi-sec.key-mgmt wpa-psk \
  wifi-sec.psk "izardleary84422" \
  ipv4.method auto \
  ipv6.method auto

nmcli connection up "OPTUS_DADS_5GHz"




# sudo mkdir -p /etc/nixos/secrets && sudo chmod 700 /etc/nixos/secrets && echo -n "izardleary84422" | sudo tee /etc/nixos/secrets/wifi.psk > /dev/null && sudo chmod 600 /etc/nixos/secrets/wifi.psk && wpa_passphrase "OPTUS_DADS_5GHz" "izardleary84422"
# nmcli dev wifi connect "OPTUS_DADS_5GHz" password "izardleary84422"

#  sudo mkdir -p /etc/nixos/secrets
#  sudo chmod 700 /etc/nixos/secrets
# echo -n "izardleary84422" | sudo tee /etc/nixos/secrets/wifi.psk
# chmod 600 /etc/nixos/secrets/wifi.psk
# wpa_passphrase "OPTUS_DADS_5GHz" "izardleary84422"
