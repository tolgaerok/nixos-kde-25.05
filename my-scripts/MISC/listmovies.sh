#!/bin/bash
# tolga erok
# list-movies.sh - Lists movie folders in PWD

# how to use: put script into folder and type:     ./listmovies.sh  > my_movie_list.txt

echo "🎬 Movie Folder Structure"
echo ""
echo "📂 Root: $(pwd)"
echo "========================================"

# List all dir's but exclude hidden and subtitle folders - BETA
find . -type d ! -name ".*" \
    ! -iname "subs" \
    ! -iname "subtitles" \
    ! -iname "eng subs" \
    | sort | while read -r dir; do

    clean_dir="${dir#./}"
    depth=$(echo "$clean_dir" | grep -o "/" | wc -l)

    # skip root
    [[ "$clean_dir" == "." ]] && continue

    # top-level category divider
    if [[ $depth -eq 0 ]]; then
        echo ""
        echo "📁 $clean_dir"
        echo "----------------------------------------"

    # movie folder divider
    elif [[ $depth -eq 1 ]]; then
        echo ""
        printf "%*s📁 %s\n" $((depth * 2)) "" "${dir##*/}"
        printf "%*s%s\n" $((depth * 2)) "" "----------------------------------------"

    # subdirectories under movie folder
    else
        printf "%*s📁 %s\n" $((depth * 2)) "" "${dir##*/}"
    fi

    # exclude unwanted extensions
    find "$dir" -maxdepth 1 -type f ! \( \
        -iname "*.bup" -o \
        -iname "*.dat" -o \
        -iname "*.db" -o \
        -iname "*.html" -o \
        -iname "*.idx" -o \
        -iname "*.ifo" -o \
        -iname "*.ini" -o \
        -iname "*.jpg" -o \
        -iname "*.metathumb" -o \
        -iname "*.nfo" -o \
        -iname "*.png" -o \
        -iname "*.rar" -o \
        -iname "*.srt" -o \
        -iname "*.sub" -o \
        -iname "*.txt" -o \
        -iname "*.url" -o \
        -iname "*.xml" -o \
        -iname "*.zip" -o \
        -iname "*.pdf" \
    \) | sort | while read -r file; do
        printf "%*s📄 %s\n" $(((depth + 1) * 2)) "" "${file##*/}"
    done
done
