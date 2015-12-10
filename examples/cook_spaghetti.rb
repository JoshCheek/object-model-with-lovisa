def cook_dinner(ingredients, guests)
  prepared_ingredients = get_ingredients(ingredients)
  dish = mix(prepared_ingredients)
  serve(dish, guests)
end

def get_ingredients(ingredients)
  ingredients.each do |ingredient|
    prepare(ingredient)
  end
end

def prepare(ingredient)
  "Preparing #{ingredient}!"
end

def mix(prepared_ingredients)
  prepared_ingredients.map do |prepared_ingredient|
    add_to_dish(prepared_ingredient)
  end
end

def add_to_dish(prepared_ingredient)
  "Adding #{prepared_ingredient} to the dish!"
end

def serve(dish, guests)
  pretty_preparations = dish.join(", ")
  pretty_guests = guests.join(", ")
  "To serve #{pretty_guests} " <<
    "I had to #{pretty_preparations}."
end

ingredients = ["spaghetti", "onion",
               "olive oil", "tomatoes",
               "garlic", "basil"]
guests      = ["Deborah", "Scott",
               "Kimmie", "Marina", "Brennan"]
puts cook_dinner(ingredients, guests)
