# postgres
```

PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

container=postgres
cmd='-c shared_buffers=256MB -c max_connections=200'
image=library/postgres:12.8-buster@sha256:26402c048be52bdd109b55b2df66bd73ae59487ebfc209959464c4e40698375b
mount_data=/var/lib/postgresql/data
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
network=postgres
restart=always
user=postgres
volume_data=postgres_data
volume_run=postgres_run
volume_var=postgres_var

docker \
    volume \
    create \
    ${volume_data}
docker \
    volume \
    create \
    ${volume_run}
docker \
    volume \
    create \
    ${volume_var}

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
    --restart ${restart} \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \
    ${cmd} \

```
```
dbname=postgres
username=postgres
docker \
    container \
    exec \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \

```
```
dbname=postgres
username=postgres
docker \
    container \
    exec \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    psql \
    --dbname ${dbname} \
    --username ${username} \

```
```
command='\l'
docker \
    container \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \
    
```
