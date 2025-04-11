#!/usr/bin/env bash

# Initialize output arrays
a_output=()
a_output2=()
a_output3=()

# Define module-related variables
l_mod_name="hfsplus"
l_mod_type="fs"
l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

# Function to check module status

f_module_chk() {
    l_dl="y"
    a_showconfig=()
    while IFS= read -r l_showconfig; do
        a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

    if ! lsmod | grep "$l_mod_chk_name" &> /dev/null; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loadable")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loadable")
    fi

    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is deny listed")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed")
    fi
}

for l_mod_base_directory in $l_mod_path; do
    if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-/\/}")" ]; then
        a_output3+=(" - \"$l_mod_base_directory\"")
        l_mod_chk_name="$l_mod_name"
        [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
        [ "$l_dl" != "y" ] && f_module_chk  # Only runs once
    else
        a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
    fi
done

# Module info
module_info=()
if [ "${#a_output3[@]}" -gt 0 ]; then
    module_info+=("module: \"$l_mod_name\" exists in:")
    for path in "${a_output3[@]}"; do
        module_info+=("$path")
    done
else
    module_info+=("module: \"$l_mod_name\" does not exist in any checked paths")
fi

# Audit result: PASS if no issues (a_output2 empty)
audit_result="FAIL"
if [ "${#a_output2[@]}" -le 0 ]; then
    audit_result="PASS"
fi

# Output result in text format
echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
printf '%s\n' "${a_output[@]}"

if [ "$audit_result" == "FAIL" ]; then
  echo "--------------------------"
  echo "Reason(s) for Failure:"
  printf '%s\n' "${a_output2[@]}"
fi
echo "--------------------------"
echo "Modules Info:"
printf '%s\n' "${module_info}"
