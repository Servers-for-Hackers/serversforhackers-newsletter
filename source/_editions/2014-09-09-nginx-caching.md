---
title: Nginx Caching
topics: [Nginx Caching]
description: See how to cache both dynamic and static content from servers that Nginx proxies from.
draft: true
---

http://nginx.com/resources/admin-guide/caching/

## Use Cases:

Nginx handles static content well on it's own - in fact, in man cases Nginx is just as good as having Varnish (you may want to consider using Nginx in front of your other applications which may also use Nginx to proxy off too applications.

Nginx can act as a cache server - what this means is that Nginx can cache content received from other servers (in addition to its ability to serve static files directly).

* Good to sit in front of other web apps, which may also use Nginx themselves
* Good for smaller apps for capturing HTML responses which don't change often (CMSes) - can capture results of any proxying, from other HTTP servers, FastCGI and uWSGI servers

## Situation (load balancing)

Example LBing Nginx, proxying to some other servers

## Cache some files

* cache levels, zone, other settings -> http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_cache_path
* cache key
* Ignore or incorporate Cookies
* Add headers
* cache bypass
* Other stuff?

>  all active keys and information about data are stored in a shared memory zone, whose name and size are configured by the keys_zone parameter. One megabyte zone can store about 8 thousand keys.

> Cached data that are not accessed during the time specified by the inactive parameter get removed from the cache regardless of their freshness. By default, inactive is set to 10 minutes.



## Cache results of PHP requests

Avoid hitting your server by caching response

```
fastcgi_cache_path /tmp/cache levels=1:2 keys_zone=fideloper:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
```

```
set $no_cache 0;

# LOL IF STATEMENT OF DOOM
if ($request_uri ~* "/(admin/)")
{
    set $no_cache 1;
}

location ~ \.php$ {
        fastcgi_cache fideloper;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_methods GET HEAD;
        fastcgi_ignore_headers Set-Cookie;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;

        add_header X-Fastcgi-Cache $upstream_cache_status;

        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
}
```
