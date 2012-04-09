#!/usr/bin/env ruby
require './markov.rb'

m = Markov.new

seed = ARGV[0] ? ARGV[0] : 'The'
order = ARGV[1] ? ARGV[1].to_i : 3
len = ARGV[2] ? ARGV[2].to_i : 40

puts m.generate_paragraph("cookbooks", seed, len, order)
