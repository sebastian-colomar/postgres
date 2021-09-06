```
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

dbname=postgres
cmd='-c shared_buffers=256MB -c max_connections=200'
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
    ${cmd} \

```
```
command="CREATE TABLE guestbook (visitor_email text, vistor_id serial, date timestamp, message text);"
docker \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

command="INSERT INTO guestbook (visitor_email, date, message) VALUES ( 'jim@gmail.com', current_date, 'This is a test.');"
docker \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

docker \
    exec \
    --user ${user} \
    ${container} \
    createuser \
    repuser \
    --connection-limit 5 \
    --replication \
    --username ${username} \

docker \
    exec \
    --user ${user} \
    ${container} \
    mkdir \
    ${mount_data}/${dir} \

file=pg_hba.conf
docker \
    cp \
    ${container}:${PGDATA}/${file} \
    ${file} \

echo "host replication repuser samenet trust" | tee --append ${file}
docker \
    cp \
    ${file} \
    ${container}:${PGDATA}/${file} \

docker \
    container \
    restart \
    ${container} \

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

cmd="--host pg-master --pgdata ${PGDATA} --progress --username repuser --verbose --wal-method stream"
entrypoint=pg_basebackup
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
    ${cmd} \

container=pg-alpine
image=library/alpine:latest
restart=always
docker \
    container \
    run \
    --detach \
    --name ${container} \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --tty \
    --volume ${volume_data}:${mount_data} \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_var}:${mount_var} \
    ${image} \

file=postgresql.conf
docker \
    cp \
    ${container}:${PGDATA}/${file} \
    ${file} \

echo "primary_conninfo = 'host=pg-master port=5432 user=repuser'" | tee --append ${file}
docker \
    cp \
    ${file} \
    ${container}:${PGDATA}/${file} \

cmd="touch ${PGDATA}/standby.signal"
restart=no
docker \
    container \
    exec \
    ${container} \
    ${cmd} \

docker \
    container \
    stop \
    ${container} \

cmd='-c shared_buffers=256MB -c max_connections=200'
container=pg-slave
image=library/postgres:latest
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
    ${cmd} \
    
```
```
command="SELECT * FROM guestbook;"
container=pg-slave
docker \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

command="INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are replicating.');"
container=pg-master
docker \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

command="SELECT * FROM guestbook;"
container=pg-slave
docker \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

```
