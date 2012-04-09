require './markov.rb'

ignore = [/\*\*\*/]
end_of_header = /^PREFACE\./
begin_footer =  /^INDEX\./
punct = /[[:punct:]]/

m = Markov.new(ignore, end_of_header, begin_footer, punct)
m.parse_and_store("nelsons_home_comforts",3, 'cookbooks')

m.ignore = [/^No\. \d+\. (\w| )+\.$/]
m.end_of_header = /^COOKERY BOOK\./

m.parse_and_store("plain_cookery", 3, 'cookbooks')
