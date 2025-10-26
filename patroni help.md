# Patroni Help

### IMPORTANT NOTE
entrypoint.sh line ending must be LF to run in linux
(in vs code change CRLF to LF)

## list cluster status
```bash
/venv/bin/patronictl -c /venv/etc/patroni.yml list
```

### install curl on alpine
```bash
apk add curl
```

## check patroni status (Patroni Rest API):
```bash
curl http://localhost:8008
curl http://localhost:8008/patroni
curl http://localhost:8008/config
```

## connect to postgres by postgres user
```bash
psql -h localhost -U postgres -d postgres
```


# list databases
```bash
SELECT datname FROM pg_database;

SELECT table_schema, table_name FROM saatdb.tables
```


# check ports
```bash
netstat -ltnp | grep 5432
```

# check process
```bash
ps aux | grep patroni
ps aux | grep postgres
```

# restart patroni with cluster-name: pg-cluster
```bash
/venv/bin/patronictl restart pg-cluster
```

# pg_hba
path to pg_hba
```bash
psql -h localhost -U postgres -t -c "SHOW hba_file;"
cat $(psql -h localhost -U postgres -t -c "SHOW hba_file;")
```

update pg_hbd
```bash
/venv/bin/patronictl show-config pg-cluster
/venv/bin/patronictl edit-config pg-cluster
```


append:
```
pg_hba:
  - host replication replicator 172.18.0.0/16 md5
  - host all all 172.18.0.0/16 md5
  - host all all 127.0.0.1/32 md5
  - host all all ::1/128 md5
```

save and exit in vi

```
:wq
```


## run pg separately (ba ip vasl mishe 192.168.1.130)
```bash
docker run -d -it -p 5430:5432 -e "POSTGRES_USER=admin" -e "POSTGRES_PASSWORD=admin" --name pg postgres:17-alpine
```
## run pgadmin

```bash
docker run -d -it -p 3080:80 -e "PGADMIN_DEFAULT_EMAIL=admin@test.com" -e "PGADMIN_DEFAULT_PASSWORD=123456" --name pgadmin dpage/pgadmin4
```