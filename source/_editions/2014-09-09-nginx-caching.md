---
title: Nginx Caching
topics: [Nginx Caching]
description: See how to cache both dynamic and static content using Nginx!
---

Like Varnish, **Nginx is a very capable web cache**. Many administrators reach for Varnish, often before it's really needed. However, there are two things to know about Nginx:

* Nginx can serve static content (directly) very, very efficiently. This is good when the static files are on the same server as Nginx.
* Nginx can also act as a "true" cache server when placed in front of application servers, just like you might with Varnish.

While Varnish is a pure web cache with more advanced cache-specific features than Nginx, Nginx may still be a perfect match for you.

If your traffic warrants adding a layer of infrastructure for caching, but not the overhead of introducing new technologies that need to be learned and maintained, Nginx might be a better fit.

This is especially true if you happen to use Nginx Plus, which comes with support and extra features.

## Use Cases

Nginx handles static content well on it's own. This is a typical use case of a web server, rather than a cache server. However, since Nginx can proxy requests to other web servers or to applications (via HTTP, FastCGI and uWSGI), it's commonly used to increase performance for serving static files while proxying application requests to other processes.

> This is a common architecture, but users of PHP might be used to Apache + Apache's `mod_php`, which puts PHP "inside of" Apache, making it seem like everything is in one magical (but less efficient) place.

In addition to its ability to serve static files directly, Nginx can act as a cache server - what this means is that Nginx can cache content received from *other servers*.

The following use-cases are some popular ones for using Nginx as a cache server:

* Nginx can sit "in front of" web servers, which may be other Nginx installations or web applications. This is a typical use case for a Cache Server - it acts as a gateway to other web/application servers, similar to a load balancer.
    * Nginx caching can be used in conjunction with a load balancer. 
    * Actually, Nginx can act as both a load balancer and a cache server!
* Nginx can *also* cache the results of requests proxied to FastCGI and uWSGI processes, in addition to other HTTP servers/listeners! A good use case is to cache the results from CMSes, where most users don't require the dynamic aspects of the site - they just want to see the content.

**The main benefit of a cache server** is that we put less load on our application servers. Requests for static or dynamic assets that are cached need not even reach the application (or static content) servers - our cache server can handle many requests all by itself!

In the example here, we'll put an Nginx cache server in front of another server which uses Nginx to serve a static site.

## How It Will Work

First you need to know what the **Origin Server** is. 

Origin Servers are the servers that have the actual static files or dynamically generated HTML. They have two responsibilities:

* Serve the dynamic and static content when requested
* Decide how files (and potentially dynamic content) should be cached, via the HTTP cache headers

Then we have the **Cache Servers**. 

The Cache Server is (usually) the "frontman"; It receives the intial HTTP request from a client. It then either handles the request itself (if it has a fresh cached copy of the requested resource) or passes the request off to the Origin Server to fulfill.

If the request is sent along to the Origin Server, the Original Server's resonse headers are read by the Cache Server to determine if the response should be cached or simply passed through.

> Some larger web applications use load balancers in addition to cache servers, resulting in a highly layered infrastructure.

Responsibilities of the Cache Server:

* Determine if HTTP request will accept a cached response, and if there's a fresh item in the cache to respond with
* Send HTTP request to the Origin Server if the request shouldn't be cached or if its cached item is stale
* Respond with HTTP responses from its cache or from the origin server as approprtiate.

Our last actor here is the **Client**. Clients can have their own local (private) cache - every browser has one for example. Our browser might cache a response itself (commonly images, CSS and JS files) and so never actually even send a request to the Cache Server for a static file if it already has fresh version in its local cache.

A client which implements a local cache has the following responsibilities:

* Sending requests
* Caching responses
* Deciding to pull requests from local cache or making HTTP request to retrieve them

## Origin Server

The origin server is ultimately responsible for serving files and controlling how files are to be cached.

> Clients can request that assets aren't cached, which Cache Servers "must" comply with according to HTTP specifications. 
> 
> Additionally, Clients requesting cachable assets "must" follow the caching parameters sent back from an Origin Server, which may include the instruction to not cache the result!

What this means is that we need to determine how files are cached on our origin servers. To do this, I usually use H5BP's Nginx server configuration by copying the [`h5bp` configuration directory](https://github.com/h5bp/server-configs-nginx/tree/master/h5bp) to `/etc/nginx/h5bp`.

After copying H5BP's files, I can then include the `basic.conf` configuration inside of my origin server's Nginx virtual host:

```nginx
server {
    # Note that it's listening on port 9000
    listen 9000 default_server;
    root /var/www/;
    index index.html index.htm;

    server_name example.com www.example.com;

    charset utf-8;
    include h5bp/basic.conf;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

The most relevant H5BP configuration file for our purposes here is [`expires.conf`](https://github.com/h5bp/server-configs-nginx/blob/master/h5bp/location/expires.conf), which determines caching behavior for common files:

```nginx
# Expire rules for static content

# cache.appcache, your document html and data
location ~* \.(?:manifest|appcache|html?|xml|json)$ {
  expires -1;
  # access_log logs/static.log; # I don't usually include a static log
}

# Feed
location ~* \.(?:rss|atom)$ {
  expires 1h;
  add_header Cache-Control "public";
}

# Media: images, icons, video, audio, HTC
location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$ {
  expires 1M;
  access_log off;
  add_header Cache-Control "public";
}

# CSS and Javascript
location ~* \.(?:css|js)$ {
  expires 1y;
  access_log off;
  add_header Cache-Control "public";
}
```

The above configuration disables caching for `manifest`, `appcache`, `html`, `xml` and `json` files. It caches `RSS` and `ATOM` feeds for 1 hour, `Javascript` and `CSS` files for 1 year, and other static files (`images` and `media`) for 1 month. 

The caches are all set to "public", so that any system can cache them. Setting them to private would limit them to being cached by private caches, such as our browser.

So the origin server isn't doing any caching itself, it's just saying how files should be cached based on file extension. H5BP provides a good baseline to set cache rules for you.

If we make requests to the Origin Server directly, we can see those rules in effect.

> The Origin Server I setup to test this happens to be running at `127.17.0.18:9000`

Files ending in `.html` are not to be cached. We can see the response saying as much:

```bash
# GET curl request and select response headers
$ curl -X GET -I 127.17.0.18:9000/index.html
HTTP/1.1 200 OK
Server: nginx/1.4.6 (Ubuntu)
Date: Fri, 05 Sep 2014 23:24:52 GMT
Content-Type: text/html
Last-Modified: Fri, 05 Sep 2014 22:16:24 GMT
Expires: Fri, 05 Sep 2014 23:24:52 GMT
Cache-Control: no-cache
```

Note that `Expires` is the same as the `Date` of the request, signifying that this expires immediately - effectively telling clients not to cache this. The response also *specifically* says not to cache the response via the `Cache-Control: no-cache` header. This is perfectly following our rules for `.html` files as set by the H5BP `expires.conf` configuration.

Next we can try to get a file that **is** set to be cached:

```bash
# GET curl request and select response headers
$ curl -X GET -I 127.17.0.18:9000/css/style.css
HTTP/1.1 200 OK
Server: nginx/1.4.6 (Ubuntu)
Date: Fri, 05 Sep 2014 23:25:04 GMT
Content-Type: text/css
Last-Modified: Fri, 05 Sep 2014 22:46:39 GMT
Expires: Sat, 05 Sep 2015 23:25:04 GMT
Cache-Control: max-age=31536000
Cache-Control: public
```

We can see that this css file expires 1 year after the current date! The cache rules are set with a `max-age` of ~1 year in seconds and allows public caches. One again, this is following our rules for `.css` files as set by the H5BP `expires.conf` configuration.

Great, so the Origin Server is all set!

## Cache Server

The Origin Server is setup, but we need to implement a cache server to sit "in front of" the Origin Server. In our scenario here, the Cache Server will be the web server receiving requests. It will pass HTTP requests off to the Origin Server if it doesn't serve files directly from it's cache.

On a new installation of Nginx on an other server, we can first look at a "standard" reverse proxy setup. The follow is not implementing any caching yet, it will simply proxy requests to the Origin Server:

```nginx
server {
    # Note that it's listening on port 80
    listen 80 default_server;
    root /var/www/;
    index index.html index.htm;

    server_name example.com www.example.com;

    charset utf-8;

    location / {
        include proxy_params;
        proxy_pass http://172.17.0.18:9000;
    }
}
```

This is simply proxying requests to our Origin Server.

> The Cache server I setup for testing is listening on `172.17.0.13:80`

If we make a request on our Cache Server, we'll see exactly what we'd see as if we hit the Origin Server itself. This is because the Cache Server is currently not caching - it's just passing requests through to the Origin Server:

```bash
$ curl -X GET -I 172.17.0.13/css/style.css
HTTP/1.1 200 OK
Server: nginx/1.4.6 (Ubuntu)
Date: Fri, 05 Sep 2014 23:30:07 GMT
Content-Type: text/css
Last-Modified: Fri, 05 Sep 2014 22:46:39 GMT
Expires: Sat, 05 Sep 2015 23:30:07 GMT
Cache-Control: max-age=31536000
Cache-Control: public
```

Now let's add the necessary items to have Nginx cache responses from the Origin Server. The following is the same virtual host we saw above, defined on the Cache Server, but with the additional Cache directives needed by Nginx to act as a Cache Server:

```nginx
# Note that these are defined outside of the server block, 
# altho they don't necessarily need to be
proxy_cache_path /tmp/nginx levels=1:2 keys_zone=my_zone:10m inactive=60m;
proxy_cache_key "$scheme$request_method$host$request_uri";

server {
    # Note that it's listening on port 80
    listen 80 default_server;
    root /var/www/;
    index index.html index.htm;

    server_name example.com www.example.com;

    charset utf-8;

    location / {
        proxy_cache my_zone;
        add_header X-Proxy-Cache $upstream_cache_status;  

        include proxy_params;
        proxy_pass http://172.17.0.18:9000;
    }
}
```

Let's cover the new items here.

**proxy_cache_path**

This is the path to save the cached files. The `levels` directive sets how cache files are saved to the file system. If this is not defined, cache file are saved directly in the path defined. If it is defined as such (`1:2`), cache files are saved in sub-directories of the cache path based on their md5 hashes.

The `keys_zone` is simply an arbitrary name of the "zone" which we refer to for this cache. It's named `my_zone` and is given 10MB of storage for cache keys and other meta data, although that doesn't limit the amount of files that can be cached! It's just for meta data. The documentation claims that a 1MB zone can store ~8000 keys and meta data.

Finally we set the `inactive` directive, which tells Nginx to clear the cache of any asset that's not access within 60 minutes. Note that `60m` here is 60 minutes, while `10m` for `keys_zone` is 10 megabytes. The `inactive` directive defaults to 10 minutes if it is not explicitly set.

Using `inactive` gives Nginx the opportunity to "forget" about cached assets which are not commonly requested. This way Nginx caching gives the most bang for your buck - the most requested resources stay in the cache (and follow cache rules as directed by the Origin Server).

**proxy_cache_key**

This is the key we use to differentiate cached files. The default is `$scheme$proxy_host$uri$is_args$args`, but we can change it if needed.

This can be set to something like `"$host$request_uri $cookie_user"` (with quotes) as well to incorporate cookies. 

*Cookies do affect caching, so be careful of your treatment with them*! You may accidentally end up with a file being cached in duplicate per indivisual cookie (effectively per site visitor) if the cookie is incorporated into the cache key. 

This means that incorporating cookies into the cache key does reduce the effectiveness of the cache. A cache per user is the purpose of a private cache (a web browser) rather than the "public" cache server we're building here. However there may be use cases in which you want to incorporate cookies; the option is available to you.

**proxy_cache**

Inside of the `location` block, we're telling Nginx to use the cache zone defined via the `proxy_cache my_zone` directive.

We also add a useful header which will inform us if the resource was served from cache or not. This is done via the `add_header X-Proxy-Cache $upstream_cache_status` directive. This sets a response header named `X-Proxy-Cache` with a value of either `HIT`, `MISS`, or `BYPASS`

Once this is saved, we can reload the Nginx's configuration (`sudo service nginx reload`) and try our HTTP requests again.

Here we attempt to get a CSS file for the first time:

```bash
# GET curl request and selected headers
$ curl -X GET -I 172.17.0.13/css/style.css
Date: Fri, 05 Sep 2014 23:50:12 GMT
Content-Type: text/css
Last-Modified: Fri, 05 Sep 2014 22:46:39 GMT
Expires: Sat, 05 Sep 2015 23:50:12 GMT
Cache-Control: max-age=31536000
Cache-Control: public
X-Proxy-Cache: MISS
```

This is a cache `MISS` because the file has not been requested before. Therefore the Cache server needed to proxy the request to the Origin Server to get the resource.

Let's try it again:

```bash
# GET curl request and selected headers
$ curl -X GET -I 172.17.0.13/css/style.css
Date: Fri, 05 Sep 2014 23:50:48 GMT
Content-Type: text/css
Last-Modified: Fri, 05 Sep 2014 22:46:39 GMT
Expires: Sat, 05 Sep 2015 23:50:12 GMT
Cache-Control: max-age=31536000
Cache-Control: public
X-Proxy-Cache: HIT
```

We can see that I requested this within ~30 seconds of the first request. We can see it was a cache `HIT` via the `X-Proxy-Cache` header.

The `Expires` header remains unchanged, as Nginx simply returned the resource from it's cache. Those headers will update the next time the Cache Server goes back to the Origin Server to get a fresh copy of the file.

As this stands now, Nginx will ignore a client's `Cache-Control` request header. However, we want our Cache Server to account for web clients which specify that they don't want a cached item.

For example if use our browser and hold down SHIFT while clicking the reload button, our browser will send a `Cache-Control: no-cache` request header. This asks the Cache Server to NOT serve a cached version of the resource. Our setup right now will ignore that.

In order to properly bypass the cache when requested to, we can add the `proxy_cache_bypass  $http_cache_control` directive to our Cache Server in the `location` block:

```nginx
location / {
    proxy_cache my_zone;
    proxy_cache_bypass  $http_cache_control;
    add_header X-Proxy-Cache $upstream_cache_status;  

    include proxy_params;
    proxy_pass http://172.17.0.18:9000;
}
```

After saving and reloading Nginx's configuration, we can test that this works:

```bash
$ curl -X GET -I 172.17.0.13/css/style.css
...
X-Proxy-Cache: HIT     # A regular request which is normally a cache HIT ...

$ curl -X GET -I -H "Cache-Control: no-cache" 172.17.0.13/css/style.css
...
X-Proxy-Cache: BYPASS  # ... is now bypassed when told to
```

The `proxy_cache_bypass` directive will inform Nginx to honor the `Cache-Control` header in HTTP requests.

## Proxy Caching

Nginx's cache is powerful! We just saw that it can cache proxied HTTP requests, however it can also cache the results of FastCGI, uWSGI proxied requests and even the results of [load balanced](https://serversforhackers.com/editions/2014/03/25/nginx/#nginx-as-a-load-balancer "nginx load balancing") requests (requests sent "upstream"). This means we can cache the results of requests to our dynamic applications.

If we use Nginx to cache the results of a FastCGI process, we can think of the FastCGI process as the Origin Server and Nginx as the Cache Server. For example, on `fideloper.com` I cache the HTML results given back from PHP-FPM. 

Here's a fancier (not exactly what I have in production, but close) example of using `fastcgi_cache`:

```nginx
fastcgi_cache_path /tmp/cache levels=1:2 keys_zone=fideloper:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";

server {

    # Boilerplay omitted

    set $no_cache 0;

    # Example: Don't cache admin area
    # Note: Conditionals are typically frowned upon :/
    if ($request_uri ~* "/(admin/)")
    {
        set $no_cache 1;
    }

    location ~ ^/(index)\.php(/|$) {
            fastcgi_cache fideloper;
            fastcgi_cache_valid 200 60m; # Only cache 200 responses, cache for 60 minutes
            fastcgi_cache_methods GET HEAD; # Only GET and HEAD methods apply
            add_header X-Fastcgi-Cache $upstream_cache_status;
            fastcgi_cache_bypass $no_cache;  # Don't pull from cache based on $no_cache
            fastcgi_no_cache $no_cache; # Don't save to cache based on $no_cache

            # Regular PHP-FPM stuff:
            include fastcgi.conf; # fastcgi_params for nginx < 1.6.1
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param LARA_ENV production;
    }
}    
```

I won't cover what's going on there, but you can see there are more options to play with when setting up your cache!

Note that for using caching with `FastCGI` cache, I did the following:

* Replaced all instances of `proxy_cache` with `fastcgi_cache`
* Used `fastcgi_cache_valid 200 60m` to set the expiration times on responses from PHP requests.

You can see this in action:

```bash
$ curl -X GET -I fideloper.com/index.php
...
Cache-Control: max-age=86400, public
X-Fastcgi-Cache: MISS

$ curl -X GET -I fideloper.com/index.php
...
X-Fastcgi-Cache: HIT

# If this URL existed, you'd see a BYPASS
$ curl -X GET -I fideloper.com/admin
...
X-Fastcgi-Cache: BYPASS
```

## Resources

You can do a lot more with caching, such as setting up situation where caching should not be done (Admin areas, for example), and methods for purging the cache.

* [Learn about Web Caches](https://www.mnot.net/cache_docs/) from Mr Caching himself, Mark Nottingham. This should be required reading for all web developers (along with the [HTTP Specification](http://www.w3.org/Protocols/rfc2616/rfc2616.html)).
* [Nginx Admin Guide on Caching](http://nginx.com/resources/admin-guide/caching/)
* [HTTP Cache Docs](http://nginx.org/en/docs/http/ngx_http_proxy_module.html)
* [FastCGI Cache docs](http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)
* [uWSGI Cache Docs](http://nginx.org/en/docs/http/ngx_http_uwsgi_module.html)

<!--
## Situation (load balancing, reverse proxying)

Example LBing Nginx, proxying to some other servers

## Cache some files

Nginx frontman:

```nginx
# Nginx config from server 172.17.0.5
location / {                                                                   
    include proxy_params;
    proxy_pass http://172.17.0.2;
}
```

Nginx backend:
```nginx
# This is just normal, for static files
location / {
    try_files $uri $uri/ =404;
}

# This adds cache directives for static assets
include h5bp;
```

Add cache stuff:

```nginx
# Nginx config from server 172.17.0.5

proxy_cache_path /tmp/nginx keys_zone=my_zone:10m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";

server {
    #...stuff

    location / {
        proxy_cache my_zone;
        include proxy_params;
        fastcgi_ignore_headers Set-Cookie;
        add_header X-Cache $upstream_cache_status;
        proxy_pass http://172.17.0.2;
    }
}
```

Check header to see if cache was a hit or miss. Note that this tracks cache settings.

**Add cache settings from Upstream! Need some cache stuff, perhaps from H5BP**

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
-->