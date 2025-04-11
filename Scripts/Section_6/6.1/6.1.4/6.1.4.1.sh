#!/usr/bin/env bash

a_output=()
a_output2=()

f_file_test_chk() {
    a_out2=()
    maxperm=$(printf '%o' $((0777 & ~$perm_mask)))  # Max allowed permission
    l_mode_dec=$((8#$l_mode))  # Convert octal mode to decimal
    # Check permissions
    if [ $((l_mode_dec & $perm_mask)) -gt 0 ]; then
        a_out2+=(" - Mode: \"$l_mode\" should be \"$maxperm\" or more restrictive")
    fi
    # Check owner
    if ! grep -Pq -- "$l_auser" <<< "$l_user"; then
        a_out2+=(" - Owned by: \"$l_user\" should be owned by \"${l_auser//|/ or }\"")
    fi
    # Check group
    if ! grep -Pq -- "$l_agroup" <<< "$l_group"; then
        a_out2+=(" - Group owned by: \"$l_group\" should be group owned by \"${l_agroup//|/ or }\"")
    fi
    if [ ${#a_out2[@]} -gt 0 ]; then
        a_output2+=("File: \"$l_fname\":")
        a_output2+=("${a_out2[@]}")
    fi
}

# Find files with potentially incorrect permissions/ownership
while IFS= read -r -d $'\0' l_file; do
    while IFS=: read -r l_fname l_mode l_user l_group; do
        if grep -Pq -- '\/(apt)\h*$' <<< "$(dirname "$l_fname")"; then
            perm_mask='0133'  # 0644
            l_auser="root"
            l_agroup="(root|adm)"
            f_file_test_chk
        else
            case "$(basename "$l_fname")" in
                lastlog | lastlog.* | wtmp | wtmp.* | wtmp-* | btmp | btmp.* | btmp-*)
                    perm_mask='0113'  # 0664
                    l_auser="root"
                    l_agroup="(root|utmp)"
                    f_file_test_chk
                    ;;
                cloud-init.log* | localmessages* | waagent.log*)
                    perm_mask='0133'  # 0644
                    l_auser="(root|syslog)"
                    l_agroup="(root|adm)"
                    f_file_test_chk
                    ;;
                secure* | auth.log | syslog | messages)
                    perm_mask='0137'  # 0640
                    l_auser="(root|syslog)"
                    l_agroup="(root|adm)"
                    f_file_test_chk
                    ;;
                SSSD | sssd)
                    perm_mask='0117'  # 0660
                    l_auser="(root|SSSD)"
                    l_agroup="(root|SSSD)"
                    f_file_test_chk
                    ;;
                gdm | gdm3)
                    perm_mask='0117'  # 0660
                    l_auser="root"
                    l_agroup="(root|gdm|gdm3)"
                    f_file_test_chk
                    ;;
                *.journal | *.journal~)
                    perm_mask='0137'  # 0640
                    l_auser="root"
                    l_agroup="(root|systemd-journal)"
                    f_file_test_chk
                    ;;
                *)
                    perm_mask='0137'  # 0640
                    l_auser="(root|syslog)"
                    l_agroup="(root|adm)"
                    # Adjust for non-shell users
                    if [ "$l_user" = "root" ] || ! grep -Pq -- "^\h*$(awk -F: '$1=="'"$l_user"'" {print $7}' /etc/passwd)\b" /etc/shells; then
                        ! grep -Pq -- "$l_auser" <<< "$l_user" && l_auser="(root|syslog|$l_user)"
                        ! grep -Pq -- "$l_agroup" <<< "$l_group" && l_agroup="(root|adm|$l_group)"
                    fi
                    f_file_test_chk
                    ;;
            esac
        fi
    done < <(stat -Lc '%n:%#a:%U:%G' "$l_file")
done < <(find -L /var/log -type f \( -perm /0137 -o ! -user root -o ! -group root \) -print0)

# Determine result
if [ ${#a_output2[@]} -eq 0 ]; then
    audit_result="PASS"
    a_output+=("- All files in \"/var/log/\" have appropriate permissions and ownership")
else
    audit_result="FAIL"
fi

echo "====== Audit Report ======"
echo "Audit Result: $audit_result"
echo "--------------------------"
echo "Correct Settings:"
[ ${#a_output[@]} -eq 0 ] && echo "(none)" || printf '%s\n' "${a_output[@]}"
[ "$audit_result" = "FAIL" ] && echo "--------------------------" && echo "Reason(s) for Failure:" && printf '%s\n' "${a_output2[@]}"
