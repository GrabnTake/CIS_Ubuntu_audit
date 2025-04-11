#!/usr/bin/env bash
a_output=()
a_output2=()
f_check_setting() {
    if grep -Psrilq -- "^\h*$2\b" /etc/dconf/db/local.d/locks/*; then
        echo "- \"$3\" is locked"
    else
        echo "- \"$3\" is not locked or not set"
    fi
}
declare -A settings=(
    ["idle-delay"]="/org/gnome/desktop/session/idle-delay"
    ["lock-delay"]="/org/gnome/desktop/screensaver/lock-delay"
)
for setting in "${!settings[@]}"; do
    result=$(f_check_setting "$setting" "${settings[$setting]}" "$setting")
    if [[ $result == *"is not locked"* || $result == *"not set"* ]]; then
        a_output2+=("$result")
    else
        a_output+=("$result")
    fi
done
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
