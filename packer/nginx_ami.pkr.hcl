packer {
  required_plugins {
    amazon = {
      version = "1.1.3"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amzn_nginx" {
  ami_name      = "amzn_nginx-${formatdate("DDMMMYYYY_hhmmss", timestamp())}"
  instance_type = "t3.micro"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"]
    most_recent = true
  }

  ssh_username = "ec2-user"
}

build {
  name = "nginx"
  sources = [
    "source.amazon-ebs.amzn_nginx"
  ]

  provisioner "shell" {
    name = ""
    inline = [
      "sudo amazon-linux-extras enable epel",
      "sudo yum install epel-release -y",
      "sudo yum update -y",
      "udo yum install python3-pip -y",
      "sudo pip install ansible"
    ]
  }

  provisioner "ansible-local" {
    playbook_file   = "./nginx_playbook.yml"
  }

}
