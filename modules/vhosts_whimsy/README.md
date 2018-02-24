Module description
==================

This is a fully backwards compatible version of the `vhosts_asf` module, which
in turn is a thin [hiera](http://docs.puppetlabs.com/hiera/latest/) wrapper
over the
[apache:::vhost](https://forge.puppetlabs.com/puppetlabs/apache#define-apachevhost),
[apache::mod](https://forge.puppetlabs.com/puppetlabs/apache#installing-arbitrary-modules),
and
[apache::custom_config](https://forge.puppetlabs.com/puppetlabs/apache#define-apachecustom_config)
portions of the 
[puppetlabs/apache](https://forge.puppetlabs.com/puppetlabs/apache)
module on puppet forge.

Usage
=====

To use, simply do a global change of `vhosts_asf` to `vhosts_whimsy` in your
node definition, and then make use of as many or as few of the following
features as you wish.

vhosts_whimsy::modules::modules
--------------------------------

As an alternative to specifying a hash listing modules to be installed, you can
use a simple array.  Example:

    vhosts_whimsy::modules::modules:
      - cgi
      - speling
      
Note that for backwards compatibility, if you specify anything other than an
array, that data will be passed through as is.
      
vhosts_whimsy::vhosts::vhosts
-----------------------------

This modules looks for `passenger` and `authldap` entries in and inserts or
appends the appropriate http configuration commands into the `custom_fragment`
for downstream processing by the [apache puppet
module](https://forge.puppetlabs.com/puppetlabs/apache#custom_fragment-1).

 * `passenger` is a simple list of paths (relative to the specified docroot)
   that contain passenger applications.  Example:
 
        passenger:
          - /racktest
          - /roster
          - /secmail
          
* `authldap` is a list of attributes used to emit
  [authnz](https://httpd.apache.org/docs/2.2/mod/mod_authnz_ldap.html)
  directives, paired with a list of locations against which this definition is
  to apply.  Sub-attributes:

    * `name` - used as the
      [AuthName](https://httpd.apache.org/docs/2.4/mod/mod_authn_core.html#authname)
      directives.
    * `attribute` - used as the
      [AuthLDAPGroupAttribute](https://httpd.apache.org/docs/2.4/mod/mod_authnz_ldap.html#authldapgroupattribute)
    * `isdn` - (optional) used as the
      [AuthLDAPGroupAttributeIsDN](https://httpd.apache.org/docs/2.4/mod/mod_authnz_ldap.html#authldapgroupattributeisdn)
      value (default is `off` if `attribute` is `memberUid`, otherwise `on`)
    * `group` - used as the value for [Require
      ldap-group](https://httpd.apache.org/docs/2.4/mod/mod_authnz_ldap.html#reqgroup)
    * `locations` - list of locations against which to require this
      authentication.  Terminate directory names with a trailing slash.
      Locations without a trailing slash are treated as a location prefix,
      which is useful for individual CGI scripts.

  Example:

        authldap:
        - name: ASF Committers
          group: cn=committers,ou=groups,dc=apache,dc=org
          attribute: memberUid
          locations:
            - /board/agenda/
            - /board/publish_minutes

Additionally as the `hiera` and Apache escape sequence for variables uses the
same syntax, and as the workarounds for escaping in hiera are both clumsy and
don't consistently work in all environments, this function will globally
replace %(varname) with %{varname} in vhost `custom_fragment`s.

Sample output
=============

Examples of HTTP configuration directives produced.

passsenger
----------

    Alias /racktest/$ /srv/whimsy/www/racktest/public

    <Location /racktest>
      PassengerBaseURI /racktest
      PassengerAppRoot /srv/whimsy/www/racktest
      Options -Multiviews
      CheckSpelling Off
      SetEnv HTTPS on
    </Location>

authldap
--------

    <Directory /srv/whimsy/www/board/agenda>
      AuthType Basic
      AuthName "ASF Committers"
      AuthLDAPUrl "ldaps://ldap-us-ro.apache.org:636 ldap-eu-ro.apache.org:636/ou=people,dc=apache,dc=org?uid"
      AuthLDAPGroupAttribute memberUid
      AuthLDAPGroupAttributeIsDN off
      Require ldap-group cn=committers,ou=groups,dc=apache,dc=org
    </Directory>

    <LocationMatch ^/www/board/publish_minutes>
      AuthType Basic
      AuthName "ASF Committers"
      AuthLDAPUrl "ldaps://ldap-us-ro.apache.org:636 ldap-eu-ro.apache.org:636/ou=people,dc=apache,dc=org?uid"
      AuthLDAPGroupAttribute memberUid
      AuthLDAPGroupAttributeIsDN off
      Require ldap-group cn=committers,ou=groups,dc=apache,dc=org
    </LocationMatch>

Test scaffolding
================

See https://github.com/apache/whimsy/blob/master/tools/vhosttest.rb
