# File name /modules/app/variables.tf
# copied from variables.tf

variable app_disk_image {
  description = "Disk image for reddit app"
  default = "fd82dkbbdpdktah8ega7" # image created by Packer with installed Ruby named reddit-base-ruby-1683553352
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
