#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcontentxlation.sh
#############################################################

source /usr/local/etc/dump_functions.sh

do_dump() {
    format=$1
    plaintext=$2
    command="$php $multiversionscript $xlationscript --wiki enwiki -q --split-at 500 --outputdir $outdir --compression gzip --format $format"

    if [ -n "$plaintext" ]; then
       command="$command --plaintext"
    fi

    if [ "$dryrun" == "true" ]; then
        echo $command
    else
        $command
    fi
}

usage() {
    echo "Usage: $0 [--config <pathtofile>] [--dryrun]"
    echo
    echo "  --config   path to configuration file for dump generation"
    echo "             (default value: ${confsdir}/wikidump.conf.dumps"
    echo "  --dryrun   display dump command instead of running it"
    exit 1
}

#####################
# MAIN
#####################

configfile="${confsdir}/wikidump.conf.dumps"
dryrun="false"

#####################
# Get cmdline args
#####################

while [ $# -gt 0 ]; do
    if [ $1 == "--config" ]; then
        configfile="$2"
        shift; shift
    elif [ $1 == "--dryrun" ]; then
        dryrun="true"
        shift
    else
        echo "$0: Unknown option $1"
        usage
    fi
done

#####################
# Get config settings
#####################

args="tools:php"
results=`python "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args"`

php=`getsetting "$results" "tools" "php"`

for settingname in "php"; do
    checkval "$settingname" "${!settingname}"
done

####################
# Dump
####################

today=`date +%Y%m%d`
xlationdir="${cronsdir}/contenttranslation"
outdir="${xlationdir}/${today}"
mkdir -p "$outdir" || exit 1
multiversionscript="${apachedir}/multiversion/MWScript.php"
xlationscript="extensions/ContentTranslation/scripts/dump-corpora.php"

do_dump json
do_dump json plaintext
do_dump tmx plaintext
