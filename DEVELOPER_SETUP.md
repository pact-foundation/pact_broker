# Developer setup

* You will need to install Ruby 2.4, and preferably a ruby version manager. I recommend using [chruby](chruby) and [ruby-install](ruby-install).
* Install bundler (the Ruby gem dependency manager) `gem install bundler`
* Check out the pact_broker repository.
* Run `bundle exec pact_broker:dev:setup`. This will create an example application that you can run locally, that uses the local source code.
* To run the example:

      cd dev
      bundle exec rackup

* The application will be available on `http://localhost:9292`

[chruby]: https://github.com/postmodern/chruby
[ruby-install]: https://github.com/postmodern/ruby-install
