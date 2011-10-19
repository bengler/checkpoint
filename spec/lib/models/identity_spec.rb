require 'spec_helper'

describe Identity do
  let(:atle) { Identity.new }

  context "with existing account" do
    let(:user) { Identity.create(:realm_id => 1) }
    before :each do
      # get rid of incidental stuff in initializer
      TwitterClient.any_instance.stub(:configure)
    end
  end

end
