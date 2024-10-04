packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.3"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "prometheus-workshop-service-python" {
  ami_name      = "prometheus-workshop-service-python-${formatdate("YYYY-MM-DD", timestamp())}"
  instance_type = "t2.medium"
  region        = "eu-central-1"

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

  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y net-tools",
    ]
  }

  provisioner "file" {
    source      = "./service-install.sh"
    destination = "/home/ubuntu/service-install.sh"
    direction   = "upload"
  }
  provisioner "shell" {
    inline = [
      "chmod +x ./service-install.sh && ./service-install.sh"
    ]
  }

  provisioner "file" {
    source      = "./prometheus-install.sh"
    destination = "/home/ubuntu/prometheus-install.sh"
    direction   = "upload"
  }
  provisioner "shell" {
    inline = [
      "chmod +x ./prometheus-install.sh && ./prometheus-install.sh"
    ]
  }

  provisioner "file" {
    source      = "./grafana-install.sh"
    destination = "/home/ubuntu/grafana-install.sh"
    direction   = "upload"
  }
  provisioner "shell" {
    inline = [
      "chmod +x ./grafana-install.sh && ./grafana-install.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "rm ./service-install.sh ./grafana-install.sh ./prometheus-install.sh"
    ]
  }
}
