#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check autorun-never settings
check_autorun_never() {
    # Check if gsettings exists
    if command -v gsettings &>/dev/null; then
        # Check if autorun-never message is enabled
        autorun_never=$(gsettings get org.gnome.desktop.media-handling autorun-never 2>/dev/null)

        if [[ "$autorun_never" == "true" ]] ; then
            a_output2+=(" - Autorun-never is enabled ")
        else
            a_output+=(" - Autorun-never is disabled ")
        fi

    else
        a_output2+=(" - gsettings command not found, error may have occurred")
    fi
}

# Run the function to check  autorun-never
check_autorun_never

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
