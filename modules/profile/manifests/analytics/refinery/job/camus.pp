# == Class profile::analytics::refinery::job::camus
# Uses camus::job to set up cron jobs to
# import data from Kafka into Hadoop.
#
# == Parameters
# [*kafka_cluster_name*]
#   Name of the Kafka cluster in the kafka_clusters hash that will be used
#   to look up brokers from which Camus will import data.  Default: analytics
#
class profile::analytics::refinery::job::camus(
    $kafka_cluster_name = hiera('profile::analytics::refinery::job::camus::kafka_cluster_name', 'jumbo')
) {
    require ::profile::hadoop::common
    require ::profile::analytics::refinery

    $kafka_config  = kafka_config($kafka_cluster_name)
    $kafka_brokers = suffix($kafka_config['brokers']['array'], ':9092')

    # Temporary while we migrate camus jobs over to new kafka cluster.
    $kafka_config_analytics  = kafka_config('analytics')

    $kafka_brokers_analytics = suffix($kafka_config_analytics['brokers']['array'], ':9092')
    $kafka_brokers_jumbo     = suffix($kafka_config['brokers']['array'], ':9092')

    # Make all uses of camus::job set default kafka_brokers and camus_jar.
    # If you build a new camus or refinery, and you want to use it, you'll
    # need to change these.  You can also override these defaults
    # for a particular camus::job instance by setting the parameter on
    # the camus::job declaration.
    Camus::Job {
        script              => "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python && ${profile::analytics::refinery::path}/bin/camus",
        kafka_brokers       => $kafka_brokers,
        camus_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/camus-wmf/camus-wmf-0.1.0-wmf7.jar",
        check_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.69.jar",
        # Email reports if CamusPartitionChecker finds errors.
        check_email_enabled => true,
        template_variables  => {
            'hadoop_cluster_name' => $::profile::hadoop::common::cluster_name
        }
    }


    # Import webrequest_* topics into /wmf/data/raw/webrequest
    # every 10 minutes, check runs and flag fully imported hours.
    camus::job { 'webrequest':
        check         => true,
        minute        => '*/10',
        kafka_brokers => $kafka_brokers_jumbo,

    }

    # Import eventlogging_* topics into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        minute                => '5',
        kafka_brokers         => $kafka_brokers_jumbo,
        check                 => true,
        # Don't need to write _IMPORTED flags for EventLogging data
        check_dry_run         => true,
        # Only check these topic, since they should have data every hour.
        check_topic_whitelist => 'eventlogging_(NavigationTiming|VirtualPageView)',
    }

    # Import eventbus topics into /wmf/data/raw/eventbus
    # once every hour.
    camus::job { 'eventbus':
        minute                => '5',
        kafka_brokers         => $kafka_brokers_jumbo,
        check                 => true,
        # Don't need to write _IMPORTED flags for EventBus data
        check_dry_run         => true,
        # Only check this topic, since it should always have data for every hour
        # (except during DC switchover).
        check_topic_whitelist => 'eqiad.mediawiki.revision-create',
    }

    # Import mediawiki_* topics into /wmf/data/raw/mediawiki
    # once every hour.  This data is expected to be Avro binary.
    camus::job { 'mediawiki':
        # Currently not used, should be re-enabled if mediawiki-analytics move to Kafa jumbo-eqiad.
        ensure        => 'absent',
        check         => true,
        minute        => '15',
        # refinery-camus contains some custom decoder classes which
        # are needed to import Avro binary data.
        libjars       => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.28.jar",
        kafka_brokers => $kafka_brokers_jumbo,
    }
    # TODO: This camus job will be removed once all mediawiki avro topics have moved to jumbo.
    # See: https://phabricator.wikimedia.org/T188136
    camus::job { 'mediawiki-analytics':
        check         => true,
        minute        => '15',
        # refinery-camus contains some custom decoder classes which
        # are needed to import Avro binary data.
        libjars       => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.28.jar",
        kafka_brokers => $kafka_brokers_analytics,
    }

    # Import eventbus mediawiki.job queue topics into /wmf/data/raw/mediawiki_job
    # once every hour.
    camus::job { 'mediawiki_job':
        minute        => '10',
        kafka_brokers => $kafka_brokers_jumbo,
    }

    # Import netflow queue topics into /wmf/data/raw/netflow
    # once every hour.
    camus::job { 'netflow':
        minute        => '30',
        kafka_brokers => $kafka_brokers_jumbo,
    }

}
