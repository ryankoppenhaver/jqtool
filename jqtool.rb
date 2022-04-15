#!/usr/bin/env ruby
require 'json'
require 'tty-prompt'
require 'pastel'

AllOption = 'All'
IndexOption = 'Index'
FilterOption = 'Filter'

# common
StopOption = "🛑 Stop Here"

@prompt = TTY::Prompt.new
@pastel = Pastel.new

def die(s)
  STDERR.puts(s)
  exit 1
end

def quote(s)
  if s.match /\A\w+\z/
    s
  else
    JSON.generate(s)
  end
end

input = ARGV[0]
die "usage #{$0} <json file>" unless input

data = File.read(input)
json = JSON.parse(data)

@cmd = ''
@arr = 0
while true
  case json
  when Hash
    keys = json.keys + [StopOption]
    
    key = @prompt.select("Choose a key:", keys, filter: true, show_help: 'always')
    break if key == StopOption

    key = quote(key)

    @cmd += ".#{key}"
    json = json[key]
    next
  when Array
    if json.empty?
      puts "Found an empty array."
      break
    end

    # TODO separate "filter one", range options ?
    options = [AllOption, IndexOption, StopOption]
    opt = @prompt.select("Found an array:", options, show_help: 'always')

    case opt
    when AllOption
      @cmd << '|' unless @cmd.empty?
      @cmd << '[.[]'
      @arr += 1
      json = json[0]
      next
    when IndexOption
      index = @prompt.ask("What index?", convert: :int, default: '0')
      @cmd <<  '|' unless @cmd.empty?
      @cmd << ".[#{index}]"
      json = json[index]
      next
    #when FilterOption
      # TODO
    when StopOption
      break
    else
      raise 'unexpected'
    end
  else
    s = json.inspect
    if s.length >= 60
      s = s[0, 50] + "..." + s[-5,5]
    end
    puts "Found a scalar: #{ @pastel.cyan(s) }"
    break
  end
end
@cmd << (']' * @arr)

final_cmd = "jq '#{@cmd}' '#{input}'"

puts "Your jq command is: #{ @pastel.green.bold(final_cmd) }"

if @prompt.yes?('Run it?', default: 'n')
  system(final_cmd)
end
