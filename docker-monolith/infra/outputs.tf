output "docker_host_ip" {
  value = yandex_compute_instance.docker-host[*].network_interface.0.nat_ip_address
}

output "docker_host_lanip" {
  value = yandex_compute_instance.docker-host[*].network_interface.0.ip_address
}
