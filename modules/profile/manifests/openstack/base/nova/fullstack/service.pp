class profile::openstack::base::nova::fullstack::service(
    $osstackcanary_pass = hiera('profile::openstack::base::nova::fullstack_pass'),
    $nova_api_host = hiera('profile::openstack::base::nova_api_host'),
    $region = hiera('profile::openstack::labtestn::region'),
    ) {

    class { '::openstack::nova::fullstack::service':
        active   => ($::fqdn == $nova_api_host),
        password => $osstackcanary_pass,
        region   => $region,
    }
    contain '::openstack::nova::fullstack::service'
}
