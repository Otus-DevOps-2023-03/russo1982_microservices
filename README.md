# russo1982_microservices


## ДЗ №15 Виртуализация vs контейнеризация (ознакомление с docker)
---

Для начала работы надо сделал
```bash
git clone git@github.com:Otus-DevOps-2023-03/russo1982_microservices.git
```
после скопировал директории **.git** **.github** **travis.yml** **pre-commit-config.yaml**, чтоб не перенастраивать линтер. Конечно возникла проблема того, что вручную пришлось удалить информацию о ветках из репо **russo1982_infra**.
И потом надо пройти регистрацию в [https://hub.docker.com/] и после уже устанвить сам **docker** и его компоненты

Есть выбор установки **Docker Engine** или **Docker Desktop** . По совету своего друга инженера DevOps решил установить **Docker Engine** и работать через него.

Буду использовать метод установки **Install using the apt repository**

### Set up the repository
1. Update the apt package index and install packages to allow apt to use a repository over HTTPS:
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
```
2. Add Docker’s official GPG key:
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```
3. Use the following command to set up the repository:
```bash
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
### Install Docker Engine
1. Update the apt package index:
```bash
sudo apt-get update
```
2. Install Docker Engine, containerd, and Docker Compose.
To install the latest version, run:
```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
3. Verify that the Docker Engine installation is successful by running the hello-world image.
```bash
sudo docker run hello-world
```
```bash
sudo docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
719385e32844: Pull complete
Digest: sha256:a13ec89cdf897b3e551bd9f89d499db6ff3a7f44c5b9eb8bca40da20eb4ea1fa
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.
```

Ну, вот, на этом можно считать, что ДЗ сделано.
