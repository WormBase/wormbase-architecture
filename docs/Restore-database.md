## Download db

Example:
```bash
aws s3 cp s3://wormbase/db-migration/WS271.tar.xz WS271.tar.xz
tar -xf WS271.tar.xz
```
## restore main db

```bash
cd /usr/local/src/datomic-pro/datomic-pro-0.9.5703
bin/datomic restore-db --from-backup-uri file:///mnt/datomic-backup/WS271.tar.xz/ --to-db-uri datomic:ddb://us-east-1/WS271/wormbase
```

## restore homol db
```bash
aws s3 cp s3://wormbase/db-migration/homology-db.tar.xz homology-db.tar.xz
tar -xf homology-db.tar.xz
cd /usr/local/src/datomic-pro/datomic-pro-0.9.5703
bin/datomic restore-db --from-backup-uri file:///home/awright/homology-db.tar.xz/ --to-db-uri datomic:ddb://us-east-1/WS271/wormbase-homol

### rsync (example)
rsync -zarch WS273 wb-dating:/homw/awright
```