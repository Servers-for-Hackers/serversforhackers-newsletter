---
title: All About Logs
topics: [All About Logs]
description: Logs are important for giving us detailed error and debugging information. Let's cover how to manage logs effectively!
---

Logs are important to application developers. They give us detailed error information about our applications and the systems supporting them. They also can give us clues about what may go wrong in the future.

## Where To Find Them

Logs are almost always found in `/var/log`. Usually they are owned by a privileged user and group, such as `root` or `adm`. Even if you don't have access to a privileged user (a user who can use `sudo`), you can often - but not always - read these files.

Within the `/var/log` directory, you'll find system and software logs. For example, in Debian/Ubuntu systems, you'll find your Apache access and errors logs in `/var/log/apache2`. In other OS distributions, this may be `/var/log/httpd`. Nginx logs are usually found in `/var/log/nginx`.

Not all log files are in a subdirectory. For example, if you're using PHP-FPM, you might find logs in `/var/log/php5-fpm.log`. MySQL is often similarly found at `/var/log/mysql.log` and `/var/log/mysql.err`.

Lastly, logs are often split between access (or events) and error logs. Apache, Nginx and MySQL all have separate error and access/use logs.

## Application Logs

Some web applications create their own logs. You should consult your framework's documentation to find out where they might be. The Laravel PHP framework, for example, will create logs in the `app/storage/logs` directory. To [avoid getting a WSOD upon an error](http://stackoverflow.com/questions/20678360/laravel-blank-white-screen/20682951#20682951), you should make sure that the log directory can be written to.

Log information on other popular frameworks:

* [laravel (PHP)](http://laravel.com/docs/errors#logging)
	* Uses [Monolog](https://github.com/Seldaek/monolog) under the hood
* [sailsJS (Node)](http://sailsjs.org/#!documentation/config.log)
	* Uses [Winston](https://github.com/flatiron/winston) under the hood
* [django (Python)](https://docs.djangoproject.com/en/dev/topics/logging/)
* [flask (Python)](http://flask.pocoo.org/docs/errorhandling/)
* [RoR (Ruby)](http://guides.rubyonrails.org/debugging_rails_applications.html)


## Watching Logs With Tail

Since logs may give you more error information than the browser when developing a web application, you may find it appropriate to monitor a log file. This is especially true in production environments where error reporting is turned off - they will only be displayed within log files.

To monitor a log file, we can "[tail](http://unixhelp.ed.ac.uk/CGI/man-cgi?tail)" it. This will show the last *n* lines of the file as they are written to it.

If I wanted to watch the last 50 lines of my apache error log for errors, I would run:

    tail -n 50 -f /var/log/apache2/error.log

## Virtual Hosts and Logs

If you read the previous newsletter on Apache virtual hosts, you may have noticed that I setup a [unique access and error log for each virtual host](https://gist.github.com/fideloper/2710970#file-vhost-sh-L44-L50). This lets you track the logs of just one website, rather than having multiple website events combined into one log.

For a site **example.com**, the log files might be `/var/log/apache2/example.com-access.log` and `/var/log/apache2/exampe.com-error.log`.

## Analyzing Log Files

Here are some simple examples of examining some Apache (or Nginx!) log files.

Some of the command line tools available for things like are [`grep`](http://unixhelp.ed.ac.uk/CGI/man-cgi?grep), [`zgrep`](http://unixhelp.ed.ac.uk/CGI/man-cgi?zgrep+1), [`awk`](http://www.hcs.harvard.edu/~dholland/computers/awk.html), [`cut`](http://linux.die.net/man/1/cut), [`sed`](http://www.panix.com/~elflord/unix/sed.html), [`sort`](http://unixhelp.ed.ac.uk/CGI/man-cgi?sort), [`uniq`](http://unixhelp.ed.ac.uk/CGI/man-cgi?uniq), [`head`](http://unixhelp.ed.ac.uk/CGI/man-cgi?head) and others. For example here's [how to count 404's per request in a group of access logs](http://thingelstad.com/count-404-in-group-of-access-logs/). This works for both regular and compressed (gzipped) access logs.

For more command-line tricks:

* [Analyzing Apache log files](http://www.the-art-of-web.com/system/logs/)
* [Sed and Awk examples](https://www.adayinthelifeof.nl/2010/12/11/sed-awk-examples/)

## More Advanced Analysis and Tooling

As you might imagine, there are LOTS of tools available to analyze and store logs. This becomes especially important if you have a multiple-server environment, each of which may be generating it's own collection of logs.

In situations like this, a common strategy is to combine log files to a central storage. This usually comes with a bonus of being both searchable and more easily analyzed.

Here's a list of some available logging tools:

### Self Install

* [Logstash](http://logstash.net/) - An easy to use Open Source log and event manager. Numerous people pointed out that I missed this at first. It's one of the easiest (and backed by [Elasticsearch](http://www.elasticsearch.org/)) open-source loggers!
* [Webalizer](http://www.webalizer.org/) - Good for single servers, and often found in hosting accounts, this is good for basic analyzing of web traffic from Apache logs
* [Fluentd](http://fluentd.org/) - Open source tool to collect events and logs (in JSON)
* [Graylog2](http://graylog2.org/) - This both collects logs AND analyzes them. It's a powerful tool, often used in conjunction with [Graphite](http://graphite.wikidot.com/) to create meaningful graphs based on log analysis.
	* Some information on [Graylog2 and PHP Monolog](http://jeremycook.ca/2012/10/02/turbocharging-your-logs/)
* [Splunk](http://www.splunk.com/) - Enterprisey

### PaaS

* [Loggly](https://www.loggly.com/)
* [Airbrake.io](https://airbrake.io/)
* [Sumplogic](http://www.sumologic.com/) - Enterprisey
* [Papertrail](https://papertrailapp.com/)
* [Logentries](https://logentries.com/)
* [Splunk Storm](https://www.splunkstorm.com/) - SaaS for Splunk

### Lastly

Here's an interesting idea on logging: [Fingers Crossed](http://zeroturnaround.com/rebellabs/attack-of-the-logs-consider-building-a-smarter-log-handler/) logging is the idea of only saving logs which are near errors. If logs do not appear near errors, they are (eventually) discarded.

For PHP readers, [Monolog](https://github.com/Seldaek/monolog) has a [ton of handlers](https://github.com/Seldaek/monolog/tree/master/src/Monolog/Handler) which may clue you into other services or ideas on how to handle logging.

For AWS users, Elastic Load Balancers [will finally have Access logs and other data available](http://aws.typepad.com/aws/2014/03/access-logs-for-elastic-load-balancers.html)!

## Resources

* [Log Resources for Distributed Environments](http://fideloper.com/web-app-load-balancing) (scroll to the bottom)

## Quick Log Analysis:

<iframe src="//player.vimeo.com/video/87936191" width="100%" height="517" style="width:100%" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>