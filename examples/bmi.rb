STDOUT.puts 'a'
class User
  STDOUT.puts 'b'
  attr_accessor :name, :age, :weight, :height
  def initialize(name, age, weight, height)
    self.name   = name
    self.age    = age
    self.weight = weight
    self.height = height
  end

  def bmi
    weight * 703 / height / height
  end

  def info
    summary = "#{name} is #{age} "
    summary << "years old, "
    summary << "#{weight} kilos, "
    summary << "#{height} cm, and has a BMI of "
    summary << bmi.to_s
    summary
  end
end

user = User.new("Josh", 32, 140, 70)
puts user.info
