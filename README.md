# russo1982_infra
russo1982 Infra repository

# Исследовать способ подключения к someinternalhost в одну
# команду из вашего рабочего устройства

 ssh -i $HOME/.ssh/<private-key> -A -J <user>@<bastion> <user>@<someinternalhost>


# Предложить вариант решения для подключения из консоли при помощи
# команды вида ssh someinternalhost из локальной консоли рабочего
# устройства, чтобы подключение выполнялось по алиасу
# someinternalhost


## The Bastion Host
 Host bastion
        HostName <bastion IP>
        User <user>

### The Remote Host
 Host someinternalhost
        HostName <host IP>
        ProxyJump bastion
        User <user>

