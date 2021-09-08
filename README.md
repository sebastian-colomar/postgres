# postgres
```

PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

container=postgres
image=library/postgres:12.8-buster@sha256:26402c048be52bdd109b55b2df66bd73ae59487ebfc209959464c4e40698375b
mount_data=/var/lib/postgresql/data
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
network=postgres
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
    --restart always \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

cmd='apt-get update'
docker \
    container \
    exec \
    --tty \
    --user root \
    ${container} \
    ${cmd} \

cmd='apt-get install -y procps net-tools vim'
docker \
    container \
    exec \
    --tty \
    --user root \
    ${container} \
    ${cmd} \

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
