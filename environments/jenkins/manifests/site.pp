hiera_include('classes')

node default {
  include build_slaves::jenkins
}
