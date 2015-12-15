def make_pizza
  toss_dough
  add_toppings
  bake
end

def toss_dough
  toss_count = rand(8)
  toss_count.times do |i|
    puts "Toss the dough"
    puts i
  end
end

def add_toppings
  puts "add those tasty anchovies"
end

def bake
  puts "cook it up in the oven"
end

make_pizza
