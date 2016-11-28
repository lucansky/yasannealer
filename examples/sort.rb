require 'yasannealer'

class Array
  def swap!(a,b)
    self[a], self[b] = self[b], self[a]
    self
  end
end

class SortAnnealer < Yasannealer
  attr_accessor :sorted_array

  def initialize(arr, opts)
    self.sorted_array = arr.sort

    super(arr, opts)
  end

  def energy
    self.state.zip(self.sorted_array).count{|pair| pair.first != pair.last}
  end

  def move
    index_a = rand(self.state.size)
    index_b = rand(self.state.size)

    self.state.swap!(index_a, index_b)
  end
end

def test
  init_state = (1..300).to_a.shuffle

  annealer = SortAnnealer.new(init_state, {tmin: 0.001, tmax: 60.0, steps: 1000000, updates: 60})
end