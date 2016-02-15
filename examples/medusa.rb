class Medusa
  attr_reader :name, :statues

  def initialize(name)
    @name, @statues = name, []
  end

  def stare(victim)
    @statues << victim
    victim.get_stoned!
  end
end

class Person
  attr_reader :name
  def initialize(name)
    @name, @stoned = name, false
  end

  def stoned?
    @stoned
  end

  def get_stoned!
    @stoned = true
  end
end

medusa = Medusa.new("Casseopia")
victim = Person.new("Persius")
victim.stoned?
medusa.stare(victim)
victim.stoned?
