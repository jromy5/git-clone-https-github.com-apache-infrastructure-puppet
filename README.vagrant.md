# Vagrant testing README

The current status of the Vagrant + Serverspec code is that there's *enough* to
run a server spec for the "base ubuntu" role.

Much of the supporting code in the `Vagrantfile` and in `spec/server` has been
shamelessly cribbed from the [jenkins-infra
project](https://github.com/jenkins-infra/jenkins-infra).



## Running tests 

 * `bundle install`
 * `bundle exec vagrant up`
