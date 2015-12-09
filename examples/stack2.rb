def weekend_with_visiting_friend
  go_to_the_airport
  go_for_dinner
  go_to_the_museum
  go_to_the_airport
end
def go_to_the_airport
  directions("airport")
  zipcar
end
def go_to_the_museum
  directions("museum")
  zipcar
end
def directions(location)
  puts "Getting directions to #{location.inspect}"
end
def zipcar
  puts "Driving in a zipcar, muthafuckahz"
end
def go_for_dinner
  puts "omnomnomnom"
end
weekend_with_visiting_friend
