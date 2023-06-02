# russo1982_infra
---
## ДЗ №12 Ansible (Ansible: работа с ролями и окружениями. Работа с веткой ansible-3)

### Создание ролей
Создаю директорию **roles** и запуще в ней команды для создания заготовки ролей для конфигурации приложения и БД
```bash
ansible-galaxy init app
- Role app was created successfully
ansible-galaxy init db
- Role db was created successfully
```
В результате создаются папки **app** и **db** с одниковым контентом
```bash
tree app
app
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── README.md
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml
```

```bash
tree db
db
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── README.md
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml
```

### Роль для базы данных

Теперь для роли конфигурации MongoDB скопирую секцию **tasks** в сценарии плейбука **ansible/db.yml** и вставлю ее в файл в директории **tasks** роли **db**
**ansible/roles/db/tasks/main.yml**
```bash
---
# tasks file for db
- name: Change mongo config file
  template:
    src: mongod_conf.j2
    dest: /etc/mongod.conf
    mode: 0644
  notify: restart mongod
```
Далее в директорию шаблоннов роли **ansble/roles/db/templates** скопирую шаблонизированный конфиг для **MongoDB** из директории **ansible/templates**. Модули **template** и **copy**, которые используются в тасках роли, будут по умолчанию проверять наличие шаблонов и файлов в директориях роли **templates** и **files** соответственно. Поэтому достаточно указать в таске только имя шаблона в качестве источника.

Точно по такой же логике оформляем **handlers**
Содержимое файла **ansble/roles/db/handlers/main.yml**
```bash
---
# handlers file for db
- name: restart mongod
  service: name=mongod state=restarted
```
Также в папку **defaults** перенесем нужные переменные
**ansble/roles/db/defaults/main.yml**
```bash
---
# defaults file for db
mongo_port: 27017
mongo_bind_ip: 0.0.0.0
```

Точно такой же подход будем реализовать для роли **app**.
Скопирую секцию **tasks** в сценарии плейбука **ansible/app.yml** и вставлю ее в файл для тасков роли **app**.

### Использую роли в созданных ранее плейбуках

Удалю определение тасков и хендлеров в плейбуках **ansible/app.yml** и **ansible/db.yml** заменив на вызов роли
```bash
---
- name: Configure App
  hosts: app
  # tags: app-tag
  become: true

  vars:
    db_host: 192.168.10.24

  roles:
    - app
```

```bash
---
- name: Configure MongoDB
  hosts: db
  # tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0

  roles:
    - db
```

Теперь пересоздам инстансы и запущу плебуки.
```bash
terraform destroy
terraform apply
ansible-playbook site.yml --check
ansible-palybook site.yml
```
Перед проверкой изменить внешние IP адреса инстансов в инвентори файле **ansible/inventory** и переменную **db_host** в плейбуке **app.yml**

Инстансы поднялись и плейбук сработал штатно. Всё норм!

---

## Управление окружением через Ansible

Для управление окружениями **prod** и **stage** Создам директорию **environments** в директории **ansible** для определения настроек окружений. В директории **ansible/environments** создам две директории для окружений **stage** и **prod**.

### Inventory File

Необходимо управлять разными хостами на разных окружениях, соответственно нужен свой инвентори-файл для каждого из окружений. Скопирую инвентори файл **ansible/inventory** в каждую из директорий окружения **environtents/prod** и **environments/stage**.

Теперь, чтобы управлять хостами окружения необходимо явно передавать команде, какой инвентори использовать.
Например, чтобы задеплоить приложение на **prod** окружении:
```bash
ansible-playbook -i environments/prod/inventory.json deploy.yml
```

Не забываю определить окружение по умолчанию для окружения **stage** в файле **ansible.cfg**
```bash
[defaults]
inventory =  ./environments/stage/inventory.json
remote_user = ubuntu
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
nocows = True
```
---

## Переменные гр Переменные групп хостов

Параметризация конфигурации ролей за счет переменных дает возможность изменять настройки конфигурации, задавая нужные значения переменных.
Ansible позволяет задавать переменные для групп хостов, определенных в инвентори файле.

Директория **group_vars**, созданная в директории плейбука или инвентори файла, позволяет создавать файлы (имена, которых должны соответствовать названиям групп в инвентори файле) для определения переменных для группы хостов.
Создам директорию **group_vars** в директориях окружений **environments/prod** и **environments/stage**.

### Конфигурация Stage
