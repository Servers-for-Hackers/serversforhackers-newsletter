---
title: A quick look at PHP-FPM Configuration
descr: See some basics on PHP-FPM cofiguration!
---

PHP-FPM provides another popular way to use PHP. Rather than embedding PHP within Apache, PHP-FPM allows us to run PHP as a separate process. 

PHP-FPM is a FastCGI implementation for PHP. When the web server detects a PHP script is called, it can hand that request off (proxy it) to PHP-FPM using the FastCGI protocol.

## Configuring PHP-FPM

Configuration for PHP-FPM is all contained within the `/etc/php5/fpm` directory:

```bash
$ cd /etc/php5/fpm
$ ls -la
drwxr-xr-x 4 root root  4096 Jun 24 15:34 .
drwxr-xr-x 6 root root  4096 Jun 24 15:34 ..
drwxr-xr-x 2 root root  4096 Jun 24 15:34 conf.d
-rw-r--r-- 1 root root  4555 Apr  9 17:26 php-fpm.conf
-rw-r--r-- 1 root root 69891 Apr  9 17:25 php.ini
drwxr-xr-x 2 root root  4096 Jun 24 15:34 pool.d
```

As you can see, the FPM configuration includes the usual `php.ini` file and `conf.d` directory. FPM also includes a global configuration file `php-fpm.conf` and the `pool.d` directory. The `pool.d` directory contains configurations for FPM's resource pools. The default `www.conf` file defines the default pool.

### Global Configuration

The first thing we'll look at is FPM's global configuration, found at `/etc/php5/php-fpm.conf`. Unless making specific performance tweaks, **I leave this file alone**. There's still some interesting information we can gleam from this.

#### daemonize = yes

Run PHP-FPM as a daemon, in the background. Setting this to 'no' would be a less common use case. Uses for not daemonizing may include:

1. Debugging
2. Use within a Docker container
3. Monitoring FPM with a monitor which prefers processes are not run as a daemon

#### include=/etc/php5/fpm/pool.d/*.conf

Include any configuration files found in `/etc/php5/fpm/pool.d` which end in the `.conf` extension. By default, there is a `www.conf` pool, but we can create more if needed. More on that next.

### Resource Pools

Here's where PHP-FPM configuration gets a little more interesting. We can define separate resource "pools" for PHP-FPM. Each pool represents an "instance" of PHP-FPM, which we can use to send PHP requests to. 

Each resource pool is configured separately.

The default `www` pool is typically all that is needed. However, you might create extra pools to run PHP application as a different Linux user. This is useful in shared hosting environments.

If you want to make a new pool, you can add a new `.conf` file to the `/etc/php5/fpm/pool.d` directory. It will get included automatically when you restart PHP-FPM.

Let's go over some of the interesting configurations in a pool file.

#### Pool name: www

At the **top** of the config file, we define the name of the pool in brackets: [www]. This one is named "www". The pool name needs to be unique per pool defined. 

#### user=www-data & group=www-data

If they don't already exist, the php5-fpm package will create a `www-data` user and group. This user and group is assigned as the run-as user/group for PHP-FPM's processes. 

#### listen = /var/run/php5-fpm.sock

By default, PHP-FPM listens on a Unix socket found at `/var/run/php5-fpm.sock`.

Changing this to a TCP socket might look like this:

```nginx
listen = 127.0.0.1:9000
```

This listens on the loopback network interface (localhost) on port 9000.

#### listen.allowed_clients = 127.0.0.1

If you are using a TCP socket, then this setting is good for security. It will only allow connections from the listed addresses. By default, this is set to "all", but you should lock this down as appropriate.

You can define multiple addresses. If you need your loopback (127.0.0.1) network AND another server to connect, you can do both:

```nginx
# Multiple addresses are comma-separated
listen.allowed_clients = 127.0.0.1, 192.168.12.12
```

## More

This is only touching the surface of what you can configure in PHP-FPM!

The Servers for Hackers eBook also covers process management in depth, giving you the ability to get more performance out of servers with more power.



