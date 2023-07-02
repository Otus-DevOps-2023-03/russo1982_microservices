variable "cloud_id" {
  description = "Yandex Cloud ID"
}
variable "folder_id" {
  description = "Yandex Cloud Folder ID"
}
variable "region_id" {
  description = "Yandex Cloud Region ID"
  default     = "ru-central1"
}
variable "zone" {
  description = "Yandex Cloud Zone"
  default = "ru-central1-a"
}
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}
variable "image_id" {
  description = "Disk image"
}
variable "image_folder_id" {
  description = "Image Folder ID"
}
variable "image_family" {
  description = "Image Family Name"
}
variable "boot_disk_size" {
  description = "Boot disk size in GB"
}
variable "subnet_name" {
  description = "Subnet Name"
  default     = "default-ru-central1-a"
}
variable "subnet_id" {
  description = "Subnet ID"
}
variable "service_account_key_file" {
  description = "Service account key file in .json"
}
variable "instances" {
  description = "How many instances to create/destroy? counts instances"
}
