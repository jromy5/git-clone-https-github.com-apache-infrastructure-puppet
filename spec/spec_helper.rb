require 'rubygems'
require 'rspec'
require 'puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.mock_with :rspec
  c.module_path = File.expand_path(File.dirname(__FILE__) + '/../modules')
  c.manifest = File.expand_path(File.dirname(__FILE__) + '/fixtures/site.pp')

  c.default_facts = {
    :kernel => 'Linux',
  }

  c.before(:each) do
    # Workaround until this is fixed:
    #   <https://tickets.puppetlabs.com/browse/PUP-1547>
    require 'puppet/confine/exists'
    Puppet::Confine::Exists.any_instance.stubs(:which => '')
  end
end
