# Datomic Transactors (AWS CloudFormation Stack)

## Pre-requisites
Ensure you have configured your AWS environment; typically by ensuring
the following environment variables are set:

   * AWS_PROFILE / AWS_DEFAULT_PROFILE
   * AWS_ACCESS_KEY
   * AWS_SECRET_ACCESS_KEY
   * AWS_DEFAULT_REGION

Transactors are configured using an AWS CloudFormation template,
which was initially generating using the datomic "Appliance" AMI,
using instructions from the Datomic [AWS docs][1].

This _transactor_ folder contains all required files.

The Datomic transactors will run within the WormBase VPC; It is
important to note that all relevant resources (Security Group(s),
Subnet and Availability Zones) should be configured appropriately.

The CloudFormation configuration used by this transactor setup is
based upon the JSON template using the Datomic tools, but changed to
accommodate the following features:

  * Specification of a VPC
  * Ability to update an existing stack (cfn-init,cfn-hup and
    cfn-signal commands from `CloudFormation:Init`)


## Installation

Install with Python3, by [installing pip] and `virtualenv`
if not already installed, then issue the following command to create a
virtualenv:

```bash
virtualenv -p python3 wb-cf-transactors
```

Activate the virtualenv:

```bash
source wb-cf-transactors/bin/activate
```

In the same directory as this file you're reading:

```
cd transactors
pip install -r requirements.txt
```

## Usage

The following assumes you've installed the transactors virtualenv as described [above](#Installation),
and you're still in the same working directory (the _transactor_ dir).

Ensure to activate the virtualenv before using:

```bash
source wb-cf-transactors/bin/activate
```

### CF Manage script

The following python script is used to manage the CloudFormation datomic transactors stack:

```bash
python bin/manage
```
This script provides an easy-to-use CLI interface to manage the CF stacks,
and runs some additional checks, like URL validation, before applying changes to prevent issues
further down the line (things that would not be done when applying changes through the AWS console).

Running the `manage` script with the `--help` argument, directly after the scriptname
 or after a sub-command, will describe the available options and any required arguments
 of the script or sub-command.

This script expects a sub-command, followed by more positional and optional arguments.

Transactors may be managed for more than one project.
(Currently web production and the "names" projects).

Each project should have its own settings file in the `./config` directory,
detailing specific instance type and datomic memory requirements.

#### `Create` subcommand example usage
The create subcommand will use `config/wb-datomic-tx-cf-template.yml` as default CF template file
(configurable through the `--cf-template-path` option), apply the provided *STACK_PARAM_FILE*
as CF parameters and deploy the complete stack as *CF_STACK_NAME* to cloudformation.

##### Main WormBase Migration DB

```bash
DDB_TABLE="WS277"
CF_STACK_NAME="WBTransactorWS277"
DATOMIC_VERSION="0.9.5703"
DESIRED_CAPACITY=1
STACK_PARAM_FILE="config/web-prod-params.json"

bin/manage $STACK_PARAM_FILE $CF_STACK_NAME \
           create  \
           --desired-capacity $DESIRED_CAPACITY \
           $DDB_TABLE \
           $DATOMIC_VERSION
```

##### Names DB (test env)

```bash
DDB_TABLE="WSNames-test-14"
CF_STACK_NAME="WBNamesTestTransactor"
DATOMIC_VERSION="1.0.6165"
DESIRED_CAPACITY=2  #Use 2 for failover
STACK_PARAM_FILE="config/name-server-params.json"
INSTALL_DEPS_URL="https://raw.githubusercontent.com/WormBase/names/master/scripts/install_transactor_deps.sh"
EXT_CLASSPATH_URL="https://raw.githubusercontent.com/WormBase/names/master/scripts/build_datomic_ext_classpath.sh"

bin/manage $STACK_PARAM_FILE $CF_STACK_NAME create \
           --desired-capacity $DESIRED_CAPACITY \
           $DDB_TABLE \
           $DATOMIC_VERSION
```

### AWS CLI usage

#### Viewing the status of the current transactor stack
This can be done via the AWS web console at the [CloudFormation Console][AWS CF Console].

or using the CLI:

```bash
aws cloudformation describe-stacks --stack-name $CF_STACK_NAME
```


### Tagging
[WormBase AWS policy](https://docs.google.com/document/d/1ZhvyvQcNxNJlpyxXv9MuL_wONNWwRAhwTHqHDFWWgJ0/edit?ts=56a7c5a2#heading=h.fjmgla6sk2ww) requires specification of tags for resources.

The `manage` script ensures that the CloudFormation stack gets the appropriate tags assigned as specified.


## Update deployment
There's two common strategies to update a CloudFormation stack:
 * Update the stack by creating and applying a change set.  
     This is the preferred option for most updates, as it allows a review of the changes made
     before applying them to the live stack.
    * Rolling updates (without config changes) can be done through the console
    * Any update involving template or parameter changes should be done through the `update` subcommand
      of the [CF manage](#CF-Manage-script) script.
      This allows for traceable template and parameter changes through code versioning in this repo.
 * Delete and recreate the stack
     This can be usefull when trying to fix unexplained issues with the current stack,
     or when doing bigger, more structural changes and CF template updates. However,
     this is not the preferred method, as it is less traceable.

### Rolling updates (console)
Rolling updates are done using change sets through the CF Console:
 1. Go to the [CloudFormation Console][AWS CF Console] and click the stack name matching the stack to update.
 2. Click Stack actions and then choose **Create change set for current stack**.
 3. On the next page, select **Use current template** and continue with **next**.
 4. Flip **Toggle** to force a rolling update without parameter changes.
 5. On the next page, leave the configurations be and click **next** to proceed.
 6. Review the presented summary and click **Create change set**
 7. Provide a description describing why the update is being made and click **Create change set**
 8. Wait for the Change set to get a status **CREATE_COMPLETE** (refresh the Overview pane in the console)
 9. Review the Changes presented at the bottom of the page and after approving, click **Execute** to apply them.

### Template/parameter updates (cli update)
For CF stack updates that require template or parameter changes,
using `update` subcommand of the [CF manage](#CF-Manage-script) script is the preferred option,
as it ensures proper tagging, URL validation and enables a semi-automatic, interactive update process,
in which the effect of deploying the updates can be assessed before updating the live stack.


For a full overview of all input arguments of the `bin/manage update` script:
```bash
python bin/manage --profile <profile-name> update --help
```

Updating a stack using this command is quite straightforward:
 1. Update any CF template files, parameter files, or transactor scripts as needed.
 2. Run the `bin/manage update` script with all required arguments.
    Make sure to provide a description about why the updates are being made (using the `--descr` argument).
 3. Inspect the reported changes to be applied.
 4. Confirm whether or not to apply the reported changes to the stack (`y/n` input),
    and whether to cleanup the change-set if not.

### Delete and replace
For larger CF config updates, using the [CF manage](#CF-Manage-script) script is the preferred option.
Activate the python virtual environment as described [above](#Usage) and then do the following steps:

 1. Delete the stack.
    ```bash
    python bin/manage $STACK_PARAM_FILE $CF_STACK_NAME delete
    ```

 2. Update any CF template files, parameter files, or transactor scripts as needed.

 3. Wait until the CF stack deletion completed.
    ```bash
    watch -n 5 "python bin/manage $STACK_PARAM_FILE $CF_STACK_NAME status"
    ```

 4. (Re)create the stack.
    ```bash
    python bin/manage $STACK_PARAM_FILE $CF_STACK_NAME create \
        [--datomic-transactor-deps-script $INSTALL_DEPS_URL \
        --datomic-ext-classpath-script $EXT_CLASSPATH_URL] \
        --desired-capacity $DESIRED_CAPACITY $DDB_TABLE $DATOMIC_VERSION
    ```


## Initial datomic transactor security and permissions setup
The following subchapters define the various IAM roles, policy statements
and security groups required for the transactor and peers to interact.

_These commands are only run to set up a brand new transactor
configuration from scratch (IAM roles, policies and security groups),
and as such do not need to be run as part of any standard WormBase release._

### IAM configuration (roles)

#### Peer

```bash
AR_POLICY_PATH="$(pwd)/roles/assume-role-policy.json"
aws iam create-role \
    --role-name datomic-aws-peer \
     --assume-role-policy-document="file://${AR_POLICY_PATH}"

PEER_POLICY_PATH="$(pwd)/roles/wormbase-peer.json"
aws iam put-role-policy \
    --role-name datomic-aws-peer \
    --policy-name wormbase-peer \
    --policy-document=file://$(pwd)/roles/wormbase-peer.json
```

#### Transactor

```bash
aws iam create-role \
    --role-name datomic-aws-transactor
    --assume-role-policy-document="${AR_POLICY_PATH}"

aws iam put-role-policy --role-name datomic-aws-transactor \
    --policy-name wormbase-transactor \
    --policy-document=file://$(pwd)/roles/wormbase-transactor.json
```

### EC2 Security group
```bash
aws ec2 create-security-group \
    --group-name datomic \
    --description "SG for Datomic transactor" \
    --vpc-id vpc-8e0087e9
```

## References
- https://groups.google.com/forum/#!topic/datomic/5N4XZp4SSwM
- http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html

[1]: https://docs.datomic.com/on-prem/aws.html
[installing pip]: https://packaging.python.org/installing/#requirements-for-installing-packages
[AWS Credentials]: ../docs/AWS-Credentials.md
[AWS CF Console]: https://console.aws.amazon.com/cloudformation
