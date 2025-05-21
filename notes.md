# Notes Update

This is a more concise and updated set of notes to the video I had initially sent.

## Initial Thoughts & Task Organization

My initial thoughts were to split the tasks up into logical groups: **webservers**, **loadbalancers**, **monitoring**, **common**, and **security**.

-   **Benefits**: This approach allows for flexibility in the environment.
    -   Using **Ansible roles** means that I can have as many hosts as I need, and it should still "just" work.
        -   *\*Need to configure loadbalancer roles* to specifically handle that type of flexibility, but that's out of scope here.

## Technology Choices & Configuration

-   **Ansible**: A great fit for easy configuration management and idempotency. Its declarative nature also fits well with mapping the tasks to Ansible tasks.
-   **Nginx**: Pretty straightforward to set up. Make sure we have the correct server settings.
    -   *\*I initially missed that I would also need to think about needing to change the nginx.conf to trust the loadbalancer and receive the real IP.*
-   **Load Balancer (HAProxy)**:
    -   Initially considered **Nginx**, but `ip_hash` will not satisfy the "don\'t fail back over" requirement.
    -   Switched to **HAProxy** and used `SRVID` sticky cookie.
    -   *\*I also missed initially that HAProxy needs to `forwardfor` with the `X-Forwarded-For` header directive, and then `nginx.conf` needs to be configured for this.*
-   **Nginx and HAProxy**: Can handle most of the port forwarding/bind related items.
-   **Nagios**: Needed to look up configurations, plugin installation, and how the plugin system worked.

## Challenges & Solutions

The main issue I encountered was locking myself out mistakenly by not carefully reviewing the order of my **UFW** tasks when running through the security hardening portions of the requirements.

-   **Solution**:
    -   Decided to create a **Terraform module** and create my own environment first to prevent any mistakes from causing issues for the infra team later on, along with the desire to be more thorough and to treat this closer to an actual production environment scenario.
    -   Leaned into **AI** for writing tests quickly and writing the script to put the Terraform module and Ansible playbooks together, and formatting the md files.
        -   The tests proved to be very beneficial in surfacing things I had missed in my first run-through, and AI acts as a sort of second pair of eyes in this scenario.
  
