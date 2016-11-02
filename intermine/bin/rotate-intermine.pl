#!/usr/bin/env perl

use strict;
use warnings;

use autodie qw(:all);
use feature qw(say);

use DateTime;
use JSON::XS;
use Capture::Tiny ':all';

use Data::Dumper;

###USAGE perl bin/rotate-intermine.pl <rollout_version>
#
# 1)change variable values at top of this script
# 2)run command (ex. perl bin/rotate-intermine.pl 254)
#
# This command would make a ami of im254 and then make an instance im255. Followed by changing the status tag for im254 to production. At this point it will also change the CNAME for ws254 so that intermine.wormbase.org points to it.  

my $im_security_group = "intermine-dev";
my $subnet_id = "subnet-a33a2bd5";

my $username = "awright";
my $rollout_version = $ARGV[0];
my $new_version = $rollout_version + 1;
$rollout_version .= "-test";
$new_version .= "-test";

my $old_name = "im-$rollout_version.wormbase.org";
my $new_im_name = "im-$new_version.wormbase.org";


my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

my ($stdout, $stderr);

say "Getting Image Information";
my $im_image = get_im_image($rollout_version);

say "Getting Instance Information";
my $im_instances = get_im_instances();

say "Getting Security Group IDs";
my $security_group_ids = get_security_groups();

say "Getting Host Zone ID";
my $hosted_zone_id = get_hosted_zone_id();

say "Getting CNAME Records";
my $cname_records = get_cname_records($hosted_zone_id);

if (not defined $im_image)  {
   say "Image of instance $old_name not found. About to create image";
   die("Could not proceed: Both image and instance of $old_name were not found") if (not defined $im_instances->{$old_name});

   say "Creating image of instance $old_name";
   my $instance = $im_instances->{$old_name};
   my $image_id = create_image($instance, $old_name);

   tag_resource($old_name, $image_id, $username, $rollout_version, "production");
   say "created $image_id";
   $im_instances = get_im_instances();
}
else {
    say "SKIPPING: image of $old_name already exists";
}

my ($command, $response);

say "Creating $new_im_name";
if (defined $im_instances->{$new_im_name}) { 
    say "SKIPPING: $new_im_name already exists";
}
else {
   my $ami = $im_instances->{$old_name};
   
   my $response = create_instance_from_ami($ami);

   my @instances = @{$response->{Instances}};
   my $instance = $instances[0];
   my $new_instance_id = $instance->{InstanceId};
   say "new instance id: $new_instance_id";

   say "tagging manchine";

   tag_resource($new_im_name, $new_instance_id, $username, $new_version, "development");

   say "create CNAME";
   my $command = "aws route53 change-resource-record-sets --hosted-zone-id";

}

say "Adding CNAME record for $new_im_name";
if (defined $cname_records->{$new_im_name}) {
    say "SKIPPING: CNAME record already exists";
}
else {
    say "creating cname record";
    my $command = aws route53 change-resource-record-sets --hosted-zone-id --change-batch '{ "Comment": "Created by rotate-intermine.pl","Changes":[{"Action": "CREATE","ResourceRecordSet": {"Name": "api.realguess.net.","Type": "CNAME","TTL": 300,"ResourceRecords": [{"Value": "'.www.realguess.net.'"}]}}]}'
}

say "Changing tag for $old_name to production and changing security group to production";
if (defined $im_instances->{$old_name}) {
    my $instance = $im_instances->{$old_name};
    my $dev_instance_id = $instance->{InstanceId};
    my $command = "aws ec2 create-tags --resources $dev_instance_id --tags \"Key=Status,Value=production\"";
    say "\tCOMMAND: $command";
    ($stdout, $stderr) = capture {system($command)};
    die "error $stderr" if $stderr;

    my $prod_security_group_id = $security_group_ids->{prod};

    $command = "aws ec2 modify-instance-attribute --instance-id $dev_instance_id --groups $prod_security_group_id";
    say "\tCOMMAND: $command";

    ($stdout, $stderr) = capture {system($command)};
    die "error $stderr" if $stderr;
}
else {
    say "SKIPPING: $old_name instance not found";
}
 
say "DONE";

sub create_instance_from_ami {
   my ($ami) = @_;

   my $image_id = $ami->{ImageId};
   my $ami_instance_type = $ami->{InstanceType};
   my $instance_type = ($ami_instance_type eq "m4.2xlarge")? "m3.2xlarge" : "m4.2xlarge"; 
   my $key_name = $ami->{KeyName};

   $command = "aws --region=us-east-1 ec2 run-instances --security-group \"intermine-dev\" --image-id $image_id --count 1 --instance-type $instance_type --key-name $key_name --subnet-id=$subnet_id";
   say "\tCOMMAND: $command";     

   ($stdout, $stderr) = capture {system($command)};
   die "error $stderr" if $stderr;
   
   $response = $coder->decode($stdout);

   return $response;
}

sub tag_resource {
   my ($name, $resource, $username, $version, $status) = @_;

   my $dt = DateTime->now;
   my $date = $dt->ymd('.');

   my %tags = ("Name" => $name,
               "Client" => "OICR",
               "CreatedBy" => $username,
               "Date" => $date,
               "Project" => "WormBase",
               "Release" => "WS$version",
               "Role" => "intermine",
               "Status" => $status);

   my $value;        
   foreach my $key (keys %tags) {
       $value = $tags{$key};
       $command = "aws ec2 create-tags --resources $resource --tags \"Key=$key,Value=$value\"";
       say "\tCOMMAND: $command";
       ($stdout, $stderr) = capture {system($command)};
       die "error $stderr" if $stderr;
   }

}

sub get_security_groups {
    $command = "aws ec2 describe-security-groups";
    say "\tCOMMAND: $command";
    ($stdout, $stderr) = capture {system($command)};
    die "error $stderr" if $stderr;
       
    $response = $coder->decode($stdout);

    my @security_groups = @{$response->{SecurityGroups}};

    my %im_security_group_ids;
    foreach my $security_group (@security_groups) {
        if ($security_group->{GroupName}  eq "intermine-production") {
             $im_security_group_ids{prod} = $security_group->{"GroupId"};
        }
        elsif ($security_group->{GroupName}  eq "intermine-dev") {
             $im_security_group_ids{dev} = $security_group->{"GroupId"};
        }
    }

    return \%im_security_group_ids;
}

sub create_image {
   my ($instance, $name) = @_;

   my $instance_id = $instance->{InstanceId};
   $command = "aws --region=us-east-1 ec2 create-image --instance-id $instance_id --name \"$name\" --description \"Created from the development instance of wormine when it is ready to be rolled out into production\"";
   say $command;

   ($stdout, $stderr) = capture {system($command)};
   die "error $stderr" if $stderr;

   $response = $coder->decode($stdout);
   my $image_id = $response->{ImageId};
   
   return $image_id;
}

sub get_im_instances {

    $command = "aws ec2 describe-instances";
    say "\tCOMMAND: $command";
    ($stdout, $stderr) = capture { system($command) };
    die "error $stderr" if $stderr;
    
    my $response = $coder->decode($stdout);
    
    my %im_instances;
    foreach my $reservation (@{$response->{Reservations}}) {
        my $instances = $reservation->{Instances};
        my ($key, $value);
        foreach my $instance (@{$reservation->{Instances}}) {
            my %tags;
            foreach my $tag (@{$instance->{Tags}}) {
                $key = $tag->{Key};
                $value = $tag->{Value};
                $tags{$key} = $value;
            }
            if ((defined $tags{Name}) && ($tags{Name} =~ /im.*\.wormbase\.org/)) {
                $instance->{Tags} = \%tags;
                $im_instances{$tags{Name}} = $instance;
            }
        }
    }

    return \%im_instances;
}

sub get_hosted_zone_id {
    my $command = "aws route53 list-hosted-zones";

    say "\tCOMMAND: $command";
    ($stdout, $stderr) = capture { system($command) };
    die "error $stderr" if $stderr;
    
    my $response = $coder->decode($stdout);
    my @hosted_zones = @{$response->{HostedZones}};

    foreach my $zone (@hosted_zones) {
        if ($zone->{Name} eq "wormbase.org.") {
            my $id = $zone->{Id};
            $id =~ /\/hostedzone\/(.*)/;
            return $1;
        }
    }
}

sub get_cname_records {
    my ($hosted_zone_id) = @_;

    my $command = "aws route53 list-resource-record-sets --hosted-zone-id $hosted_zone_id";

    say "\tCOMMAND: $command";
    ($stdout, $stderr) = capture { system($command) };
    die "error $stderr" if $stderr;
    
    my $response = $coder->decode($stdout);
    
    my @resource_record_set = @{$response->{ResourceRecordSets}};

    my %cname_records;
    foreach my $record (@resource_record_set) {
        if ($record->{Type} eq "CNAME") { 
           $cname_records{$record->{Name}} = $record; 
        }
    }

    return \%cname_records;   
}

sub get_im_image {
    my ($rollout_version) = @_;

    my $command = "aws ec2 describe-images"; 
    say "\tCOMMAND: $command";
    ($stdout, $stderr) = capture {system($command)};
    die "error $stderr" if $stderr;
    
    my $images = $coder->decode($stdout);
    
    my $im_image;
    foreach my $image (@{$images->{Images}}) {
        if (defined($image->{Name}) && ($image->{Name} =~ /im-$rollout_version\.wormbase\.org/)) {
           $im_image = $image;
           last;
        }
    }

    return $im_image;
 }   


