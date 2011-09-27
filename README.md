Keeper of Gates
Centralized identity store and authentication broker for realms against external providers such as facebook and twitter.
Acts as a persistent atomic cache for realms through different web services, limited to what the individual gates need to operate responsive at the moment, and what the user allows.

When we think of an Identity within the Realm it's a real person somewhere, and not necessarily a user within our system (yet).

An identity is all about authentications initiated by that person, on how exposed that person want's to be within the actual realm.

If a person uses both Facebook and Twitter, it's still just one person (Identity), and this person will have a local profile for each of these providers, caching relevant data.

There are different kinds of people (robots are people too!)

```
Species::Robot = -1
Species::Stub = 0
Species::User = 1
Species::Admin = 2
Species::God = 9
```

### It's more important to have an authentication with an access_token for that user...

...to a spesific data source. Then we can collect data about this user at any time,
and make them available fast in the Redis storage. Key data (uids'n'stuff) are
saved in postgres though. 

Data put into Redis must always be recreateable from postgres data or third party API's!

The point of Redis storage is to make collections and atomic data available fast, and keep
them permanent just as long as we need to.

## Installation

### Get the code

* Clone project from GitHub.

* (RVM) bundle install

### Set up database

thor development:setup

This creates the postgreSQL user for the project. Notice how we're giving the user not only superpowers, but the ability to create databases. This is for automated testing purposes

### Pagackes and dependencies

RVM will handle all gems.

#### Development
For development on Mac / Ports in order to get SSL working properly you
must set the following env. variable: export RUBYOPT='-r openssl

#### Testing
Katrina, help! :)

#### Production
See debian info below

#### Services
There are some background tasks that always should be running:

* rake jobs:work (process all delayed jobs)

In production mode these should be monitored (see Monit configurations)

#### Tasks
Refer to ```thor -T``` and ```rake -T```
There is also a cron helper (Wheneverize) installed.
Take a look in ```/config/schedule.rb```

#### Server configurations
Depends on Rails 3, Postgres, Redis Server

##### Linux (Ubuntu) setup

###### User and group:

```
  sudo groupadd checkpoint
  useradd -g checkpoint checkpoint  
  sudo mkdir /srv/checkpoint && cd /srv/checkpoint && sudo chmod 775 checkpoint && sudo chown checkpoint:checkpoint checkpoint
  sudo mkdir /srv/checkpoint/releases && sudo chown checkpoint:checkpoint /srv/checkpoint/releases && sudo chmod 775 /srv/checkpoint/releases  
  sudo mkdir /srv/checkpoint/shared && sudo chown checkpoint:checkpoint /srv/checkpoint/shared && sudo chmod 775 /srv/checkpoint/shared
  sudo mkdir /srv/checkpoint/shared/log && sudo chown checkpoint:checkpoint /srv/checkpoint/shared/log && sudo chmod 775 /srv/checkpoint/shared/log

```

###### Packages / Dependencies:

Install packages:

```
  sudo apt-get install libxml2 libxml2-dev libxslt1.1 libxslt1-dev libruby1.9 zlib1g-dev libssl-dev libreadline5-dev
   build-essential
```

###### RVM / Bundle / Thor:

```
  sudo bash < <(curl -s https://rvm.beginrescueend.com/install/rvm) 
  sudo /usr/local/rvm/bin/rvm install 1.9.2
  sudo /usr/local/rvm/bin/rvm --default use 1.9.2
  sudo [vi|vim|nano] /etc/profile
    Add: [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
  cd /tmp
  wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.5.tgz
  tar -zxvf rubygems-1.8.5.tgz
  cd rubygems-1.5.2
  sudo ruby setup.rb
  sudo gem install bundler
  sudo gem install thor
  sudo gem install daemonizer ##
  sudo gem install daemons

  sudo rvm --default use 1.9.2-p290

```

Remember to add developer users to the checkpoint group:

```
  usermod -G checkpoint [username]

```

###### Miscellaneous setups:

Have a look in config/deploy.rb to see how the app is deployed on a server.

####### Redis

Compile from source:

mkdir /srv/checkpoint/shared/redis/tmp
cd /srv/checkpoint/shared/redis/tmp
wget http://redis.googlecode.com/files/redis-2.2.11.tar.gz
tar xzf redis-2.2.11.tar.gz
cd redis-2.2.11
make
cp sudo cp redis-server /usr/bin/redis-server

```

Configure Redis server conf. as something like this:
```      
port 6379
dbfilename /srv/checkpoint/shared/redis/checkpoint.rdb
logfile /srv/checkpoint/shared/log/redis.log
```

####### Monit

Configs for daemons can be found in /config/monit.conf


## Notes

* openID auths have problems with the Webrick server
  (http://stackoverflow.com/questions/4926740/omniauth-google-openid-webrickhttpstatusrequesturitoolarge)
  Use thin or mongrel instead when testing Google auth.
  
* OmniAuth may be picky on SSL certificates. Consult these links:
    * http://stackoverflow.com/questions/6046453/rails-3-with-mysql-and-omniauth-bug-segmentation-fault
    * http://stackoverflow.com/questions/3977303/omniauth-facebook-certificate-verify-failed
    * http://redmine.ruby-lang.org/issues/4373

* Delayed Job + Puppet / Monit / Whenever / CronD
  See ./script/delayed_job, ./config/initializers/delayed_job and ./config/schedule.rb
  * http://rubydoc.info/gems/delayed_job/
  * https://github.com/javan/whenever
  * http://asciicasts.com/episodes/171-delayed-job
  * http://stackoverflow.com/questions/1226302/how-to-monitor-delayed-job-with-monit
  * http://gist.github.com/175866
  * https://github.com/collectiveidea/delayed_job/issues/7
  * http://www.bencurtis.com/2011/04/auto-spawning-delayed-job-workers/


### Ohm
  * http://blog.citrusbyte.com/2010/04/12/mixing-ohm-with-activerecord-datamapper-and-sequel/
  
### GeoKit
  * https://github.com/andre/geokit-gem

## Links (not yet sorted)  
* https://github.com/intridea/omniauth/wiki/Dynamic-Providers
* http://www.ur-ban.com/blog/2011/04/30/devise-omniauth-dynamic-providers/
* http://blog.joshsoftware.com/2010/12/16/multiple-applications-with-devise-omniauth-and-single-sign-on/
* http://www.railsatwork.com/2010/10/implementing-oauth-provider-part-1.html
* http://stackoverflow.com/questions/3977303/omniauth-facebook-certificate-verify-failed
* http://stackoverflow.com/questions/5533064/omniauth-dynamic-callback-url-to-authenticate-particular-objects-instead-of-curre
* http://groups.google.com/group/omniauth/browse_thread/thread/4d99d608af904879
* http://www.kbedell.com/2011/03/08/overriding-omniauth-callback-url-for-twitter-or-facebook-oath-processing/
* http://developers.facebook.com/docs/authentication/permissions/
* http://www.mikepackdev.com/blog_posts/2-dynamically-requesting-facebook-permissions-with-omniauth
* https://github.com/intridea/omniauth/issues/259
* http://www.kbedell.com/2011/03/08/overriding-omniauth-callback-url-for-twitter-or-facebook-oath-processing/
* http://dira.ro/2010/11/30/omniauth-strategy-for-everything-else
* http://blog.blenderbox.com/2011/01/07/installing-rvm-ruby-rails-passenger-nginx-on-centos/
* http://rubydoc.info/gems/delayed_job/2.1.4/frames
* http://playnice.ly/blog/2010/05/05/a-fast-fuzzy-full-text-index-using-redis/
* http://pivotallabs.com/users/jdean/blog/articles/1419-building-a-fast-lightweight-rest-service-with-rails-3
* http://blog.assimov.net/post/2358661274/twitter-integration-with-omniauth-and-devise-on-rails-3
* http://ohm.keyvalue.org/
* http://www.paperplanes.de/2009/10/30/how_to_redis.html
* http://www.funonrails.com/2011/03/monitor-delayedjob-in-rails.html
* http://www.ubuntugeek.com/monitoring-ubuntu-services-using-monit.html
* http://css3wizardry.com/2010/07/13/css3-page-flips/


## TODO:
* Dereference Person data (Redis) after user destroy / make auth/terminate clean up data in redis storage.
* Fix No route matches "/auth/google/callback" and that whole weird open auth business.
* Make a /apps/1/terms/ (something) (priv.pol. etc) to show a custom priv.policy for the app.
* Play with https://github.com/jnunemaker/twitter and especially geo data tweets (TwitterClient).

And of course (!):

* + grep for TODO: in the project

## Greetinx!

* Alex 4 p2p!
* Simen for the thinking of Users as Identitys in Origo.
* Everyone involved in any software or code which this humble project depends on.
* Please check out the links!

## Author
Per-Kristian Nordnes
Origogruppen AS
https://github.com/skogsmaskin
http://origo.no
