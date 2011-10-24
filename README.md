= Checkpoint

Centralized identity store and authentication broker for realms against external providers such as facebook and twitter.

An identity is a keychain, which holds a single person's keys to  many different accounts. For the moment, accounts are providers set up through omniauth, but we expect to expand on this such that a verified mobile number and/or a verified email address is also an account belonging to the identity.

If a person uses both Facebook and Twitter, it's still just one person (Identity), and this person will have a local profile for each of these providers, caching relevant data (name, url to the profile, url to the profile image).

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

Per-Kristian Nordnes and
git log --format="%an" | sort | uniq
