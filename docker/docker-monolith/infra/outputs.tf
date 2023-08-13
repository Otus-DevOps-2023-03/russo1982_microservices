output "gitlab_host_ip" {
  value = yandex_compute_instance.gitlab-ci[*].network_interface.0.nat_ip_address
}

output "gitlab_host_lanip" {
  value = yandex_compute_instance.gitlab-ci[*].network_interface.0.ip_address
}
