```
cd
mkdir --parents ssl/ca
openssl req -new -nodes -text -out ssl/ca/root.csr -keyout ssl/ca/root.key -subj "/CN=root.yourdomain.com"
chmod og-rwx ssl/ca/root.key
openssl x509 -req -in ssl/ca/root.csr -text -days 3650 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -signkey ssl/ca/root.key -out ssl/ca/root.crt

mkdir --parents ssl/server
openssl req -new -nodes -text -out ssl/server/server.csr -keyout ssl/server/server.key -subj "/CN=dbhost.yourdomain.com"
chmod og-rwx ssl/server/server.key
openssl x509 -req -in ssl/server/server.csr -text -days 365 -CA ssl/ca/root.crt -CAkey ssl/ca/root.key -CAcreateserial -out ssl/server/server.crt
cat ssl/ca/root.srl >> ssl/ca/list.srl
openssl dhparam -out ssl/server/dhparams.pem 2048

mkdir --parents ssl/client
#openssl req -new -nodes -text -out ssl/client/testssl.csr -keyout ssl/client/testssl.key -subj "/CN=testssl"
openssl req -new -text -out ssl/client/testssl.csr -keyout ssl/client/testssl.key -subj "/CN=testssl"
chmod og-rwx ssl/client/testssl.key
openssl x509 -req -in ssl/client/testssl.csr -text -days 365 -CA ssl/ca/root.crt -CAkey ssl/ca/root.key -CAcreateserial -out ssl/client/testssl.crt

```
```
echo hostssl testssl         testssl         samenet                 cert    clientcert=verify-full | tee --append data/pgdata/pg_hba.conf
echo ssl = on | tee --append data/pgdata/postgresql.conf
ssl_ca_file = '/var/lib/postgresql/ssl/ca/root.crt' | tee --append data/pgdata/postgresql.conf
ssl_cert_file = '/var/lib/postgresql/ssl/server/server.crt' | tee --append data/pgdata/postgresql.conf
ssl_key_file = '/var/lib/postgresql/ssl/server/server.key' | tee --append data/pgdata/postgresql.conf
ssl_dh_params_file = '/var/lib/postgresql/ssl/server/dhparams.pem' | tee --append data/pgdata/postgresql.conf
```
```
createuser testssl -P
```
```
exit
docker restart postgres
docker container exec --interactive --tty --user postgres postgres /bin/bash
```
```
psql "host=postgres sslmode=require sslrootcert=ssl/ca/root.crt sslcert=ssl/client/testssl.crt sslkey=ssl/client/testssl.key port=5432 user=testssl dbname=postgres"

```
