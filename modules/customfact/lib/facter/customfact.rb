Facter.add("asf_osrelease") do
  setcode do
    Facter::Util::Resolution.exec('facter operatingsystemrelease | perl -pe s/[[:punct:]]//g | sed -e "s/\(.*\)/\L\1/"')
  end
end


Facter.add("asf_osname") do
  setcode do
    Facter::Util::Resolution.exec('facter operatingsystem | sed -e "s/\(.*\)/\L\1/"')
  end
end

Facter.add("asf_colo") do
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
    else
      'No Colo could be automatically determined'
    end
  end
end

