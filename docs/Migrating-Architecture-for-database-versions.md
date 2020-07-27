All work is to be done on the migration machine. These instructions will go through restoring the database to DynamoDB, setting up the development transactor and to change the production transactors to point to the new DynamoDB table.

First, ensure you've set your [aws credentials][1].

## Create new DynamoDB table
From Datomic pro
```bash
bin/datomic create-dynamodb-system \
    --region us-east-1 \
    --table-name WS255 \
    --read-capacity 300 \
    --write-capacity 1500
```

## Create transactor



# Restore table to DynamoDB table
Change aws-dynamodb-table=<tablename> in wb-cf-ensure.json 

bin/datomic -Xmx10g -Xms10g restore-db --from-backup-uri file:///wormbase/datomic-db-backup/2016-08-15/WS255/ --to-db-uri datomic:ddb://us-east-1/WS255/wormbase

## Rolling update the production transactors
```bash
alias cf="aws cloudformation"
cf update-stack --stack-name WBTransactor --template-body "$(cat wb-cf-ensure.template.json)"
```bash

[1]: ./AWS-Credentials.md