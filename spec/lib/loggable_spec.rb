require 'spec_helper'
require 'stringio'
require 'loggable'
require 'timecop'

class TheThing
  include Loggable

  def initialize
    self.logger = CheckpointLogger.use(:the_thing)
  end
end

describe TheThing do
  it "uses a log file on init" do
    TheThing::CheckpointLogger.should_receive(:use).with(:the_thing)
    TheThing.new
  end

  specify "the log gets initialized" do
    TheThing::CheckpointLogger.class_variable_set(:@@logs, {})
    TheThing.new.logger.class.should eq(TheThing::CheckpointLogger)
  end

  it "uses the same log class for two instances" do
    one = TheThing.new
    two = TheThing.new

    one.logger.should eq(two.logger)
  end

  it "can override one log without overriding the other" do
    one = TheThing.new
    two = TheThing.new
    two.logger = stub

    one.logger.should_not eq(two.logger)
  end
end

describe Loggable::CheckpointLogger do
  let(:path) { "#{Rails.root}/log" }

  it "creates a named log file" do
    File.should_receive(:open).with("#{path}/dinosaur_test.log", 'a')
    Loggable::CheckpointLogger.use(:dinosaur)
  end

  it "makes the log directory if it is missing" do
    File.stub(:open)
    File.stub(:exists?).with(path).and_return false
    FileUtils.should_receive(:mkdir_p).with(path)
    Loggable::CheckpointLogger.use(:whatever)
  end

  it "formats per desired output" do
    Timecop.freeze(Time.utc(2038, 12, 8, 11, 43, 17))

    output = StringIO.new
    log = Loggable::CheckpointLogger.new output
    log.warn "Ah, jeez, Alfred!"

    Timecop.return

    output.string.should eq("2038-12-08 12:43:17 WARN Ah, jeez, Alfred!\n")
  end

end
