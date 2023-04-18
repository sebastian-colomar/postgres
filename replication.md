ON BOTH MASTER AND SLAVE INSTANCES
```
PGDATA=/var/lib/pgsql/data/userdata
POSTGRESQL_ADMIN_PASSWORD=xxx
POSTGRESQL_DATABASE=database
POSTGRESQL_MAX_CONNECTIONS=1200
POSTGRESQL_SHARED_BUFFERS=512MB
POSTGRESQL_USER=user
POSTGRESQL_PASSWORD=xxx

registry=registry.redhat.io

cmd=/bin/bash
dbname=postgres
entrypoint=/bin/bash
host_master=10.168.2.100
host_slave=10.168.2.200
image=${registry}/rhel9/postgresql-13:1-103
mount_data=/var/lib/pgsql/data
port=5432
protocol=tcp
samenet=10.168.2.0/24
user=postgres
username=postgres
replication_password=xxx
replication_user=postgres
volume_data=/postgres/DATA
```
ON THE MASTER INSTANCE:
```
container=pg-master

mkdir -p ${volume_data} && chmod 777 ${volume_data}

```
```
docker login ${registry}

docker \
    container \
    run \
    --detach \
    --env PGDATA=${PGDATA} \
    --env POSTGRESQL_ADMIN_PASSWORD=${POSTGRESQL_ADMIN_PASSWORD} \
    --env POSTGRESQL_DATABASE=${POSTGRESQL_DATABASE} \
    --env POSTGRESQL_MAX_CONNECTIONS=${POSTGRESQL_MAX_CONNECTIONS} \
    --env POSTGRESQL_SHARED_BUFFERS=${POSTGRESQL_SHARED_BUFFERS} \
    --env POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD} \
    --env POSTGRESQL_USER=${POSTGRESQL_USER} \
    --name ${container} \
    --publish ${port}:${port}/${protocol} \
    --restart always \
    --volume ${volume_data}:${mount_data} \
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

exit

```
ON THE SLAVE INSTANCE:
```
container=pg-slave
volume_start=/postgres/START

mkdir -p ${volume_data} && chmod 777 ${volume_data}
mkdir -p ${volume_start} && chmod 777 ${volume_start}

```
```
docker login ${registry}

docker \
    container \
    run \
    --env PGDATA=${PGDATA} \
    --env host_master=${host_master} \
    --env user_replication=${user_replication} \
    --entrypoint ${entrypoint} \
    --interactive \
    --rm \
    --tty \
    --user ${user} \
    --volume ${volume_data}:${mount_data} \
    ${image} \

```
```
pg_basebackup \
    --host ${host_master} \
    --pgdata ${PGDATA} \
    --progress \
    --username ${user_replication} \
    --verbose \
    --wal-method stream \

exit
```
```
docker \
    container \
    run \
    --env PGDATA=${PGDATA} \
    --env host_master=${host_master} \
    --env port=${port} \
    --env replication_password=${replication_password} \
    --env replication_user=${replication_user} \
    --entrypoint ${entrypoint} \
    --interactive \
    --rm \
    --tty \
    --volume ${volume_data}:${mount_data} \
    ${image} \

```
```
file=postgresql.conf
echo "primary_conninfo = 'host=${host_master} password=${replication_password} port=${port} user=${replication_user}'" | tee --append ${PGDATA}/${file}
touch ${PGDATA}/standby.signal

exit
```
```
docker \
    container \
    run \
    --detach \
    --env PGDATA=${PGDATA} \
    --env POSTGRESQL_ADMIN_PASSWORD=${POSTGRESQL_ADMIN_PASSWORD} \
    --name ${container} \
    --publish ${port}:${port}/${protocol} \
    --restart always \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_start}:${volume_start} \
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
docker \
    container \
    exec \
    --env PGDATA=${PGDATA} \
    --env host_slave=${host_slave} \
    --env port=${port} \
    --env replication_user=${replication_user} \
    --interactive \
    --tty \
    --user ${user} \
    ${container} \
    ${cmd} \

```
```
file=postgresql.conf
echo "primary_conninfo = 'host=${host_slave} password=${replication_password} port=${port} user=${replication_user}'" | tee --append ${PGDATA}/${file}
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
rm -rf ${volume_data}
```
