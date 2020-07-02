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
    && rm -rf /var/cache/apk/*

RUN apk add --no-cache openssl

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz


COPY Gemfile /home/Gemfile
COPY pact_broker.gemspec /home/pact_broker.gemspec
COPY lib/pact_broker/version.rb /home/lib/pact_broker/version.rb
COPY .gitignore /home/.gitignore

RUN gem install bundler -v '~>2.0.0' \
    && bundle install --jobs 3 --retry 3

RUN echo '#!/bin/sh' >> /home/start.sh
RUN echo 'bundle exec rackup -o 0.0.0.0 -p 9292' >> /home/start.sh
RUN chmod +x /home/start.sh

CMD []
