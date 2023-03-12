packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

####################
# All variables
####################

variable "packer_access_key" {
  type      = string
  sensitive = false
}

variable "packer_secret_key" {
  type      = string
  sensitive = true
}

variable "packer_region" {
  type      = string
  sensitive = false
}

variable "packer_role_arn" {
  type      = string
  sensitive = false
}

####################
# This source will create an EBS AMI from an existing AMI.
#
# * The skip_create_ami option is used to skip the creation of the AMI. This helps debugging the build process.
# * The AMI name is set to a timestamp to ensure uniqueness.
# * The instance type is set to a t3a.medium to build for x86_64.
# * Tags are set to identify the resources created by Packer for easier cleanup.
####################

source "amazon-ebs" "ubuntu" {
  skip_create_ami = true
  region          = var.packer_region
  access_key      = var.packer_access_key
  secret_key      = var.packer_secret_key
  ami_name        = "ebpf-xdp-devspace-{{isotime `2006-01-02-15-04-05`}}"
  instance_type   = "t3a.medium"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  ssh_username = "ubuntu"
  assume_role {
    role_arn     = var.packer_role_arn
    session_name = "packer"
  }
  run_tags = {
    Creator = "Packer"
  }
  run_volume_tags = {
    Creator = "Packer"
  }
  snapshot_tags = {
    Creator = "Packer"
  }
  tags = {
    Creator = "Packer"
  }
}

####################
# This build will install Docker K3s and Acorn on the Ubuntu AMI.
# 
# * It's based on the source created above.
# * Wait for cloud-init to finish. This is important to ensure that the instance is
#   fully configured. If this is not done, the instance might not be able to reach the
#   internet or things like apt-get might not work.
# * Upgrade the system to the latest packages.
# * Skip start and enable of K3s to initialize secrets at first startup for uniqueness
####################

build {
  name = "k3s"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl jq",
      "curl https://releases.rancher.com/install-docker/20.10.sh | sudo bash",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_ENABLE=true sh -",
      "curl -s https://api.github.com/repos/acorn-io/acorn/releases/latest | jq -r '.assets[] | select(.name | contains(\"linux-amd64\")) | .browser_download_url' | xargs curl -L | sudo tar zxv -C /usr/local/bin acorn",
      "sudo chmod 755 /usr/local/bin/acorn"
    ]
  }
}

