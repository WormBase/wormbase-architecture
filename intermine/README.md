#intermine release tool

This tool allows you to migrate a dev intermine box to prodcution on AWS. 


##Installation


###Install CPAN

```bash
yum install perl-CPAN
```

or

```bash
apt-get install cpan
```
###Install Carton

This is a work in progress. The cpanfile that Carton uses to install the modules locally works. At this point, I have not been able to figure out how to point the script at the locally installed modules. Instead of using Carton the modules listed in the cpanfile need to be installed seperately. 

```bash
sudo cpan Carton
```

#Install requirements with Carton
```bash
carton install
```

##Usage

Currently the command is very simple: e.g. perl bin/rotate-intermine.pl 254

The rollout_version is the version of the machine that you would like to roll into production.

```bash
perl bin/rotate-intermine.pl <rollout_version>
```

##Steps performeed

1. AMI Created of rollout machine if does not already exist
2. Tagging the image
3. Creation of new development machine with the name of the next incremental database version
4. Tagging the new machine
5. Adding a CNAME for the new machine
6. Changing the tag for the rollout machine to production
7. Changing security group for rollout machine to production group
8. Changing CNAME for intermine.wormbase.org to point to new production intermine machine
