#!/usr/bin/env bash

a_output=()    # Array for output messages (for manual review)

# Run apt-cache policy and capture output
while IFS= read -r line; do
    a_output+=("- $line")
done < <(apt-cache policy)

# Print audit report for manual review
echo "====== Audit Report ======"
echo "Audit Result: Manual Review Required"
echo "--------------------------"
echo "Package Repository Configuration (from apt-cache policy):"
if [ ${#a_output[@]} -eq 0 ]; then
    echo "- No output from apt-cache policy (possible error or no repositories configured)"
else
    printf '%s\n' "${a_output[@]}"
fi
echo "--------------------------"
echo "Instructions:"
echo "- REVIEW and VERIFY the listed package repositories against site policy to ensure correct configuration."
echo "- Rationale: Misconfigured repositories may miss important patches or introduce compromised software."