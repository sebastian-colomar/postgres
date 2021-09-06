```
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_PASSWORD=mysecretpassword

cmd='-c shared_buffers=256MB -c max_connections=200'
image=library/postgres:latest
mount_data=/var/lib/postgresql
mount_run=/run/postgresql
network=postgres
restart=always
user=postgres

docker \
    network \
    create \
    ${network}

container=pg-master
volume_data=pg-master_data
volume_run=pg-master_run

docker \
    volume \
    create \
    ${volume_data}
docker \
    volume \
    create \
    ${volume_run}

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
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_data}:${mount_data} \
    ${image} \
    ${cmd}

command="CREATE TABLE guestbook (visitor_email text, vistor_id serial, date timestamp, message text);"
container=pg-master
dbname=postgres
user=postgres
username=postgres
docker \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username} \

command="INSERT INTO guestbook (visitor_email, date, message) VALUES ( 'jim@gmail.com', current_date, 'This is a test.');"
container=pg-master
dbname=postgres
user=postgres
username=postgres
docker \
    exec \
    --user ${user} \
    ${container} \
    psql \
    --command "${command}" \
    --dbname ${dbname} \
    --username ${username}

container=pg-master
user=postgres
username=postgres
docker \
    exec \
    --user ${user} \
    ${container} \
    createuser \
    repuser \
    --connection-limit 5 \
    --replication \
    --username ${username}

container=pg-master
dir=archivedir
user=postgres
docker \
    exec \
    --user ${user} \
    ${container} \
    mkdir \
    ${mount_data}/${dir}

container=pg-master
file=pg_hba.conf
docker \
    cp \
    ${container}:${PGDATA}/${file} \
    ${file} \

echo "host replication repuser pg-slave trust" | tee --append ${file}
docker \
    cp \
    ${file} \
    ${container}:${PGDATA}/${file} \

container=pg-master
file=postgresql.conf
docker \
    cp \
    ${container}:${PGDATA}/${file} \
    ${file} \

echo "archive_mode = on" | tee --append ${file}
echo "archive_command = 'test ! -f /${dir}/%f && cp %p /${dir}/%f'" | tee --append ${file}
docker \
    cp \
    ${file} \
    ${container}:${PGDATA}/${file} \

docker \
    container \
    restart \
    ${container}

cmd='-c shared_buffers=256MB -c max_connections=200'
container=pg-slave
restart=always
volume_data=pg-slave_data
volume_run=pg-slave_run

docker \
    volume \
    create \
    ${volume}
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
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_data}:${mount_data} \
    ${image} \
    ${cmd}

cmd="-rf ${PGDATA}"
container=pg-rm
entrypoint=rm
restart=no
volume_data=pg-slave_data
volume_run=pg-slave_run

docker \
    container \
    run \
    --detach \
    --entrypoint ${entrypoint} \
    --env PGDATA=${PGDATA} \
    --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    --name ${container} \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --tty \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_data}:${mount_data} \
    ${image} \
    ${cmd}

cmd="--host pg-master --pgdata ${PGDATA} --progress --username repuser --verbose --wal-method stream"
container=pg-basebackup
entrypoint=pg_basebackup
restart=no
volume_data=pg-slave_data
volume_run=pg-slave_run

docker \
    container \
    run \
    --entrypoint ${entrypoint} \
    --env PGDATA=${PGDATA} \
    --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    --interactive \
    --name ${container} \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --tty \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_data}:${mount_data} \
    ${image} \
    ${cmd}

container=pg-slave
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

cmd="${PGDATA}/standby.signal"
container=pg-slave
entrypoint=touch
restart=no
volume_data=pg-slave_data
volume_run=pg-slave_run

docker \
    container \
    run \
    --detach \
    --entrypoint ${entrypoint} \
    --env PGDATA=${PGDATA} \
    --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    --interactive \
    --name ${container} \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --tty \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_data}:${mount_data} \
    ${image} \
    ${cmd}

cmd='-c shared_buffers=256MB -c max_connections=200'
container=pg-slave
restart=always
volume_data=pg-slave_data
volume_run=pg-slave_run

docker \
    container \
    run \
    --detach \
    --env PGDATA=${PGDATA} \
    --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    --interactive \
    --name ${container} \
    --network ${network} \
    --read-only \
    --restart ${restart} \
    --tty \
    --volume ${volume_run}:${mount_run} \
    --volume ${volume_data}:${mount_data} \
    ${image} \
    ${cmd}
```
