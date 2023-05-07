## ДЗ №8 Terraform
#### Описание работы

1. Создаем ветку **terraform-1** и устанавливаем дистрибутив Terraform
```bash
git branch terraform-1
wget https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_linux_amd64.zip
unzip terraform_1.4.6_linux_amd64.zip
mv terraform /home/std/.local/bin
terraform -v
  Terraform v1.4.6
  on linux_amd64
```

2. Создаем каталог **terraform** с **main.tf** внутри и добавляем исключения в **.gitignore**
```bash
mkdir terraform
touch terraform/main.tf
cat .gitignore
  ...
  variables.json
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform
.terraform*
  ...
```

3. Создаем сервисный аккаунт и профиль для работы terraform на веб консоле Yandex Cloud

https://console.cloud.yandex.ru/folders/b1ghj2aqa2mlhsqvhmpe?section=service-accounts

```bash
yc iam service-account list
+----------------------+--------------+
|          ID          |     NAME     |
+----------------------+--------------+
| ajem574vimiqjfjm0cm5 | cloud-editor |
| ajepecgsan0paarejfgc | image-puller |
+----------------------+--------------+
```

Создать ключ авторизации для сервисного аккаунта
```bash
yc iam key create --service-account-name cloud-editor --output /home/std/yandex-cloud/cloud-editor-key.json
```
далее создвть профиль м активизировать его
```bash
yc config profile create cloud-editor-profile
yc config profile activate cloud-editor-profile
yc config profile list 
  cloud-editor-profile  ACTIVE
  russo1982
```
Указывает в в файле настроек шелл переменную
```bash
YC_SRVC_ACCT_KEY="/home/std/yandex-cloud/cloud-editor-key.json"
```
```bash
source ~/.zshrc
echo $YC_SRVC_ACCT_KEY
  /home/std/yandex-cloud/cloud-editor-key.json
```

4. Первый делом определим секцию Provider в файле main.tf
```bash
provider "yandex" {
  token     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "<идентификатор облака>"
  folder_id = "<идентификатор каталога>"
  zone      = "ru-central1-a"
}
```
и запускаем инициализацию
```bash
terraform init
```

5. Редактируем **main.tf** создаем инстанс с помощью **terraform**
```bash
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = "fd8fg4r8mrvoq6q2ve76"
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = "e9bem33uhju28r5i7pnu"
    nat       = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/appuser.pub")}"
  }
}
```
```bash
terraform plan
terraform apply
```

Для создания инстанса использован образ reddit-base из предыдущего ДЗ
```bash
yc compute image list
+----------------------+------------------------+-------------+----------------------+--------+
|          ID          |          NAME          |   FAMILY    |     PRODUCT IDS      | STATUS |
+----------------------+------------------------+-------------+----------------------+--------+
| fd8h9ujjq500fhoq80eo | reddit-base-1682885935 | reddit-base | f2em6cfv0q0plhpcefat | READY  |
| fd8l195i665ap12igu0k | reddit-full-1683012942 | reddit-full | f2eu5d4ulcfnhspd9hmf | READY  |
+----------------------+------------------------+-------------+----------------------+--------+
```

6. terraform загружает все файлы в текущей директории, имеющие расширение .tf Поэтому создаем **outputs.tf** для получения IP данных инстанса
``` bash
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

7. Теперь создаём блок провижионеры, и копируем файл  puma.service на создаваемый инстанс для этого добавляем в **main.tf** провижионер file:
```bash
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  ```
  для запуска приложения используем скрипт **deploy.sh**, для которого используем remote-exec
  ```bash
    provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
  ```
  для подключения используем  connection
  ```bash
    connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file("~/.ssh/appuser")
  }
  ```

для того чтобы наши изменения применились
```bash
terraform taint yandex_compute_instance.app
terraform plan
terraform apply
```

8.  Использование input vars, для начала опишем наши переменные в **variables.tf**
```bash
...
variable cloud_id {
  description = "Cloud"
}
...
```
значения этих переменных указываем в **terraform.tfvars**
```bash
...
cloud_id  = "abv"
...
```
теперь указываем эти параметры в **main.tf**
```bash
provider "yandex" {
#  token     = "t1.9euelZqPko_"
#              token of terraform service account "cloud-editor"  
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
```
И так делаем для других параметров, затем перепроверяем
```bash
terraform destroy
terraform apply
```
---
#### Самостоятельные задания

1. Определите input переменную для приватного ключа
**variables.tf**
```bash
variable "private_key_path" {
  # Описание переменной
  description = "Path to the private key used for ssh access"
}
```
**terraform.tfvars**
```bash
private_key_path         = "~/.ssh/appuser"
```

2. Определите input переменную для задания зоны
**variables.tf**
```bash
variable "zone" {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
```
---

#### Задание со ⭐⭐
1. Создаем файл **lb.tf** с настройками балансировщика. Тут важен именно таргет группа и переменная **intances**
```terraform
resource "yandex_lb_target_group" "loadbalancer" {
  name      = "lb-group"
  folder_id = var.folder_id
  region_id = var.region_id

  dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
}
```

2.  Не забываем добавить переменные в **output.tf**
```terraform
output "loadbalancer_ip_address" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
```
Доюавим переменную **intances**
```bash
variable "instances" {
  description = "counts instances"
  default     = 1
}
```

При добавлении дополнительных инстансов для обеспечения отказаустойчивосте сервиса создаём копию изначального интанса с одинаковыми требованиями. Далее балансировщик уровня 3 будет распределять трафик всегда на наименее нагружиенный инстанс.
Необходио было добиться автоматического увеличения создаваемых инстансов и указания их сйоств. Конечно при ручном добавлении инстансов такого автоматизма не будет. Потому используются перменная **intances**
и
```bash
resource "yandex_compute_instance" "app" {
  count = var.instances
  name  = "reddit-app-${count.index}"
  hostname = "reddit-base-${count.index}"
  zone = var.zone
```

---
---
# russo1982_infra
russo1982 Infra repository

# Исследовать способ подключения к someinternalhost в одну
# команду из вашего рабочего устройства

 ssh -i $HOME/.ssh/<private-key> -A -J <user>@<bastion> <user>@<someinternalhost>


# Предложить вариант решения для подключения из консоли при помощи
# команды вида ssh someinternalhost из локальной консоли рабочего
# устройства, чтобы подключение выполнялось по алиасу
# someinternalhost

#  $HOME/.ssh/config
## The Bastion Host
 Host bastion
        HostName <bastion IP>
        User <user>

### The Remote Host
 Host someinternalhost
        HostName <host IP>
        ProxyJump bastion
        User <user>


VM bastion          --\__
VM someinternalhost --/  `---- both created and configured successfully.

FQDN for pritunlVPN in bastion is   https://158.160.97.131.sslip.io

After FQDN created Let's Encrypt certificate obtained with:  sudo pritunl renew-ssl-cert

pritunlVPN Server

	bastion_IP = 158.160.97.131
	someinternalhost_IP = 10.128.0.5
	user: test
	PIN: same as in HW
-----------------------------------------------------------------------------------------------------
ДЗ №6

testapp_IP = 84.201.132.86

testapp_port = 9292


Команды Yandex CLI для создания инстанса



yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=2 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=startup.yaml

=======
>>>>>>> packer-base
-------------------------------------------------------------------------------------------------------

ДЗ №7

Важным  файлом для перовой части ДЗ явлется: ubuntu16.json
В этом файле указаны builders и provisioners что позволяет создать и запустить инстанс в облаке.
Далее деплой приложения происходит вручную

Во второй части были использованы два файла json
variables.json - тут хранятся переменные для использования в
immutable.json - здесь указана переменные в builders и далее bash скрипты для деплоя уже в созданном инстансе

В репо был закоммичен файл variables.json.examples

После тестов образ новый reddit-full-1682966029 уже с деплойенным приложением создался и сразу можно было идти к ней по адресу
<ip-of-VM>:9222

Далее надо было создать скрипт create-reddit-vm.sh в директории config-scripts, который будет создавать ВМ с помощью Yandex.Cloud CL
Данный файл состоит из следующих строк
yc compute instance create \
    --name test-reddit \
    --hostname test-redditfull \
    --memory=4 \
    --create-boot-disk image-id=fd8l195i665ap12igu0k,size=10GB \
    --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
    --metadata serial-port-enable=1 \
    --metadata-from-file user-data=/home/std/git/russo1982_infra/packer/scripts/startup-ycli.yaml


image-id=fd8l195i665ap12igu0k   - это и есть ID созданного с помощью Packer образа, где уже осуществлён деплой puma.service который запускается systemd

Использован файл мета-данных startup-ycli.yaml
Данный файл состоит из следующих строк
#cloud-config
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCR+pETU1CQ9TOoz0he3PLPVfjqCr3hf5g1kDfdJpxLOG1bZ00iCxzCVfQd76tpLL3sSvgAguUqq1y6gongUG/DW9necvcUYOKSC/H1jUv6iwnh1I0d5A+VjbgzBu/cEUpYSTz/Hr2JUJ0rPs0Cxby+OOtc1GADyGbIr/CqHIM4DEN3cDKeBDb13iOMvhsmfnNmeLTOYsE5SSgSG1kHsgzD509s8vCikFS267OAkizW9shjkdtNEiApw2/ybvOiMCiJKHsB+e4QXvDtHZdYfaigrSyEg8ZsncivWZ+LAsKy/S63DLIh052aed8WFd9IrOevhuBra21voNEzRWAOHIX0zKdvqLZFOcY52DHIGG3Bl0VAjTwJc9RgYWEJrrukxnLsXLxniNkU9Y3Jt3BD6LvpYw9JSEbHWGlkiHxWgXFLu9zspmnRBdLo0qQD9SS45BOL3tC7kek4UpHEY2KiX6u5/HCxQsLZau6u0MtX5l2PAShrQfFdzX3ZxEQeKM/t6K3TZlqqAD/4L/hr6KHdG7BaWaUsTuO/hREyBnGp1j7JSh9nsfRW1N0yZT79sqGr9CILYaF6gtVjBofvhpjJMyOfOeYg/ESn+Rkg5tcViD01MfM89bURjD2ipk4gs3p/xg1NciSCxx78OIJENpUA1SAFj6wWg7YhxlIogX6KoygSbw== std@stdpc


ОЧЕНЬ ВАЖНО!!! ЧТОБЫ СОЗДАНИЕ ИНСТАНСА И ЗАПУСК puma.service ПРОШЛО УСПЕШНО ВАЖНО УКАЗАТЬ ПРАВИЛЬНОЕ ИМЯ ПОЛЬЗОВАТЕЛЯ. В ДАННОМ СЛУЧАЕ ubuntu


