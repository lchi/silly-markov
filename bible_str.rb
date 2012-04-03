require './markov.rb'

m = Markov.new

loop do
  seed = gets.strip
  len = gets.to_i
  puts m.generate_paragraph("king_james_bible", seed, len, 3)
end
