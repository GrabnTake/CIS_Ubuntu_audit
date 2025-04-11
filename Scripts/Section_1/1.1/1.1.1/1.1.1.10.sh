#!/usr/bin/env bash

a_output=()
a_output2=()
a_modprope_config=()
a_excluded=()
a_available_modules=()
a_ignore=("xfs" "vfat" "ext2" "ext3" "ext4")
a_cve_exists=("afs" "ceph" "cifs" "exfat" "ext" "fat" "fscache" "fuse" "gfs2" "nfs_common" "nfsd" "smbfs_common")

f_module_chk() {
    l_out2=""
    grep -Pq -- "\b$l_mod_name\b" <<< "${a_cve_exists[*]}" && l_out2=" <- CVE exists!"
    
    if ! grep -Pq -- '\bblacklist\h+'"$l_mod_name"'\b' <<< "${a_modprope_config[*]}"; then
        a_output2+=(" - Kernel module: \"$l_mod_name\" is not fully disabled $l_out2")
    elif ! grep -Pq -- '\binstall\h+'"$l_mod_name"'\h+(\/usr)?\/bin\/(false|true)\b' <<< "${a_modprope_config[*]}"; then
        a_output2+=(" - Kernel module: \"$l_mod_name\" is not fully disabled $l_out2")
    fi
    
    if lsmod | grep "$l_mod_name" &> /dev/null; then
        a_output2+=(" - Kernel module: \"$l_mod_name\" is loaded")
    fi
}

while IFS= read -r -d $'\0' l_module_dir; do
    a_available_modules+=("$(basename "$l_module_dir")")
done < <(find "$(readlink -f /lib/modules/"$(uname -r)"/kernel/fs)" -mindepth 1 -maxdepth 1 -type d ! -empty -print0)

while IFS= read -r l_exclude; do
    if grep -Pq -- "\b$l_exclude\b" <<< "${a_cve_exists[*]}"; then
        a_output2+=(" - ** WARNING: kernel module: \"$l_exclude\" has a CVE and is currently mounted! **")
    elif grep -Pq -- "\b$l_exclude\b" <<< "${a_available_modules[*]}"; then
        a_output+=(" - Kernel module: \"$l_exclude\" is currently mounted - do NOT unload or disable")
    fi
    ! grep -Pq -- "\b$l_exclude\b" <<< "${a_ignore[*]}" && a_ignore+=("$l_exclude")
done < <(findmnt -knD | awk '{print $2}' | sort -u)

while IFS= read -r l_config; do
    a_modprope_config+=("$l_config")
done < <(modprobe --showconfig | grep -P '^\h*(blacklist|install)')

for l_mod_name in "${a_available_modules[@]}"; do
    [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"
    
    if grep -Pq -- "\b$l_mod_name\b" <<< "${a_ignore[*]}"; then
        a_excluded+=(" - Kernel module: \"$l_mod_name\"")
    else
        f_module_chk
    fi
done

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
echo "Excluded Modules:"
printf '%s\n' "${a_excluded[@]}"