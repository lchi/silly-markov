#!/usr/bin/env ruby
require 'json'
require 'mongo'

class Markov
  CACHE = ".silly-cache"
  attr_accessor :ignore, :end_of_header, :begin_footer, :punct

  def initialize(ignore=[], end_of_header=nil, begin_footer=nil,
                 punct=/[[:punct:]]/)
    @ignore = ignore
    @end_of_header = end_of_header
    @begin_footer = begin_footer
    @punct = punct

    @rand_gen = Random.new

    @db = Mongo::Connection.new("localhost", 27017).db("silly-markov")
  end

  # generates a paragraph from a seed word and
  # desired length of paragraph (in words)
  def generate_paragraph(source, seed, length=40, chain_order=2)
    coll = @db.collection(source)

    # add first space
    paragraph = seed + ' '
    seed = [seed]
    counter = 0
    loop do
      # must end on period
      if counter > length and paragraph[-2] == '.'
        break
      end
      #seed = seed.gsub(/\./, ":dot:")
      states = coll.find_one('word' => seed.to_s)

      # happens when we don't have words that lead to one more
      if states == nil
        len = -1 * (chain_order - 1)
        loop do
          break if len.abs == chain_order
          states = coll.find_one('word' => seed[0 .. len].to_s)
          break if states != nil
          len -= 1
        end
      end
      rand_n = 1 + @rand_gen.rand(states['transitions'][':totalwordcount:'])

      new_word = ""
      states['transitions'].each do |next_word, count|
        if next_word != ':totalwordcount:'
          rand_n -= count
          if rand_n <= 0
            next_word = next_word.gsub(/:dot:/, ".")
            paragraph.chop! if @punct.match(next_word)
            paragraph += "#{next_word} "
            new_word = next_word
            break
          end
        end
      end
      if seed.length == chain_order
        seed.delete_at(0)
        seed << new_word
      else
        seed << new_word
      end
      counter += 1
    end
    paragraph
  end

  def parse_and_store(filename, chain_order=2, db_name=nil)
    db_name = filename if db_name == nil
    puts "Parsing #{filename}"
    all_words = get_all_words(File.new(filename))
    puts "Done parsing, now creating chains..."
    coll = @db.collection(db_name)
    chain_order.times do |i|
      states = chain_of_order(i+1, all_words)

      # put into mongodb
      states.each do |k, val|
        existing = coll.find_one('word' => k)
        if existing == nil
          coll.insert({ 'word' => k, 'transitions' => val })
        else
          val.each do |word, count|
            if existing['transitions'][word] != nil
              existing['transitions'][word] += count
            else
              existing['transitions'][word] = count
            end
          end
          coll.save(existing)
        end
      end
      coll.create_index("word")
      puts "Inserted #{states.count} records into '#{db_name}' for chain of order #{i+1}"
    end
  end

  private

  def chain_of_order(len, all_words)
    states = {}
    len_words = []
    all_words.each_with_index do |word, idx|
      if idx < len
        len_words[idx] = word
        next
      end

      if idx+1 != all_words.length
        # the '.' char is not allowed in mongo keys
        #len_words.each { |word| word = word.gsub(/\./, ":dot:") }

        # need to serialize the array to a str, otherwise the
        # object itself is used as the key (and changes...fml)
        key = len_words.to_s

        # set an empty hash if none exists
        states[key] ||= {}

        # the '.' char is not allowed in mongo keys
        next_word = all_words[idx+1].gsub(/\./, ":dot:")

        # set count of the following word to 0 if not set
        # and add one to the count
        states[key][next_word] ||= 0
        states[key][next_word] += 1

        # keeping track of how times we've seen this word
        states[key][':totalwordcount:'] ||= 0
        states[key][':totalwordcount:'] += 1

        # remove oldest word, append newest
        len_words.delete_at(0)
        len_words << all_words[idx+1]
      end
    end
    states
  end

  def get_all_words(fp)
    process = @end_of_header ? false : true
    all_words = []
    fp.each do |line|
      if process
        # ignore lines after footer
        if @begin_footer
          break if begin_footer.match(line)
        end

        line.split(/\s/).each do |word|
          should_ignore = false
          @ignore.each { |ig| should_ignore = true if ig.match(word) }
          if not should_ignore and not word.empty?
            if @punct.match(word[-1])
              all_words << word[0 .. -2]
              all_words << word[-1]
            elsif @punct.match(word[0])
              all_words << word[0]
              all_words << word[1 .. -1]
            else
              all_words << word
            end
          end
        end
      else
        # ignore lines before header
        process = true if @end_of_header.match(line)
      end
    end
    all_words
  end
end

