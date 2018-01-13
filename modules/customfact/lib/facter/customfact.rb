require 'ipaddr'

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

Facter.add("ipaddress_primary") do
  setcode do
    if Facter.value('ipaddress_eth0')
      Facter.value('ipaddress_eth0')
    elsif Facter.value('ipaddress_em0')
      Facter.value('ipaddress_em0')
    elsif Facter.value('ipaddress_eth1')
      Facter.value('ipaddress_eth1')
    elsif Facter.value('ipaddress_em1')
      Facter.value('ipaddress_em1')
    else
      Facter.value('ipaddress')
    end
  end
end

Facter.add("asfcolo") do
  setcode do
    hostname = Facter.value('hostname')
    if hostname.include? "ubuntu1464"
      "vagrant"
    else
      ipadd = Facter.value('ipaddress_primary')
      case ipadd
      when /^140.211.11.([0-9]+)$/
        "osuosl"
      when /^192.87.106.([0-9]+)$/
        "sara"
      when /^160.45.251.([0-9]+)$/
        "fub"
      when /^9.9.9.([0-9]+)$/
        "rackspace"
      when /^67.195.81.([0-9]+)$/
        "yahoo"
      when /^172\.31\.3[2-9]|4[0-7]\.\d+$/
        "amz-vpc-virginia-1b"
      when /^10.0.([0-9]+).([0-9]+)$/
        "amz-vpc-virginia-1d"
      when /^10.3.([0-9]+).([0-9]+)$/
        "amz-vpc-us-west"
      when /^10.2.([0-9]+).([0-9]+)$/
        "amz-vpc-eu-west"
      when /^10.30.([0-9]+).([0-9]+)$/
        "amz-vpc-eu-central"
      when /^162.209.6.([0-9]+)$/
        "rax-vpc-us-mid"
      when /^10.41.([0-9]+).([0-9]+)$/
        "phoenixnap-public"
      when /^10.40.([0-9]+).([0-9]+)$/
        "phoenixnap-private"
      when /^163.172.([0-9]+).([0-9]+)$/
        "iliad-paris"
      when /^62.210.89.([0-9]+)$/
        "iliad-paris"
      when /^10.10.([0-9]+).([0-9]+)$/
        "lw-us"
      when /^10.20.([0-9])+.([0-9]+)$/
        "lw-nl"
      else
        "default"
      end
    end
  end
end

Facter.add("oem") do
  setcode do
    oem = Facter.value('bios_vendor')
    if oem =~ /dell/i
      "dell"
    end
  end
end

Facter.add("masklength") do
  setcode do
    netmask = Facter.value('netmask')
    IPAddr.new(netmask).to_i.to_s(2).count("1")
  end
end
