

data "local_file" "env" {
  filename = "${path.module}/../.env"
}

resource "digitalocean_ssh_key" "dg_pub_key" {
  name = "dg-pub-key"
  public_key = file("${path.module}/id_rsa.pub")
}

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
    token = regex("DO_TOKEN=(.*)", data.local_file.env.content)[0]
}

resource "digitalocean_droplet" "web" {
    image   = "ubuntu-20-04-x64"
    name    = "cloud-1"
    region  = "fra1"
    size    = "s-1vcpu-2gb"

    ssh_keys = [
      digitalocean_ssh_key.dg_pub_key.fingerprint
    ]

    provisioner "remote-exec" {
      connection {
        host = self.ipv4_address
        user = "root"
        private_key = file("id_rsa")
      }
      inline = [
          "rm -rf /var/lib/apt/lists/*",
          "apt-get update",
          "apt-get upgrade -y",
          "apt-get install python3 -y"
      ]
    }

    connection {
      host  = self.ipv4_address
      type  = "ssh"
      user  = "root"
    }

    provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key=${path.module}/id_rsa playbook.yml"
    }
}

output "droplet_ip" {
    value = digitalocean_droplet.web.ipv4_address
}
