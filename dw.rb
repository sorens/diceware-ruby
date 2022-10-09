#!/usr/bin/env ruby

#########################################################################
#                                                                       #
# Ruby based Diceware(tm) password generator using agp                  #
#                                                                       #
# Diceware:                                                             #
#   Arnold G. Reinhold                                                  #
#   http://world.std.com/~reinhold/diceware.html                        #
#                                                                       #
#                                                                       #  
#                                                                       #
#########################################################################

# a single line of integers in .seed is our initial seed value
INITIAL_SEED_PATH                = ".seed"

# shamelessly borrowed from
# https://raw.github.com/guzart/rassphrase/master/lib/rassphrase/wordlist_parser.rb
module Dw
  class Dw

    def initialize( options = {} )
      # parse the word file
      parse( options[:wordlist_path] )
      @size = 5
      @size = options[:size] if options[:size] > 0
      @seed = options[:seed] || Time.now.to_i.to_s

      if INITIAL_SEED_PATH
        if File.exists?( INITIAL_SEED_PATH )
          # load our initial seed
          @initial_seed = File.readlines(INITIAL_SEED_PATH).first.strip.chomp.to_i
          # sanity check
          @initial_seed = Time.now.to_i if 0 == @initial_seed
        end
      end
    end

    def gen
      numbers = apg
      words = lookup( numbers )
      words.join( " " )
    end

    private

    def lookup( numbers )
      words = []
      numbers.each do |n|
        words << @wordlist[n]
      end
      words
    end

    # generate a random seed
    def seed
      # take each character of our initial seed and operate
      result = Time.now.to_i
      @seed.split("").each do |chr|
        chr_to_int = chr.ord.to_i
        if chr_to_int > 0
          result = result + (@initial_seed * Random.rand(chr_to_int) * Time.now.to_i)
        end
      end

      result
    end

    # call apg and return an array of numbers as if you threw some dice
    def apg
      `apg -a 1 -M n -n #{@size} -m 5 -x 5 -E 0789 -c #{seed}`.split
    end

    # Parses a line into a hash with :code, and :word.
    def parse_line(line)
      items = line.split(' ')
      {:code => items[0], :word => items[1]}
    end

    # Parses a file with wordlist items.
    # A path to the file must be given as the first argument.
    def parse(file_path)
      @wordlist = {}
      File.open(file_path, 'r') do |file|
        while line = file.gets
          parts = parse_line(line)
          @wordlist[parts[:code].to_s] = parts[:word]
        end
      end
    end
  end
end

$LOAD_PATH << File.expand_path( __FILE__ )

require "optparse"

WORDLIST_PATH               = "words.txt"

@options                    = {}
@options[:number]           = 1
@options[:size]             = 5
@options[:wordlist_path]    = File.expand_path(WORDLIST_PATH)
@options[:seed]             = nil

op = OptionParser.new do |opts|
  opts.banner = "Usage: ruby dw.rb [options]"

  opts.on( "-s", "--size [SIZE]", Integer, "number of words for passphrase" ) do |s|
    @options[:size] = s.to_i
  end

  opts.on( "-n", "--numb [NUMBER]", Integer, "number of passphrases to generate" ) do |n|
    @options[:number] = n.to_i
  end

  opts.on( "-e", "--seed [SEED]", String, "random keypresses to generate entropy" ) do |seed|
    @options[:seed] = seed.strip
  end

  opts.on( "-h", "--help", "Help" ) do
    puts opts
    exit
  end

end
op.parse!

begin
  d = Dw::Dw.new(@options)

  @options[:number].times do
    puts d.gen
  end
rescue Exception => e
  puts e
  puts e.backtrace.join("\n")
end