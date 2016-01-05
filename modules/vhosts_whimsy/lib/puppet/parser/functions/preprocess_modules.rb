module Puppet::Parser::Functions
  newfunction(:preprocess_modules, :type => :rvalue) do |args|
    if args.first.instance_of? Array
      Hash[args.first.map {|name| [name, {'name' => name}]}]
    else
      args.first
    end
  end
end

