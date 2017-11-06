# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::k8s (
    $users = hiera('k8s_infrastructure_users'), # lint:ignore:wmf_styleguide
){
    include ::standard
    include ::base::firewall

    $targets_path = '/srv/prometheus/k8s/targets'
    $storage_retention = hiera('prometheus::server::storage_retention', '2190h0m0s')
    $max_chunks_to_persist = hiera('prometheus::server::max_chunks_to_persist', '524288')
    $memory_chunks = hiera('prometheus::server::memory_chunks', '1048576')
    $bearer_token_file = '/srv/prometheus/k8s/k8s.token'
    $master_host = "kubemaster.svc.${::site}.wmnet"
    $client_token = $users['prometheus']['token']

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site' => $::site,
        },
    }

    # Configure scraping from k8s cluster with distinct jobs:
    # - k8s-api: api server metrics (each one, as returned by k8s)
    # - k8s-node: metrics from each node running k8s
    # See also:
    # * https://prometheus.io/docs/operating/configuration/#<kubernetes_sd_config>
    # * https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml
    $scrape_configs_extra = [
        {
            'job_name'              => 'k8s-api',
            'bearer_token_file'     => $bearer_token_file,
            'scheme'                => 'https',
            'kubernetes_sd_configs' => [
                {
                    'api_server'        => "https://${master_host}:6443",
                    'bearer_token_file' => $bearer_token_file,
                    'role'              => 'endpoints',
                },
            ],
            # Scrape config for API servers, keep only endpoints for default/kubernetes to poll only
            # api servers
            'relabel_configs'       => [
                {
                    'source_labels' => ['__meta_kubernetes_namespace',
                                        '__meta_kubernetes_service_name',
                                        '__meta_kubernetes_endpoint_port_name'],
                    'action'        => 'keep',
                    'regex'         => 'default;kubernetes;https',
                },
            ],
        },
        {
            'job_name'              => 'k8s-node',
            'bearer_token_file'     => $bearer_token_file,
            # Force (insecure) https only for node servers
            'scheme'                => 'https',
            'kubernetes_sd_configs' => [
                {
                    'api_server'        => "https://${master_host}:6443",
                    'bearer_token_file' => $bearer_token_file,
                    'role'              => 'node',
                },
            ],
            'relabel_configs'       => [
                # Map kubernetes node labels to prometheus metric labels
                {
                    'action' => 'labelmap',
                    'regex'  => '__meta_kubernetes_node_label_(.+)',
                },
            ]
        },
    ]

    prometheus::server { 'k8s':
        storage_encoding      => '2',
        listen_address        => '127.0.0.1:9906',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        global_config_extra   => $config_extra,
        scrape_configs_extra  => $scrape_configs_extra,
    }

    prometheus::web { 'k8s':
        proxy_pass => 'http://localhost:9906/k8s',
    }

    prometheus::rule { 'rules_k8s.conf':
        instance => 'k8s',
        source   => 'puppet:///modules/role/prometheus/rules_k8s.conf',
    }

    file { $bearer_token_file:
        ensure  => present,
        content => $client_token,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
        require => Prometheus::Server['k8s'],
    }
}