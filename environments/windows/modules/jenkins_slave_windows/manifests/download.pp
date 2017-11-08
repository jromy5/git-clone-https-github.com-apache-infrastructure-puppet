class jenkins_slave_windows::download (

  $ant = $jenkins_slave_windows::params::ant,
  $chromedriver = $jenkins_slave_windows::params::chromedriver,
  $geckodriver = $jenkins_slave_windows::params::geckodriver,
  $iedriver = $jenkins_slave_windows::params::iedriver,
  $jdk = $jenkins_slave_windows::params::jdk,
  $maven = $jenkins_slave_windows::params::maven,
  $nant = $jenkins_slave_windows::params::nant,
) {
  include jenkins_slave_windows::params
  #### Download winSVN ####
  download_file { "Download winsvn from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/Setup-Subversion-1.8.17.msi',
    destination_directory => 'C:\temp',
  }

  #### Download Git from Bintray
  download_file { "Download Git from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/Git-2.14.3-64-bit.exe',
    destination_directory => 'C:\temp',
  }

  #### Download JDK9 from Bintray
  download_file { "Download JDK9 from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/asf-build-jdk9.0.exe',
    destination_directory => 'C:\temp',
  }
}