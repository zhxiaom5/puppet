class role::analytics_cluster::webserver {

    system::role { 'analytics_cluster::webserver':
        description => 'Webserver hosting the main Analytics websites'
    }

    include ::profile::analytics::cluster::gitconfig

    include ::profile::statistics::web

    # Superset. T166689
    include ::profile::superset

    include ::profile::hue

    # Turnilo replaced Pivot - T194427
    include ::profile::druid::turnilo

    include ::profile::base::firewall
    include standard
}