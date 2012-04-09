require './markov.rb'

m = Markov.new

loop do
  seed = gets.strip
  len = gets.to_i
  puts m.generate_paragraph("nelsons_home_comforts", seed, len, 3)
end
