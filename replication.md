```
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

container=pg-master
dbname=postgres
dir=archivedir
image=library/postgres:12.8-buster@sha256:26402c048be52bdd109b55b2df66bd73ae59487ebfc209959464c4e40698375b
mount_data=/var/lib/postgresql/data
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
network=replication
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

cmd='apt-get update'
docker \
    container \
    exec \
    ${container} \
    ${cmd} \

cmd='apt-get install -y procps net-tools vim'
docker \
    container \
    exec \
    ${container} \
    ${cmd} \

```
EXECUTE TERMINAL INSIDE MASTER
```
cmd=/bin/bash
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env dir=${dir} \
    --env mount_data=${mount_data} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
CREATE SAMPLE TABLE AND CONFIGURE REPLICATION
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

exit
```
RUN TERMINAL TO MODIFY SLAVE FILESYSTEM
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
    --env PGDATA=${PGDATA} \
    --entrypoint ${entrypoint} \
    --interactive \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --rm \
    --tty \
    --user ${user} \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

```
RUN BASE BACKUP
```
pg_basebackup \
    --host pg-master \
    --pgdata ${PGDATA} \
    --progress \
    --username repuser \
    --verbose \
    --wal-method stream \

exit
```
RUN TERMINAL TO MODIFY SLAVE FILESYSTEM
```
container=pg-alpine
image=library/debian:stable-slim@sha256:a7cb457754b303da3e1633601c77636a0e05e6c26831d1f58c0e6b280f3f7c88
restart=no
docker \
    container \
    run \
    --env PGDATA=${PGDATA} \
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
CONFIGURE STREAMING REPLICATION IN SLAVE
```
file=postgresql.conf
echo "primary_conninfo = 'host=pg-master port=5432 user=repuser'" | tee --append ${PGDATA}/${file}
touch ${PGDATA}/standby.signal

exit
```
START SLAVE
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
EXECUTE TERMINAL IN SLAVE
```
cmd=/bin/bash
container=pg-slave
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
VIEW SAMPLE TABLE
```
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
EXECUTE TERMINAL IN MASTER
```
container=pg-master
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
INSERT NEW SAMPLE ROW
```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
EXECUTE TERMINAL IN SLAVE
```
container=pg-slave
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
VIEW SAMPLE TABLE TO CHECK REPLICATION
```
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
EXECUTE TERMINAL IN MASTER
```
container=pg-master
docker \
    container \
    exec \
    --env PGDATA=${PGDATA} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
DEMOTE MASTER
```
touch ${PGDATA}/standby.signal

exit
```
RESTART MASTER
```
docker \
    container \
    restart \
    ${container} \

```
EXECUTE TERMINAL IN MASTER
```
container=pg-master
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
TRY TO WRITE IN DEMOTED MASTER
 ```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are AGAIN replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
EXECUTE TERMINAL IN SLAVE
```
container=pg-slave
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
TRY TO WRITE
```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are AGAIN replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
PROMOTE SLAVE
```
pg_ctl promote

```
TRY AGAIN TO WRITE
```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are AGAIN replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
VIEW SAMPLE TABLE TO CHECK NEW MASTER
```
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
TO DO: CONFIGURE OLD MASTER TO LISTEN TO NEW MASTER

CLEAN UP
```
docker container rm --force $( docker container ls --all --quiet )
docker network rm $( docker network ls --quiet )
docker volume rm $( docker volume ls --quiet )

```
