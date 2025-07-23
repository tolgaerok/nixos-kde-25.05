# Varied icon theme

## Description:
Diverse icon theme for linux, based on the Evolvere icon pack, but using a variety of themes, e.g. (Qogir, WhiteSur, Mkos-Big-Sur, Papirus, Yaru++, etc.) and includes some self-made icons.

Various distribution-specific packages are also available, e.g.:
Arch, Fedora, Manjaro, Opensuse, Ubuntu.

Light and dark themed icon sets are also available for all variations.

Compatible with, KDE, Gnome, but other window managers (xfce, mate, cinnamon, etc.) can also use it.
The GNOME and KDE icon packs were selected separately.

The packages also include themes for folder icons in different colors. (red, yellow, cyan, purple, etc.).

These are also made specifically for the Kde and Gnome packages, but of course they can be used for other window managers as well.

To use them, you need to install at least one Varied icon theme.
The repo contains the "icon-update-light" and "icon-update-dark" packages, which contain the requested, improved, and newly added icons.

These have also been made into light and dark variations.

The packages need to be unpacked into the root directory of the current icon theme and the icon cache needs to be regenerated.


## Installation:

For system-wide use (recommended):

```
$ sudo tar -xvf Varied-5.0.tar.xz -C /usr/share/icons
$ sudo gtk-update-icon-cache -f /usr/share/icons/Varied < variant >

```


## Authors and acknowledgment:
Thanks to the creators of the basic themes:

- Evolvere icon theme:     https://github.com/franksouza183/Evolvere-Icons
- Mkos-Big-Sur icon theme: https://github.com/zayronxio/Mkos-Big-Sur
- Qogir icon theme:        https://github.com/vinceliuice/Qogir-icon-theme
- WhiteSur icon theme:     https://github.com/vinceliuice/WhiteSur-icon-theme
- Yaru++ icon theme:       https://github.com/Bonandry/yaru-plus
- Papirus icon theme:      https://github.com/PapirusDevelopmentTeam/papirus-icon-theme

