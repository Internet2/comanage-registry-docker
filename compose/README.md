# Docker Compose Example for COmanage Registry 

This is an example Docker Compose file to deploy COmanage
Registry with the Shibboleth Native SP for Apache HTTP Server
and a PostgreSQL database.

See the individual image Dockerfile templates and README
files for details on how to prepare the volumes and the
necessary contents including the COmanage Registry 
configuration and the Shibboleth SP configuration.

Change the tag from `COMANAGE_REGISTRY_VERSION-shibboleth-sp`
to `COMANAGE_REGISTRY_VERSION-basic-auth` to quickly deploy
without the need for federation.

## Deploy

```
docker-compose up
```

## Tear Down

```
docker-compose down
```
