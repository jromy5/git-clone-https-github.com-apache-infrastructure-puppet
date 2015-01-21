#!/etc/puppet/modules/ldapserver/manifests/install/ubuntu/1404.pp

class ldapserver::install::ubuntu::1404 (

) { 

  file { '/etc/ldap/slapd.conf': 
    content   => template('ldapserver/slapd.conf.erb'), 
    notify    => Service["slapd"],
   }


   service { 'slapd':
     hasrestart   =>  true,
     ensure       =>  running,
   }
}
