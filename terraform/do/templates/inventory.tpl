[webservers]
%{ for d in droplets ~}
%{ if contains(d.tags,"web") }
${d.name} ansible_host=${d.ipv4_address} proxy=lb
%{ endif ~}
%{ endfor }

[loadbalancer]
lb ansible_host=${droplets["lb"].ipv4_address}

[monitoring]
mon ansible_host=${droplets["mon"].ipv4_address} proxy=lb

[internal:children]
webservers
monitoring

[all:vars]
ansible_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
