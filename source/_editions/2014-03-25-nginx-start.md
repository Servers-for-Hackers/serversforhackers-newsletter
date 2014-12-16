---
title: Getting Started with Nginx
topics: [Getting Started with Nginx]
description: Get started installing and using the latest Nginx now.
---

> <em>"Apache is like Microsoft Word, it has a million options but you only need six. Nginx does those six things, and it does five of them 50 times faster than Apache."</em> - [Chris Lea](http://wiki.nginx.org/WhyUseIt)

Nginx is a lightweight alternative to Apache. It does less things, but still covers 90% of the most common use cases.

When we run PHP with Apache, a typical setup is to use the PHP5 Module. This means PHP is essentially loaded and available on every request, even for static files and images! That creates some overhead for each web request.

Nginx, on the other hand, deals primarily with static files, prefering to hand-off other requests to another process. This way, Nginx doesn't have to load in PHP or know about Python or Ruby in order to handle a web request.

How, then, does Nginx hand-off a request to a dynamic application? As mentioned, it passes the request off to another process instead of handling the request itself. With PHP, for example, we would install PHP5-FPM alongside Nginx. Nginx would then hande-off any PHP request to PHP5-FPM to process and respond to. In fact, we can install any type of CGI/FastCGI process, or even another http server, to handle a request. These would then process the request and return the result for Nginx to ultimately return to a client (usually a web browser). This lets us use PHP, Python, Ruby and other languages to handle dynamic web requests.

Nginx, then, can be used as a frontman for your application. Rather than handling the request, it dispatches dynamic requests off to a process and returns the result. This gives you the ability to unburden the loading of static assets (html, images, js, css) from your web application and even lets you install Nginx on a separate server.

Futhermore, and similar to NodeJS, Nginx is evented and runs asynchronously. This helps Nginx work with (relatively) very low memory usage, ultimately also helping your server serve more requests.

Let's see how this works with a few languages.

## Install Nginx

This is different per flavor of Linux you use. In general, their [installation docs](http://wiki.nginx.org/Install) are good for the more popular flavors (Debign/Ubuntu and RedHat/CentOS).

For Ubuntu, which I continue to use for both ease and popularity (and thus good support/Googleablity) the install process looks like this:

```shell
# If you don't already have this:
# You may need to install python-software-properties on Ubuntu 12.04
sudo apt-get install -y software-properties-common

# Add repository of stable builds:
sudo add-apt-repository -y ppa:nginx/stable

# Update local repositories after adding nginx/stable
sudo apt-get update

# Install latest stable nginx
sudo apt-get install -y nginx

# Start nginx
    sudo service nginx start
```

## Configuring Nginx

Similar to Apache configuration, Nginx in Ubuntu uses the `/etc/nginx/sites-available` and `/etc/nginx/sites-enabled` directory convention. Configuration files in `sites-available` can be enabled by sym-linking them to the `sites-enabled` directory (and then reloaded Nginx's configuration).

These configuration files are analogous to Apache's Virtual Hosts. Let's create a basic configuration file to serve static site files. Create/edit `/etc/nginx/sites-available/example.conf`:

```
server {
    listen 80;

    root /var/www;
    index index.html index.htm;

    # Will also reply to "localhost" results
    server_name example.com;

    # If root URI
    location / {
        try_files $uri $uri/;
    }
}
```

This will instruct Nginx to listen on port 80 and pull files from the `/var/www` directory for requests made to the `example.com` domain. We also define the "index" documents to try (in order of precendence). Pretty simple!

> This sets up Nginx to reply to the domain `example.com`. You may want to set it to something like `ip-address.xip.io` so you can avoid editing your hosts file to make `example.com` work. For example, `192.168.33.10.xip.io`.

Here's [another Nginx config file](https://gist.github.com/fideloper/9477321) with some extra options you may want to explore and use as well.

Once you have a configuration setup, you can symlink it to Nginx's `sites-enabled` directory and reload Nginx!

```shell
# Symlink available site to enabled site
$ sudo ln -s /etc/nginx/sites-available/example.conf /etc/nginx/sites-enabled/example.conf
# Reload Nginx config
$ sudo service nginx reload
```
Then you're site should be up and running! Be sure to check out the screencasts below for an example of this setup and some extra tricks.

## Resources

Here's how to use Nginx with our favorite languages.

* With [PHP](http://fideloper.com/ubuntu-12-04-lemp-nginx-setup), or see the screencasts below!
* With [NodeJS](http://stackoverflow.com/questions/5009324/node-js-nginx-and-now)
* With [Python](http://michal.karzynski.pl/blog/2013/06/09/django-nginx-gunicorn-virtualenv-supervisor/) - **[Gunicorn docs](http://gunicorn.org/)**
* With [Ruby on Rails](https://coderwall.com/p/yz8cha), or [Rails with Capistrano](http://ariejan.net/2011/09/14/lighting-fast-zero-downtime-deployments-with-git-capistrano-nginx-and-unicorn/) and finally [nginx+unicorn](http://sirupsen.com/setting-up-unicorn-with-nginx/) - **[Unicorn docs](http://unicorn.bogomips.org/)**
