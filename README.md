# mediawiki-docker-compose

A prototype docker-compose setup for a fully-featured MediaWiki install
including VisualEditor, Parsoid, RESTBase, Mathoid & other services.

## Requirements 

You need `docker` and `docker-compose`, which is available in recent distros
like Debian Sid. Alternatively, you can follow [the Docker install
instructions](https://docs.docker.com/compose/install/) for your distribution.

The minimum hardware requirements are a KVM or similar VM with 512M RAM. These
can be had from a variety of vendors for around $5/month. [This
comparison from ServerBear lists some
options](http://serverbear.com/compare?Sort=BearScore&Order=desc&Server+Type=VPS&Monthly+Cost=-&HDD=-&RAM=500000000-&BearScore=-&Virtualization=kvm).

## Description

Running `docker-compose up` in a checkout of this repository will start three
containers:

- An Apache/MediaWiki container with PHP 5.6 and MediaWiki
    1.25.3(wikimedia/mediawiki, based on
    https://github.com/gwicke/docker-mediawiki).
- A MySQL container, used as the database backend for MediaWiki.
- A [mediawiki-node-services](https://github.com/gwicke/mediawiki-node-services)
    container, currently running RESTBase and Parsoid in a single node process
    for memory efficiency.

After startup, a brand new MediaWiki install will be reachable at
http://localhost/.

### Architecture notes

All data is stored outside the containers in a host directory:

```bash
ls /var/lib/mediawiki-docker-compose/
mediawiki-core  mediawiki-mysql  node-services
```

To reset all state:

```
docker-compose rm
rm -rf /var/lib/mediawiki-docker-compose
```

## Status & next steps

This is a fairly early prototype. The basic functionality of MediaWiki +
services is there, but some details about the configuration will likely change
before this can be used in production.

Next steps:

- Include / configure VisualEditor by default.
- Forward `/api/rest_v1/` to RESTBase.
- Set up systemd / init scripts to start up the docker-compose setup on boot.
