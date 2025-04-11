#!/usr/bin/env bash
{
    check_setting() {
        # If Enable=true is found, print it; otherwise, print a "disabled" message
        awk -v fpath="$1" '
            /\[xdmcp\]/{f=1;next}
            /\[/{f=0}
            f{if(/^\s*Enable\s*=\s*true/){print "- The file: \""fpath"\" includes: \""$0"\" in the \"[xdmcp]\" block";found=1}}
            END{if(!found)print "- XDMCP is disabled or not configured in \""fpath"\""}
        ' "$1" 2>/dev/null
    }
    l_output=()
    l_output2=()
    while IFS= read -r l_file; do
        result=$(check_setting "$l_file")
        l_output+=("$result")
        if [[ $result == *"Enable = true"* ]]; then
            l_output2+=("$result")
        fi
    done < <(grep -Psil -- '^\h*\[xdmcp\]' /etc/{gdm3,gdm}/{custom,daemon}.conf)
    # Report results in plain text format
    if [ ${#l_output2[@]} -le 0 ]; then
        echo "====== Audit Report ======"
        echo "Audit Result: PASS"
        echo "--------------------------"
        echo "Correct Settings:"
        printf '%s\n' "${l_output[@]}"
    else
        echo "====== Audit Report ======"
        echo "Audit Result: FAIL"
        echo "--------------------------"
        echo "Correct Settings:"
        printf '%s\n' "${l_output[@]}"
        echo "--------------------------"
        echo "Reason(s) for Failure:"
        printf '%s\n' "${l_output2[@]}"
    fi
}