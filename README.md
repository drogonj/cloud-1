# Cloud-1

### Introduction to cloud servers

Using **Terraform** and **Ansible**, the project aim to deploy a simple Wordpress website on a cloud servers.

### **Stack**

* Makefile
* Docker
* Terraform
* Ansible
* DigitalOcean library for Terraform

---

Fill both `.env` files and `make deploy` ! (`mv .env-template .env`)

`/.env` Contain the DigitalOceans project's API KEY, our VM root password and our User username & password.

`/srcs/.env` Contain all credidentials for Wordpress, Mariadb, and the title of our website.

In short `/setup/` contains all files to **deploy** and **config** our VM(s). `/srcs/` contain all files that will be copied on our VM(s).

**Terraform** ask our provider to create the VM(s) and config there DNS, Firewall, ... everything that can be done on DigitalOcean's website.

**Ansible** will remote-connect to our VM(s) and config them (Initialize users credentials, installing depencies like docker, ... **And finally start our docker project**)

Our Docker's project aim to deploy a basic Wordpress website. With an **Nginx** server, **mariadb** database and **phpmyadmin**, all done in an microservice's architecture way.

---

/Makefile :

```
make deploy          -> deploy a single droplet

make deploy d=DOMAIN -> Set a domain for your droplet(s)
- without this option, droplet(s) will be configured for ipv4 connections

make deploy n=NUMBER -> choose how many droplet's are created
- If a domain name is set, deploying more than 1 droplet will create subdomains like s1.domain.org, s2.domain.org, ...

make destroy         -> DESTROY EVERYTHING

make ssh             -> remote connection to the droplet with it's id (0 to NUMBER-1)
```

Deploying the projects will create a lot of file in `/setup/`.

`hosts.ini` Contain all IPs, only used by `make ssh` and in case you want to fast access them.

`inventory.ini` is for Ansible runtime, it contain what user to use, the ssh key and our droplet's IPs/Domains name.

`id_rsa` is the private key that we use for remote connections, ONLY THIS KEY will give you an remote access to the VMs (except DigitalOcean's website).

`id_rsa.pub` is the key given to our VMs.

---

/srcs/Makefile :

```
make up     -> Deploy website
make down   -> Shutdown website
make clean  -> Clean all containes images
make fclean -> Clean all images & volumes (databases !)
make logs   -> display docker compose's logs

```

---

Setting a domain name does not mean you got one. You need to "buy" one on a Domain registrar (like Namecheap) and config the DNS to point to your provider (DigitalOcean in my case).

Feedback: Nice project ! Could be better without Wordpress
