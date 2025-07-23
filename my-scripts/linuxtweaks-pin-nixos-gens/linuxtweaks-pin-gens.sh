#!/usr/bin/env bash
# Tolga Erok
# 9/7/25
# personal nixos gen pinner VERSION: 1.0
# REF: https://nixos.wiki/wiki/Storage_optimization

GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${CYAN}───────────────────────────────────────────────"
echo -e "          NIXOS GENERATION PINNER"
echo -e "───────────────────────────────────────────────${RESET}"

# make manual gcroots dir
sudo mkdir -p /nix/var/nix/gcroots/manual

printf "${YELLOW}%-5s %-25s %-s${RESET}\n" "GEN" "NAME" "→ STATUS"
echo "───────────────────────────────────────────────────────────────────────────────"

for i in 1 2 3; do
    case $i in
        1) name="My Original Install" ;;
        2) name="My Second Install" ;;
        3) name="My Third Install" ;;
    esac

    target=$(readlink -f "/nix/var/nix/profiles/system-${i}-link")

    # check if system generation are already exist
    if [[ -z "$target" || ! -e "$target" ]]; then
        printf "${RED}%-5s %-25s %-s${RESET}\n" "$i" "$name" "❌ Generation link missing - skipping."
        continue
    fi

    # check if already pinned
    pin_path="/nix/var/nix/gcroots/manual/$name"
    existing_pin=$(readlink -f "$pin_path" 2>/dev/null || true)

    if [[ "$existing_pin" == "$target" ]]; then
        printf "${CYAN}%-5s %-25s %-s${RESET}\n" "$i" "$name" "ℹ️ Already pinned."
        continue
    fi

    # Pin the gen's i want
    sudo ln -sfn "$target" "$pin_path"
    printf "${GREEN}%-5s %-25s %-s${RESET}\n" "$i" "$name" "✅ Pinned → $target"
done

echo -e "\n${CYAN}Pinned generations:${RESET}"
ls -lh --color=auto /nix/var/nix/gcroots/manual/

echo -e "\n${CYAN}───────────── PINNING COMPLETE ─────────────${RESET}"
echo ""