require './markov.rb'

ignore = [/\p{Digit}+:\p{Digit}+/]
end_of_header = /^\*\*\* START OF THIS PROJECT GUTENBERG EBOOK/
begin_footer =  /^End of the Project Gutenberg EBook/
punct = /[[:punct:]]/

m = Markov.new(ignore, end_of_header, begin_footer, punct)
m.parse_and_store("king_james_bible")
