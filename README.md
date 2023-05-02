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

testapp_IP = 84.201.132.86 (данный IP не статичный поэтому после выгрузки ДЗ инстанс удалю)
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

-------------------------------------------------------------------------------------------------------

ДЗ №7

Важным  файлом для перовой части ДЗ явлется: ubuntu16.json
В этом файле указаны builders и provisioners что позволяет создать и запустить инстанс в облаке.
Далее деплой проилоения происходит вручную

Во второй части были использованы два файла json
variables.json - тут хранятся переменные для использования в
immutable.json - здесб указана переменные в builders и далее bash скрипты для деплоя уже в созданном инатансе

В репо был закоммичен файл variables.json.examples

После тестов образ новый reddit-full-1682966029 уже с деплойенным приложением создался и сразу можно было идти к ней по адресу
<ip-of-VM>:9222

