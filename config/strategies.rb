require "hanuman/checkpoint/strategy"
require "hanuman/config"

File.open("config/hanuman.yml") do |f|
  Hanuman::Config.load(f)
end

Checkpoint.strategies << Hanuman::Strategy.new