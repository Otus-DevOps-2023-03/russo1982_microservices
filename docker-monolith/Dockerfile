# за основу беру дистрибутив Ubuntu версии 18.04
FROM ubuntu:18.04

# для работы приложения нужны mongo и ruby
RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git
RUN gem install bundler -v 2.3.26

# скачиваю приложение в контейнер из git репо
RUN git clone -b monolith https://github.com/express42/reddit.git

# скопирую файлы конфигурации в создаваемый контейнер
COPY mongod.conf /etc/mongodb.conf
COPY db_config /reddit/db_config
COPY start.sh /start.sh

# нужно установить зависимости приложения и произвести настройку
RUN chmod 0777 /start.sh
RUN cd /reddit && rm Gemfile.lock && bundle install && cd /

#CMD ["mongod --fork --logpath /var/log/mongodb/mongodb.log --config /etc/mongodb.conf --dbpath /var/lib/mongodb"]
CMD ["/start.sh"]
# добавляю команду для старт сервиса при запуске контейнера
#
