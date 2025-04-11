#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()

# Function to check if user list display is disabled in GDM
check_gdm_user_list() {
    # Check if gsettings exists
    if command -v gsettings &>/dev/null; then
        # Check if disable-user-list is enabled
        user_list_disabled=$(gsettings get org.gnome.login-screen disable-user-list 2>/dev/null)

        if [[ "$user_list_disabled" == "true" ]]; then
            a_output+=(" - User list is disabled on the login screen")
        else
            a_output2+=(" - User list is enabled on the login screen")
        fi
    else
        a_output2+=(" - gsettings command not found, GDM may not be installed")
    fi
}

# Run the function to check GDM user list settings
check_gdm_user_list

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

