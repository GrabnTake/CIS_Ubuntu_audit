#!/usr/bin/env bash

a_output=()   
a_output2=()  

# Define valid interactive shells (exclude nologin)
l_valid_shells="^($(awk -F/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' -))$"

# Get interactive users and their home directories from /etc/passwd
a_uarr=()      # Array to store user and home directory pairs
while read -r l_epu l_eph; do
    a_uarr+=("$l_epu $l_eph")
done < <(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd)

# Optional: Warn if there are many users (threshold: 10,000)
l_asize="${#a_uarr[@]}"
[ "$l_asize" -gt 10000 ] && a_output2+=("- INFO: \"$l_asize\" local interactive users found, this may take a while")

# Check each user's home directory
while read -r l_user l_home; do
    if [ -d "$l_home" ]; then
        # Define permission mask: 750 (rwxr-x---), max allowed permissions
        l_mask='0027'  # Bits to disallow: o+rwx, g+w
        l_max=$(printf '%o' $((0777 & ~$l_mask)))  # 750

        # Get ownership and mode of the home directory
        while read -r l_own l_mode; do
            # Check ownership
            [ "$l_user" != "$l_own" ] && a_output2+=("- User: \"$l_user\" home \"$l_home\" is owned by: \"$l_own\" (should be \"$l_user\")")

            # Check permissions (mode must be 750 or stricter)
            if [ $(( "$l_mode" & "$l_mask" )) -gt 0 ]; then
                a_output2+=("- User: \"$l_user\" home \"$l_home\" is mode: \"$l_mode\" (should be \"$l_max\" or more restrictive)")
            fi
        done < <(stat -Lc '%U %#a' "$l_home")
    else
        # Home directory doesn’t exist
        a_output2+=("- User: \"$l_user\" home \"$l_home\" does not exist")
    fi
done < <(printf '%s\n' "${a_uarr[@]}")

# Populate success messages if no issues found in each category
[ ! "$(printf '%s\n' "${a_output2[@]}" | grep -i "does not exist")" ] && a_output+=("- All local interactive user home directories exist")
[ ! "$(printf '%s\n' "${a_output2[@]}" | grep -i "is owned by")" ] && a_output+=("- All local interactive users own their home directories")
[ ! "$(printf '%s\n' "${a_output2[@]}" | grep -i "is mode")" ] && a_output+=("- All local interactive user home directories are mode \"$l_max\" or more restrictive")

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