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

