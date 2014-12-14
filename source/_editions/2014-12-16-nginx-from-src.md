---
title: Compiling Third-Party Modules Into Nginx
topics: [Re-packaging Nginx with additional modules]
description: Learn how to add the Nginx HTTP Upload and Pagespeed modules without missing out on Debian package extras.
---

Normally in Ubuntu we might add the Nginx repository and install Nginx like so:

```shell
sudo add-apt-repository -y ppa:nginx/stable
sudo apt-get update
sudo apt-get install -y nginx
```

But if we want some extra modules, such as Google's Pagespeed or perhaps the HTTP upload module, we actually **need to recompile Nginx** with those modules.

Compiling Nginx from source [isn't actually too hard](http://wiki.nginx.org/Install), BUT we lose out on important additions the Debian package provides. 

The Debian package provided by `ppa:nginx/stable` sets up configuration to monitor and start Nginx on system boot (Upstart/SysInit), logrotate and other system needs. These are things we would otherwise need to setup manually. We don't want to skip these by installing from source!

**However, there's a way to have our cake and eat it to.** We can use the repository's package to:

1. Get the sources/dependencies used to 
2. Add our modules to the `ppa:nginx/stable` package
3. Rebuild the packages
4. Re-install Nginx

> If you already have Nginx installed, you can still proceed with the following. I would backup any `sites-available` or customer configuration first. You can remove Nginx first if you run into issues: `sudo apt-get remove nginx`.

## Get Extra Modules

Before we start to get the Nginx dependencies, we'll first download the module files.

Let's get the Pagespeed module files (latest version 1.9.32.2) [as per their docs](https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source), with a little adding of "sudo" in my case:

```shell
sudo mkdir /opt/pagespeed
cd /opt/pagespeed
NPS_VERSION=1.9.32.2
sudo wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip
sudo unzip release-${NPS_VERSION}-beta.zip
cd ngx_pagespeed-release-${NPS_VERSION}-beta/
sudo wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
sudo tar -xzvf ${NPS_VERSION}.tar.gz  # extracts to psol/
# Gives us directory /opt/pagespeed/ngx_pagespeed-release-1.9.32.2-beta
```

Then we can get the HTTP Upload Module (latest version 2.2) [as per the docs](http://wiki.nginx.org/HttpUploadModule):

```shell
sudo mkdir /opt/httpupload
cd /opt/httpuplaod
sudo wget https://github.com/vkholodkov/nginx-upload-module/archive/2.2.zip
sudo unzip 2.2.zip
# Gives us directory: /opt/httpupload/nginx-upload-module-2.2
```

## Get Nginx Sources & Dependencies

Alright, now the parts that might be more unfamiliar to you. We're going to get the Nginx packages from `ppa:nginx/stable`, adjust them, rebuild them, and then reinstall Nginx.

> This assumes you've added the `ppa:nginx/stable` repository already. Ensure that the file `/etc/apt/sources.list.d/nginx-stable-trusty.list` exists. Not that mine says "trusty" because I'm using Ubuntu Trusty (14.04).

First, edit the PPA's sources file and ensure the `deb-src` directive is not commented out. This will let us get the sources files:

```
$ cat /etc/apt/sources.list.d/nginx-stable-trusty.list 
deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main
# deb-src http://ppa.launchpad.net/nginx/stable/ubuntu trusty main
```

If, like mine, your `deb-src` line is commented out, edit that file and remove the `#`:

```
$ cat /etc/apt/sources.list.d/nginx-stable-trusty.list 
deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main
deb-src http://ppa.launchpad.net/nginx/stable/ubuntu trusty main
```

Then update:

```shell
sudo apt-get update
```

Now we can continue to get the source packages of Nginx, adjust it, build it and install it!

First we'll get the source package and any needed system dependencies:

```shell
# Install package creation tools
sudo apt-get install -y dpkg-dev

sudo mkdir /opt/rebuildnginx
cd /opt/rebuildnginx

# Get Nginx (ppa:nginx/stable) source files
sudo apt-get source nginx

# Install the build dependencies
sudo apt-get build-dep nginx
```

Then we will adjust the build files to add the extra modules. As of the time of this writing, the latest stable Nginx installed on Ubuntu Trusty is 1.6.2.

```shell
$ ls -lah /opt/rebuildnginx
drwxr-xr-x 10 root root   4096 Dec 14 16:37 nginx-1.6.2/
-rw-r--r--  1 root root 934244 Dec 14 02:10 nginx_1.6.2-5+trusty0.debian.tar.gz
-rw-r--r--  1 root root   2798 Dec 14 02:10 nginx_1.6.2-5+trusty0.dsc
-rw-r--r--  1 root root 804164 Sep 18 21:31 nginx_1.6.2.orig.tar.gz
```

To adjust add the modules into the build, edit the `/opt/rebuildnginx/nginx-1.6.2/debian/rules` file.

The `ppa:nginx/stable` has multiple Nginx packages available: `common`, `light`, `full` and `extras`. When you run `apt-get install -y nginx`, you're installing the "full" version. 

The "common" package is the base install upon which the others are built. The "lighter" package, however is in fact lighter than the "common" package due to the use of the `--without-*` flags.

For this example, we'll simply edit the "full" version to add our modules. This assumes we'll keep using the "full" package as normal when installing Nginx.

From the `rules` file, here's the "full" version configuration with our 2 new modules added at the end:

```make
full_configure_flags := \
                        $(common_configure_flags) \
                        --with-http_addition_module \
                        --with-http_dav_module \
                        --with-http_geoip_module \
                        --with-http_gzip_static_module \
                        --with-http_image_filter_module \
                        --with-http_spdy_module \
                        --with-http_sub_module \
                        --with-http_xslt_module \
                        --with-mail \
                        --with-mail_ssl_module \
                        --add-module=$(MODULESDIR)/nginx-auth-pam \
                        --add-module=$(MODULESDIR)/nginx-dav-ext-module \
                        --add-module=$(MODULESDIR)/nginx-echo \
                        --add-module=$(MODULESDIR)/nginx-upstream-fair \
                        --add-module=$(MODULESDIR)/ngx_http_substitutions_filter_module \
                        --add-module=/opt/httpupload/nginx-upload-module-2.2 \
                        --add-module=/opt/pagespeed/ngx_pagespeed-release-1.9.32.2-beta
```

Once that's edited and saved, we can build Nginx!

```shell
cd /opt/rebuildnginx/nginx-1.6.2
sudo dpkg-buildpackage -b
```

This will take a few minutes.

## Install Nginx

Once the build is complete, we'll find a bunch of `.deb` files added in `/opt/rebuildnginx`. We can use these to install Nginx. 

We adjusted the "full" package, and so we'll want to use that build to install Nginx. Looking at the `deb` files, we'll see two "full" packages:

```
nginx-full-dbg_1.6.2-5+trusty0_amd64.deb
nginx-full_1.6.2-5+trusty0_amd64.deb
```

I'm on a 64bit version of Ubuntu, so I'm using the `amd64` version. The `dbg` version is a debug version, so we'll use the other package to install Nginx:

```shell
# .deb files appear one level above the `nginx-1.6.2` directory
cd /opt/rebuildnginx
sudo dpkg --install nginx-full_1.6.2-5+trusty0_amd64.deb
```

That step should be done quickly.

Our recompiled Nginx is installed! We can use `nginx -V` (capital "V") to see which flags were used during compilation, letting us know which modules are installed:

```shell
$ nginx -V
nginx version: nginx/1.6.2
TLS SNI support enabled
configure arguments: 
    --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2' 
    # A bunch of these removed for brevity   
    --add-module=/opt/httpupload/nginx-upload-module-2.2            # yay!
    --add-module=/opt/pagespeed/ngx_pagespeed-release-1.9.32.2-beta # yay!
```

The last two are our new modules!

## Test Pagespeed

Create a cache directory for Pagespeed items:

```shell
sudo mkdir -p /var/cache/ngx_pagespeed/
```

Edit the `/etc/nginx/nginx.conf` file to enable Pagespeed.

```conf
# Stuff up here omitted
server {
    pagespeed On;
    pagespeed FileCachePath "/var/cache/ngx_pagespeed/";
    pagespeed EnableFilters combine_css,combine_javascript;

    # Stuff down here omitted
}
```

Save that, then test the configuration:

```shell
$ sudo service nginx configtest
 * Testing nginx configuration            [ OK ]

# Restart, assuming it's OK
$ sudo service nginx restart
```

I haven't gone into the details of configuring Pagespeed for your server, but there's lots of [good information on configuring Mod Pagespeed here](https://developers.google.com/speed/pagespeed/module/configuration).

For the [HTTP Upload module](http://wiki.nginx.org/HttpUploadModule), I haven't included the [HTTP Upload Progress module](http://wiki.nginx.org/HttpUploadProgressModule). You can add that into "full" manually, or add the Upload and Pagespeed modules into the "extras" package and install it. 


## Resources

* [Server Fault answer on the previous steps](http://serverfault.com/questions/227480/installing-optional-nginx-modules-with-apt-get)

<!--
Coderwall with more: (original): https://coderwall.com/p/drhh8w/nginx-add-modules-and-repack-on-debian


This will install the source files.

> One of the messages output also lets us now that these package files are located in git:
> "NOTICE: 'nginx' packaging is maintained in the 'Git' version control system at:
git://anonscm.debian.org/collab-maint/nginx.git"


# Install Nginx From Source

We want mod_pagespeed and http_upload modules in Nginx. How do we get them?

1. Pagespeed: https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
2. http://wiki.nginx.org/HttpUploadModule

# Install Deps:

```shell
sudo apt-get install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip
```

# Download what we need:

1. http://nginx.org/en/download.html
    - http://nginx.org/download/nginx-1.6.2.tar.gz
2. Two files from https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
3. http://wiki.nginx.org/HttpUploadModule
    - https://github.com/vkholodkov/nginx-upload-module/archive/2.2.zip

# Install

Check out the [ppa:nginx/stable](https://launchpad.net/~nginx/+archive/ubuntu/stable). Find the build steps for your Ubuntu. I'm using Trusty (14.04). Here's the [build log](https://launchpadlibrarian.net/192577260/buildlog_ubuntu-trusty-i386.nginx_1.6.2-5%2Btrusty0_UPLOADING.txt.gz).

We want the build "nginx-full". Search for "`cd /build/buildd/nginx-1.6.2/debian/build-full && ./configure`". Here's how they are building Nginx, including all the options:

```
cd /build/buildd/nginx-1.6.2/debian/build-full && ./configure \
    --with-cc-opt="-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2" \
    --with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro" \
    --prefix=/usr/share/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/run/nginx.pid \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --with-debug \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_auth_request_module \
    --with-http_addition_module \
    --with-http_dav_module \
    --with-http_geoip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module \
    --with-http_spdy_module \
    --with-http_sub_module \
    --with-http_xslt_module \
    --with-mail \
    --with-mail_ssl_module \
    --add-module=/build/buildd/nginx-1.6.2/debian/modules/nginx-auth-pam \
    --add-module=/build/buildd/nginx-1.6.2/debian/modules/nginx-dav-ext-module --add-module=/build/buildd/nginx-1.6.2/debian/modules/nginx-echo \
    --add-module=/build/buildd/nginx-1.6.2/debian/modules/nginx-upstream-fair \
    --add-module=/build/buildd/nginx-1.6.2/debian/modules/ngx_http_substitutions_filter_module
```

We need to add the following after downloading our modules:

```shell
    ./configure \
    # ... above items omitted ...
    --add-module=$HOME/ngx_pagespeed-release-${NPS_VERSION}-beta \
    --add-module=$HOME/nginx_upload_module
```
-->