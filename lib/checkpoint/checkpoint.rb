module Checkpoint
  class << self
    attr_accessor :strategies
  end
  self.strategies = []
end