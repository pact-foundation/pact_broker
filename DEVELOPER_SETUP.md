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
    docker run --rm \
        -v $(PWD)/config:/home/config \
        -v $(PWD)/db:/home/db \
        -v $(PWD)/docs:/home/docs \
        -v $(PWD)/lib:/home/lib \
        -v $(PWD)/public:/home/public \
        -v $(PWD)/spec:/home/spec \
        -v $(PWD)/tasks:/home/tasks \
        -v $(PWD)/vendor:/home/vendor \
        -v $(PWD)/Rakefile:/home/Rakefile \
        -v $(PWD)/.rspec:/home/.rspec \
        -w /home -it pact_broker:dev bash
    ```
We can't just mount the whole $(PWD) directory because the local Gemfile.lock and .bundle/config will override the ones in the image

Remember to rebuild the image if you change any of the gems or gem versions.

* Run the server on the docker image

    ```sh
    docker run --rm -v $(PWD):/home -w /home --entrypoint /bin/sh -p 9292:9292 -it pact_broker:dev /usr/local/bin/start
    ```

### With native install

* You will need to install Ruby 2.7, and preferably a ruby version manager. I recommend using [chruby][chruby] and [ruby-install][ruby-install].
* Install bundler (the Ruby gem dependency manager) `gem install bundler`
* Check out the pact_broker repository and cd into it.
* Run `bundle install`. If you have any gem conflict issues, run `bundle update`.

To make the barrier to entry as low as possible, the mysql2 and pg gems are not installed by default, as they require mysql and postgres to be installed on your local machine. If you want to install them, run `bundle config set --local with pg mysql` before running `bundle install`.

## Running a local application

* Install Ruby and the gems as per the instructions above.
* Run `bundle exec rackup`.
* The application will be available on `http://localhost:9292`. It uses a sqlite database that is stored in the `./tmp` directory.

You can set the `PACT_BROKER_DATABASE_URL` environment variable to use a postgres/mysql database using the format `driver://username:password@host:port/database` eg. `postgres://pact_broker:password@localhost/pact_broker`. Ensure you have run `bundle config set --local with pg mysql` and run `bundle install` to make sure the required gems are present.

## Listing the routes

```
bundle exec rake pact_broker:routes
```

## Running the tests with postgres and mysql

```
docker-compose -f docker-compose-test.yml up --build --remove-orphans

# in separate console window...
docker-compose -f docker-compose-test.yml run --rm postgres-tests bash

# in separate console window...
docker-compose -f docker-compose-test.yml run --rm mysql-tests bash

# inside the tests container
bundle exec rake

# if you don't want to run the whole rake test suite, init the db first
/home/init-db.sh
```

Running a mysql client in the mysql-tests container:

```
mysql -hmysql -upact_broker -ppact_broker
```

Running a postgresql client in the postgres-tests container:

```
psql postgres://postgres:postgres@postgres/postgres
```

## Running the tests

* To run everything (specs, pact verifications, vulnerability scan...):
  ```sh
  bundle exec rake
  ```
* To set up the database (this is done automatically when running the default rake task, but if you want to run a different task without running the default task first, this must be run once beforehand):
  ```sh
  bundle exec rake db:prepare:test
  ```
* To run a smaller subset of the tests:
  ```sh
  bundle exec rake spec
  ```
* To run the "quick tests" (skip the lengthy migration specs and db setup)
  ```sh
  bundle exec rake spec:quick
  ```
* To run a single spec:
  ```sh
  bundle exec rspec path_to_your_spec.rb
  ```

## Running the regression tests

The regression tests record a series of API requests/responses using a real exported database (not included in the git repository because of the size) and store the expectations in files using the Approvals gem. They allow you to make sure that the changes you have made have not made any (unexpected) changes to the interface.

The tests and files are stored in the [regression](regression) directory.

To run:

1. Set up your local development environment as described above, making sure you have run `bundle config set --local with pg; bundle install`.

1. Make sure you have the master branch checked out.

1. Load an exported real database into a postgres docker image. The exported file must be in the pg dump format to use this script, and it must be located in the project root directory for it to be found via the mounted directory.

    ```
    script/docker/restore.sh <export>

    ```
1. Clear any previously generated approvals.

    ```
    regression/script/clear.sh
    ```

1. Run the tests. They will fail because there are no approval files yet.

    ```
    regression/script/run.sh
    ```

1. Approval all the things.

    ```
    regression/script/approval-all.sh
    ```

1. Run the tests again to make sure that the same results can be expected each time.

    ```
    regression/script/run.sh
    ```

1. Check out the feature branch (or enable the feature toggle)

1. Run the tests again.
    ```
    regression/script/run.sh
    ```

1. If there is a diff, you can set `SHOW_REGRESSION_DIFF=true`, but the output is quite noisy, and you're probably better off using diff or diffmerge to view the differences.

[chruby]: https://github.com/postmodern/chruby
[ruby-install]: https://github.com/postmodern/ruby-install
