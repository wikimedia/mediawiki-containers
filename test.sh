#!/bin/bash

# Basic mediawiki-containers install tests.

set -e

_COLORS=${BS_COLORS:-$(tput colors 2>/dev/null || echo 0)}
__detect_color_support() {
    if [ $? -eq 0 ] && [ "$_COLORS" -gt 2 ]; then
        RC="\033[1;31m"
        GC="\033[1;32m"
        BC="\033[1;34m"
        YC="\033[1;33m"
        EC="\033[0m"
    else
        RC=""
        GC=""
        BC=""
        YC=""
        EC=""
    fi
}
__detect_color_support

# Echo info to stdout
echoinfo() {
    printf "${GC}[TEST INFO]${EC}: %s\n" "$@";
}

# Echo error to stderr
echoerror() {
    printf "${RC}[TEST ERROR]${EC}: %s\n" "$@" 1>&2;
}

# Echo warnings to stdout
echowarn() {
    printf "${YC}[TEST WARN]${EC}: %s\n" "$@";
}

check_service() {
    echoinfo "curl http://localhost/index.php/Main_Page"
    # Make sure that the wiki is reachable & RESTBase works
    curl http://localhost/index.php/Main_Page \
        | grep -q "MediaWiki has been successfully installed"
}

# Make sure the installer does not ask questions
export MEDIAWIKI_DOMAIN=localhost
export AUTO_UPDATE=true

CHECKOUT=$(pwd)

test_install() {
    cd /tmp

    if [ -d /srv/mediawiki-containers ];then
        echowarn "Found existing /srv/mediawiki-containers checkout."
        read -p "Delete it? (y/[n]): " DELETE_IT
        if [ "$DELETE_IT" == 'y' ];then
            rm -rf /srv/mediawiki-containers
        else
            echoerror "Aborted test as /srv/mediawiki-containers exists."
            exit 1
        fi
    fi
        
    # Trick the installer into testing the new code, rather than master.
    git clone "$CHECKOUT" /srv/mediawiki-containers

    cat "$CHECKOUT/mediawiki-containers" | bash -s install

    check_service

    echoinfo "Restart the service"
    service mediawiki-containers restart

    sleep 10

    check_service

    echoinfo "Exercise the automatic updater"
    /etc/cron.daily/mediawiki-containers

    check_service
}

if [ "$1" == 'noinstall' ];then
    echoinfo "noinstall option set, only testing 'mediawiki-containers start'".
    # Sadly, `docker logs` ignores sigpipe, so we can't wait for startup to be
    # done via | sed '/Done in /q'. Instead, employ a static sleep for now.
    ./mediawiki-containers restart &
    sleep 180
    check_service
else
    test_install
fi

echoinfo "Congratulations, all is looking good!"
exit 0
