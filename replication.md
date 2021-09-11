```
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

container_master=pg-master
container_slave=pg-slave
dbname=postgres
image=academiaonline/postgres:latest
mount_data=/var/lib/postgresql/data
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
network=replication
user=postgres
username=postgres
user_replication=replicator

volume_data=${container_master}_data
volume_run=${container_master}_run
volume_var=${container_master}_var

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
    --name ${container_master} \
    --network ${network} \
    --read-only \
    --restart always \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

volume_data=${container_slave}_data
volume_run=${container_slave}_run
volume_var=${container_slave}_var

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

```
EXECUTE TERMINAL INSIDE MASTER
```
cmd=/bin/bash
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env mount_data=${mount_data} \
    --env username=${username} \
    --env user_replication=${user_replication} \
    --interactive \
    --tty \
    --user ${user} \
    ${container_master} \
    ${cmd} \

```
CREATE SAMPLE TABLE AND CONFIGURE REPLICATION
```
command="CREATE TABLE guestbook (visitor_email text, visitor_id serial, date timestamp, message text);"
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
    ${user_replication} \
    --replication \
    --username ${username} \

file=pg_hba.conf
echo "host replication ${user_replication} samenet trust" | tee --append ${PGDATA}/${file}

exit
```
RUN TERMINAL TO MODIFY SLAVE FILESYSTEM
```
docker \
    container \
    restart \
    ${container_master} \

entrypoint=/bin/bash
docker \
    container \
    run \
    --env PGDATA=${PGDATA} \
    --env container_master=${container_master} \
    --env user_replication=${user_replication} \
    --entrypoint ${entrypoint} \
    --interactive \
    --network ${network} \
    --read-only \
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
    --host ${container_master} \
    --pgdata ${PGDATA} \
    --progress \
    --username ${user_replication} \
    --verbose \
    --wal-method stream \

exit
```
RUN TERMINAL TO MODIFY SLAVE FILESYSTEM
```
debian_image=library/debian:stable-slim@sha256:a7cb457754b303da3e1633601c77636a0e05e6c26831d1f58c0e6b280f3f7c88
docker \
    container \
    run \
    --env PGDATA=${PGDATA} \
    --env container_master=${container_master} \
    --env user_replication=${user_replication} \
    --entrypoint ${entrypoint} \
    --interactive \
    --network ${network} \
    --read-only \
    --rm \
    --tty \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${debian_image} \

```
CONFIGURE STREAMING REPLICATION IN SLAVE
```
file=postgresql.conf
echo "primary_conninfo = 'host=${container_master} port=5432 user=${user_replication}'" | tee --append ${PGDATA}/${file}
touch ${PGDATA}/standby.signal

exit
```
START SLAVE
```
docker \
    container \
    run \
    --detach \
    --env PGDATA=${PGDATA} \
    --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    --name ${container_slave} \
    --network ${network} \
    --read-only \
    --restart always \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \
    
```
EXECUTE TERMINAL IN SLAVE
```
cmd=/bin/bash
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container_slave} \
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
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container_master} \
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
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container_slave} \
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
docker \
    container \
    exec \
    --env PGDATA=${PGDATA} \
    --interactive \
    --tty \
    --user ${user} \
    ${container_master} \
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
    ${container_master} \

```
EXECUTE TERMINAL IN MASTER
```
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container_master} \
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
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env username=${username} \
    --interactive \
    --tty \
    --user ${user} \
    ${container_slave} \
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
