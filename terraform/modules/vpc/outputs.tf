# /modules/db/output.tf


output "subnet" {
  value       = yandex_vpc_network.app-network.id
  sensitive   = true
  description = "ID of VPC Subnet"
  depends_on  = []
}
