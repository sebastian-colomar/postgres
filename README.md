# postgres
```

PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

container=postgres
cmd='-c shared_buffers=256MB -c max_connections=200'
image=library/postgres:latest
mount=/var/lib/postgresql
network=postgres
restart=always
run=/run/postgresql
user=postgres
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
    --name ${container} \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --volume ${run}:${run} \
    --volume ${volume}:${mount} \
    ${image} \
    ${cmd}

docker \
    exec \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    psql

command='\l'
dbname=postgres
user=postgres
username=postgres
docker \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \
    
```
