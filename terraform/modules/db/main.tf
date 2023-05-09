# File name /modules/bd/main.tf
# copied from db.tf

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.89.0"
    }
  }
}

resource "yandex_compute_instance" "db" {
  count = var.instances
  name  = "reddit-db-${count.index}"
  hostname = "reddit-db-${count.index}"
  zone = var.zone

  labels = {
    tags = "reddit-db"
  }

  resources {
    core_fraction = 20
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}