#!/usr/bin/env bash

echo -n "nixos:$(nixos-version | cut -d ' ' -f1)"

if [ -d /sys/firmware/efi/efivars ]; then
    if mokutil --sb-state | grep -q 'SecureBoot enabled'; then
        echo -n " 🔐"
    else
        echo -n -e " \033[5m🔓\033[0m"
    fi
else
    echo -n " 🧪"  # Not in EFI mode
fi
