#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check GDM login banner settings
check_gdm_banner() {
    # Check if gsettings exists
    if command -v gsettings &>/dev/null; then
        # Check if banner message is enabled
        banner_enabled=$(gsettings get org.gnome.login-screen banner-message-enable 2>/dev/null)
        banner_text=$(gsettings get org.gnome.login-screen banner-message-text 2>/dev/null)

        if [[ "$banner_enabled" == "true" ]] && [[ -n "$banner_text" ]]; then
            a_output+=(" - Login banner is enabled and contains a message")
        else
            a_output2+=(" - Login banner is disabled or does not contain a message")
        fi
    else
        a_output2+=(" - gsettings command not found, GDM may not be installed")
    fi
}

# Run the function to check GDM login banner
check_gdm_banner

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

