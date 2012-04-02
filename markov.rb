#!/usr/bin/env ruby
require 'json'

class Markov
  CACHE = ".silly-cache"

  def initialize(filename)
    @states = {}
    @rand_gen = Random.new
    if not File.exists?("#{CACHE}/#{filename}")
      generate_chain(File.new(filename))
      calculate_probabilities
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
  def generate_paragraph(seed, length)
    paragraph = seed
    length.times do
      n = @rand_gen.rand

      new_word = ""
      @states[seed].each do |next_word, bounds|
        if next_word != ':totalwordcount:'
          lower, upper = bounds[0], bounds[1]
          if n >= lower and n < upper
            paragraph += " #{next_word}"
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
    process = false
    all_words = []
    fp.each do |line|
      if process
        # ignore lines after project gutenberg footer
        break if /^End of the Project Gutenberg EBook/.match(line)

        line.split(/\s/).each do |word|
          if not /\p{Digit}+:\p{Digit}+/.match(word) and not word.empty?
            if /[[:punct:]]/.match(word[-1])
              all_words << word[0 .. -2]
              all_words << word[-1]
            else
              all_words << word
            end
          end
        end
      else
        # ignore lines before project gutenberg header
        process = true if /^\*\*\* START OF THIS PROJECT GUTENBERG EBOOK/.match(line)
      end
    end
    all_words
  end
end

m = Markov.new("king_james_bible")
puts m.generate_paragraph("The", 40)
#m.cache_states("king_james_bible2.json")
