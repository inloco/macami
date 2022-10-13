#!/usr/bin/sudo bash
set -ex

VOLBASE='/mnt'

mount -o readwrite /dev/xvdf2 "${VOLBASE}"

AWSBIN='/opt/aws/bin'
AWSBINVOL="${VOLBASE}${AWSBIN}"
mkdir -p "${AWSBINVOL}"

wget https://github.com/inloco/aws-ec2-instance-connect-config/archive/HEAD.zip
unzip ./HEAD.zip
rm ./HEAD.zip
cp ./aws-ec2-instance-connect-config-*/src/bin/* "${AWSBINVOL}"

SSHDCONF="${VOLBASE}/private/etc/ssh/sshd_config.d/075-aws-eic.conf"
echo "AuthorizedKeysCommand ${AWSBIN}/eic_run_authorized_keys %u %f" >> "${SSHDCONF}"
echo 'AuthorizedKeysCommandUser ec2-instance-connect' >> "${SSHDCONF}"

python3 << EOF
import plistlib

d = {
    'name': [
        'ec2-instance-connect',
    ],
    'generateduid': [
        'EC20IA57-AACE-0C0A-AEC7-000000000000',
    ],
    'gid': [
        '209',
    ],
    'realname': [
        'EC2 Instance Connect',
    ],
    'shell': [
        '/sbin/nologin',
    ],
    'uid': [
        '209',
    ],
}
with open('${VOLBASE}/private/var/db/dslocal/nodes/Default/users/ec2-instance-connect.plist', 'wb') as f:
    plistlib.dump(d, f, fmt=plistlib.FMT_BINARY)

d = {
    'name': [
        'ec2-instance-connect',
    ],
    'generateduid': [
        'EC20IA57-AACE-0C0A-AEC7-000000000000',
    ],
    'gid': [
        '209',
    ],
    'groupmembers': [
        'EC20IA57-AACE-0C0A-AEC7-000000000000',
    ],
    'realname': [
        'EC2 Instance Connect',
    ],
    'users': [
        'ec2-instance-connect',
    ],
}
with open('${VOLBASE}/private/var/db/dslocal/nodes/Default/groups/ec2-instance-connect.plist', 'wb') as f:
    plistlib.dump(d, f, fmt=plistlib.FMT_BINARY)

d = {
    'KeepAlive': {
        'SuccessfulExit': False,
    },
    'Label': 'com.amazon.aws.ec2-instance-connect',
    'Program': '/opt/aws/bin/eic_harvest_hostkeys',
    'RunAtLoad': True,
}
with open('${VOLBASE}/Library/LaunchDaemons/com.amazon.aws.ec2-instance-connect.plist', 'wb') as f:
    plistlib.dump(d, f, fmt=plistlib.FMT_XML)
EOF

umount "${VOLBASE}"
