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
6. Теперь надо разбить остальную конфигурацию по файлам.

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
Также внутри папки **vpc** создам файл **outputs.tf** для передачи значения переменной из модуля **vpc** на другие. Например данные про подсеть.
```bash
output "subnet" {
  value = yandex_vpc_subnet.app-subnet.id
}
```
далее уже в главной файле **main.tf** ссылаемся на вывод модуля таким образом
```bash
module "vpc" {
  source = "./modules/vpc"
}

module "app" {
  source          = "./modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = module.vpc.subnet
}

module "db" {
  source          = "./modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id       = module.vpc.subnet
}
```

добавлю *адреса инстансов в **outputs.tf** переменные
```bash
output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}

output "internal_ip_address_app" {
  value = module.app.internal_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}

output "internal_ip_address_db" {
  value = module.db.internal_ip_address_db
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

7. Создадим Stage & Prod

В директории terrafrom создам две директории: **stage** и **prod**. Скопирую файлы **main.tf**, **variables.tf**, **outputs.tf**, **terraform.tfvars**, **__.json** из директории **terraform** в каждую из созданных директорий
```bash
tree
.
├── cloud-editor-key.json
├── files
│   ├── deploy.sh
│   ├── lb.tf
│   └── puma.service
├── main.tf
├── modules
│   ├── app
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── db
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc
│       ├── main.tf
│       └── outputs.tf
├── outputs.tf
├── prod
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   ├── terraform.tfvars
│   └── variables.tf
├── stage
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   ├── terraform.tfvars
│   └── variables.tf
├── terraform.tfstate
├── terraform.tfstate.backup
├── terraform.tfvars
├── terraform.tfvars.example
└── variables.tf

7 directories, 31 files
```
---

## Самостоятельные задания

1. Удалите из папки **terraform** файлы **main.tf**, **outputs.tf**, **terraform.tfvars**, **variables.tf**, так как они теперь перенесены в **stage** и **prod**


2. Отформатируйте конфигурационные файлы, используя команду terraform fmt

---

## Задание со ⭐⭐

1. Настройте хранение стейт файла в удаленном бекенде (remote backends) для окружений **stage** и **prod**, используя **Yandex Object Storage** в качестве бекенда.

Необходимо создать сам бакет. Для это копирую файлы **variables.tf** и **terraform.tfvars** обратно в директорию **terraform**. Создаё файл **backet-s3.tf** где описываю как надо создать бакет и запускаю создание бакета.
```bash
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
```

Естественно сначало создаю необхожимые ключи для этого:
```bash
yc iam access-key create --service-account-name cloud-editor
```
далее указываю соответствующие переменные
```bash
variable access_key {
  description = "key id"
}
variable secret_key {
  description = "secret key"
}
variable bucket_name {
  description = "bucket name"
}
```
и запускаю создание бакета
```bash
terraform apply
```
результат
```bash
yc storage bucket list
+-----------------+----------------------+----------+-----------------------+---------------------+
|      NAME       |      FOLDER ID       | MAX SIZE | DEFAULT STORAGE CLASS |     CREATED AT      |
+-----------------+----------------------+----------+-----------------------+---------------------+
| terr-state-file | b1ghdadfvadfvaqvhmpe |        0 | STANDARD              | 2023-05-14 10:13:59 |
+-----------------+----------------------+----------+-----------------------+---------------------+
```
Вот теперь уже можно "кидать" **tfstat** на удалённый бакет

```bash
terraform init
terraform apply
```
Теперь наш tfstate лежит в хранилище. Тожно удалить локальное и проверить запуск. Блокировки тоже работают если одноврменное запускать создание инстансов так как у s3 есть такая возможность.

---

## Задание с **

1. Добавьте необходимые **provisioner** в модули для деплоя и работы приложения.

Файлы были перемещены
**puma.service** изменена следующая строка. Запросы из инстанса **app** будут идти на **db** и соответственно ip необходимо указать
```bash
Environment="DATABASE_URL=$db_ip:27017"
```
нужно добавить в **db/outputs.tf** вывод внутреннего ip адреса
```bash
output "internal_ip_address_db" {
  value = yandex_compute_instance.db[*].network_interface.0.ip_address
}
```
Но веб страница инстанса  **app** выдаёт следующую ошибку доступа в базе данных
```bash
Can't show blog posts, some problems with database. Refresh?
```
Проблема заключается в том, что демон **mongod** слушает 
```bash
# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1
```
как указано в файле конфигурации **/etc/mongod.conf**
Поэтому внесем изменение в модуль **db** и вовремя создание инстанса файл конфигурации **/etc/mongod.conf** будет корректирован так, чтоб слушал все IP

Для изменений создам файл **mongodb.sh** внутри директории модуля **db** где будут указаны следующие команды
```bash
#!/bin/bash
set -e
sleep 60
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
sleep 3
sudo systemctl restart mongod
```
после данный скрипт запустим в провижине


Всё работает, но **reddit-app** не может определить по какому сокету идти в базе данных **reddit-db**

Для этого применяю следующее изменение в **puma.service**
```bash
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always
Environment="DATABASE_URL=${database_url}:27017"

[Install]
WantedBy=multi-user.target
```

Далее перменную **database_url** используем в модуле **app**
```bash
provisioner "file" {
    content     = templatefile("${path.module}/puma.service", { database_url = "${var.db_ip}" })
    destination = "/tmp/puma.service"
  }
```
Для внедрения DTABASE_URL можно использовать вот такой подход тоже
```bash
metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
      user-data = <<-EOF
                  #!/bin/bash
                  echo "DATABASE_URL=${var.db_ip}:27017" >> /etc/environment
                  EOF
  }
```
ТАким образом взамо связь между двумя инстансами будет обеспечена


