# PostgreSQL for COmanage Registry

A simple example demonstrating how to create and image and container
based on PostgreSQL to use with COmanage Registry containers. 

## Build

```
docker build -t comanage-registry-postgres .
```

## Run

Create a user-defined network bridge with

```
docker network create --driver=bridge \
  --subnet=192.168.0.0/16 \
  --gateway=192.168.0.100 \
  comanage-registry-internal-network
```

and then mount a host directory such as `/tmp/postgres-data`
to `/var/lib/postgresql/data` inside the container to persist
data, eg.

```
docker run -d --name comanage-registry-database \
  --network comanage-registry-internal-network \
  -v /tmp/postgres-data:/var/lib/postgresql/data \
  comanage-registry-postgres
```
