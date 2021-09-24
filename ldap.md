```

PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword
network=postgres
```
```
cmd=/bin/bash
container=postgres
image_repository=academiaonline/postgres
mount_data=/var/lib/postgresql/data
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
user=postgres
volume_data=postgres_data
volume_run=postgres_run
volume_var=postgres_var
```
```
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
    ${image_repository} \

while true
    do
        sleep 3
        docker container ls | grep Up.*${container} && break
    done

```
```
cmd=/bin/bash
container=openldap
image_repository=bitnami/openldap
mount_data=/bitnami/openldap/data
mount_lapd=/bitnami/openldap/slapd.d
mount_run=/opt/bitnami/openldap/var/run
mount_var=/opt/bitnami/openldap/share
volume_data=openldap_data
volume_lapd=openldap_lapd
volume_run=openldap_run
volume_var=openldap_var
volume_lapd=openldap_lapd

docker \
    volume \
    create \
    ${volume_data}

docker \
    volume \
    create \
    ${volume_ldap}

docker \
    volume \
    create \
    ${volume_run}

docker \
    volume \
    create \
    ${volume_var}

docker \
    container \
    run \
    --detach \
    --name ${container} \
    --network ${network} \
    --restart always \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_data}:${mount_lapd} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image_repository} \

while true
    do
        sleep 3
        docker container ls | grep Up.*${container} && break
    done

```
