#!/usr/bin/env ruby

require 'io/console'
require 'find'

class Play
  AUDIO_EXTENSIONS = %w(aac aiff flac m4a mp3 ogg wav wma).map { |f| ".#{f}" }

  DIR = '/PATH/TO/AUDIO/FILES/'
  RE_DIR = /#{DIR}/

  attr_reader :regex, :files, :ok

  def initialize(*args)
    args.flatten!

    create_regex(args)
    search_for_files

    @ok = false
    prompt_to_play until ok

    play_files
  end

  private

  def create_regex(pattern = [])
    pattern = prompt_for_pattern until !pattern.empty?
    @regex = /#{pattern.join('.+')}/i
  end

  def prompt_for_pattern
    puts
    print 'Search pattern > '
    STDIN.flush
    response = STDIN.gets.chomp
    response.split(/\s+/)
  end

  def search_for_files
    @files = []

    Find.find(DIR) do |path|
      next unless File.file?(path)
      next unless audio_file?(path)
      next unless name_match?(path)
      files << path
    end
  end

  def audio_file?(path)
    AUDIO_EXTENSIONS.include?(File.extname(path).downcase)
  end

  def name_match?(path)
    File.basename(path, '.*') =~ regex
  end

  def prompt_to_play
    display_files

    if files.empty?
      prompt = "(s)SEARCH (q)UIT"
      responses = /q|s/
    else
      prompt = "(p)LAY (f)ILTER (m)IX (s)SEARCH (q)UIT"
      responses = /f|m|p|q|s/
    end

    case prompt_user(prompt, responses)
    when 'f'
      select_files

    when 'm'
      shuffle_files

    when 'p'
      @ok = true

    when 'q'
      puts 'bye'
      exit

    when 's'
      create_regex
      search_for_files

    end
  end

  def display_files
    puts
    puts '---------------------------------------------'
    puts files.map { |f| file_name(f) }
    puts '---------------------------------------------'
    puts
  end

  def prompt_user(prompt, response_regex)
    response = nil

    while response !~ response_regex
      puts unless response.nil?
      print "#{prompt} > "
      STDIN.flush
      response = STDIN.getch
    end
    puts

    response
  end

  def select_files
    old_files = files.dup
    files.clear

    old_files.each do |file|
      break unless prompt_to_select(file)
    end
  end

  def prompt_to_select(file)
    case prompt_user("#{file_name(file)} (y)ES (n)O q(UIT)", /y|n|q/)
    when 'y'
      files << file
      true

    when 'n'
      true

    when 'q'
      false
    end
  end

  def file_name(path)
    path.gsub(RE_DIR, '')
  end

  def shuffle_files
    @files = files.shuffle
  end

  def play_files
    exec %(nohup cvlc #{args} vlc://quit > /dev/null 2>&1)
  end

  def args
    urls.inject('') { |s, url| s << %( "#{url}") }
  end

  def urls
    files.map { |file| "file://#{file}" }
  end
end

Play.new(ARGV)
