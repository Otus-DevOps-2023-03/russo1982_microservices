# File name /modules/app/main.tf
# copied from db.tf

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.89.0"
    }
  }
}

resource "yandex_compute_instance" "app" {
  count    = var.instances
  name     = "reddit-app-${count.index}"
  hostname = "reddit-app-${count.index}"
  zone     = var.zone

  labels = {
    tags = "reddit-app"
  }

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа
      image_id = var.app_disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

}


