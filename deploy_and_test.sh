#!/bin/bash

set -e

TERRAFORM_DIR="terraform/do"
ANSIBLE_DIR="ansible"        

TF_VARS_FILE="environments/test.tfvars"

INVENTORY_FILE="${ANSIBLE_DIR}/inventory.ini"
ANSIBLE_PLAYBOOK="${ANSIBLE_DIR}/site.yml" 


TEST_PLAYBOOKS=(
    "test_common.yml"
    "test_webservers.yml"
    "test_loadbalancer.yml"
    "test_monitoring.yml"
    "test_security.yml"
)
# --- End Configuration ---

# --- Helper Functions ---
run_terraform_command() {
    (cd "${TERRAFORM_DIR}" && terraform "$@")
}

cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "ERROR: Script exited with status $exit_code."
        echo "The environment may not have been fully deployed, tested, or torn down."
        echo "Please review logs carefully."
        echo "If manual teardown is needed, run 'terraform destroy -auto-approve' in '${TERRAFORM_DIR}'."
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    fi
}
trap cleanup_on_error EXIT
# --- End Helper Functions ---

# --- Argument Parsing ---
DO_PROVISION=false
DO_CONFIGURE=false
DO_TEST=false
DO_DESTROY=false
ACTIONS_REQUESTED=0

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 [--provision] [--configure] [--test] [--destroy]"
    echo "No actions specified. Exiting."
    exit 1
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --provision) DO_PROVISION=true; ((ACTIONS_REQUESTED++)); shift ;;
        --configure) DO_CONFIGURE=true; ((ACTIONS_REQUESTED++)); shift ;;
        --test) DO_TEST=true; ((ACTIONS_REQUESTED++)); shift ;;
        --destroy) DO_DESTROY=true; ((ACTIONS_REQUESTED++)); shift ;;
        *) echo "Unknown parameter passed: $1"; trap - EXIT; exit 1 ;; # Disable trap for clean exit on unknown param
    esac
done

if [ "$ACTIONS_REQUESTED" -eq 0 ]; then
    echo "Usage: $0 [--provision] [--configure] [--test] [--destroy]"
    echo "No valid actions specified. Exiting."
    trap - EXIT 
    exit 1
fi
# --- End Argument Parsing ---

echo "INFO: Starting script with requested actions: Provision=${DO_PROVISION}, Configure=${DO_CONFIGURE}, Test=${DO_TEST}, Destroy=${DO_DESTROY}"

# --- Provisioning Phase (Terraform) ---
if [ "${DO_PROVISION}" = true ]; then
    echo "INFO: --- Starting Provisioning Phase (Terraform) ---"
    echo "INFO: Terraform Init..."
    run_terraform_command init

    echo "INFO: Terraform Apply..."
    if [ -n "${TF_VARS_FILE}" ] && [ -f "${TERRAFORM_DIR}/${TF_VARS_FILE}" ]; then
        echo "INFO: Using TF_VARS_FILE: ${TERRAFORM_DIR}/${TF_VARS_FILE}"
        run_terraform_command apply -var-file="${TF_VARS_FILE}" -auto-approve
    else
        if [ -n "${TF_VARS_FILE}" ]; then
            echo "WARNING: TF_VARS_FILE '${TERRAFORM_DIR}/${TF_VARS_FILE}' specified but not found. Applying with existing variables..."
        else
            echo "INFO: No TF_VARS_FILE specified, applying with existing variables..."
        fi
        run_terraform_command apply -auto-approve
    fi

    echo "INFO: Generating Ansible inventory from terraform output..."
    mkdir -p "$(dirname "${INVENTORY_FILE}")" # Ensure ansible directory exists
    run_terraform_command output -raw inventory_ini > "${INVENTORY_FILE}"
    echo "INFO: Inventory file '${INVENTORY_FILE}' created."
    echo "INFO: --- Provisioning Phase Complete ---"
fi
# --- End Provisioning Phase ---

# --- Configuration Phase (Ansible) ---
if [ "${DO_CONFIGURE}" = true ]; then
    echo "INFO: --- Starting Configuration Phase (Ansible) ---"
    if [ ! -f "${INVENTORY_FILE}" ]; then
        echo "ERROR: Ansible inventory file '${INVENTORY_FILE}' not found. Run --provision first or ensure it exists."
        exit 1
    fi

    if [ -f "${ANSIBLE_PLAYBOOK}" ]; then
        (cd "${ANSIBLE_DIR}"; ansible-playbook -i "$(basename "${INVENTORY_FILE}")" "$(basename "${ANSIBLE_PLAYBOOK}")" --ssh-extra-args='-o StrictHostKeyChecking=no') || \
            { echo "ERROR: Main Ansible playbook '${ANSIBLE_PLAYBOOK}' failed."; exit 1; }
    else
        echo "ERROR: Main Ansible playbook '${ANSIBLE_PLAYBOOK}' not found."
        exit 1
    fi
    echo "INFO: --- Configuration Phase Complete ---"
fi
# --- End Configuration Phase ---

# --- Testing Phase ---
if [ "${DO_TEST}" = true ]; then
    echo "INFO: --- Starting Testing Phase ---"
    if [ ! -f "${INVENTORY_FILE}" ]; then
        echo "ERROR: Ansible inventory file '${INVENTORY_FILE}' not found. Run --provision or --configure first, or ensure it exists."
        exit 1
    fi

    if [ ${#TEST_PLAYBOOKS[@]} -eq 0 ]; then
        echo "WARNING: No test playbooks defined. Skipping actual test runs."
    else
        echo "INFO: Running test playbooks from '${ANSIBLE_DIR}/tests/'..."
        (
            cd "${ANSIBLE_DIR}" || { echo "ERROR: Failed to cd into ${ANSIBLE_DIR}"; exit 1; }
            echo "INFO: Changed to directory for running test playbooks."
            for playbook_name in "${TEST_PLAYBOOKS[@]}"; do
                test_playbook_relative_path="tests/${playbook_name}"
                if [ ! -f "${test_playbook_relative_path}" ]; then
                    echo "ERROR: Test playbook '${test_playbook_relative_path}' (expected at ${ANSIBLE_DIR}/${test_playbook_relative_path}) not found."
                    exit 1
                fi
                echo "INFO: Running test playbook: ${test_playbook_relative_path} with inventory $(basename "${INVENTORY_FILE}")..."
                ansible-playbook -i "$(basename "${INVENTORY_FILE}")" "${test_playbook_relative_path}" --ssh-extra-args='-o StrictHostKeyChecking=no'
                echo "INFO: Test playbook ${playbook_name} passed."
            done
            echo "SUCCESS: All defined test playbooks passed."
        ) || { echo "ERROR: Test execution block failed."; exit 1; } 
    fi
    echo "INFO: --- Testing Phase Complete ---"
fi
# --- End Testing Phase ---

# --- Teardown Phase ---
if [ "${DO_DESTROY}" = true ]; then
    echo "INFO: --- Starting Teardown Phase ---"
    echo "INFO: Tearing down the environment as requested..."
    TF_VARS_FILE_PATH=""
    if [ -n "${TF_VARS_FILE}" ] && [ -f "${TERRAFORM_DIR}/${TF_VARS_FILE}" ]; then
        TF_VARS_FILE_PATH="-var-file=${TERRAFORM_DIR}/${TF_VARS_FILE}"
    elif [ -n "${TF_VARS_FILE}" ]; then 
        echo "WARNING: TF_VARS_FILE '${TERRAFORM_DIR}/${TF_VARS_FILE}' for destroy specified but not found. Attempting destroy without it."
    fi
    run_terraform_command destroy -auto-approve -var-file="${TF_VARS_FILE}"
    echo "INFO: Environment teardown complete."
    echo "INFO: --- Teardown Phase Complete ---"
fi
# --- End Teardown Phase ---

trap - EXIT 

echo ""
echo "INFO: Script finished."
