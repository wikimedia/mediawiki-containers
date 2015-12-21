# mediawiki-containers

Containerized MediaWiki install including VisualEditor, Parsoid, RESTBase,
Mathoid & other services.

## Requirements 

You need `docker` >= 1.6. On a recent Debian or Ubuntu distribution (Jessie,
Sid), this can be installed with `apt-get install docker.io`. See [the Docker
install instructions](https://docs.docker.com/engine/installation/) for other
platforms.

The minimum hardware requirements are a KVM or similar VM with 512M RAM. These
can be had from a variety of vendors for around $5/month. [This
comparison from ServerBear lists some
options](http://serverbear.com/compare?Sort=BearScore&Order=desc&Server+Type=VPS&Monthly+Cost=-&HDD=-&RAM=500000000-&BearScore=-&Virtualization=KVM).

## Description

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
ls /var/lib/mediawiki-containers/
mediawiki  mysql  node-services
```

This greatly simplifies backups and upgrades. Update scripts are run on each
startup, which means that updating to a newer version of the entire setup is as
easy as a restart:

```bash
sudo ./mediawiki-containers restart
```

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

### Alternative to the shell script: `docker-compose`

This project also provides an equivalent `docker-compose` configuration, which
can be used by executing `docker-compose up`. A nice thing about using
docker-compose is a very slightly cleaner configuration, and merged output from
all containers. 

A downside is its lacking support for parametrizing the docker network IP. It
turns out that docker on older distributions like Jessie uses a different
network than newer distros, which makes it difficult to support DNS resolution
in both using the same `docker-compose` config. The provided configuration
assumes a recent distribution, so won't work on Jessie out of the box.
