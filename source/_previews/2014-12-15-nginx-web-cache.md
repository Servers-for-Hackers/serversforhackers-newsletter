---
title: Nginx Web Cache
descr: Using Nginx as a Web Cache, similar to Varnish
---

Like Varnish, **Nginx is a very capable web cache**. Many administrators reach for Varnish, often before it's really needed. However, there are two things to know about Nginx:

* Nginx can serve static content (directly) very, very efficiently. This is good when the static files are on the same server as Nginx.
* Nginx can also act as a "true" cache server when placed in front of application servers, just like you might with Varnish.

While Varnish is a pure web cache with more advanced cache-specific features than Nginx, Nginx may still be a perfect match for you.

Let's see how we might set web caching up.

## Origin Server

Origin Servers are the servers that have the actual static files or dynamically generated HTML. They have two responsibilities:

* Serve the dynamic and static content when requested
* Decide how files (and potentially dynamic content) should be cached, via the HTTP cache headers

Let's pretend we have an Nginx web server, acting as an origin server. We want to make sure Nginx will serve cache headers for files that the cache server will read. The cache server will then cache the files as instructed.

Here's some settings you can use within your `server` block of a virtual host:

```
server {
    # Note that it's listening on port 9000
    listen 9000 default_server;
    
    root /var/www/;
    index index.html index.htm;

    server_name example.com www.example.com;

    charset utf-8;
    
    # Expire rules for static content

    # cache.appcache, your document html and data
    location ~* \.(?:manifest|appcache|html?|xml|json)$ {
      expires -1;
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

    location / {
        try_files $uri $uri/ =404;
    }
}
```

This origin server, listening on port 9000 for requests, will return `cache-control` headers specifying that files of certain types can be cached by any cache for the amount of time defined. Note that we treat some static files differently from others.

## Cache Server

The Cache Server is (usually) the "frontman"; It receives the intial HTTP request from a client. It then either handles the request itself (if it has a fresh cached copy of the requested resource) or passes the request off to the Origin Server to fulfill.

If the request is sent along to the Origin Server, the Original Server's resonse headers are read by the Cache Server to determine if the response should be cached or simply passed through.

Let's add the necessary items to an Nginx virtual host. The following will enable Nginx to cache responses from the Origin Server:

```nginx
# Note that these are defined outside of the server block, 
# altho they don't necessarily need to be
proxy_cache_path /tmp/nginx levels=1:2 keys_zone=my_zone:10m inactive=60m;
proxy_cache_key "$scheme$request_method$host$request_uri";

server {
    # Listening on port 80
    listen 80 default_server;
    root /var/www/;
    index index.html index.htm;

    server_name example.com www.example.com;

    charset utf-8;

    location / {
        proxy_cache my_zone;
        add_header X-Proxy-Cache $upstream_cache_status;  

        include proxy_params;

        # Our origin server listening on port 9000
        # on another server
        proxy_pass http://172.17.0.18:9000;
    }
}
```

Let's cover the cache-related items.

**proxy_cache_path**

This is the path to save the cached files.

The `keys_zone` is simply an arbitrary name of the "zone" which we refer to for this cache. It's named `my_zone` and is given 10MB of storage for cache keys and other meta data (not the cache itself).

The `inactive` directive tells Nginx to clear the cache of any asset that's not access within 60 minutes. Using `inactive` gives Nginx the opportunity to "forget" about cached assets which are not commonly requested.

**proxy_cache_key**

This is the key we use to differentiate cached files. The default is `$scheme$proxy_host$uri$is_args$args`, but we can change it if needed.

This can be set to something like `"$host$request_uri $cookie_user"` (with quotes) to incorporate cookies. 

**proxy_cache**

Inside of the `location` block, we're telling Nginx to use the cache zone defined via the `proxy_cache my_zone` directive.

We also add the `X-Proxy-Cache` header which will inform us if the resource was served from cache or not.

## More

You'll learn **a lot more** about Nginx in the Servers for Hackers [newsletter](https://serversforhackers.com) and especially in the [eBook](https://book.serversforhackers.com)!

The newsletter article about Nginx caching in particular goes into more detail. The [eBook](https://book.serversforhackers.com) will contain a guide about using Varnish as well!



