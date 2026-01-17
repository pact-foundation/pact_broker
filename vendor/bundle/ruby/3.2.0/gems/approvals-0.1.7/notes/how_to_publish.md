# Publish
## Prereqs
- [ ] `brew install rbenv ruby-build`
     This installs [rbenv](https://github.com/rbenv/rbenv)
- [ ] `brew install openssl`
- [ ] `eval "$(rbenv init - zsh)"`
    **note:** this command will diff based on the shell. run `rbenv init` to find
 - [ ] `RUBY_CONFIGURE_OPTS=--with-openssl-dir=/usr/local/Cellar/openssl@3/3.0.3 rbenv install 3.1.2`
    **note:** this path comes from
    `brew info openssl`
    ruby version comes from
    `rbenv install -l`
## Build
