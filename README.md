# Ciinabox
---

![build-status](https://travis-ci.com/ciinabox/ciinabox.svg?branch=master)

Tool to create and manage ciinaboxes

```bash
Commands:
  ciinabox --version, -v     # print the version
```

## Setup

1. Get Credentials

Get keys for the AWS account and export the to the environment.
You can also supply a profile by using the `--profile my-profile` flag with ciinabox commands.

2. Initialise ciinabox

This command will create the required config to deploy the ciinabox stack in AWS

```bash
$ ciinabox init myciinabox
```

3. Deploy the stack

This will create the cloudformation stack with all the AWS resources ciinabox requires

```bash
$ ciinabox deploy myciinabox
```

4. Retrieve the admin password

```bash
$ ciinabox instances myciinabox
+---------------------+--------+-----------+-------+--------+------------+----------+---------------------------+
| Instance Id         | Status | Connected | Tasks | Agent  | Docker     | Type     | Up Since                  |
+---------------------+--------+-----------+-------+--------+------------+----------+---------------------------+
| i-xxxxxxxxxxxxxxxxx | ACTIVE | true      | 1     | 1.29.1 | 18.06.1-ce | t2.small | 2019-07-16 16:11:17 +1000 |
+---------------------+--------+-----------+-------+--------+------------+----------+---------------------------+

$ aws ssm start-session --target i-xxxxxxxxxxxxxxxxx

Starting session with SessionId: xxxxxxxxxxxxxxxxx

$ sudo docker ps
CONTAINER ID        IMAGE                                             COMMAND                  CREATED             STATUS              PORTS               NAMES
cb4f24c4879d        cloudbees/cloudbees-jenkins-distribution:latest   "/bin/tini -- /usr/l…"   31 hours ago        Up 31 hours                             ecs-myciinabox-ciinabox-jenkins-U7FQNYDLXC9U-Task-1SPBBASY29XER-1-jenkins-80838a96d2c6dab5a501
63d606e90873        amazon/amazon-ecs-pause:0.1.0                     "./pause"                31 hours ago        Up 31 hours                             ecs-myciinabox-ciinabox-jenkins-U7FQNYDLXC9U-Task-1SPBBASY29XER-1-internalecspause-aad9f1f0f9cbefc99701
e5d2e6b32a00        amazon/amazon-ecs-agent:latest                    "/agent"                 31 hours ago        Up 31 hours                             ecs-agent

$ sudo docker exec -ti cb4f24c4879d bash

$ cat var/jenkins_home/secrets/initialAdminPassword
abc123abc123abc123abc123abc123ab
```

5. Jenkins Wizard

Go to the Jenkins url of https://jenkins.myciinabox.domain.tld and login as user `admin` and retrieved password.
Click through the wizard and complete
  - Registration
  - install plugins
    - Blue Ocean
    - pipeline: decretive
    - pipeline
    - pipeline: stage view
    - ssh credentials
    - credential binding
    - scm api
    - git
    - git client
    - github branch
    - bitbucket branch
    - junit

7. S3 Bucket policy

config the s3 bucket policy with your vpc endpoint

```bash
ciinabox bucket-policy myciinabox --update
```

7. Install more plugins

Go to manage plugins and install
  - configuration as code
  - configuration as code support
  - ec2-fleet
  - job dsl
  
8. Configure the Jcasc plugin

retrieve the spot fleet id

```bash
$ ciinabox fleets myciinabox
+------------------------------------------+----------+-------------------------------+------------------------+-------------------------+
| Id                                       | Capacity | Launch Template               | Fleet Template Version | Latest Template Version |
+------------------------------------------+----------+-------------------------------+------------------------+-------------------------+
| sfr-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | 0        | myciinabox-ciinabox-ec2-agent | 1                      | 1                       |
+------------------------------------------+----------+-------------------------------+------------------------+-------------------------+
```

paste spot fleet id into the jenkins.yaml

```yaml
jenkins:
  clouds:
  - eC2Fleet:
      ...
      fleet: "sfr-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

and upload it

```bash
$ ciinabox jenkins-config myciinabox
uploaded jenkins.yaml config file to s3://123456789012.ap-southeast-2.ciinabox/myciinabox/jenkins/jenkins.yaml
Go to https://jenkins.myciinabox.domain.tld/configuration-as-code/ to apply the changes
```

go to the jenkins link, copy the s3 https link and paste it into the `Path or URL` box and click `Apply new configuration`

9. Create Jobs

start creating jobs that use the label `ec2-fleet`!

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
