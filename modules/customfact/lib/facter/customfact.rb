Facter.add("asfosrelease") do
  setcode do
    Facter::Util::Resolution.exec("facter operatingsystemrelease | sed -e 's/[[:punct:]]//g' | awk '{print tolower($0)}'")
  end
end


Facter.add("asfosname") do
  setcode do
    Facter::Util::Resolution.exec("facter operatingsystem | sed -e 's/[[:punct:]]//g' | awk '{print tolower($0)}'")
  end
end

Facter.add("asfcolo") do
  setcode do
    ipadd = Facter.value('ipaddress')
    case ipadd
    when /^140.211.11.([0-9]+)$/
      "osuosl"
    when /^192.87.106.([0-9]+)$/
      "sara"
    when /^160.45.251.([0-9]+)$/
      "fub"
    when /^9.9.9.([0-9]+)$/
      "rackspace"
    when /^67.195.81..([0-9]+)$/
      "yahoo"
    when /^172.31.33.([0-9]+)$/ # Need to expand this, the subnet is actually a /20
      "amz-vpc-virginia-1b"
    when /^10.0.([0-9]+).([0-9]+)$/
      "amz-vpc-virginia-1d"
    when /^10.3.([0-9]+).([0-9]+)$/
      "amz-vpc-us-west"
    when /^10.2.([0-9]+).([0-9]+)$/
      "amz-vpc-eu-west"
    when /^162.209.6.([0-9]+)$/
      "rax-vpc-us-mid"
    else
      'No Colo could be automatically determined'
    end
  end
end

