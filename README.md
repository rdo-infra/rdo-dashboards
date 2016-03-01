Copy config.ru.in to config.ru then add your secret token to config.ru.

Then follow http://dashing.io/#setup

Add a crontab launching:

    ./feed-dashboard.sh <dashboard url> <token>
