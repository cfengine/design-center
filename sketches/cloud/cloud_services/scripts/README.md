Note -v can be added to any command for much more information about what it's doing.

* EC2

    shim.pl --ec2 security_group=quick-start-1 --ec2 instance_type=m1.small --ec2 region=us-east-1 --ec2 ssh_pub_keyvar/tmp/mysshkey.pub --ec2 ami=ami-b89842d1 --ec2 aws_access_key=AK...2A --ec2 aws_secret_key=23..8p --hub=192.168.1.27 --install_cfengine=ON ec2 console cf3worker-1
    shim.pl --ec2 security_group=quick-start-1 --ec2 instance_type=m1.small --ec2 region=us-east-1 --ec2 ssh_pub_keyvar/tmp/mysshkey.pub --ec2 ami=ami-b89842d1 --ec2 aws_access_key=AK...2A --ec2 aws_secret_key=23..8p --hub=192.168.1.27 --install_cfengine=ON ec2 control 0 cf3worker
    shim.pl --ec2 security_group=quick-start-1 --ec2 instance_type=m1.small --ec2 region=us-east-1 --ec2 ssh_pub_keyvar/tmp/mysshkey.pub --ec2 ami=ami-b89842d1 --ec2 aws_access_key=AK...2A --ec2 aws_secret_key=23..8p --hub=192.168.1.27 --install_cfengine=ON ec2 control 1 cfworker
    shim.pl --ec2 security_group=quick-start-1 --ec2 instance_type=m1.small --ec2 region=us-east-1 --ec2 ssh_pub_keyvar/tmp/mysshkey.pub --ec2 ami=ami-b89842d1 --ec2 aws_access_key=AK...2A --ec2 aws_secret_key=23..8p --hub=192.168.1.27 --install_cfengine=ON ec2 list cf3worker
    shim.pl --ec2 security_group=quick-start-1 --ec2 instance_type=m1.small --ec2 region=us-east-1 --ec2 ssh_pub_keyvar/tmp/mysshkey.pub --ec2 ami=ami-b89842d1 --ec2 aws_access_key=AK...2A --ec2 aws_secret_key=23..8p --hub=192.168.1.27 --install_cfengine=ON ec2 ssh cf3worker-1

* S3

    shim.pl --s3 acl=public-read --s3 aws_access_key=AK...2A --s3 aws_secret_key=23..8p s3 clear bucket.cfengine.com
    shim.pl --s3 acl=public-read --s3 aws_access_key=AK...2A --s3 aws_secret_key=23..8p s3 ls bucket.cfengine.com
    shim.pl --s3 acl=public-read --s3 aws_access_key=AK...2A --s3 aws_secret_key=23..8p s3 sync . bucket.cfengine.com

* SDB

    shim.pl --sdb aws_access_key=AK...2A --sdb aws_secret_key=23..8p sdb dump cftest
    shim.pl --sdb aws_access_key=AK...2A --sdb aws_secret_key=23..8p sdb list cftest
    shim.pl --sdb aws_access_key=AK...2A --sdb aws_secret_key=23..8p sdb sync /tmp/test.lines.json cftest

* OpenStack

    shim.pl --openstack user=tzlatanov --openstack key=72..42 --openstack image=5cebb13a-f783-4f8c-8058-c4182c724ccd --openstack master=cfmaster --hub 10.10.10.1 --openstack password=r00tm01 openstack control 1 cfnode
    shim.pl --openstack user=tzlatanov --openstack key=72..42 --openstack image=5cebb13a-f783-4f8c-8058-c4182c724ccd --openstack master=cfmaster --hub 10.10.10.1 --openstack password=r00tm01 openstack control 0 cfnode
    shim.pl --openstack user=tzlatanov --openstack key=72..42 --openstack image=5cebb13a-f783-4f8c-8058-c4182c724ccd --openstack master=cfmaster openstack list
    shim.pl --openstack user=tzlatanov --openstack key=72..42 --openstack image=5cebb13a-f783-4f8c-8058-c4182c724ccd --openstack master=cfmaster openstack list cfnode
