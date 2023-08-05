# russo1982_microservices


## ДЗ №20 Gitlab CI: Построение процесса непрерывной поставки (работа с веткой: gitlab-ci-1)
---
### ЦЕЛЬ
- Подготовить инсталляцию Gitlab CI
- Подготовить репозиторий с кодом приложения
- Описать для приложения этапы пайплайна
- Определить окружения

### Инсталляция Gitlab CI

Необходимо развернуть свой **Gitlab CI** с помощью **Docker**. **Gitlab CI** состоит из множества компонентов и выполняет ресурсозатратную работу, например, компиляцию приложений. Для это надо создать в **Yandex.Cloud** новую виртуальную машину со следующими параметрами:
    - 2 CPU
    - 4 GB RAM
    - 50 GB HDD
    - Ubuntu 18.04
Буду использовать Terraform файл использованный ранее, только, подкорректирую свойства ВМ.
файл Terraform

В описании ДЗ есть текст *"Для запуска Gitlab CI мы будем использовать omnibus-установку."* Но, пока не увидел установку с использованием этого OMNIBUS

Ну, ладно уж, продолжу далее...
Устанавливаю Docker через **docker-machine**
```
docker-machine create \
  --driver generic \
  --engine-storage-driver overlay2 \
  --generic-ip-address=158.160.44.33 \
  --generic-ssh-user ubuntu \
  --generic-ssh-key ~/.ssh/appuser \
  gitlab-ci-host-0
```
```
eval $(docker-machine env gitlab-ci-0)
```
Нужно на удаленной машине создать необходимые директории и подготовить **docker-compose.yml** Иду по ssh к хосту **gitlab-ci-0**
```
ssh ubuntu@158.160.44.33
```
```
sudo mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
cd /srv/gitlab
sudo touch docker-compose.yml
sudo chown -R ubuntu /srv
vi docker-compose.yml
```
 Файл **docker-compose.yml**
```
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://158.160.44.33'
  ports:
    - '80:80'
    - '443:443'
    - '2222:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
```
Зпускаю контейнер описанный в файле **docker-compose.yml** находяь в **/srv/gitlab**
```
sudo docker-compose up -d

Command 'docker-compose' not found, but can be installed with:

sudo apt install docker-compose
```
 UPS!!! Ну, значит надо установить

Результат:
```
sudo docker ps -a
CONTAINER ID   IMAGE                     COMMAND             CREATED          STATUS
d61dfa9ca055   gitlab/gitlab-ee:latest   "/assets/wrapper"   18 minutes ago   Up 18 minutes (healthy)
```
### Автоматизация развёртывания GitLab (этим займусь позже)

А сейча уже можно установить ппароль от **root** уже на веб-странице. НО, сперва необходимо получить уже имеющийся пароль от пользователя **root**. Для этого в Яндекс Интансе куда и установили **Gitlab** надо запустить следующую команду
```
sudo docker exec -it gitlab_web_1 grep 'Password:' /etc/gitlab/initial_root_password
    Password: rZGIEkBdYxBqCi9jLwreNSeh0pp3QqK0MTeODfHm8HM=
```
Это и есть пароль от **root** Но, тут проблема в том, что пароль не подходит и надо будет сбрасывать пароль от **root**

Для этого надо зайти в **bash** оболочку контейнера
```
docker ps -a
CONTAINER ID   IMAGE                     COMMAND             CREATED          STATUS
0953ca4dab69   gitlab/gitlab-ce:latest   "/assets/wrapper"   12 minutes ago   Up 5 minutes (healthy)
```

```
docker exec -it 0953ca4dab69 bash
root@gitlab:/#
```
 И запускаю команду
 ```
 gitlab-rails console -e production
 ```
Надо дождаться соответствующего приглашения командной строки. Это займёт несколько минут

```
--------------------------------------------------------------------------------
 Ruby:         ruby 3.0.6p216 (2023-03-30 revision 23a532679b) [x86_64-linux]
 GitLab:       16.2.1 (3216f7a4aef) FOSS
 GitLab Shell: 14.23.0
 PostgreSQL:   13.11
-----------------------------------------------------------[ booted in 294.34s ]
Loading production environment (Rails 7.0.6)
irb(main):001:0> user = User.where(id: 1).first # указываю, что буду менять настройки пользователя с ID=1
=> #<User id:1 @root>
irb(main):002:0> user.password = 'some_password' # указываю новый пароль
=> "pass1234"
irb(main):003:0> user.password_confirmation = 'some_password' # подтверждение нового пароля
=> "pass1234"
irb(main):004:0> user.save! # сохраняю
=> true
irb(main):005:0> quit # выход
root@gitlab:/# exit # выход из командной строки контейнера
```
Полезная ссылка *https://forum.gitlab.com/t/default-root-password-for-gitlab-running-in-a-docker-container/59677/9*

И РАБОТАЕТ!!!

---

### Создание группы и проектов

Создал группу **homework** и в этой группе проект **example**

Далее в этот проект привязал свою локальную ветку **gitlab-ci-1**
```
git remote add gitlab http://158.160.44.44/homework/example.git
git push gitlab gitlab-ci-1
    To http://158.160.44.44/homework/example.git
    * [new branch]      gitlab-ci-1 -> gitlab-ci-1
```
Пайплайн для GitLab определяется в файле **.gitlab-ci.yml**
Данный файл создаю в локальной ветке и после **git push**
```
stages:
  - build
  - test
  - deploy

build_job:
  stage: build
  script:
    - echo 'Building'

test_unit_job:
  stage: test
  script:
    - echo 'Testing 1'

test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'

deploy_job:
  stage: deploy
  script:
    - echo 'Deploy'
```
И отправляю на Gitlab
```
git add .
git commit -m '.gitlab-ci.yml file added'
```

Таким образом файл деклорации запуска пайплайна улител в репо в Gitlab но не запустился так как пока нет раннеров.
Но для того чтоб его запустить надо будет найти токен. Увидеть его можно в настройках проекта. РОЙСЯ ТАМ!!! и найдешь что-то в таком виде
```
sudo gitlab-runner register --url http://158.160.44.44/ --registration-token GR1348941s7Bc6gFEJfb
```

**GR1348941s7Bc6gFEJfb** это и есть токен.

Для добавления раннера подключаюсь по **ssh** к Яндекс Инстансу где и крутится Gitlab и запускаю следующие команды
```
docker run -d --name gitlab-runner --restart always -v /srv/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest
```
После запуска раннер нужно зарегистрировать. Узнать подробно о команде **docker exec -it gitlab-runner gitlab-runner register --help**
```
docker exec -it gitlab-runner gitlab-runner register \
> --url http://158.160.44.44/ \
> --non-interactive \
> --locked=false \
> --name DockerRunner \
> --executor docker \
> --docker-image alpine:latest \
> --registration-token GR1348941s7BcLFZGEJfb \
> --tag-list "linux,xenial,ubuntu,docker" \
> --run-untagged


Registering runner... succeeded                     runner=GR1348941s7BcLFZG
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!

Configuration (with the authentication token) was saved in "/etc/gitlab-runner/config.toml"
```
Сейчас раннер запускает тесты и всё проходит успешно. Тесты по очереди проходят стадии **build** **test** **deploy** . Но, снова, исходя из описаний в файле **.gitlab-ci.yml** преполагаю, что в каждой стадии теста просто запускается команда **echo** и цель была просто добиться того, чтоб пайплайн запускался и проходил все стадии теста.

### Добавление Reddit в проект

Да, надо добавить **Reddit** в локальное репо и после запушать в Gitlfb наш.

```
git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git
git add reddit/
git commit -m "Add reddit app"
git push gitlab gitlab-ci-1
```
Раннер запустил тесты сразу.

Далее корректирую файл пайплайна **.gitlab-ci.yml** добавляю следующое описание

```
image: ruby:2.4.2

stages:
  ...

variables:
  DATABASE_URL: "mongodb://mongo/user_posts"

before_script:
  - cd reddit
  - bundle install

test_unit_job:
  stage: test
  services: -mongo:latest
  script:
    - ruby simpletest.rb
    - echo 'Testing 1'
...
```

В описании пайплайна добавил вызов теста в файле **simpletest.rb** и нужно создать его в папке **reddit**
Файл **simpletest.rb**
```
require_relative './app'
require 'test/unit'
require 'rack/test'

set :environment, :test

class MyAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_get_request
    get '/'
    assert last_response.ok?
  end
end
```
Последним шагом нужно добавить в файл **reddit/Gemfile** библиотеку **rack-test** для тестирования. В файл  **reddit/Gemfile** добавил следующее

```
...
gem 'sinatra', '~> 2.0.1'
gem 'haml'
gem 'bson_ext'
gem 'bcrypt'
gem 'puma'
gem 'mongo'
gem 'json'
gem 'rack-test'
...
```

Теперь отправлю код в GitLab и проверю, что теперь **test_unit_job** гоняет тесты

Но тут начали появлятся проблемы при проведении тестов. Причиной тому нехватака memeroy 4Gb. Пришлось поменять селдующие свойства Яндекс Инстанса
```
...
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
  ...
```
Указал платформу **"standard-v3"** и размер оперативной памяти **memory = 8Gb**

В результате тесты успешно пройдены.

### Окружение dev

В пайплайне есть задача ( job) с названием **deploy_job** , но там не определено, что и куда будет задеплоено. Поменяю пайплайн таким образом, чтобы **deploy_job** стал определением окружения **dev**, на которое условно будет выкатываться каждое изменение в коде проекта.

Редактирую файл **.gitlab-ci.yml**.
- Надо переименовать stage deploy в review
- deploy_job заменить на deploy_dev_job и определить окружение в ней
```
image: ruby:2.4.2

stages:
  - build
  - test
  - review

build_job:
  stage: build
  script:
    - echo 'Building'

variables:
  DATABASE_URL: "mongodb://mongo/user_posts"

before_script:
  - cd reddit
  - bundle install

test_unit_job:
  stage: test
  services:
    - mongo:latest
  script:
    - ruby simpletest.rb
    - echo 'Testing 1'

test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'

deploy_dev_job:
  stage: review
  script:
    - echo 'Deploy'
  environment:
    name: dev
    url: http://dev.example.com
```
Далее делаем git push и запускается пайплайн. Всё прошло отлично! Если перейти в Operate -> Environments , то там появится определение первого окружения.

### Staging и Production

Теперь надо определить два новых этапа: **stage** и **production**. Первый будет содержать задачу, имитирующую выкатку на окружение **staging**, второй - на **production**. Эти задачи нужно определить таким образом, чтобы они запускались вручную, с помощью аргумента **when: manual**.
```
...
stages:
  - build
  - test
  - review
  - stage
  - production
...
staging:
  stage: stage
  when: manual
  script:
    - echo 'Deploy'
  environment:
    name: beta
    url: http://beta.example.com

production:
  stage: production
  when: manual
  script:
    - echo 'Deploy'
  environment:
    name: production
    url: http://example.com
```
Снова пушаю.

Теперь в пайплайне можно увидить шаги **stage** и **production**

Окружения **beta** и **production** можно встретить в Operate -> Environments

### Условия и ограничения

- Добавление условия для задач

Обычно на **production** выводится приложение с явно зафиксированной версией (например, 2.4.10). Добавлю в описание пайплайна директиву, которая не позволит выкатить на **staging** и **production** код, не помеченный с помощью тэга в git.

Директива **only** описывает список условий, которые должны быть истинны, чтобы job мог запуститься.

```
...
stage:
  stage: stage
  when: manual
  only:
    - /^\d+\.\d+\.\d+/  # /^ начало строки, \d любая цифра, + одна или несколько, \.  символ "точка"
  script:
    - echo 'Deploy'
  environment:
    name: beta
    url: http://beta.example.com
...
```
Теперь изменения без указания тэга запустят пайплайн без задач **staging** и **production**. А изменение, помеченное тэгом в git, запустит полный пайплайн.
