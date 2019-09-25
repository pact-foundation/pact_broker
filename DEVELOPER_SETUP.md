# Developer setup

## Preparation

### With virtual battery

* Build an initial local image with Docker
  ```sh
  docker build --rm -t pact_broker:dev .
  ```

* Spin up a container with mounted volume and open an interactive shell session
  ```sh
  docker run --rm -v $(PWD):/app -w /app -it pact_broker:dev bash
  ```

### With native install

* You will need to install Ruby 2.5, and preferably a ruby version manager. I recommend using [chruby][chruby] and [ruby-install][ruby-install].
* Install bundler (the Ruby gem dependency manager) `gem install bundler`
* Check out the pact_broker repository and cd into it.
* Run `bundle install`. If you have not got mysql or postgres installed locally, comment out the `mysql2` and `pg` development dependency lines in `pact_broker.gemspec`, as these are only really required on Travis.

## Running a local application

* Run `bundle exec rake pact_broker:dev:setup`. This will create an example application that you can run locally, that uses the local source code.
* To run the example:
  ```sh
  cd dev
  bundle install
  bundle exec rackup
  ```
* The application will be available on `http://localhost:9292`

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
