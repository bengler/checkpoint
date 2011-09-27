# This might need to be called something else,
# especially if it starts having to do with access levels
# (i.e. do something for everyone over a certain level)
module Species

  Robot = -1
  Stub = 0
  User = 1
  Admin = 2
  God = 9

  KINDS = {Robot => :robot, Stub => :stub, User => :user, Admin => :admin, God => :god}

  class << self
    def to_code(species)
      KINDS.invert[species.to_sym]
    end
  end

  KINDS.values.each do |species|
    define_method "#{species}?" do
      kind == Species.to_code(species)
    end
  end

  def human?
    kind != Robot
  end
end
