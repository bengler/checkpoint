require 'species'

class Creature
  include Species
  attr_accessor :kind
end

describe Species do
  let(:kari) { Creature.new }

  describe "Species.to_code" do
    it "can translate :god" do
      Species.to_code(:god).should eq(Species::God)
    end

    it "can translate :admin" do
      Species.to_code(:admin).should eq(Species::Admin)
    end

    it "can translate :user" do
      Species.to_code(:user).should eq(Species::User)
    end

    it "can translate :stub" do
      Species.to_code(:stub).should eq(Species::Stub)
    end

    it "can translate :robot" do
      Species.to_code(:robot).should eq(Species::Robot)
    end
  end

  describe "human readable" do
    specify "god" do
      kari.kind = Species::God
      kari.should be_god
    end

    it "is an admin" do
      kari.kind = Species::Admin
      kari.should be_admin
    end

    it "is a user" do
      kari.kind = Species::User
      kari.should be_user
    end

    it "is a stub" do
      kari.kind = Species::Stub
      kari.should be_stub
    end

    it "is a robot" do
      kari.kind = Species::Robot
      kari.should be_robot
    end

    specify "a robot is not god" do
      kari.kind = Species::Robot
      kari.should_not be_god
    end
  end

  describe "humans" do
    [Species::Stub, Species::Admin, Species::User, Species::God].each do |code|
      it "#{Species::KINDS[code]} is human" do
        kari.kind = code
        kari.should be_human
      end
    end

    specify "robots are not human" do
      kari.kind = Species::Robot
      kari.should_not be_human
    end
  end

end
