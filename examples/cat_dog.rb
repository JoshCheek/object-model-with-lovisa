  class Dog

    def name
      @name
    end

    def initialize(name)
      @name = name
    end

    def chase(cat)
      dog_reaction = "woof"
      cat.be_chased(self)
      puts dog_reaction
    end
  end

  class Cat
    def initialize(breed)
      @breed = breed
    end

    def be_chased(dog)
      puts "oh no being chased by this dog:"
      puts dog.name
    end
  end

  sassy = Cat.new("Siamese")
  chance = Dog.new("Chance")
  chance.chase(sassy)
