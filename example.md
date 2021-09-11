```

PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

container=postgres
image_repository=academiaonline/postgres
image_tag=:12.8-buster
image_digest=@sha256:26402c048be52bdd109b55b2df66bd73ae59487ebfc209959464c4e40698375b
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
network=postgres
sleep=3
user=postgres
volume_run=postgres_run
volume_var=postgres_var

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
    --read-only \
    --restart always \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image_repository}${image_tag}${image_digest} \

while true
    do
        sleep ${sleep}
        docker container ls | grep Up.*${container} && break
    done

cmd='/bin/bash'
docker \
    container \
    exec \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
```
command='\l'
dbname=postgres
username=postgres
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \
    
```
```
docker container rm --force $( docker container ls --all --quiet )
docker network rm $( docker network ls --quiet )
docker volume rm $( docker volume ls --quiet )

```
