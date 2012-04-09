require './markov.rb'

m = Markov.new

loop do
  seed = gets.strip
  len = gets.to_i
  puts m.generate_paragraph("cookbooks", seed, len, 3)
end
