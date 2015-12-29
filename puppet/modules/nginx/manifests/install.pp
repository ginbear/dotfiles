class nginx::install {

  yumrepo {'nginx':
    descr    => 'nginx yum repository',
    name     => 'nginx',
    baseurl  => "http://nginx.org/packages/mainline/centos/7/\$basearch/",
    enabled  => 1,
    gpgcheck => 0,
  }

  package { 'nginx':
    require => Yumrepo['nginx'],
  }

}
