# russo1982_infra
---
## ДЗ №9 Terraform (работа в ветке terraform-2)
```
Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform.
```
---

#### Описание работы
---
1. Создайте новую ветку в вашем инфраструктурном репозитории для выполнения данного ДЗ.
```bash
git branch terraform-2
git switch terraform-2
```
Количеаство инстансов в **terraform.tfvras** указываем равным 1
```bash
instances                = 1
```
Файл **lb.tf** переносим в папку **files/**
```bash
cd terraform  
mv lb.tf files/.
```
---
2. Зададим IP для инстанса с приложением в виде внешнего ресурса. Для этого определим ресурсы **yandex_vpc_network** и **yandex_vpc_subnet** в конфигурационном файле **main.tf**.
```bash
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```
---
3. Удалим созданные до этого ресурсы и создадим новые
```bash
terraform destroy
terraform plan
terraform apply
```
Выводится следующая ошибка из-за того, что переместили файл **lb.tf**
```bash
Error: Reference to undeclared resource
│ 
│   on outputs.tf line 6, in output "loadbalancer_ip_address":
│    6:   value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
│ 
│ A managed resource "yandex_lb_network_load_balancer" "lb" has not been declared in the root module.
```
Закомментирую строки относящмеся к loadbalancer в файле **outputs.tf**

Во время создания инстанса заметно, что ресурсы сети и сам инстанс созадются параллельно.
Теперь укажу в файле **main.tf** то, что внутренний IP адрес инстанса будет выделен из снова создаваемого ресурса **"yandex_vpc_subnet" "app-subnet"**. В результате появляется зависимость одного ресурса терраформ из другого. Соответственно при создании ресурсов эта зависимость будет учтена
```bash
network_interface {
    # Указан id подсети из CIDR блока в зоне ru-central1-a
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat       = true
  }

далее снова

  terraform destroy
  terraform plan
  terraform apply
```
---
4. Несколько VM. Создание образа с MongoDB и отдельный образ с установленным Ruby

Для это созадны **app.json** и **db.json** файлы для Packer, где был описан создание образа и установки необходимого ПО.
Стоить отметить, что из-за данной ошибки:
```bash
==> yandex: E: Could not get lock /var/lib/dpkg/lock-frontend - open (11: Resource temporarily unavailable)
==> yandex: E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?
==> yandex: Failed to start mongod.service: Unit mongod.service not found.
==> yandex: Failed to execute operation: No such file or directory
```
пришлось указать **sleep 120** после команды **apt-get update** в SHELL скриптах.
В итоге следующие образы были созданы:
```bash
reddit-base-ruby-1683553352
reddit-base-mdb-1683552819
```
---
5. Создание двух VM

Разделю конфиг **main.tf** на несколько конфигов. Создам файл **app.tf**, куда вынесу конфигурацию для VM с приложением. Также введу новую переменную для образа приложения в **variables.tf** и задам в **terraform.tfvars**

Переменная для использования образа с **MongoD**
```bash
variable db_disk_image {
  description = "Disk image for reddit db"
  default = "abcde" # image created by Packer with installed MongoDB named "reddit-base-mdb"
}
```
Переменная для использования образа с **Ruby**
```bash
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "fgthj" # image created by Packer with installed Ruby named reddit-base-ruby"
}
```
Также в файлы **app.tf**, **db.tf** перенесем соответствующие модули/блоки из **main.tf**

**app.tf**
```bash
...
  boot_disk {
    initialize_params {
      # Указать id образа
      image_id = var.app_disk_image
    }
  }
...
```

**db.tf**
```bash
...
  boot_disk {
    initialize_params {
      # Указать id образа
      image_id = var.db_disk_image
    }
  }
...
```
---
6. Теперь надо разбить остальную концигурацию по файлам.

Создам файл **vpc.tf**, в который вынесу кофигурацию сети и подсети, которое применимо для всех инстансов.
```bash
resource "yandex_vpc_network" "app-network" {
  name = "app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```
добавлю **nat** адреса инстансов в **outputs.tf** переменные
```bash
output "external_ip_addresses_app" {
  value = yandex_compute_instance.app[*].network_interface.0.nat_ip_address
}

output "external_ip_addresses_db" {
  value = yandex_compute_instance.db[*].network_interface.0.nat_ip_address
}
```

В итоге, в файле **main.tf** должно остаться только определение провайдера
```bash
provider "yandex" { 
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
```
ПРОВИЖЕНЫ ПОКА ОСТАВЛЯЕМ ЗА КОММЕНТАМИ

Планируем и применяем изменения одной командой
```bash
terraform apply
```
Во время проверки в инстансе с MongoDB определена следующая проблема:
```bash
Please ensure LANG and/or LC_* environment variables are set correctly
```
что решаеться редактированием файла **/etc/default/locale**
```bash
LANG="en_US.UTF-8"
LANGUAGE="en_US"
LC_ALL="en_US.UTF-8"
```
---

