# mediawiki-docker-compose

Experimental docker-compose setup for a fully-featured MediaWiki install
including VisualEditor, Parsoid, RESTBase, Mathoid & other services.

## Description

We are starting three containers:

- An Apache/MediaWiki container with PHP 5.6 and MediaWiki
    1.25.3(wikimedia/mediawiki, based on
    https://github.com/gwicke/docker-mediawiki).
- A MySQL container, used as the database backend for MediaWiki.
- A [mediawiki-node-services](https://github.com/gwicke/mediawiki-node-services)
    container, currently running RESTBase and Parsoid in a single node process
    for memory efficiency.

All data is stored outside the containers in a host directory:

```bash
ls /var/lib/mediawiki-docker-compose/
mediawiki-core  mediawiki-mysql  node-services
```
## Usage

```bash
docker-compose up
```

## TODO

This is a fairly early prototype. The basic functionality of MediaWiki +
services is there, but some details about the configuration will likely change
before this can be used in production.

Next steps:

- Forward `/api/rest_v1/` to RESTBase.
- Include / configure VisualEditor by default.
