```
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

container_master=pg-master
container_slave=pg-slave
dbname=postgres
debian_image=library/debian:stable-slim@sha256:a7cb457754b303da3e1633601c77636a0e05e6c26831d1f58c0e6b280f3f7c88
image=academiaonline/postgres:latest
mount_archive=/var/lib/postgresql/archive
mount_data=/var/lib/postgresql/data
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
network=replication
user=postgres
username=postgres
user_replication=replicator

volume_archive=postgresql_archive
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
    ${volume_archive} \

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
    --volume ${volume_archive}:${mount_archive} \
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
    --env mount_archive=${mount_archive} \
    --env mount_data=${mount_data} \
    --env username=${username} \
    --env user_replication=${user_replication} \
    --interactive \
    --tty \
    --user ${user} \
    ${container_master} \
    ${cmd} \

```
CREATE SAMPLE TABLE AND CONFIGURE REPLICATION AND WAL ARCHIVING
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
    ${user_replication} \
    --replication \
    --username ${username} \

file=pg_hba.conf
echo "host replication ${user_replication} samenet trust" | tee --append ${PGDATA}/${file}

file=postgresql.conf
echo "archive_command = 'test ! -f ${mount_archive}/%f && cp %p ${mount_archive}/%f'" | tee --append ${PGDATA}/${file}
echo "archive_mode = on" | tee --append ${PGDATA}/${file}
echo "archive_timeout = 100" | tee --append ${PGDATA}/${file}

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
echo "recovery_min_apply_delay = 10min" | tee --append ${PGDATA}/${file}
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
    --volume ${volume_archive}:${mount_archive} \
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

sleep 1000
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
INSERT A NEW ROW IN THE SAMPLE TABLE
```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are AGAIN replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

date
exit
```
TAKE NOTE OF THE DATE AND STOP THE SLAVE
```
docker \
    container \
    stop \
    ${container_slave} \

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
INSERT YET A NEW ROW IN THE SAMPLE TABLE
 ```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are AGAIN and AGAIN replicating.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
RUN TERMINAL TO MODIFY SLAVE FILESYSTEM
```
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
CONFIGURE RECOVERY MODE WITH THE DATE YOU TOOK NOTE BEFORE
```
file=postgresql.conf
echo "recovery_target_action = pause" | tee --append ${PGDATA}/${file}
echo "recovery_target_inclusive = false" | tee --append ${PGDATA}/${file}
echo "recovery_target_time = 'Thu Sep  9 02:19:15 UTC 2021'" | tee --append ${PGDATA}/${file}
echo "restore_command = 'cp ${mount_archive}/%f %p'" | tee --append ${PGDATA}/${file}

```
RESTART SLAVE
```
docker \
    container \
    restart \
    ${container_slave} \

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
VIEW SAMPLE TABLE TO CHECK PITR
```
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
STOP MASTER
```
docker \
    container \
    stop \
    ${container_master} \

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
RESUME RECOVERY AND PROMOTE SLAVE
```
command="SELECT pg_wal_replay_resume();"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

pg_ctl promote
exit
```
TO DO: CONFIGURE OLD MASTER TO LISTEN TO NEW MASTER

CLEAN UP
```
docker container rm --force $( docker container ls --all --quiet )
docker network rm $( docker network ls --quiet )
docker volume rm $( docker volume ls --quiet )
```
