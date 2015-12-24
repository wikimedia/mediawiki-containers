# mediawiki-containers

Containerized MediaWiki install including VisualEditor, Parsoid, RESTBase,
Mathoid & other services.

## Requirements 

- KVM or similar VM with at least 512mb RAM. These can be had from a variety
    of vendors for around $5/month. [This comparison from
    ServerBear](http://serverbear.com/compare?Sort=BearScore&Order=desc&Server+Type=VPS&Monthly+Cost=-&HDD=-&RAM=500000000-&BearScore=-&Virtualization=KVM)
    lists some popular options. Any [labs
    instance](https://www.mediawiki.org/wiki/Wikimedia_Labs#Open_access) will
    work as well.
- Distribution: One of
    - Debian 8.0 Jessie or newer, or
    - Ubuntu 15.04 or newer, or
    - arbitrary systemd-based distro with git and [docker >=
        1.6](https://docs.docker.com/engine/installation/) installed.
- Root shell.
- Port 80 available (TODO: automatically switch to alternative ports).

## Installation

On Debian and Ubuntu, the fastest installation method is this one-liner:
```bash
curl https://raw.githubusercontent.com/wikimedia/mediawiki-containers/master/mediawiki-containers | sudo bash
```

Alternatively, you can check out this repository, and run `sudo
./mediawiki-containers install` in the checkout.

The installer mode will prompt you for
- the domain to use, and
- whether to enable automatic nightly updates.

It will set up a systemd unit, so that your MediaWiki install automatically
starts on boot. [Here is a
screencast](https://people.wikimedia.org/~gwicke/mediawiki-containers-install.ogv)
of an installer run.

## Architecture

Running `sudo ./mediawiki-containers start` in a checkout of this repository will
start four containers:

- An Apache/MediaWiki container with PHP 5.6 and MediaWiki 1.27-wmf9
    using [wikimedia/mediawiki](https://hub.docker.com/r/wikimedia/mediawiki/),
    built from https://github.com/gwicke/docker-mediawiki.
- A [MySQL container](https://hub.docker.com/_/mysql/), used as the database
    backend for MediaWiki.
- A
    [wikimedia/mediawiki-node-services](https://hub.docker.com/r/wikimedia/mediawiki-node-services/)
    container built from
    [mediawiki-node-services](https://github.com/gwicke/mediawiki-node-services),
    currently running RESTBase and Parsoid in a single node process for memory
    efficiency.
- A small DNS resolver for service discovery.

After startup, a brand new MediaWiki install will be reachable at
http://localhost/.

### Architecture notes

All data is stored outside the containers in a host directory:

```bash
ls /srv/mediawiki-containers/data
mediawiki  mysql  node-services
```

This greatly simplifies backups and upgrades. Update scripts are run on each
startup, which means that updating to a newer version of the entire setup is as
easy as a restart:

```bash
sudo service mediawiki-containers restart
```

Building on this upgrade-by-default approach, the installer can optionally set
up fully automatic nightly upgrades by setting up a one-line cron job.

## Status & next steps

This is alpha quality software. The basic functionality of MediaWiki, services
and VisualEditor is there, but some details about the configuration will
likely change before this can be used in production.

Done:

- Hook up VisualEditor out of the box.
- Update to MediaWiki ~~1.26~~ 1.27-wmf9.


Next steps:

- Forward `/api/rest_v1/` to RESTBase & configure RESTBase updates. Enable
    Wikitext / HTML switching in VE.
- Set up systemd / init scripts to start up the docker-compose setup on boot.
  - Possibly, also provide a systemd-only startup script that doesn't require docker-compose.
- Add more extensions?
- Use HHVM?
- Profit.

Tell us about your ideas at https://phabricator.wikimedia.org/T92826. 
