# Checkpoint

Centralized authentication broker for web applications that supports a number of authentication mechanisms and is provided via a http-interface. Checkpoint can take care of logging your users into your application and keep track of session and access privileges across services.

In a next iteration, logging in is going to be extracted into a frontend pebble. This is partly for performance purposes (identity store vs logging in have very differente usage patterns), and partly because they're different things and should, therefore, live in different places. However, that is going to happen after we've gotten the bare bones of our Cahootsware project working.

## Concepts

* Realm - the security context for your application. A given session is valid for a specific realm. Realms may span any number of services, but they should ideally be construed as a single coherent 'brand' in the mind of your users. An example realm could be "google" where all the services provided within the 'google' realm shared identities across services.
* Domain - A realm is connected to a number of domains (e.g. 'google' realm could be attached to the domains 'maps.google.com' and 'reader.google.com' and even 'youtube.com'). Checkpoint looks at the current host domain to determine the current realm when e.g. logging a user in.
* Identity - represents one specific person. An identity may have a number of accounts.
* Account - a verified account with a specific provider that can be used to log in to a specific identity.
* Provider - refers to an authentication mechanism, e.g. Twitter or Facebook.

## Basic config

To initiate authentication, you first need to have a realm with a domain set up for your application:

    require './config/environment'
    realm = Realm.create!(:label => 'example')
    Domain.create!(:realm => realm, :name => 'example.org')

Checkpoint is provided as a http-service and needs to be mapped into the url-space of your application using some proxy mechanism. The standard root url for checkpoint is:

    /api/checkpoint/v1/

In production this mapping is done with ha-proxy. In development a rack proxy will be provided.

[[TODO: Write documentation/spec for pebbles, and create a gem which can be installed and includes a bunch of useful tools to map and use pebbles in development.]]

## Typical usage

Given that your basic config is set up, your user can log in by being sent to the appropriate login action. A "Log in with twitter"-link should direct the browser to the following url:

    /api/checkpoint/v1/login/twitter

An authentication process will commence possibly taking your user via twitter to confirm their identity. If login is successful your user is returned to your application at:

    /login/succeeded

The session key for the logged in user is now stored in the cookie named 'checkpoint.session'. This is a 512 bit hash that can be used with all Pebble-compliant web-services to identify your current user and hir credentials. (Unsuccessful logins are returned to: /login/failed)

Currently Checkpoint supports the following authentication mechanisms: 

* Twitter
* Facebook
* Google
* Origo

## Sessions

The basic purpose of Checkpoint is providing and managing sessions for your users. A session in Checkpoint is represented by a 512 bit string of random garbage, the 'session string'. This string can be passed around to all pebbles compliant web services as proof of identity.

To check the identity for a specific session, this call to checkpoint could be used:

    /api/checkpoint/v1/identity/me?session=10e9pde6ww4kr5nv7y9k54kei1dj1lfe9s [...]

Pebbles expect to find the session string in one of two places. First it looks for a url-parameter named 'session', if it is not found there it will attempt to retrieve it from a cookie named 'checkpoint.session'. If neither of these are present the request will be processed without authentication.

## Known weaknesses

* The service defines a criticial single point of failure. Infrastructure should be put in place for a redundant solution – either a clustered Redis if one should become available, multiple Redis installations or a separate key-value store.

* 

## Installation

### Get the code

* Clone project from GitHub.
* (RVM) bundle install

### Set up database

    $ rake db:bootstrap
    $ rake db:seed
    $ rake db:test:prepare

This creates the postgreSQL user for the project. Notice how we're giving the user not only superpowers, but the ability to create databases. This is for automated testing purposes.

### Pagackes and dependencies

RVM will handle all gems.

#### Development
For development on Mac / Ports in order to get SSL working properly you
must set the following env. variable: export RUBYOPT='-r openssl

##### Pow

http://pow.cx/

    $ curl get.pow.cx | sh

To set up a Rack app, just symlink it into ~/.pow:
    $ cd ~/.pow
    $ ln -s /path/to/myapp


##### Testing against facebook

You won't be able to use pow for this, as it doesn't expose its port.

Log in to Tilde Nielsen's facebook account (tilde@skogsmaskin.no).
Password is the same as the local network at the office.

    `gem install localtunnel`
    `localtunnel 9292`

You'll get back a url that is publically available on the web, mapped to port 9292.
Obviously, you can pick whatever port you like.

Then you need to run the app on that port, forexample with rackup.

    `rackup -p 9292`


#### Production
See debian info below

#### Server configurations
Depends on Sinatra, Postgres, Redis Server

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

## Links to oauth providers
<table>
    <tr>
        <th>Provider</th>
        <th>Administer API keys for apps</th>
        <th>Administer authenticated apps</th>
    </tr>
    <tr>
        <td>Origo</td>
        <td>http://origo.no/-/admin/external_application</td>
        <td>n/a</td>
    </tr>
    <tr>
        <td>Google</td>
        <td>https://code.google.com/apis/console/#:access</td>
        <td>https://accounts.google.com/b/0/IssuedAuthSubTokens</td>
    </tr>
    <tr>
        <td>Twitter</td>
        <td>&lt;fill in&gt;</td>
        <td>&lt;fill in&gt;</td>
    </tr>
    <tr>
        <td>Facebook</td>
        <td>&lt;fill in&gt;</td>
        <td>&lt;fill in&gt;</td>
    </tr>
</table>

## Notes

* openID auths have problems with the Webrick server
  (http://stackoverflow.com/questions/4926740/omniauth-google-openid-webrickhttpstatusrequesturitoolarge)
  Use thin or mongrel instead when testing Google auth.
  
* OmniAuth may be picky on SSL certificates. Consult these links:
    * http://stackoverflow.com/questions/6046453/rails-3-with-mysql-and-omniauth-bug-segmentation-fault
    * http://stackoverflow.com/questions/3977303/omniauth-facebook-certificate-verify-failed
    * http://redmine.ruby-lang.org/issues/4373

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

## Authors

    git log --format="%an" | sort | uniq

Per-Kristian Nordnes
Bjørge Næss
Katrina Owen
Simen Svale Skogsrud
Thomas Drevon

