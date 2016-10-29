#!/usr/bin/env perl

use strict;
use warnings;

use autodie qw(:all);
use feature qw(say);

use JSON::XS;
use Capture::Tiny ':all';

use Data::Dumper;

my $im_security_group = "intermine-dev";
my $subnet_id = "subnet-a33a2bd5";

my $username = "awright";
my $rollout_version = 253;
my $new_version = $rollout_version + 1;
$new_version .= "-test";

my $old_name = "im-$rollout_version.wormbase.org";
my $new_im_name = "im-$new_version.wormbase.org";


my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

my ($stdout, $stderr);

say "Pulling image information";
my $command = "aws ec2 describe-images"; 
say "\t$command";
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

say "Pulling Instance Information";
$command = "aws ec2 describe-instances";
say "\t$command";
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
        if ($tags{Name} =~ /im.*\.wormbase\.org/) {
            $instance->{Tags} = \%tags;
            $im_instances{$tags{Name}} = $instance;
        }
    }
}

say "Creating image of $old_name";
if (not defined $im_image) {
#   aws --region=us-east-1 ec2 create-image --instance-id "PROD" --name "wormine backup" --description "This image gets created from the development instance of wormine when it is ready to be roled out into production"
}
else {
    say "SKIPPING: image of $old_name already exists";
}


say "Creating $new_im_name";
if (defined $im_instances{$new_im_name}) { 
    say "SKIPPING: $new_im_name already exists";
}
else {
   my $ami = $im_instances{$old_name};
   my $image_id = $ami->{ImageId};
   my $ami_instance_type = $ami->{InstanceType};
   my $instance_type = ($ami_instance_type eq "m4.2xlarge")? "m3.2xlarge" : "m4.2xlarge"; 
   my $key_name = $ami->{KeyName};
   $command = "aws --region=us-east-1 ec2 run-instances --image-id $image_id --count 1 --instance-type $instance_type --key-name $key_name --subnet-id=$subnet_id";
   say "\t$command";     
  
   ($stderr, $stdout) = capture {system($command)};
   die "error $stderr" if $stderr;
   
   print Dumper $stdout;
   $response = $coder->decode($stdout);
   my @instances = @{$response->{Instances}};
   my $instance = $instances[0];
   my $new_instance_id = $instance->{InstanceId};
   say "new instance id: $new_instance_id";

   $command = "aws ec2 create-tag --resources --tags \"Name=$new_im_name,Client=OICR,CreatedBy=$username,Project=WormBase,Release=WS$new_version,Role=intermine,Status=development\"";
   say "tagging manchine";
   say "\t$command";
   ($stderr, $stdout) = capture {system($command)};

   say "result of command";
   print Dumper $stdout;
}


say "DONE";
#delete-instance: @aws --region=us-east-1 ec2 \
#                        terminate-instances  \
#                        --instance-ids PROD
