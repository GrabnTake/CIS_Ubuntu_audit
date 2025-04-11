#!/usr/bin/env bash

a_output=()
a_output2=()

# Get traversable filesystems (excluding noexec/nosuid)
fs_exclude=$(awk '/nodev/ { print $2 }' /proc/filesystems | paste -sd,)
partitions=$(findmnt -n -l -k -it "$fs_exclude" | grep -Pv "noexec|nosuid" | awk '{print $1}')

# Check if partitions are found
if [ -z "$partitions" ]; then
    a_output2+=("- No traversable filesystems found (excluding noexec/nosuid)")
fi

# Function to check rules
check_rules() {
    local type="$1"  # "disk" or "running"
    local privileged="$2"
    local found=0

    if [ "$type" = "disk" ]; then
        grep -qr "$privileged" /etc/audit/rules.d 2>/dev/null && found=1
    else
        [ -n "$RUNNING" ] && printf -- "$RUNNING" | grep -q "$privileged" 2>/dev/null && found=1
    fi

    if [ "$found" -eq 1 ]; then
        a_output+=("- ${type^} rule for '$privileged' found")
    else
        a_output2+=("- ${type^} rule for '$privileged' not found")
    fi
}

# Audit on-disk configuration
disk_missing=0
for partition in $partitions; do
    while IFS= read -r privileged; do
        check_rules "disk" "$privileged"
        [ "${#a_output2[@]}" -gt "$disk_missing" ] && disk_missing=$((disk_missing + 1))
    done < <(find "$partition" -xdev -perm /6000 -type f 2>/dev/null)
done

# Audit running configuration
RUNNING=$(auditctl -l 2>/dev/null)
running_missing=0
if [ -n "$RUNNING" ]; then
    for partition in $partitions; do
        while IFS= read -r privileged; do
            check_rules "running" "$privileged"
            [ "${#a_output2[@]}" -gt "$running_missing" ] && running_missing=$((running_missing + 1))
        done < <(find "$partition" -xdev -perm /6000 -type f 2>/dev/null)
    done
else
    a_output2+=("- auditctl output unavailable; running configuration checks skipped")
fi

# Summarize if all rules are missing
total_checks=$((disk_missing + running_missing))
if [ ${#a_output[@]} -eq 0 ] && [ "$total_checks" -gt 0 ]; then
    a_output2=("- All expected on-disk and running rules for privileged binaries are missing")
fi

# Check if auditctl is available
if ! command -v auditctl >/dev/null 2>&1; then
    a_output2+=("- auditctl not found; running configuration checks incomplete")
    a_output2+=("- Install auditd package")
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
echo "--------------------------"
echo "Note: Special mount points not visible to findmnt must be manually audited."