class MyProvider < Checkpoint::Strategy::Provider
  def authenticate(params)
    {
        provider: 'myprovider',
        uid: 'foo',
        name: 'Foo Bar',
        location: 'Oslo',
        image_url: 'http://gravatar.com/foo.png',
        description: 'Bar Baz Qux',
        email: 'foo@bar.com',
        nickname: 'foobar',
        profile_url: 'bar.com/foo'
    }
  end
end

Checkpoint.strategies << Checkpoint::Strategy.new([MyProvider.new])