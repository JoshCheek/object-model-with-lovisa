def double(n)
  if n == 0
    0
  elsif n < 0
    -2 + double(n+1)
  else
    2 + double(n-1)
  end
end

puts double 6
