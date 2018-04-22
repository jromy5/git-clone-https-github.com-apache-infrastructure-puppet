#/etc/puppet/modules/build_slaves/manifests/kube.pp

class build_slaves::kube ( ) {

  exec { 'download_and_install_kubectl':
    command => '/usr/bin/curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/kubectl',
    creates => '/usr/local/bin/kubectl',
    timeout => 600,
  }

}
