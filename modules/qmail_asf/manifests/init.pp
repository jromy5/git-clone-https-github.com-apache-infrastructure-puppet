##/etc/puppet/modules/qmail_asf/manifests/init.pp

class qmail_asf (

  $username                      = 'apmail',
  $user_present                  = 'present',
  $groupname                     = 'apmail',
  $group_present                 = 'present',
  $groups                        = [],
  $shell                         = '/bin/bash',

  # override below in yaml
  $parent_dir,

){

# qmail specific

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => "${parent_dir}/${username}",
      shell      => $shell,
      groups     => $groups,
      managehome => true,
      require    => Group[$groupname],
      system     => true,
  }

  group {
    $groupname:
      ensure => $group_present,
      name   => $groupname,
  }

}
