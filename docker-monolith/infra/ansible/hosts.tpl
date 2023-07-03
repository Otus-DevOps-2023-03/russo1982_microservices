[dockerhosts]
%{ for ip in host_ip ~}
${ip}
%{ endfor ~}
