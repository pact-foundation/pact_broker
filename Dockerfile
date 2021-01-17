FROM ruby:2.5.3-alpine

WORKDIR /home

ENV INSTALL_MYSQL=true
ENV INSTALL_PG=true
RUN apk update \
    && apk --no-cache add \
      "build-base>=0.5" \
      "bash>=4.4" \
      "ca-certificates>=20190108" \
      "git>=2.20" \
      "postgresql-dev>=11.3" \
      "sqlite-dev>=3.28" \
      "sqlite>=3.28" \
      "tzdata>=2019" \
      "mariadb-dev>=10.3" \
      "mysql-client>=10.3.25" \
    && rm -rf /var/cache/apk/*

RUN apk add --no-cache openssl less

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz


COPY Gemfile /home/Gemfile
# COPY Gemfile.lock /home/Gemfile.lock # lock file does not exist on CI
COPY pact_broker.gemspec /home/pact_broker.gemspec
COPY lib/pact_broker/version.rb /home/lib/pact_broker/version.rb
COPY .gitignore /home/.gitignore

RUN gem install bundler -v '~>2.0.0' \
    && bundle install --jobs 3 --retry 3

RUN echo '#!/bin/sh' >> /usr/local/bin/start
RUN echo 'bundle exec rackup -o 0.0.0.0 -p 9292' >> /usr/local/bin/start
RUN chmod +x /usr/local/bin/start

RUN echo '#!/bin/sh' >> /usr/local/bin/test
RUN echo 'bundle exec rake' >> /usr/local/bin/test
RUN chmod +x /usr/local/bin/test

RUN echo '#!/bin/sh' >> /home/init-db.sh
RUN echo 'bundle exec rake db:prepare:test' >> /home/init-db.sh
RUN chmod +x /home/init-db.sh

ENTRYPOINT bash
CMD []
