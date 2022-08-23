packer {
  required_plugins {
    amazon = {
      source  = "github.com/inloco/amazon"
      version = "= 1.0.4-incognia.2"
    }
  }
}

variable "aws_region" {
  default = env("AWS_REGION")

  validation {
    condition     = length(var.aws_region) > 0
    error_message = "The aws_region var is not set."
  }
}

data "amazon-ami" "macos12" {
  most_recent = true

  owners = [
    "amazon",
  ]

  filters = {
    architecture        = "x86_64_mac"
    name                = "amzn-ec2-macos-12.*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
}

source "amazon-ebssurrogate" "macami" {
  availability_zone             = "${var.aws_region}a"
  ami_architecture              = "x86_64_mac"
  ami_name                      = data.amazon-ami.macos12.name
  ami_virtualization_type       = "hvm"
  decode_authorization_messages = true
  ebs_optimized                 = true
  ena_support                   = true
  force_delete_snapshot         = true
  force_deregister              = true
  iam_instance_profile          = "AmazonSSMRoleForInstancesQuickSetup"
  instance_type                 = "t3a.nano"
  region                        = var.aws_region
  shutdown_behavior             = "terminate"
  ssh_agent_auth                = true
  ssh_interface                 = "private_dns"
  ssh_username                  = "ec2-user"
  ssh_bastion_agent_auth        = true
  ssh_bastion_host              = "localhost"
  ssh_bastion_port              = 2222
  ssh_bastion_username          = "ec2-user"

  aws_polling {
    max_attempts = 240
    delay_seconds = 60
  }

  vpc_filter {
    filters = {
      is-default = false
    }
  }

  subnet_filter {
    most_free = true
    random    = true

    filters = {
      availability-zone = "${var.aws_region}a"
    }
  }

  security_group_filter {
    filters = {
      group-name = "SSH"
    }
  }

  source_ami_filter {
    most_recent = true

    owners = [
      "amazon",
    ]

    filters = {
      architecture        = "x86_64"
      name                = "amzn2-ami-hvm-2.*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvdf"
    snapshot_id           = data.amazon-ami.macos12.block_device_mappings[0].snapshot_id
    volume_size           = 60
    volume_type           = "gp2"
    delete_on_termination = true
  }

  ami_root_device {
    device_name           = "/dev/sda1"
    source_device_name    = "/dev/xvdf"
    volume_size           = 60
    volume_type           = "gp2"
    delete_on_termination = true
  }
}

build {
  sources = [
    "sources.amazon-ebssurrogate.macami",
  ]

  provisioner "shell" {
    scripts = [
      "./scripts/apfs.sh",
      "./scripts/eic.sh",
      "./scripts/jailbreak.sh",
    ]
  }
}
