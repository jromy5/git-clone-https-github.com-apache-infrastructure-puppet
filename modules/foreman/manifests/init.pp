# Install a Foreman master without a Puppet master
# NOTE: There is some manual setup required here!
# see http://theforeman.org/manuals/1.6/index.html#3.2.3InstallationScenarios
class foreman ($password) {
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

      package { 'ipmitool':
        ensure => latest,
      }

      package { $ruby_cli:
        ensure => $ruby_cli_version
      }

      file { '/etc/foreman/database.yml':
        ensure  => present,
        content => template('foreman/database.yaml.erb'),
      }

      file { '/etc/foreman-proxy/settings.yml':
        ensure  => present,
        content => template('foreman/settings.yml.erb')
      }

      apache::vhost { 'foreman':
        require       => Package[$packages],
        servername    => 'foreman.apache.org',
        serveraliases => 'foreman',
        port          => 80,
        docroot       => '/usr/share/foreman/public',
        options       => ['SymLinksIfOwnerMatch'],
        priority      => '05',
        directories   => [
          {
            path         => '/usr/share/foreman/public',
            auth_require => 'all granted',
            options      => ['SymLinksIfOwnerMatch'],
          },
        ],
      }

      # From the docs: 
      # "For the order parameter for the custom fragment, the vhost defined
      #  type uses multiples of 10, so any order that isn't a multiple of 10
      #  should work."
      concat::fragment { 'foreman_passenger':
        target  => '05-foreman.conf',
        order   => 11,
        content => "\n  PassengerAppRoot /usr/share/foreman\n  PassengerMinInstances 1\n  PassengerStartTimeout 600\n",
      }

      concat::fragment { 'foreman_assets':
        target  => '05-foreman.conf',
        order   => 17,
        content => template('foreman/assets.erb')
      }

      concat::fragment { 'foreman_prestart':
        target  => '05-foreman.conf',
        order   => 19,
        content => '  PassengerPreStart http://foreman.apache.org',
      }
    }
    # Don't do anything if not on Trusty
    default: {
    }
  }
}
