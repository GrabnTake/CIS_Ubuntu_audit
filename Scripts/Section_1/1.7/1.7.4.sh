#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check screen lock settings
check_screen_lock() {
    # Check if gsettings command exists
    if command -v gsettings &>/dev/null; then
        # Check the lock-delay setting (should be 5 seconds or less)
        lock_delay=$(gsettings get org.gnome.desktop.screensaver lock-delay | awk '{print $2}')
        
        if [ "$lock_delay" -le 5 ]; then
            a_output+=(" - Screen lock delay is set to 5 seconds or less")
        else
            a_output2+=(" - Screen lock delay is set to more than 5 seconds")
        fi

        # Check the idle-delay setting (should be 900 seconds or less)
        idle_delay=$(gsettings get org.gnome.desktop.session idle-delay | awk '{print $2}')
        
        if [ "$idle_delay" -le 900 ] && [ "$idle_delay" -ne 0 ]; then
            a_output+=(" - Screen idle delay is set to 900 seconds or less")
        else
            a_output2+=(" - Screen idle delay is set to more than 900 seconds or is disabled (0)")
        fi
    else
        a_output2+=(" - gsettings command not found, GNOME may not be installed")
    fi
}

# Run the function to check screen lock settings
check_screen_lock

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

