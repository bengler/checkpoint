class Mockcached
  def initialize
    @store = {}
  end

  def set(*args)
    @store[args[0]] = args[1]
  end

  def get(*args)
    @store[args[0]]
  end

  def get_multi(*keys)
    result = {}
    keys.each do |key|
      value = get(key)
      result[key] = value if value
    end
    result
  end

  def delete(*args)
    @store.delete(args[0])
  end

  def fetch(key, &block)
    @store[key] = (@store[key] || yield)
  end
end