[app]
%{ for i in range(length(app_public_ip)) ~}
${app_hosts[i]} ansible_host=${app_public_ip[i]} ansible_user=ubuntu
%{ endfor ~}
[db]
${db_host} ansible_host=${db_private_ip} ansible_user=ubuntu
