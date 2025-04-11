#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check media-handling settings
check_media_handling() {
    # Check if gsettings exists
    if command -v gsettings &>/dev/null; then
        # Check if media-handling message is enabled
        media_handling_enabled=$(gsettings get org.gnome.desktop.media-handling automount 2>/dev/null)
        media_handling_open=$(gsettings get org.gnome.desktop.media-handling automount-open 2>/dev/null)

        if [[ "$media_handling_enabled" == "true" ]] ; then
            a_output2+=(" - Media-handling automount is enabled ")
        else
            a_output+=(" - Media-handling is disabled ")
        fi

        if [[ "$media_handling_open" == "true" ]] ; then
            a_output2+=(" - Media-handling automount open is enabled ")
        else
            a_output+=(" - Media-handling open is disabled ")
        fi
    else
        a_output2+=(" - gsettings command not found, error may have occurred")
    fi
}

# Run the function to check  media-handling
check_media_handling

# Report results in plain text format
if [ ${#a_output2[@]} -eq 0 ]; then
    echo "====== Audit Report ======"
    echo "Audit Result: PASS"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${a_output[@]}"
else
    echo "====== Audit Report ======"
    echo "Audit Result: FAIL"
    echo "--------------------------"
    echo "Correct Settings:"
    printf '%s\n' "${a_output[@]}"
    echo "--------------------------"
    echo "Reason(s) for Failure:"
    printf '%s\n' "${a_output2[@]}"
fi

