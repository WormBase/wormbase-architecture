## Motivation
The WormBase datomic database uses DynamoDB, hosted on AWS.

For purposes such as testing (or simply when not wanting to incur AWS costs), 
it's possible to run the WormBase "WS\d+" release database (or any other datomic database) locally, using `DynamoDBLocal` 

## Setting up DynamoDB Local

After following the [official documentation][1], the DDB local server can be started with the following command (terminal):

```bash
cd /wormbase/dynamodb-local
java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb &
```
The will start the local DynamoDB service process in the background, and creates a single database file named shared-local-instance.db in your current working dir. Every program that connects to DynamoDBLocal accesses this file. If you delete or overwrite the file, you lose any data that you have stored in it.

The following commands are run to create the dynamodb table, which houses the datomic databases.

_**Note 1: Specifying the `--endpoint` parameter is key here, otherwise this command attempts to create the table in the real DynamoDB AWS service** (although, this should fail due to the use of non-valid credentials, see Note 2)_  
_**Note 2:**_ As an additional safety mechanism, use invalid credential values for the AWS envvars, to prevent accidental AWS interactions. Although DynamoDBLocal requires the variables to be set, they don't need to contain valid data, since all DynamoDB operations should happen locally.

```bash
# Set some bogus AWS credentials for use with local DDB service.
AWS_PROFILE=""
AWS_DEFAULT_REGION="us-east-1"
AWS_SECRET_ACCESS_KEY="blahadfgdgfwsgfdsdF"
AWS_ACCSES_KEY_ID="foobararalofsdfsdf"
AWS_SECRET_KEY=$AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY=$AWS_ACCESS_KEY_ID
MyDDBTableName="TableNameHere"
# note these credentials are fictitious, which is intentional

# Create a new empty DDB table (to be used as datomic storage)
aws dynamodb create-table \
    --table-name $MyDDBTableName \
    --attribute-definitions AttributeName=id,AttributeType="S" \
    --key-schema KeyType="HASH",AttributeName="id" \
    --endpoint http://localhost:8000 \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

Now we can download a copy of the WormBase database, and restore it into the local DDB storage with the usual datomic commands.

Assuming you have downloaded and extracted a version of datomic-pro to `$HOME/datomic-pro`.  
In a new terminal (define your *real* AWS credentials):

To download a copy of the wormbase DB (You'll need approx. 22 GB of space free for the wormbase DB):
For a copy from S3:
```bash
# Get a the version of the WormBase database for loading.
aws s3 cp s3://wormbase/db-migration/WS266.tar.xz /tmp/.
mkdir -p ~/datomic-db-backups
pushd ~/datomic-db-backups
tar xf /tmp/WS255.tar.xz .
popd
```
For a copy from a current AWS DynamoDB (example):
```bash
# Copy a current AWS DynamoDB database to a local file.
~/datomic-pro/bin/datomic backup-db "datomic:ddb://us-east-1/<DB-NAME>/<TABLE-NAME>" "file:///abspath/to/tmp/backup-dirname"
```

After download a local copy, restore it into the local DDB storage:
```bash
# Load local file into local DDB
~/datomic-pro/bin/datomic restore-db "file:///path/to/tmp/backup-dirname" "datomic:ddb-local://localhost:8000/<DB-NAME>/<TABLE-NAME>"
```

## Running a local datomic transactor with DynamoDB local
Alter the configuration file used to start the transactor (typically, a copy of `samples/config/ddb-transactor-template.properties` from a unpacked datomic-pro distribution).

The following variables are required to be set. The value of `aws-dynamodb-table` should match the name of the table you created with the `aws dynamodb create-table` command.  
**Note:** Setting the `aws-dynamodb-override-endpoint` is particularly important, otherwise datomic will look for and use a table of the same name in the AWS DynamoDB service.
 
```ini
protocol=ddb-local
aws-dynamodb-table=MyDDBTableName
aws-dynamodb-override-endpoint=localhost:8000
```
After defining the correct transactor properties file, start a local datomic transactor to the local DDB:
```bash
~/datomic-pro/bin/transactor local-ddb-transactor.properties &
```


## Working with Docker

When you've got an application running docker, 
it needs to communicate with both the transactor and storage back-end,
both of which are atypically set to run on the host.
In order to enable these processes to communicate together,
you'll need to:

  * Find out the address of the docker application container
  * Use this address when configuring the transactor and storage engine

To find out the address of your docker container, do:

```bash
# for "apline" based in images, only the "sh" shell is available
docker exec -i -t "${app-name-or-id}" /bin/sh
```

Once you have a prompt in the container, the following command will
display the container's IP address (instruction taken from the following [article][2]):

```bash
netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}'
```
Assuming the container address is for example `172.17.0.1`,
add or change the properties file used to start the transactor to contain:

```ini
protocol=ddb-local
host=172.17.0.1
aws-dynamodb-table=datomic-dbs
aws-dynamodb-override-endpoint=localhost:8000
```

When referencing the storage URI in application configuration,
you'll need to update it to use the Docker ip, for example,
in a `.ebextensions/.config` file, you'd need to specify:
```yaml
options_settings:
    option_name: DB_URI
    value: datomic:ddb-local://172.17.0.1:8000/datomic-dbs/my-db-name
```

[1]: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html
[2]: http://blog.michaelhamrah.com/2014/06/accessing-the-docker-host-server-within-a-container/
