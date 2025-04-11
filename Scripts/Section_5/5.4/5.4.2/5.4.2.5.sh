#!/usr/bin/env bash

a_output=()
a_output2=()

# Set variables
l_pmask="0022"  # umask for permissions
l_maxperm=$(printf '%o' $((0777 & ~$l_pmask)))  # 0755
l_root_path=$(sudo -Hiu root env 2>/dev/null | grep '^PATH' | cut -d= -f2)

# Split PATH into array
unset a_path_loc
IFS=":" read -ra a_path_loc <<< "$l_root_path"

# Check for issues in root's PATH
if grep -q "::" <<< "$l_root_path"; then
    a_output2+=("- root's PATH contains an empty directory (::)")
fi
if grep -Pq ":\h*$" <<< "$l_root_path"; then
    a_output2+=("- root's PATH contains a trailing (:)")
fi
if grep -Pq '(\h+|:)\.(:|\h*$)' <<< "$l_root_path"; then
    a_output2+=("- root's PATH contains current working directory (.)")
fi

# Check each path location
for l_path in "${a_path_loc[@]}"; do
    if [ -d "$l_path" ]; then
        while IFS= read -r line; do
            l_fmode=$(echo "$line" | awk '{print $1}')  # File mode in octal
            l_fown=$(echo "$line" | awk '{print $2}')   # File owner
            if [ "$l_fown" != "root" ]; then
                a_output2+=("- Directory: \"$l_path\" is owned by: \"$l_fown\" (should be \"root\")")
            fi
            if [ $((l_fmode & l_pmask)) -gt 0 ]; then
                a_output2+=("- Directory: \"$l_path\" is mode: \"$l_fmode\" (should be \"$l_maxperm\" or more restrictive)")
            fi
        done <<< "$(stat -Lc '%#a %U' "$l_path" 2>/dev/null)"
    else
        a_output2+=("- \"$l_path\" is not a directory")
    fi
done

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
    a_output+=("- Root's PATH is correctly configured: $l_root_path")
else
    audit_result="FAIL"
    a_output2=("- Root's PATH: \"$l_root_path\"" "${a_output2[@]}")
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"