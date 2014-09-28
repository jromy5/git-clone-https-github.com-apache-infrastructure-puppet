# Install a Foreman master without a Puppet master
# NOTE: There is some manual setup required here!
# see http://theforeman.org/manuals/1.6/index.html#3.2.3InstallationScenarios
class foreman {
  require apt
  require foreman::apache
  require foreman::postgres

  $foreman_version = '1.6.0-1'
  $ruby_cli_version = '0.1.3-1'

  case $::lsbdistcodename {
    'trusty': {
      $packages = [
        'foreman',
        'foreman-postgresql',
        'foreman-compute',
        'foreman-proxy',
        'foreman-vmware',
      ]

      $ruby_cli = [
        'ruby-hammer-cli',
        'ruby-hammer-cli-foreman',
      ]

      package { $packages:
        ensure  => $foreman_version,
      }

      package { $ruby_cli:
        ensure => $ruby_cli_version
      }

      file { '/etc/foreman/database.yml':
        ensure => present,
        source => 'puppet:///modules/foreman/database.yaml',
      }
    }
    default: {
    }
  }
}
