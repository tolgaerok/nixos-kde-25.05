#!/usr/bin/env bash

# Metadata
# ----------------------------------------------------------------------------
AUTHOR="Tolga Erok"
VERSION="4"
DATE_CREATED="19/12/2024"

# Configuration
# ----------------------------------------------------------------------------
REPO_DIR="/etc/nixos"
COMMIT_MSG_TEMPLATE="(ツ)_/¯ Edit: %s"
GIT_REMOTE_URL="git@github.com:tolgaerok/nixos-kde-25.05.git"
CREDENTIAL_CACHE_TIMEOUT=3600

# Functions
# ----------------------------------------------------------------------------
protect_gitignore() {
    echo "Ensuring .gitignore is up to date..."
  cat <<EOF > "$REPO_DIR/.gitignore"
samba/mnt/qnap-secrets
samba/mnt/router-secrets
NOTES/
nvidia/z_NOTES.txt
nvidia/z_MASTER_BAKUP.nix
my-scripts/
EOF
}

setup_git_config() {
    git config --global core.compression 9
    git config --global core.deltaBaseCacheLimit 2g
    git config --global diff.algorithm histogram
    git config --global http.postBuffer 524288000
}

ensure_git_initialized() {
    if [ ! -d "$REPO_DIR/.git" ]; then
        echo "Initializing Git repository in $REPO_DIR..."
        git init "$REPO_DIR"
        cd "$REPO_DIR" || exit 1
        git remote add origin "$GIT_REMOTE_URL"
        git branch -M main
        git checkout -b main
    fi
}

check_remote_url() {
    local remote_url
    remote_url=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
    if [[ $remote_url != git@github.com* ]]; then
        echo "Error: Remote URL is not SSH-based."
        echo "How to fix:"
        echo "1. ssh-keygen -t ed25519 -C 'your_email'"
        echo "2. eval \$(ssh-agent -s); ssh-add ~/.ssh/id_ed25519"
        echo "3. Copy: cat ~/.ssh/id_ed25519.pub"
        echo "4. Add to GitHub → SSH Keys"
        echo "5. git remote set-url origin git@github.com:your/repo.git"
        exit 1
    fi
}

auto_untrack_ignored() {
    echo "Untracking files listed in .gitignore..."
    
    cd "$REPO_DIR" || exit 1
    
    tracked_ignored_files=$(git ls-files --cached --ignored --exclude-standard)
    
    if [ -z "$tracked_ignored_files" ]; then
        echo "Nothing to untrack."
        return
    fi
    
    echo "$tracked_ignored_files" | while read -r file; do
        echo "Untracking: $file"
        git rm --cached --ignore-unmatch "$file" || true
    done
}

upload_files() {
    cd "$REPO_DIR" || exit 1
    
    if [ -d ".git/rebase-merge" ]; then
        echo "Rebase in progress. Resolve it first."
        exit 1
    fi
    
    git add --all --ignore-errors
    echo "Git status:"
    git status
    
    if git status --porcelain | grep -qE '^\s*[MARCDU]'; then
        commit_msg=$(printf "$COMMIT_MSG_TEMPLATE" "$(date '+%d-%m-%Y %I:%M:%S %p')")
        git commit -am "$commit_msg"
        
        echo "Pulling from remote..."
        git pull --rebase origin main || true
        
        echo "Pushing to remote..."
        git push origin main
        figlet "Files Uploaded" | lolcat
    else
        echo "No changes detected."
        figlet "Nothing Uploaded" | lolcat
    fi
}

# Main Script
# ----------------------------------------------------------------------------
set -e
start_time=$(date +%s)

# Function to change directory and execute commands
with_repo_dir() {
    cd "$REPO_DIR" || { echo "Cannot cd to $REPO_DIR"; exit 1; }
    "$@"
}

with_repo_dir setup_git_config
with_repo_dir ensure_git_initialized
with_repo_dir check_remote_url
with_repo_dir auto_untrack_ignored
with_repo_dir upload_files

# Get the current time in seconds since the Unix epoch
end_time=$(( $(date +%s) ))
time_taken=$((end_time - start_time))

notify-send --icon=ktimetracker --app-name="DONE" "Uploaded" "Completed:

        (ツ)_/¯
    Time taken: $time_taken seconds
" -u normal
