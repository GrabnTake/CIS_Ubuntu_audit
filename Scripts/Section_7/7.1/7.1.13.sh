#!/usr/bin/env bash

a_output=()
a_output2=()

# Arrays to store SUID and SGID files
a_suid=()
a_sgid=()

# Get local mount points, excluding specific filesystem types and options
while IFS= read -r l_mount; do
    while IFS= read -r -d $'\0' l_file; do
        if [ -e "$l_file" ]; then
            l_mode="$(stat -Lc '%#a' "$l_file")"
            # Check for SUID (4000)
            if [ $(( "$l_mode" & 04000 )) -gt 0 ]; then
                a_suid+=("$l_file")
            fi
            # Check for SGID (2000)
            if [ $(( "$l_mode" & 02000 )) -gt 0 ]; then
                a_sgid+=("$l_file")
            fi
        fi
    done < <(find "$l_mount" -xdev -type f \( -perm -2000 -o -perm -4000 \) -print0 2> /dev/null)
done < <(findmnt -Dkerno fstype,target,options | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^\/run\/user\// && $3 !~/noexec/ && $3 !~/nosuid/) {print $2}')

# Check for SUID files
if [ ${#a_suid[@]} -eq 0 ]; then
    a_output+=("- No executable SUID files exist on the system")
else
    a_output2+=("- Found \"${#a_suid[@]}\" SUID executable files:")
    for file in "${a_suid[@]}"; do
        a_output2+=("  - \"$file\"")
    done
fi

# Check for SGID files
if [ ${#a_sgid[@]} -eq 0 ]; then
    a_output+=("- No SGID files exist on the system")
else
    a_output2+=("- Found \"${#a_sgid[@]}\" SGID executable files:")
    for file in "${a_sgid[@]}"; do
        a_output2+=("  - \"$file\"")
    done
fi

# Add manual review note if there are findings
if [ ${#a_output2[@]} -gt 0 ]; then
    a_output2+=("- Review the preceding list(s) of SUID and/or SGID files to ensure no rogue programs have been introduced onto the system")
fi

echo "====== Audit Report ======"
echo "Audit Result: MANUAL"
echo "--------------------------"
echo "Correct Settings (No Findings):"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ ${#a_output2[@]} -gt 0 ] && echo "--------------------------" && echo "Findings for Review:" && printf '%s\n' "${a_output2[@]}"
echo "Note: This audit may take time on systems with many files."