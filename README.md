# postgres
```

PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

cmd='-c shared_buffers=256MB -c max_connections=200'
image=library/postgres:latest
mount=/var/lib/postgresql/data
name=postgres
network=postgres
volume=postgres

docker \
    volume \
    create \
    ${volume}
docker \
    network \
    create \
    ${network}
docker \
    container \
    run \
    --detach \
    --env PGDATA=${PGDATA} \
    --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    --name ${name} \
    --network ${network} \
    --volume ${volume}:${mount} \
    ${image} \
    ${cmd}

```
