# Gravel

Unified Push Notifications

## Installation

You can install **Gravel** using the following command:

    $ gem install gravel

## Usage

Currently, Gravel only supports APNS (but FCM support is on the list).

### APNS

Gravel uses the new APNS token based authentication so if you don't have an
APNS token, you'll need to generate one using the Apple Developer portal.

You'll also need the ID for that key, your team's ID and the bundle identifier
of your application (which should be passed as the 'topic' value - see below).

The APNS class provides the connection to APNS, you can create an instance
like this:

```ruby
apns = Gravel::APNS.new(
  key: Gravel::APNS.key_from_file('/path/to/APNsAuthKey_XXXXXXXXXX.p8'),
  key_id: 'XXXXXXXXXX',
  team_id: 'XXXXXXXXXX',
  topic: 'com.example.app'
)
```

There are also a few other parameters you can specify, you can check the
documentation for the full list but a couple that you might need are:

##### :environment

This can be set to either ```:production``` or ```:development```.

The default value is ```:development```.

##### :concurrency

This tells Gravel how many connections it should open to APNS.

One notification can be sent at a time through a connection, so opening multiple connections will improve the speed at which you can crunch through a notification task.

This is fully supported by APNS.

The default value is ```1```.

## Development

After checking out the repo, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.
