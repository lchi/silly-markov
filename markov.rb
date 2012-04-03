#!/usr/bin/env ruby
require 'json'

class Markov
  CACHE = ".silly-cache"
  attr_accessor :ignore, :end_of_header, :begin_footer, :punct

  def initialize(filename, ignore=[], end_of_header=nil, begin_footer=nil,
                 punct=/[[:punct:]]/)
    @ignore = ignore
    @end_of_header = end_of_header
    @begin_footer = begin_footer
    @punct = punct

    @states = {}
    @rand_gen = Random.new
    if true
      generate_chain(File.new(filename))

      # I think this may be wasteful...
      # calculate_probabilities
    else
      load_chain(File.new("#{CACHE}/#{filename}"))
    end

  end

  def cache_states(filename)
    fout = File.open("#{CACHE}/#{filename}", "w")
    fout.write(JSON.generate(@states))
  end

  # generates a paragraph from a seed word and
  # desired length of paragraph (in words)
  def generate_paragraph(seed, length=40)
    paragraph = seed + ' '
    length.times do
      rand_n = 1 + @rand_gen.rand(@states[seed][':totalwordcount:'])

      new_word = ""
      @states[seed].each do |next_word, count|
        if next_word != ':totalwordcount:'
          rand_n -= count
          if rand_n <= 0
            paragraph.chop! if @punct.match(next_word)
            paragraph += "#{next_word} "
            new_word = next_word
            break
          end
        end
      end
      seed = new_word
    end
    paragraph
  end
  private

  def load_chain(fp)
  end

  # DEPRECATED
  def calculate_probabilities
    @states.each do |word, hash|
      total_count = hash[':totalwordcount:'].to_f
      lower_p = 0.0
      upper_p = 0.0
      hash.each do |next_word, count|
        if next_word != ':totalwordcount:'
          upper_p = lower_p + (count / total_count)

          # set next word to a list
          # elem 0 will hold lower bound
          # elem 1 will hold upper bound
          #
          # we will use these bounds when we look for a random
          # choice of next word
          hash[next_word] = []
          hash[next_word][0] = lower_p
          hash[next_word][1] = upper_p

          lower_p = upper_p
        end
      end
    end
  end

  def generate_chain(fp)
    all_words = get_all_words(fp)
    all_words.each_with_index do |word, idx|
        if idx+1 != all_words.size
          # set an empty hash if none exists
          @states[word] ||= {}

          # set count of the following word to 0 if not set
          @states[word][all_words[idx+1]] ||= 0

          # add one to the wordcount
          @states[word][all_words[idx+1]] += 1

          # keeping track of how times we've seen this word
          @states[word][':totalwordcount:'] ||= 0
          @states[word][':totalwordcount:'] += 1
        end
    end
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

ignore = [/\p{Digit}+:\p{Digit}+/]
end_of_header = /^\*\*\* START OF THIS PROJECT GUTENBERG EBOOK/
begin_footer =  /^End of the Project Gutenberg EBook/
punct = /[[:punct:]]/

m = Markov.new("king_james_bible", ignore, end_of_header, begin_footer, punct)

10.times { puts m.generate_paragraph("Moses", 40) }
#m.cache_states("king_james_bible2.json")
