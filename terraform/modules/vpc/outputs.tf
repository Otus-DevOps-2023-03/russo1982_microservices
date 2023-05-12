# /modules/db/output.tf


output "subnet" {
  value = yandex_vpc_subnet.app-subnet.id
}
