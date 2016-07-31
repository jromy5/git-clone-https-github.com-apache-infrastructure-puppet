module Puppet::Parser::Functions
  # preprocess and expand each vhost
  newfunction(:preprocess_vhosts, :type => :rvalue) do |args|
    vhosts = args.first

    # get ldap servers: prefer colo specific info over total list
    ldap = function_hiera(['ldapclient::ldapservers', false])
    ldap ||= function_hiera(['ldapserver::slapd_peers', {}]).values.
      map {|name| "#{name}:636"}.join(' ')
    ldap = 'ldap1-us-west.apache.org:636' if ldap.empty?

    vhosts.each do |vhost, config|
      vhosts[vhost] = ApacheVHostMacros.new(vhosts[vhost], ldap).result
    end
  end

  #
  # Expand 'passenger' and 'authldap' entries into updates to 'custom_fragment'
  #
  class ApacheVHostMacros
    # extract facts, process passenger and authldap entries
    def initialize(facts, ldap)
      @facts = facts.dup
      @docroot = @facts['docroot'] || '/var/www'
      @fragment = @facts['custom_fragment'] || ''
      @ldap = 'ldaps://' + ldap.gsub('ldaps://', '') +
        '/ou=people,dc=apache,dc=org?uid'

      @alias = Hash.new {|hash, key| "#@docroot#{key}"}

      passenger = @facts.delete('passenger')
      expand_passenger(passenger) if passenger

      authldap = @facts.delete('authldap')
      expand_authldap(authldap) if authldap
    end

    # common logic to add/update an Apache http config section
    def section(tag, path, content=nil)
      unless @fragment.include? "<#{tag} #{path}>"
        @fragment += "\n<#{tag} #{path}>\n</#{tag}>\n"
      end

      if content
        path = Regexp.escape(path)
        content.strip!.gsub! /^\s*/, '  '
        @fragment[/\n<#{tag} #{path}>\n.*?()<\/#{tag}>/m, 1] = content + "\n"
      end
    end

    # expand passenger entries
    def expand_passenger(passenger)
      passenger.each do |url|
        @alias[url] = "#@docroot#{url}/public"
        @fragment += "\nAlias #{url}/ #{@alias[url]}\n"
        section 'Location', url, %{
          PassengerBaseURI #{url}
          PassengerAppRoot #{@docroot}#{url}
          Options -MultiViews
          CheckSpelling Off
          SetEnv HTTPS on
        }
      end
    end
    
    # expand authldap entries
    def expand_authldap(authldap)
      authldap.each do |auth|
        isdn = auth['idsn'] || (auth['attribute']=='memberUid' ? 'off' : 'on')

        auth['locations'].each do |url|
          if url.end_with? '/'
            directive = 'Directory'
            path = @alias[url].chomp('/')
          else
            directive = 'LocationMatch'
            path = '^' + url
          end

          section directive, path, %{
            AuthType Basic
            AuthName #{auth['name'].inspect}
            AuthBasicProvider ldap
            AuthLDAPUrl #{@ldap.inspect}
            AuthLDAPGroupAttribute #{auth['attribute']}
            AuthLDAPGroupAttributeIsDN #{isdn}
            Require ldap-group #{auth['group']}
          }
        end
      end
    end

    # produce result
    def result
      @fragment.gsub!(/\A\n+/, '') # eliminate leading whitespace
      @fragment.gsub!(/%\((\w+:?\w*)\)/, '%{\1}') # convert %(...) => %{...}
      @facts['custom_fragment'] = @fragment unless @fragment.empty?
      @facts
    end
  end
end
