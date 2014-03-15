#!/bin/bash

# Replace "sculpin generate" with "php sculpin.phar generate" if sculpin.phar
# was downloaded and placed in this directory instead of sculpin having been
# installed globally.

php ./sculpin.phar generate --env=prod
if [ $? -ne 0 ]; then echo "Could not generate the site"; exit 1; fi

rsync -vzrS output_prod/ fido@fidbot:/var/www/serversforhackers.com/public
if [ $? -ne 0 ]; then echo "Could not publish the site"; exit 1; fi
