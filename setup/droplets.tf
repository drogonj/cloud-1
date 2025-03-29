# #
#
# Load depencies for our provider
# in our case, its DigitalOcean
#
# #

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}


# #
#
# Load our .env file
# DO_TOKEN, and credentials for root and user
#
# #

data "local_file" "env" {
  filename = "${path.module}/../.env"
}

# #
#
# Configure our provider:
# Take the DO_TOKEN from loaded .env file
# DO_TOKEN is an API key we've created in our DigitalOcean's project
# It give terraform access to our project allowing it to create/delete/modify droplets
#
# #

provider "digitalocean" {
    token = regex("DO_TOKEN=(.*)", data.local_file.env.content)[0]
}


# #
#
# Load our SSL pub key,
# allowing us to connect with our private key
#
# #

resource "digitalocean_ssh_key" "dg_pub_key" {
  name = "dg-pub-key"
  public_key = file("${path.module}/id_rsa.pub")
}


# #
#
# Generate a random id
# added our Firewall  VM's names
#
# #

resource "random_id" "unique" {
  byte_length = 8
}


# #
#
# Create our droplet.
# "s-1vcpu-2gb" is our droplet's config (1vCPU and 2GB of ram)
# 
# Then we do a "remote-exec" to init apt-get and install python3.
# The first "local-exec" is to take our droplet's ip and store it in setup/hosts.ini file localy
# Second one is to start our Ansible playbook ("setup/playbook.yml")
#
# #

resource "digitalocean_droplet" "web" {
    image   = "ubuntu-20-04-x64"
    name    = "cloud-1-${random_id.unique.hex}"
    region  = "fra1"
    size    = "s-1vcpu-2gb"

    ssh_keys = [
      digitalocean_ssh_key.dg_pub_key.fingerprint
    ]

    connection {
      host  = self.ipv4_address
      type  = "ssh"
      user  = "root"
    }

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

    provisioner "local-exec" {
      command = "echo '[web]\n${self.ipv4_address}' > hosts.ini"
    }

    provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key=${path.module}/id_rsa playbook.yml"
    }
}


# #
#
# Create a Firewall for our droplet
# Only allowing inputs from 22, 80 and 443 ports
#  
# /!\ allowing 22 inbounds from all ips isn't safe but its a student project so..
#
# #

resource "digitalocean_firewall" "web" {
  name = "cloud-1-firewall-${random_id.unique.hex}"
  droplet_ids = [digitalocean_droplet.web.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}


# #
#
# Just output our droplet's ip in stdout 
#
# #

output "droplet_ip" {
    value = digitalocean_droplet.web.ipv4_address
}
