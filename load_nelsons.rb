require './markov.rb'

ignore = [/\*\*\*/]
end_of_header = /^PREFACE\./
begin_footer =  /^INDEX\./
punct = /[[:punct:]]/

m = Markov.new(ignore, end_of_header, begin_footer, punct)
m.parse_and_store("nelsons_home_comforts",3)
