# MacAMI

macOS Amazon Machine Image built with Packer

## Connecting to AWS

Use [`ec2-instance-connect-bastion`](https://github.com/inloco/ec2-instance-connect-bastion/) to bridge the connection to AWS:

```
git clone git@github.com:inloco/ec2-instance-connect-bastion
cd ec2-instance-connect-bastion
go build
sudo cat /etc/ssh/ssh_host_rsa_key | ./ec2-instance-connect-bastion
```

Install openssh-server to have automatically generated host key.
