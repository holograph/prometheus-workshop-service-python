packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.3"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "prometheus-workshop-service-python" {
  ami_name              = "prometheus-workshop-service-python-${formatdate("YYYY-MM-DD", timestamp())}"
  instance_type         = "t2.large"
  region                = "eu-central-1"
  force_deregister      = true
  force_delete_snapshot = true

  launch_block_device_mappings {
    device_name           = "/dev/sda1" # Root device
    delete_on_termination = true
    volume_size           = 30
  }

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }



  ssh_username = "ubuntu"
}

build {
  name    = "prometheus-workshop-service-python"
  sources = ["source.amazon-ebs.prometheus-workshop-service-python"]

  provisioner "file" {
    sources = [
      "./base-install.sh",
      "./service-install.sh",
      "./otel-collector-install.sh",
      "./prometheus-install.sh",
      "./grafana-install.sh"
    ]
    destination = "/home/ubuntu/"
    direction   = "upload"
  }
  provisioner "shell" {
    inline = ["chmod +x ./*-install.sh && ./base-install.sh"]
  }
  provisioner "shell" {
    inline = ["rm ./*-install.sh"]
  }
}
