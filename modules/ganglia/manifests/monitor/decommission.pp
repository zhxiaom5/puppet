class ganglia::monitor::decommission {
    package { 'ganglia-monitor':
        ensure => purged,
    }

    package { 'libganglia1':
        ensure => purged,
    }

    # We normally would need only /usr/lib/ganglia/python_modules but let's be
    # ultra cautious here and purge the parent directory
    file { '/usr/lib/ganglia/':
        ensure  => absent,
        recurse => true,
        force   => true,
        require => Package['ganglia-monitor'],
    }
    # This is handled by the purging of ganglia-monitor, but let's be extra
    # explicit so that this is not ever created by some human mistake
    file { '/etc/ganglia/':
        ensure  => absent,
        recurse => true,
        force   => true,
        require => Package['ganglia-monitor'],
    }
    # in some cases /var/lib/ganglia becomes a remnant
    # with files like pdns_gmetric.state in it
    file { '/var/lib/ganglia/':
        ensure  => absent,
        recurse => true,
        force   => true,
        require => Package['ganglia-monitor'],
    }

    # in some cases the pid file was left even when service was stopped
    file { '/run/ganglia-monitor.pid':
        ensure => absent,
    }
    file { '/etc/systemd/system/ganglia-monitor.service':
        ensure => absent,
    }

    file { '/etc/systemd/system/ganglia-monitor-aggregator@.service':
        ensure => absent,
    }
}
