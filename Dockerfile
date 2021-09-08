FROM    library/postgres:12.8-buster@sha256:26402c048be52bdd109b55b2df66bd73ae59487ebfc209959464c4e40698375b
RUN     apt-get update && apt-get install -y net-tools procps sysstat vim
VOLUME  /run/postgresql /var/lib/postgresql /var/lib/postgresql/data
