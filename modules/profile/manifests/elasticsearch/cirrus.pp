#
# This class configures elasticsearch
#
# == Parameters:
#
# For documentation of parameters, see the elasticsearch profile.
#
class profile::elasticsearch::cirrus(
    String $cluster_name = hiera('profile::elasticsearch::cluster_name'),
    String $ferm_srange = hiera('profile::elasticsearch::cirrus::ferm_srange'),
    String $certificate_name = hiera('profile::elasticsearch::cirrus::certificate_name'),
    String $storage_device = hiera('profile::elasticsearch::cirrus::storage_device'),
) {
    $http_port = 9200
    $tls_port = 9423

    include ::profile::elasticsearch

    package {'wmf-elasticsearch-search-plugins':
        ensure => present,
        before => Service['elasticsearch'],
    }

    ferm::service { 'elastic-http':
        proto   => 'tcp',
        port    => $http_port,
        notrack => true,
        srange  => $ferm_srange,
    }

    file { '/etc/udev/rules.d/elasticsearch-readahead.rules':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "SUBSYSTEM==\"block\", KERNEL==\"${storage_device}\", ACTION==\"add|change\", ATTR{bdi/read_ahead_kb}=\"128\"",
        notify  => Exec['elasticsearch_udev_reload'],
    }

    exec { 'elasticsearch_udev_reload':
        command     => '/sbin/udevadm control --reload && /sbin/udevadm trigger',
        refreshonly => true,
    }

    class { '::elasticsearch::https':
        certificate_name => $certificate_name,
        ferm_srange      => $ferm_srange,
    }

    # Install the hot threads collector
    elasticsearch::log::hot_threads_cluster { $cluster_name:
        http_port => $http_port,
    }
}
