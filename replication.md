ON BOTH MASTER AND SLAVE INSTANCES
```
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

cmd=/bin/bash
dbname=postgres
entrypoint=/bin/bash
host=10.168.2.100
image=academiaonline/postgres:latest
mount_data=/var/lib/postgresql/data
mount_run=/run/postgresql
mount_var=/var/lib/postgresql
network=replication
port=5432
protocol=tcp
samenet=10.168.2.0/24
user=postgres
username=postgres
user_replication=replicator
```
ON THE MASTER INSTANCE:
```
container=pg-master
volume_data=${container}_data
volume_run=${container}_run
volume_var=${container}_var

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
    --publish ${port}:${port}/${protocol} \
    --read-only \
    --restart always \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

```
```
docker \
    container \
    exec \
    --env dbname=${dbname} \
    --env mount_data=${mount_data} \
    --env samenet=${samenet} \
    --env username=${username} \
    --env user_replication=${user_replication} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
```
command="CREATE TABLE guestbook (visitor_email text, visitor_id serial, date timestamp, message text);"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

command="INSERT INTO guestbook (visitor_email, date, message) VALUES ( 'jim@gmail.com', current_date, 'Test 1.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

createuser \
    ${user_replication} \
    --replication \
    --username ${username} \

file=pg_hba.conf
echo "host replication ${user_replication} ${samenet} trust" | tee --append ${PGDATA}/${file}

exit
```
```
docker \
    container \
    restart \
    ${container} \

```
ON THE SLAVE INSTANCE:
```
container=pg-slave
volume_data=${container}_data
volume_run=${container}_run
volume_var=${container}_var

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

```
```
docker \
    container \
    run \
    --env PGDATA=${PGDATA} \
    --env host=${host} \
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
```
pg_basebackup \
    --host ${host} \
    --pgdata ${PGDATA} \
    --progress \
    --username ${user_replication} \
    --verbose \
    --wal-method stream \

exit
```
```
debian_image=library/debian:stable-slim@sha256:a7cb457754b303da3e1633601c77636a0e05e6c26831d1f58c0e6b280f3f7c88
docker \
    container \
    run \
    --env PGDATA=${PGDATA} \
    --env host=${host} \
    --env port=${port} \
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
```
file=postgresql.conf
echo "primary_conninfo = 'host=${host} port=${port} user=${user_replication}'" | tee --append ${PGDATA}/${file}
touch ${PGDATA}/standby.signal

exit
```
```
docker \
    container \
    run \
    --detach \
    --env PGDATA=${PGDATA} \
    --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    --name ${container} \
    --network ${network} \
    --publish ${port}:${port}/${protocol} \
    --read-only \
    --restart always \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

```
```
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
```
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
ON THE MASTER INSTANCE:
```
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
```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Test 2.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
ON THE SLAVE INSTANCE:
```
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
```
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
ON THE MASTER INSTANCE:
```
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
```
touch ${PGDATA}/standby.signal

exit
```
```
docker \
    container \
    restart \
    ${container} \

```
```
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
```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Test 3.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
ON THE SLAVE INSTANCE:
```
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
```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Test 4.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
```
pg_ctl promote
```
```
command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Test 5.');"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
```
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
ON THE MASTER INSTANCE:
```
debian_image=library/debian:stable-slim@sha256:a7cb457754b303da3e1633601c77636a0e05e6c26831d1f58c0e6b280f3f7c88
host=10.168.2.210
docker \
    container \
    run \
    --env PGDATA=${PGDATA} \
    --env host=${host} \
    --env port=${port} \
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
```
file=postgresql.conf
echo "primary_conninfo = 'host=${host} port=${port} user=${user_replication}'" | tee --append ${PGDATA}/${file}
touch ${PGDATA}/standby.signal

exit
```
```
docker \
    container \
    restart \
    ${container} \

```
```
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
```
command="SELECT * FROM guestbook;"
psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

exit
```
CLEAN UP
```
docker container rm --force $( docker container ls --all --quiet )
docker network rm $( docker network ls --quiet )
docker volume rm $( docker volume ls --quiet )
```
