packer {
  required_version = "= 1.12.0"

  required_plugins {
    amazon = {
      source  = "github.com/inloco/amazon"
      version = "= 1.3.3"
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
  instance_type                 = "t3a.small"
  pause_before_ssm              = "2m"
  region                        = var.aws_region
  shutdown_behavior             = "terminate"
  ssh_agent_auth                = true
  ssh_interface                 = "session_manager"
  ssh_username                  = "ec2-user"

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
    delete_on_termination = true
    device_name           = "/dev/xvdf"
    snapshot_id           = data.amazon-ami.macos12.block_device_mappings[0].snapshot_id
    volume_size           = data.amazon-ami.macos12.block_device_mappings[0].volume_size
    volume_type           = data.amazon-ami.macos12.block_device_mappings[0].volume_type
  }

  ami_root_device {
    delete_on_termination = true
    source_device_name    = "/dev/xvdf"
    device_name           = data.amazon-ami.macos12.block_device_mappings[0].device_name
    volume_size           = data.amazon-ami.macos12.block_device_mappings[0].volume_size
    volume_type           = data.amazon-ami.macos12.block_device_mappings[0].volume_type
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
