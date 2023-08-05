# Terraform main config taken from OTUS course webinar PDF
#
#
#

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.89.0"
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

resource "yandex_vpc_address" "static_ip" {
  name                = "static white IP"
  deletion_protection = false
  external_ipv4_address {
    zone_id = var.zone
  }
}

resource "yandex_compute_instance" "gitlab-ci" {
  count                     = var.instances
  name                      = "gitlab-ci-host-${count.index}"
  platform_id               = "standard-v3"
  hostname                  = "gitlab-ci-${count.index}"
  allow_stopping_for_update = true

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 50
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    nat_ip_address = "158.160.44.33"
    subnet_id      = var.subnet_id
    nat            = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/appuser.pub")}"
  }
}

/*
resource "local_file" "ans_inventory" {
  filename = "${path.module}/ansible/inventory.ini"
  content = templatefile("${path.module}/ansible/hosts.tpl",
    {
      host_ip = "${yandex_compute_instance.docker-host[*].network_interface.0.nat_ip_address}"
  })

}
*/
