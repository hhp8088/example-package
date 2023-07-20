#!/usr/bin/env bash

# shellcheck source=/dev/null
source "./.github/workflows/scripts/e2e-verify.common.sh"

# Script Inputs
GITHUB_REF=${GITHUB_REF:-}
GITHUB_REF_NAME=${GITHUB_REF_NAME:-}
GITHUB_REF_TYPE=${GITHUB_REF_TYPE:-}
PROVENANCE=${PROVENANCE:-}
CONTAINER=${CONTAINER:-}
RUNNER_DEBUG=${RUNNER_DEBUG:-}
if [[ -n "${RUNNER_DEBUG}" ]]; then
    set -x
fi

go env -w GOFLAGS=-mod=mod

# verify_provenance_content verifies provenance content generated by the container generator.
verify_provenance_content() {
    attestation=$(jq -r '.payload' <"$PROVENANCE" | base64 -d)

    echo "  **** Provenance content verification *****"

    # Verify all common provenance fields.
    e2e_verify_common_all "${attestation}"

    subject=$(echo "${CONTAINER}" | cut -f1 -d"@")
    e2e_verify_predicate_subject_name "${attestation}" "${subject}"
    e2e_verify_predicate_builder_id "${attestation}" "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/heads/main"
    e2e_verify_predicate_buildType "${attestation}" "https://github.com/slsa-framework/slsa-github-generator/container@v1"
}

this_file=$(e2e_this_file)
this_branch=$(e2e_this_branch)
echo "branch is ${this_branch}"
echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"
echo "GITHUB_REF_TYPE: $GITHUB_REF_TYPE"
echo "GITHUB_REF: $GITHUB_REF"
echo "DEBUG: file is ${this_file}"

export SLSA_VERIFIER_TESTING="true"

# Verify provenance authenticity.
e2e_run_verifier_all_releases "HEAD"

# Verify provenance content.
verify_provenance_content
