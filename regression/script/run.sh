#/bin/sh

REGRESSION=true INSTALL_PG=true DATABASE_ADAPTER=docker_postgres RACK_ENV=development bundle exec rake regression
