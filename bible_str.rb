require './markov.rb'

m = Markov.new

10.times { puts m.generate_paragraph("king_james_bible", "The") }
