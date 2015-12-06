#!/usr/bin/env ruby

require 'find'
require 'io/console'

class Play
  AUDIO_EXTENSIONS = %w(aac aiff flac m4a mp3 ogg wav wma).map { |f| ".#{f}" }

  DIR = '/PATH/TO/AUDIO/FILES/'
  RE_DIR = /#{DIR}/

  attr_reader :wide, :regex, :files, :ok

  def initialize(*args)
    @wide = false
    create_regex(args.flatten)
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
    name = wide ? file_name_with_dir(path) : file_name(path)
    name =~ regex
  end

  def file_name_with_dir(path)
    file_with_dir(path).gsub(/\..+$/, '')
  end

  def file_with_dir(path)
    path.gsub(RE_DIR, '')
  end

  def file_name(path)
    File.basename(path, '.*')
  end

  def prompt_to_play
    display_files

    if files.empty?
      if wide
        prompt = '(s)EARCH (q)UIT'
        response = /q|s/i
      else
        prompt = '(w)IDEN (s)EARCH (q)UIT'
        response = /q|s|w/i
      end

    elsif wide
      prompt = '(p)LAY (f)ILTER (m)IX (n)ARROW (s)EARCH (q)UIT'
      response = /f|m|n|p|q|s/i

    else
      prompt = '(p)LAY (f)ILTER (m)IX (w)IDEN (s)EARCH (q)UIT'
      response = /f|m|p|q|s|w/i
    end

    case prompt_user(prompt, response)
    when 'f'
      select_files

    when 'm'
      shuffle_files

    when 'n'
      @wide = false
      search_for_files

    when 'p'
      @ok = true

    when 'q'
      puts 'bye'
      exit

    when 's'
      create_regex
      search_for_files

    when 'w'
      @wide = true
      search_for_files

    end
  end

  def display_files
    puts
    puts '---------------------------------------------'
    puts files.map { |f| file_with_dir(f) }
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
    case prompt_user("#{file_with_dir(file)} (y)ES (n)O q(UIT)", /y|n|q/i)
    when 'y'
      files << file
      true

    when 'n'
      true

    when 'q'
      false
    end
  end

  def shuffle_files
    @files = files.shuffle
  end

  def play_files
    exec %(nohup cvlc #{file_args} vlc://quit >/dev/null 2>&1)
  end

  # assuming audio files don't contain double quotes
  def file_args
    urls.inject([]) { |s, url| s << %("#{url}") }.join(' ')
  end

  def urls
    files.map { |file| "file://#{file}" }
  end
end

Play.new(ARGV)
