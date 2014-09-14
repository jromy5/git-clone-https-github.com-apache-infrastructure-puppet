# Install a Foreman master without a Puppet master
# NOTE: There is some manual setup required here!

class Foreman {
  $version = '1.6.0'
  case $lsbdistcodename{
    trusty:
      $packages = [
        'foreman',
        'foreman-pgsql',
        'foreman-compute',
        'foreman-proxy',
        'foreman-vmware'
        'ruby-hammer-cli'
        'ruby-hammer-cli-foreman'
      ]

      package { $packages:
        require => [ Apt::key['foreman'], Apt::source['foreman'] ],
        ensure  => $version
      }
  }
}
