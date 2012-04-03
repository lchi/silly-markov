require './markov.rb'

m = Markov.new

10.times { m.generate_paragraph("king_james_bible", "A") }
