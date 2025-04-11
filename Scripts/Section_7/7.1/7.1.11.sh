#!/usr/bin/env bash

a_output=()
a_output2=()

# Sticky bit mask
l_smask="01000"  # Sticky bit in octal

# Paths to exclude from the find command
a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/*" -a ! -path "/snap/*")

# Arrays to store world-writable files and directories without sticky bit
a_file=()
a_dir=()

# Get local mount points, excluding specific filesystem types and paths
while IFS= read -r l_mount; do
    while IFS= read -r -d $'\0' l_file; do
        if [ -e "$l_file" ]; then
            # Check for world-writable files
            if [ -f "$l_file" ]; then
                a_file+=("$l_file")
            fi
            # Check for world-writable directories without sticky bit
            if [ -d "$l_file" ]; then
                l_mode="$(stat -Lc '%#a' "$l_file")"
                if [ ! $(( "$l_mode" & "$l_smask" )) -gt 0 ]; then
                    a_dir+=("$l_file")
                fi
            fi
        fi
    done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2> /dev/null)
done < <(findmnt -Dkerno fstype,target | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^(\/run\/user\/|\/tmp|\/var\/tmp)/) {print $2}')

# Check for world-writable files
if [ ${#a_file[@]} -eq 0 ]; then
    a_output+=("- No world-writable files exist on the local filesystem")
else
    a_output2+=("- Found \"${#a_file[@]}\" world-writable files on the system:")
    for file in "${a_file[@]}"; do
        a_output2+=("  - \"$file\"")
    done
fi

# Check for world-writable directories without sticky bit
if [ ${#a_dir[@]} -eq 0 ]; then
    a_output+=("- Sticky bit is set on all world-writable directories on the local filesystem")
else
    a_output2+=("- Found \"${#a_dir[@]}\" world-writable directories without the sticky bit:")
    for dir in "${a_dir[@]}"; do
        a_output2+=("  - \"$dir\"")
    done
fi

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
echo "Note: This audit may take time on systems with many files or directories."