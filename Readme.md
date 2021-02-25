Object Model
============

Resources
---------

* [Object Model Challenges](https://gist.github.com/JoshCheek/ad9f70a6d855be9ed50d)
* [Quiz 1](https://quizzes-ruby-object-model.herokuapp.com/1)
* [Quiz 2](https://quizzes-ruby-object-model.herokuapp.com/2)
* [Quiz 3](https://quizzes-ruby-object-model.herokuapp.com/3)
* [The current version of this lesson](https://github.com/JoshCheek/object-model-hash-style)
* [The first version of Object Model](https://github.com/JoshCheek/ruby-object-model)

Stack
-----

* Describe it briefly.
* Have them execute the code.


Non-Code Example: Picking friend up at the airport

1. weekend with visiting friend
2. go to museum

```
weekend with visiting friend
  go to the airport
  go for dinner
  go to the museum

go to the airport
  directions to airport, zipcar

go to the museum
  directions to museum, zipcar

zipcar
  ...
```

Exercise
--------

```
def graduate_turing
  module_1
  module_2
  module_3
  module_4
end

def module_1
  rubies
end

def module_2
  rails
end

def module_3
  personal_project
end

def module_4
  javascripting
end

def rubies
  puts "I know Ruby!"
end

def rails
  puts "Rails is also Ruby!"
end

def personal_project
  puts "I can do whatever I want?"
end

def javascripting
  puts "JavaScript is the best."
end

graduate_turing
```

Instances and Classes
---------------------


Exercise
--------

```ruby
class User
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
```

Shitloads of Obj Model Challenges within the thing
--------------------------------------------------
