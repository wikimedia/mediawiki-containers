#!/bin/bash

# mediawiki-containers installer utils

set -e

check_docker_version() {
    if [ "$docker_version" \< "1.6." ];then 
        echo "Docker version >= 1.6 is needed, $docker_version available."
    fi
}


install_docker() {
    if hash docker 2>/dev/null;then
        docker_version=$(docker --version | awk '{print $3}')
        check_docker_version
        echoinfo "Found docker $docker_version"
    else
        docker_version=$(apt-cache show docker.io | grep Version | head -1 | awk '{print $2}') 
        check_docker_version
        echoinfo "Installing docker.io.."
        apt-get install -y docker.io
    fi
}

ask_config() {
    mkdir -p $DATADIR
    conf=$DATADIR/config
    if [ ! -f $conf ];then
        echo
        # Ask a couple of config questions & save a config file.
        echoinfo "MediaWiki needs to know the domain your wiki will be using."
        echoinfo "Examples: www.yourdomain.com, localhost"
        read -p "Domain [localhost]: " MEDIAWIKI_DOMAIN </dev/tty 
        if [ -z "$MEDIAWIKI_DOMAIN" ];then
            MEDIAWIKI_DOMAIN='localhost'
        fi
        echo
        echoinfo "We can set up automatic nightly code updates for you."
        echoinfo "Enabling this keeps your installation secure and up to date."
        while true; do
            read -p "Should we enable automatic nightly code updates? (y/n): " \
                AUTO_UPDATE </dev/tty
            case $AUTO_UPDATE in
                [Yy]* ) AUTO_UPDATE=true; break;;
                [Nn]* ) AUTO_UPDATE=false; break;;
                * ) echowarn "Please answer yes or no.";;
            esac
        done
        echo "MEDIAWIKI_DOMAIN=\"$MEDIAWIKI_DOMAIN\"" > "$conf"
        echo "AUTO_UPDATE=$AUTO_UPDATE" >> "$conf"
        echo "MEDIAWIKI_ADMIN_PASS='$MEDIAWIKI_ADMIN_PASS'" >> "$conf"
    fi
    source "$conf"
}

install_systemd_init() {
    if hash systemd 2>/dev/null; then
        # Install systemd unit
        echoinfo "Installing systemd unit file /etc/systemd/system/mediawiki-containers.."
        ln -sf "`pwd`/init/mediawiki-containers.service" /etc/systemd/system
        systemctl daemon-reload
    else
        echoerror "FIXME: Support init scripts on distributions without systemd!"
        report_bug
        exit 1
        # echo "Installing init script /etc/init.d/mediawiki-containers.."
    fi
}

enable_automatic_updates() {
    # Link a job restarting the service to /etc/cron.daily.
    ln -sf "`pwd`/cron/mediawiki-containers" /etc/cron.daily
}


# Main setup routine.
do_install() {
    # Make sure we have docker.
    install_docker

    # Ask some configuration question.
    ask_config

    # Install a systemd unit or init script.
    install_systemd_init

    # Set up a cron job for automatic updates.
    if [ "$AUTO_UPDATE" = 'true' ];then
        enable_automatic_updates
    fi

    # TODO: Prompt for the domain name & set up letsencrypt & wgServer
}
