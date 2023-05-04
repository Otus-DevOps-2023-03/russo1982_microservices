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


