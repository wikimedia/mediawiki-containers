#!/bin/bash

# mediawiki-containers installer
# 
# Usage:
# curl https://raw.githubusercontent.com/wikimedia/mediawiki-containers/master/install.sh \
#   | sudo bash
#

set -e

# Output the instructions to report bug about this script
report_bug() {
  echo "Please file a Bug Report at https://github.com/wikimedia/mediawiki-containers/issues/new"
  echo ""
  echo "Please include as many details about the problem as possible i.e., how to reproduce"
  echo "the problem (if possible), type of the Operating System and its version, etc.,"
  echo "and any other relevant details that might help us with troubleshooting."
  echo ""
}

# Platform and Platform Version detection
#
# NOTE: This should now match ohai platform and platform_version matching.
# do not invented new platform and platform_version schemas, just make this behave
# like what ohai returns as platform and platform_version for the server.
#
# ALSO NOTE: Do not mangle platform or platform_version here.  It is less error
# prone and more future-proof to do that in the server, and then all omnitruck clients
# will 'inherit' the changes (install.sh is not the only client of the omnitruck
# endpoint out there).
#

machine=`uname -m`
os=`uname -s`

if test -f "/etc/lsb-release" && grep -q DISTRIB_ID /etc/lsb-release; then
  platform=`grep DISTRIB_ID /etc/lsb-release | cut -d "=" -f 2 | tr '[A-Z]' '[a-z]'`
  platform_version=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f 2`
elif test -f "/etc/debian_version"; then
  platform="debian"
  platform_version=`cat /etc/debian_version`
elif test -f "/etc/redhat-release"; then
  platform=`sed 's/^\(.\+\) release.*/\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]'`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release`

  # If /etc/redhat-release exists, we act like RHEL by default
  if test "$platform" = "fedora"; then
    # FIXME: stop remapping fedora to el
    # FIXME: remove client side platform_version mangling and hard coded yolo
    # Change platform version for use below.
    platform_version="6.0"
  fi

  if test "$platform" = "xenserver"; then
    # Current XenServer 6.2 is based on CentOS 5, platform is not reset to "el" server should hanlde response
    platform="xenserver"
  else
    # FIXME: use "redhat"
    platform="el"
  fi

elif test -f "/etc/system-release"; then
  platform=`sed 's/^\(.\+\) release.\+/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
  platform_version=`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/system-release | tr '[A-Z]' '[a-z]'`
  # amazon is built off of fedora, so act like RHEL
  if test "$platform" = "amazon linux ami"; then
    # FIXME: remove client side platform_version mangling and hard coded yolo, and remapping to deprecated "el"
    platform="el"
    platform_version="6.0"
  fi
# Apple OS X
elif test -f "/usr/bin/sw_vers"; then
  platform="mac_os_x"
  # Matching the tab-space with sed is error-prone
  platform_version=`sw_vers | awk '/^ProductVersion:/ { print $2 }' | cut -d. -f1,2`

  # x86_64 Apple hardware often runs 32-bit kernels (see OHAI-63)
  x86_64=`sysctl -n hw.optional.x86_64`
  if test $x86_64 -eq 1; then
    machine="x86_64"
  fi
elif test -f "/etc/release"; then
  machine=`/usr/bin/uname -p`
  if grep -q SmartOS /etc/release; then
    platform="smartos"
    platform_version=`grep ^Image /etc/product | awk '{ print $3 }'`
  else
    platform="solaris2"
    platform_version=`/usr/bin/uname -r`
  fi
elif test -f "/etc/SuSE-release"; then
  if grep -q 'Enterprise' /etc/SuSE-release;
  then
      platform="sles"
      platform_version=`awk '/^VERSION/ {V = $3}; /^PATCHLEVEL/ {P = $3}; END {print V "." P}' /etc/SuSE-release`
  else
      platform="suse"
      platform_version=`awk '/^VERSION =/ { print $3 }' /etc/SuSE-release`
  fi
elif test "x$os" = "xFreeBSD"; then
  platform="freebsd"
  platform_version=`uname -r | sed 's/-.*//'`
elif test "x$os" = "xAIX"; then
  platform="aix"
  platform_version="`uname -v`.`uname -r`"
  machine="powerpc"
elif test -f "/etc/os-release"; then
  . /etc/os-release
  if test "x$CISCO_RELEASE_INFO" != "x"; then
    . $CISCO_RELEASE_INFO
  fi

  platform=$ID
  platform_version=$VERSION
fi

if test "x$platform" = "x"; then
  echo "Unable to determine platform version!"
  report_bug
  exit 1
fi


if [ "$platform" != "debian" -a "$platform" != "ubuntu" ]; then
	echo "Only Debian and Ubuntu are currently supported!"
	exit 1;
fi


check_docker_version() {
    if [ "$docker_version" \< "1.6." ];then 
        echo "Docker version >= 1.6 is needed, $docker_version available."
    fi
}

install_docker() {
    if hash docker 2>/dev/null;then
        docker_version=$(docker --version | awk '{print $3}')
        check_docker_version
        echo "[OK] Found docker $docker_version"
    else
        docker_version=$(apt-cache show docker.io | grep Version | head -1 | awk '{print $2}') 
        check_docker_version
        echo "Installing docker.io.."
        apt-get install -y docker.io
    fi
}

install_git() {
    if ! hash git 2>/dev/null;then
        echo "Installing git.."
        apt-get install -y git
    else
        echo "[OK] Found git."
    fi
}

check_out_mediawiki_containers() {
    srcdir=/usr/local/src/mediawiki-containers
    if [ ! -d /usr/local/src/mediawiki-containers ];then
        echo "Cloning mediawiki-containers to $srcdir.."
        git clone https://github.com/wikimedia/mediawiki-containers.git "$srcdir"
    else
        cd "$srcdir"
        echo "Updating mediawiki-containers in $srcdir.."
        git pull
    fi
    cd "$srcdir"
}

ask_config() {
    mkdir -p /var/lib/mediawiki-containers
    conf=/var/lib/mediawiki-containers/config
    if [ ! -f $conf ];then
        # Ask a couple of config questions & save a config file.
        read -p "Please enter the domain your wiki will be reachable as: " domain
        while true; do
            read -p "Should we enable automatic nightly code updates? [yn]: " autoupdate
            case $autoupdate in
                [Yy]* ) autoupdate=true; break;;
                [Nn]* ) autoupdate=false; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        echo "MEDIAWIKI_DOMAIN=\"$domain\"" > $conf
        echo "AUTO_UPDATE=$autoupdate" >> $conf
    fi
    source /var/lib/mediawiki-containers/config
}

install_systemd_init() {
    pwd
    if hash systemd 2>/dev/null; then
        # Install systemd unit
        echo "Installing systemd unit file /etc/systemd/system/mediawiki-containers.."
        ln -sf "`pwd`/init/mediawiki-containers.service" /etc/systemd/system
        systemctl daemon-reload
    else
        echo "Installing init script /etc/init.d/mediawiki-containers.."
    fi
}

enable_automatic_updates() {
    # Link a job restarting the service to /etc/cron.daily.
    ln -sf "`pwd`/cron/mediawiki-containers" /etc/cron.daily
}


# Main setup routine.
install() {
    # Make sure we have docker.
    install_docker

    # Make sure we have git.
    install_git

    # Clone the mediawiki-containers repository.
    check_out_mediawiki_containers

    # Ask some configuration question.
    ask_config

    # Install a systemd unit or init script.
    install_systemd_init

    # Set up a cron job for automatic updates.
    if [ "$AUTO_UPDATE" = 'true' ];then
        enable_automatic_updates
    fi

    # TODO: Prompt for the domain name & set up letsencrypt & wgServer

    echo "Starting mediawiki-containers.."
    service mediawiki-containers restart

    echo "[OK] All done."
    echo "Your wiki should now be available at http://localhost/."
}
install
