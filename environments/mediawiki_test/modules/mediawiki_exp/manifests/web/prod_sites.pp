class mediawiki_exp::web::prod_sites {
    tag 'mediawiki', 'mw-apache-config'

    apache::site { 'redirects':
        content  => compile_redirects('puppet:///modules/mediawiki_exp/apache/sites/redirects/redirects.dat'),
        priority => 2,
    }

    apache::site { 'main':
        source   => 'puppet:///modules/mediawiki_exp/apache/sites/main.conf',
        priority => 3,
    }

    apache::site { 'remnant':
        source   => 'puppet:///modules/mediawiki_exp/apache/sites/remnant.conf',
        priority => 4,
    }

    apache::site { 'search.wikimedia':
        source   => 'puppet:///modules/mediawiki_exp/apache/sites/search.wikimedia.conf',
        priority => 5,
    }

    apache::site { 'secure.wikimedia':
        source   => 'puppet:///modules/mediawiki_exp/apache/sites/secure.wikimedia.conf',
        priority => 6,
    }

    apache::site { 'wikimania':
        source   => 'puppet:///modules/mediawiki_exp/apache/sites/wikimania.conf',
        priority => 7,
    }

    apache::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki_exp/apache/sites/wikimedia.conf',
        priority => 8,
    }

    apache::site { 'foundation':
        source   => 'puppet:///modules/mediawiki_exp/apache/sites/foundation.conf',
        priority => 9,
    }

    $sites_available = '/etc/apache2/sites-available'
    # Included in main.conf
    $main_conf_sites = [
        'mediawiki.org',
        'test.wikidata.org',
        'wikidata.org',
        'wiktionary.org',
        'wikiquote.org',
        'donate.wikimedia.org',
        'vote.wikimedia.org',
        'wikipedia.org',
        'wikibooks.org',
        'wikisource.org',
        'wikinews.org',
        'wikiversity.org',
        'wikivoyage.org'
    ]
    mediawiki_exp::web::site { $main_conf_sites:
        before => Apache::Site['main']
    }

    $remnant_conf_sites = [
        'meta.wikimedia.org',
        '_wikisource.org',
        'commons.wikimedia.org',
    ]

    mediawiki_exp::web::site { $remnant_conf_sites:
        before => Apache::Site['remnant']
    }
}