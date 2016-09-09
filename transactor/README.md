# Datomic Transactor (AWS CloudFormation Stack)

The transactor is configured using an AWS CloudFormation template,
which was initially generating using the datomic "Appliance" AMI,
using instructions from the [Datomic [AWS docs][1].

The _transactor_ folder contains all required files.

The Datomic transactor will run within the WormBase VPC; It's
important to note that all relevant resources (Security Group(s),
Subnet and Availablility Zones) should be configured appropriately.

The CloudFormation configuration used by this transactor setup is
based upon the JSON template using the Datomic tools, but changed to
accommodate the following features:

  * Specification of a VPC
  * Ability to update an existing stack (cfn-init,cfn-hup and
    cfn-signal commands from `CloudFormation:Init`)

Please note the following: #5

## Usage

### CloudFormation stack operations for managing the datomic transactor
The stack was created the _very first_ time using the datomic tools'
_create-cf-stack_ command.

Assuming this repository is checked-out to the home directory of the
current user.

In the examples below:

  * `$PROFILE` should be the name of the profile you've previously
configured AWS credentials with the AWS CLI (via `aws configure`)

  * `$WS_RELEASE` should be the name of the data release (and DynamoDB
    table) that you wish to use.

  * `$DESIRED_CAPACITY` should be the number of transactors desired to
    be in service (Currently this is permitted to be 1 or 2).

#### Creating a new datomic transactor CloudFormation stack

First, setup an alias to the command (or add to `$PATH`):
```bash
alias cf-transactors="$HOME/git/wormbase-architecture/transactor/bin/cf-transactors"
```

```bash
cf-transactors "${PROFILE}" create "${WS_RELEASE}" "${DESIRED_CAPACITY}"
```

#### Updating an existing datomic transactor CloudFormation stack

```bash
cf-transactors "${PROFILE}" update "${WS_RELEASE}" "${DESIRED_CAPACITY}"
```

### Tagging
[WormBase AWS policy](https://docs.google.com/document/d/1ZhvyvQcNxNJlpyxXv9MuL_wONNWwRAhwTHqHDFWWgJ0/edit?ts=56a7c5a2#heading=h.fjmgla6sk2ww) requires
specification of tags for resources.

The `cf-transactors` script ensures that the CloudFormation JSON
template contains the appropriate tags as specified.

## IAM roles for the datomic transactor

### AWS CLI usage
In the alias below, `$USER` should be the profile name you used to
configure the AWS Command Line Interface (i.e the profile you supplied
when running `aws configure`) This just ensures usage of the correct
credentials when interacting with AWS.

```bash
alias wb-aws="aws --profile=$USER"
```

The following commands define the various IAM role and policy statements
required for the transactor and peers to interact.

_*These commands are only run to set up a brand new transactor
configuration in IAM for the first time, and such do not need to be
run as part of any WormBase release.*_

### Datomic peer configuration

```bash
AR_POLICY_PATH="$(pwd)/roles/assume-role-policy.json"
wb-aws iam create-role \
    --role-name datomic-aws-peer \
     --assume-role-policy-document="file://${AR_POLICY_PATH}"

PEER_POLICY_PATH="$(pwd)/roles/wormbase-peer.json"
wb-aws iam put-role-policy \
    --role-name datomic-aws-peer \
    --policy-name wormbase-peer \
    --policy-document=file://$(pwd)/roles/wormbase-peer.json
```

### Datomic transactors

```bash
wb-aws iam create-role \
    --role-name datomic-aws-transactor
    --assume-role-policy-document="${AR_POLICY_PATH}"

wb-aws iam put-role-policy --role-name datomic-aws-transactor \
    --policy-name wormbase-transactor \
    --policy-document=file://./roles/wormbase-transactor.json
```

### Creation of an EC2 Security Group
```bash
wb-aws ec2 create-security-group \
    --group-name datomic \
    --description "SG for Datomic transactor" \
    --vpc-id vpc-8e0087e9
```

## References
- https://groups.google.com/forum/#!topic/datomic/5N4XZp4SSwM
- http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html

[1]: http://docs.datomic.com/aws.html
