# File name /modules/bd/variables.tf
# copied from variables.tf

variable db_disk_image {
  description = "Disk image for reddit db"
  default = "fd8t80ruels55tjlmf65" # image created by Packer with installed MongoDB named "reddit-base-mdb-1683552819"
}
variable "public_key_path" {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable "zone" {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable "subnet_id" {
  description = "Subnet for modules"
}
variable "instances" {
  description = "counts instances"
  default     = 1
}
