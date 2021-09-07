```
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

dbname=postgres
container=pg-master
dir=archivedir
image=library/postgres:12.8-buster@sha256:26402c048be52bdd109b55b2df66bd73ae59487ebfc209959464c4e40698375b
mount_data=/var/lib/postgresql/data
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
network=postgres
restart=always
user=postgres
username=postgres
volume_data=pg-master_data
volume_run=pg-master_run
volume_var=pg-master_var

docker \
    network \
    create \
    ${network} \

docker \
    volume \
    create \
    ${volume_data} \

docker \
    volume \
    create \
    ${volume_run} \

docker \
    volume \
    create \
    ${volume_var} \

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
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

volume_data=pg-slave_data
volume_run=pg-slave_run
volume_var=pg-slave_var

docker \
    volume \
    create \
    ${volume_data} \

docker \
    volume \
    create \
    ${volume_run} \

docker \
    volume \
    create \
    ${volume_var} \

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
command="CREATE TABLE guestbook (visitor_email text, vistor_id serial, date timestamp, message text);"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

command="INSERT INTO guestbook (visitor_email, date, message) VALUES ( 'jim@gmail.com', current_date, 'This is a test.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

createuser \
    repuser \
    --connection-limit 5 \
    --replication \
    --username ${username} \

mkdir \
    ${mount_data}/${dir} \

file=pg_hba.conf
echo "host replication repuser samenet trust" | tee --append ${PGDATA}/${file}

```
```
docker \
    container \
    restart \
    ${container} \

entrypoint=/bin/bash
restart=no
docker \
    container \
    run \
    --entrypoint ${entrypoint} \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --rm \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

```
```
cmd="--host pg-master --pgdata ${PGDATA} --progress --username repuser --verbose --wal-method stream"
pg_basebackup \
    ${cmd} \

```
```
container=pg-alpine
image=library/alpine:latest
restart=no
docker \
    container \
    run \
    --entrypoint ${entrypoint} \
    --interactive \
    --name ${container} \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --tty \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

```
```
file=postgresql.conf
echo "primary_conninfo = 'host=pg-master port=5432 user=repuser'" | tee --append ${PGDATA}/${file}
touch ${PGDATA}/standby.signal

```
```
container=pg-slave
image=library/postgres:12.8-buster@sha256:26402c048be52bdd109b55b2df66bd73ae59487ebfc209959464c4e40698375b
restart=always
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
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \
    
```
```
cmd=/bin/bash
container=pg-slave
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
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
```
container=pg-master
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
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
```
container=pg-slave
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
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
```
container=pg-master
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
touch ${PGDATA}/standby.signal
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are AGAIN replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
```
container=pg-slave
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
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are AGAIN replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
