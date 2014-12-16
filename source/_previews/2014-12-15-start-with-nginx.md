---
title: Up and Running with Nginx
descr: Learn how to get started using Nginx!
---

In the previous preview, we saw getting started with Vagrant. We also installed Nginx. Let's go a little further with Nginx.

## Install Nginx

Assuming you have an Ubuntu (or Debian) server, we can install the latest stable version of Nginx like so. We'll install the basics, add the official Nginx repository and then install Nginx.

```shell
# Update repositories of available packages
sudo apt-get update

# Install some basics
sudo apt-get install -y vim wget unzip software-properties-common

# Add a the official Nginx package repository to get 
# the latest stable version of Nginx
sudo add-apt-repository -y ppa:nginx/stable

# Update repositories again and install Nginx
sudo apt-get update
sudo apt-get install -y nginx
```

Once that's all run, Nginx will be up and running.

## Configure Nginx

Nginx in Ubuntu uses a `/etc/nginx/sites-available` and `/etc/nginx/sites-enabled` directory convention. Configuration files in `sites-available` can be enabled by sym-linking them to the `sites-enabled` directory, and then reloaded Nginx's configuration.

These configuration files are analogous to Apache's Virtual Hosts. Let's create a basic configuration file to serve static site files. Create/edit `/etc/nginx/sites-available/example.conf`:

```conf
server {
    listen 80;

    root /var/www;
    index index.html index.htm;

    # Will also reply to "localhost" results
    server_name example.com;

    # If root URI
    location / {
        try_files $uri $uri/ =404;
    }
}
```

This will instruct Nginx to listen on port 80 and pull files from the `/var/www` directory for requests made to the `example.com` domain. We also define the "index" documents to try (in order of precendence). Pretty simple!

> This sets up Nginx to reply to the domain `example.com`. You may want to set it to something like `ip-address.xip.io` so you can avoid editing your hosts file to make `example.com` work. For example, `192.168.33.10.xip.io`.
> 
> You can also simply add "localhost", so requests to "localhost" head to this virtual host. If you do that, delete the `/etc/nginx/sites-enabled/default` file, which is also set to listen to "localhost".

Here's [another Nginx config file](https://gist.github.com/fideloper/9477321) with some extra options you may want to explore and use as well.

Once you have a configuration setup, you can symlink it to Nginx's `sites-enabled` directory and reload Nginx!

```shell
# Symlink available site to enabled site
$ sudo ln -s /etc/nginx/sites-available/example.conf \
             /etc/nginx/sites-enabled/example.conf

# Test configuration
$ sudo service nginx configtest

# Reload Nginx config
$ sudo service nginx reload
```

## More

You'll learn **a lot more** about Nginx in the Servers for Hackers [newsletter](https://serversforhackers.com) and especially in the [eBook](https://book.serversforhackers.com)!

In the future, we'll see:

* Using Nginx with applications
* Load balancing with Nginx
* And lots more!

