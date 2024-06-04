# MacAMI

macOS Amazon Machine Image built with Packer

## Building

Firstly, make sure `sshd` is installed on your system and that it has generated host keys for you.

```bash
cat /etc/ssh/ssh_host_rsa_key.pub
```

Then, check you are able to resolve `ip-${XXX}-${YYY}-${ZZZ}-${WWW}.ec2.internal`.

```bash
dig ip-10-0-0-1.ec2.internal
```

Now, build and run EC2 Instance Connect Bastion on your machine.

```bash
git clone https://github.com/inloco/ec2-instance-connect-bastion
cd ec2-instance-connect-bastion
go build
sudo cat /etc/ssh/ssh_host_rsa_key | ./ec2-instance-connect-bastion /dev/stdin
```

While EIC Bastion is running, bake the AMI.

```bash
make
```