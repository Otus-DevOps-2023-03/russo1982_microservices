# File name /modules/s3/main.tf/
#
#  Saves terraform.tfstate in Yandex Object Storage
#
#-------------------------------------------------------------


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

resource "yandex_storage_bucket" "s3-bucket" {
  bucket        = var.bucket_name
  access_key    = var.access_key
  secret_key    = var.secret_key
  force_destroy = "true"
}

