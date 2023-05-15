# Terraform main config taken from OTUS course webinar PDF
#
# 
#

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.89.0"
    }
  }
}

provider "yandex" {
  #  token     = "t1.9euelZqPko_"
  #              token of terraform service account "cloud-editor"  
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

/*
module "vpc" {
  source = "../modules/vpc"
}
*/

module "app" {
  source          = "../modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = module.vpc.subnet
}

module "db" {
  source          = "../modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id       = module.vpc.subnet
}

/*
resource "yandex_storage_bucket" "s3-bucket" {
  bucket        = var.bucket_name
  access_key    = var.access_key
  secret_key    = var.secret_key
  force_destroy = "true"
}

  provisioner "file"{
  source = "files/puma.service"
  destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
  script = "files/deploy.sh"
  }

  connection {
  type = "ssh"
  host  = self.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  # путь до приватного ключа
  private_key = file(var.private_key_path)
  }
*/
