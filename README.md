# Monitoring Setup with Ansible

This project uses Ansible to automate the deployment and configuration of a Nagios-based monitoring stack for a web cluster.

## Prerequisites

- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (version 2.9+ recommended)
- Python 3.x on your control machine
- SSH access to all target hosts (configured in `inventory.ini`)
- The `inventory.ini` file listing your hosts

## Installation

### 1. Install Ansible

If you don't have Ansible installed, you can install it using `uvx ansible`

### 2. Clone the Repository

- clone this repo

### 3. Configure Inventory

You'll need to define your target hosts in the `inventory.ini` file. An example structure is usually provided in the repository, or you can create one based on your infrastructure.

Make sure you have SSH access (with appropriate keys or credentials) configured from your control machine to all hosts listed in the inventory. The Ansible playbook will use this to connect and execute tasks.

Example `inventory.ini`:
```ini
[loadbalancer]
loadbalancer_server_ip ansible_host=your_loadbalancer_ip_here ansible_user=your_ssh_user

[webservers]
webserver1_ip ansible_host=your_webserver1_ip_here ansible_user=your_ssh_user
webserver2_ip ansible_host=your_webserver2_ip_here ansible_user=your_ssh_user
... 
# other webservers

[internal:children]
webservers
monitoring
# other children

# Add other groups like database servers if applicable
```
Ensure you replace placeholder IPs and usernames with your actual values. The `ansible_host` variable is used to specify the IP address Ansible should connect to, and `ansible_user` specifies the remote user.

```group_vars/all.yml
expensify_user: "expensify"
admin_user: "ubuntu"
expensify_pubkey: "{{ lookup('file', 'files/expensify_id_rsa.pub') }}"
ssh_public_key: "{{ lookup('file', 'files/expensify_id_rsa.pub') }}"
```

### 4. Run the Ansible Playbook

Once your inventory is configured, you can run the main playbook. Assuming your main playbook is named `site.yml` (a common convention) located in the root of the repository or an `ansible` directory:

```bash
ansible-playbook site.yml -i inventory.ini
```
Or, if your playbook is in a subdirectory like `ansible/`:
```bash
ansible-playbook ansible/site.yml -i inventory.ini
```

This command will execute the tasks defined in your playbook against the hosts specified in your inventory file.

## Playbook Structure (Example)

This project might be structured with roles. For example:

- `ansible/`
  - `site.yml` (Main playbook that includes roles)
  - `inventory.ini` (Your host inventory)
  - `roles/`
    - `common/` (Common configurations for all servers)
    - `nagios_server/` (Tasks to set up Nagios server)
    - `nagios_client/` (Tasks to configure Nagios clients on monitored hosts)
    - `webserver/` (Tasks to configure web servers)
    - `security/` (Tasks for security hardening, like UFW rules)


