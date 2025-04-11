#!/usr/bin/env bash

# Initialize arrays for audit results
a_output=()
a_output2=()

# Kernel parameter to check
kernel_param="fs.suid_dumpable"
expected_value="0"

# Check the runtime value of the kernel parameter
running_value=$(sysctl -n "$kernel_param" 2>/dev/null)

if [[ "$running_value" == "$expected_value" ]]; then
    a_output+=(" - \"$kernel_param\" is correctly set to \"$running_value\" in the running configuration")
else
    a_output2+=(" - \"$kernel_param\" is incorrectly set to \"$running_value\" in the running configuration and should be \"$expected_value\"")
fi

# Check if the parameter is set correctly in persistent config files
config_files=("/etc/sysctl.conf" "/etc/sysctl.d/*.conf")
found_in_config=0

for file in "${config_files[@]}"; do
    if grep -Pq -- "^\s*$kernel_param\s*=\s*$expected_value\b" "$file" 2>/dev/null; then
        a_output+=(" - \"$kernel_param\" is correctly set in \"$file\"")
        found_in_config=1
    fi
done

if [[ "$found_in_config" -eq 0 ]]; then
    a_output2+=(" - \"$kernel_param\" is not set correctly in any persistent configuration files")
fi
if systemctl list-unit-files | grep -q "systemd-coredump"; then
    a_output2+=( " -systemd-coredump is installed")
elif [ -f "/usr/lib/systemd/system/systemd-coredump.service" ]; then
    a_output2+=(" - systemd-coredump service file exists but might not be active")
else
    a_output+=("- systemd-coredump is not installed")
fi


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
