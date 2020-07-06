# Developer setup

## Preparation

### With Docker Compose

The following command runs the application from the source code and binds it to port 9292 of your host. It mounts the source code as a volume, so changes to the code will be applied if you stop and start the containers (the app code doesn't hot reload however).

```sh
docker-compose -f docker-compose-dev-postgres.yml up --build
```

### With Docker

This allows you to open a shell to a development environment where you can run the tests and rake tasts.

* Build an initial local image with Docker

    ```sh
    docker build --rm -t pact_broker:dev .
    ```

* Spin up a container with mounted volume and open an interactive shell session

    ```sh
    docker run --rm -v $(PWD):/home -w /home -it pact_broker:dev bash
    ```

Remember to rebuild the image if you change any of the gems or gem versions.

### With native install

* You will need to install Ruby 2.5, and preferably a ruby version manager. I recommend using [chruby][chruby] and [ruby-install][ruby-install].
* Install bundler (the Ruby gem dependency manager) `gem install bundler`
* Check out the pact_broker repository and cd into it.
* Run `bundle install`. If you have any gem conflict issues, run `bundle update`.

To make the barrier to entry as low as possible, the mysql2 and pg gems are not installed by default, as they require mysql and postgres to be installed on your local machine. If you want to install them, set `INSTALL_MYSQL=true` and/or `INSTALL_PG=true` before running `bundle install`.

## Running a local application

* Install Ruby and the gems as per the instructions above.
* Run `bundle exec rackup`.
* The application will be available on `http://localhost:9292`. It uses a sqlite database that is stored in the `./tmp` directory.

You can set the `PACT_BROKER_DATABASE_URL` environment variable to use a postgres/mysql database using the format `driver://username:password@host:port/database` eg. `postgres://pact_broker:password@localhost/pact_broker`. Ensure you have set `INSTALL_MYSQL=true` or `INSTALL_PG=true` and run `bundle install` to make sure the required gems are present.

## Running the tests with mysql

```
docker-compose -f docker-compose-test-mysql.yml up --build --remove-orphans

# in separate console window...
docker-compose -f docker-compose-test-mysql.yml run --rm tests bash

# inside the tests container
bundle exec rake
```

## Running the tests with postgres

```
docker-compose -f docker-compose-test-postgres.yml up --build --remove-orphans

# in separate console window...
docker-compose -f docker-compose-test-postgres.yml run --rm tests bash

# inside the tests container
bundle exec rake
```
## Running the tests

* To run everything (specs, pact verifications, vulnerability scan...):
  ```sh
  bundle exec rake
  ```
* To run a smaller subset of the tests:
  ```sh
  bundle exec rake spec
  ```
* To run the "quick tests" (skip the lengthy migration specs)
  ```sh
  bundle exec rake spec:quick
  ```
* To run a single spec:
  ```sh
  bundle exec rspec path_to_your_spec.rb
  ```

[chruby]: https://github.com/postmodern/chruby
[ruby-install]: https://github.com/postmodern/ruby-install
