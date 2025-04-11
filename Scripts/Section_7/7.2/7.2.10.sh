#!/usr/bin/env bash

a_output=()     
a_output2=()    
a_output3=()    # Array for warning messages (e.g., compliant .netrc files)

l_maxsize="1000"  # Maximum number of local interactive users before warning (Default 1,000)
# Define valid interactive shells (exclude nologin)
l_valid_shells="^($(awk -F/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' -))$"

# Get interactive users and their home directories
a_user_and_home=()
while read -r l_local_user l_local_user_home; do
    [[ -n "$l_local_user" && -n "$l_local_user_home" ]] && a_user_and_home+=("$l_local_user:$l_local_user_home")
done < <(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd)

# Warn if there are many users
l_asize="${#a_user_and_home[@]}"
[ "$l_asize" -gt "$l_maxsize" ] && a_output2+=("- INFO: \"$l_asize\" local interactive users found, this may take a while")

# Function to check file access permissions, ownership, and group ownership
file_access_chk() {
    a_access_out=()
    l_max=$(printf '%o' $((0777 & ~$l_mask)))  # Calculate max allowed mode
    # Check permissions
    if [ $(( "$l_mode" & "$l_mask" )) -gt 0 ]; then
        a_access_out+=("- File: \"$l_hdfile\" is mode: \"$l_mode\" (should be \"$l_max\" or more restrictive)")
    fi
    # Check ownership
    if [[ ! "$l_owner" =~ ($l_user) ]]; then
        a_access_out+=("- File: \"$l_hdfile\" owned by: \"$l_owner\" (should be \"$l_user\")")
    fi
    # Check group ownership
    if [[ ! "$l_gowner" =~ ($l_group) ]]; then
        a_access_out+=("- File: \"$l_hdfile\" group owned by: \"$l_gowner\" (should be \"$l_group\")")
    fi
}

# Process each user’s home directory
while IFS=: read -r l_user l_home; do
    a_dot_file=()    # .forward, .rhost violations
    a_netrc=()       # .netrc violations
    a_netrc_warn=()  # .netrc compliant but present
    a_bhout=()       # .bash_history violations
    a_hdirout=()     # Other dot file violations

    if [ -d "$l_home" ]; then
        l_group=$(id -gn "$l_user" | xargs)  # Get user’s primary group
        l_group="${l_group// /|}"            # Replace spaces with | for regex

        # Find all dot files in the home directory
        while IFS= read -r -d $'\0' l_hdfile; do
            while read -r l_mode l_owner l_gowner; do
                case "$(basename "$l_hdfile")" in
                    .forward | .rhost)
                        a_dot_file+=("- File: \"$l_hdfile\" exists (should not exist)")
                        ;;
                    .netrc)
                        l_mask='0177'  # 0600 or stricter
                        file_access_chk
                        if [ "${#a_access_out[@]}" -gt 0 ]; then
                            a_netrc+=("${a_access_out[@]}")
                        else
                            a_netrc_warn+=("- File: \"$l_hdfile\" exists (compliant but present)")
                        fi
                        ;;
                    .bash_history)
                        l_mask='0177'  # 0600 or stricter
                        file_access_chk
                        [ "${#a_access_out[@]}" -gt 0 ] && a_bhout+=("${a_access_out[@]}")
                        ;;
                    *)
                        l_mask='0133'  # 0644 or stricter
                        file_access_chk
                        [ "${#a_access_out[@]}" -gt 0 ] && a_hdirout+=("${a_access_out[@]}")
                        ;;
                esac
            done < <(stat -Lc '%#a %U %G' "$l_hdfile")
        done < <(find "$l_home" -xdev -type f -name '.*' -print0)
    fi

    # Combine failures for this user
    if [ "${#a_dot_file[@]}" -gt 0 ] || [ "${#a_netrc[@]}" -gt 0 ] || [ "${#a_bhout[@]}" -gt 0 ] || [ "${#a_hdirout[@]}" -gt 0 ]; then
        a_output2+=("- User: \"$l_user\" Home Directory: \"$l_home\"" "${a_dot_file[@]}" "${a_netrc[@]}" "${a_bhout[@]}" "${a_hdirout[@]}")
    fi
    # Add warnings for compliant .netrc files
    [ "${#a_netrc_warn[@]}" -gt 0 ] && a_output3+=("- User: \"$l_user\" Home Directory: \"$l_home\"" "${a_netrc_warn[@]}")
done < <(printf '%s\n' "${a_user_and_home[@]}")

# Populate success message if no failures
if [ ${#a_output2[@]} -eq 0 ]; then
    a_output+=("- All local interactive user dot files meet requirements")
fi

# Determine audit result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
else
    audit_result="FAIL"
fi

# Print audit report
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
[ ${#a_output3[@]} -gt 0 ] && echo "--------------------------" && echo "Warnings:" && printf '%s\n' "${a_output3[@]}"