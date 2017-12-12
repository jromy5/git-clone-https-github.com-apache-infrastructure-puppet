#/environments/windows/modules/datadog_agent/manifests/init.pp

class datadog_agent (
  $api_key = '',
){

  file { 'c:\temp':
    ensure => 'directory',
  }

  download_file { 'Download datadog agent' :
    url                   => 'https://s3.amazonaws.com/ddagent-windows-stable/ddagent-cli-latest.msi',
    destination_directory => 'c:\temp',
  }

  package { 'ddagent-cli-latest.msi' :
    source          => 'c:\temp\ddagent-cli-latest.msi',
    install_options => ["APIKEY=${api_key}"],
  }
}
