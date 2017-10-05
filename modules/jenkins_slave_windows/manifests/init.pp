class jenkins_slave_windows (

  $user_password    = '',
  $ant = ['apache-ant-1.8.4', 'apache-ant-1.9.4', 'apache-ant-1.9.7', 'apache-ant-1.9.9', 'apache-ant-1.10.1'],
  $maven = ['apache-maven-2.2.1', 'apache-maven-3.0.4', 'apache-maven-3.0.5', 'apache-maven-3.2.1', 'apache-maven-3.2.5', 'apache-maven-3.3.3', 'apache-maven-3.3.9', 'apache-maven-3.5.0'], # lint:ignore:140chars
  $java_jenkins = ['jdk1.9.0', 'jdk1.8.0-144'],

) {
  user { 'jenkins':
    ensure   => present,
    comment  => 'non-admin Jenkins account',
    groups   => ['Users'],
    password => $user_password, #password has to meet whatever policy exists or the account doesn't get created with no error
  }
 
   #### Download JDK9 from Bintray
  download_file { "Download JDK9 from bintray" :
    url                   => 'https://apache.bintray.com/WindowsPackages/asf-build-jdk1.9.0.exe',
    destination_directory => 'C:\temp',
  }  

  #### Install JDK 9 silently for the system, but only if C:\Program Files\Java doesn't exist
  exec { 'install jdk' :
    command => 'powershell.exe c:\temp\asf-build-jdk1.9.0.exe /s',
    onlyif    => "if (Test-Path 'C:\\Program Files\\Java') { exit 1;}  else { exit 0; }",
    logoutput => true,
    provider => powershell,
  }
  
  #### create directories for Jenkins, tools, and such
  file { ['F:/jenkins','F:/jenkins/tools','F:/jenkins/tools/ant','F:/jenkins/tools/java','F:/jenkins/tools/maven']:
    ensure => directory,
  }

  $java_jenkins.each |String $jdk| {
    #### Download various build tools (..jenkins/tools/), unzip them, and symlink the latest versions
    download_file { "Download asf-build-${jdk} zip from bintray" :
      url                   => "https://apache.bintray.com/WindowsPackages/asf-build-${jdk}.zip",
      destination_directory => 'F:\jenkins\tools\java',
    }  
  
    file { ["F:/jenkins/tools/java/${jdk}"]:
    ensure => directory,
    }
    
    exec { "extract ${jdk}" :
      command => "powershell.exe Expand-Archive F:\\jenkins\\tools\\java\\asf-build-${jdk}.zip -DestinationPath F:\\jenkins\\tools\\java\\${jdk}",
      onlyif    => "if (Test-Path 'F:\\jenkins\\tools\\java\\asf-build-${jdk}.zip') { exit 0;}  else { exit 1; }",
      logoutput => true,
      provider => powershell,
    }
  }
  exec { "create symlink for JDK1.9":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.9 F:\\jenkins\\tools\\java\\jdk1.9.0",
    provider => powershell,
  }
    exec { "create symlink for JDK1.8":
    command      => "powershell.exe cmd.exe /c mklink /d F:\\jenkins\\tools\\java\\latest1.8 F:\\jenkins\\tools\\java\\jdk1.8.0-144",
    provider => powershell,
  }
}