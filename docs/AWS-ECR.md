# AWS ECR 

ECR = Elastic Container Repository - a sub-service of Elastic Container Service (ECS)

We use ECR to store docker images. 
Images are stored in a private repository, because we are using datomic-pro (proprietary). 

The commands here are based on and closely follow the [official getting started guide][1]
First, ensure you've setup [aws credentials][2].

## Creating an image repository

```bash
REPO_NAME="wormbase/datomic-to-catalyst" # for example
aws ecr create-repository --repository-name ${REPO_NAME}
```
Example output:
```
{
    "repository": {
        "repositoryUri": "357210185381.dkr.ecr.us-east-1.amazonaws.com/<repo-name>",
        "registryId": "357210185381",
        "repositoryName": "<repo-name>",
        "repositoryArn": "arn:aws:ecr:us-east-1:357210185381:repository/<repo-name>"
    }
}
```

## Generating the `docker login` command
To get a password to authenticate to ECR:
```bash
aws ecr get-login-password
```
This will print out the password to be used with the `docker login` command for connecting your local docker daemon to ECS

Run the following command to authenticate with ECR (example):
```
docker login -u AWS -p $BASE64_CREDENTIALS https://<your-account>.dkr.ecr.us-east-1.amazonaws.com
```

## Tagging the image
```bash
WB_AWS_ACCOUNT_NUM=
VERSION=$(git describe)  # or use "latest" if you're sure you want that.
docker tag \
    wormbase/datomic-to-catalyst:${VERSION}
    ${WB_AWS_ACCOUNT_NUM}.dkr.ecr.us-east-1.amazonaws.com/wormbase/datomic-to-catalyst:${VERSION}
```
## Pushing the image
```bash
docker push ${WB_AWS_ACCOUNT_NUM}.dkr.ecr.us-east-1.amazonaws.com/wormbase/datomic-to-catalyst:${VERSION}
```
## Listing images
```bash
aws ecr list-images --repository-name wormbase/datomic-to-catalyst
```

## Pulling the image
```bash
docker pull ${WB_AWS_ACCOUNT_NUM}.dkr.ecr.us-east-1.amazonaws.com/wormbase/datomic-to-catalyst:${VERSION}
```

## Allowing EB instance access to ECR

To do this you will need to add policy `AmazonEC2ContainerRegistryReadOnly` to the `aws-elasticbeanstalk-ec2-role`


[1]: http://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_GetStarted.html
[2]: ./AWS-Credentials.md