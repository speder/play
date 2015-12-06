#!/usr/bin/env ruby

# Purpose:
# - search audio files by name from the command line and play via vlc
#
# Example:
# - play lucy diamonds
#
# Limitations:
# - all hell breaks loose if file names contain double quotes
# - no control of audio player

require 'find'
require 'io/console'

class Play
  AUDIO_EXTENSIONS = %w(aac aiff flac m4a mp3 ogg wav wma).map { |f| ".#{f}" }

  DIR = '/media/common/audio'

  attr_reader :args, :regex, :wide, :files, :play

  def initialize(*args)
    @args = args.flatten
    create_regex

    @wide = false
    search_for_files

    @play = false
    prompt_to_play until play

    play_files
  end

  private

  def create_regex
    @args = prompt_for_pattern until !args.empty?
    @regex = /#{args.join('.+')}/i
  end

  def prompt_for_pattern
    puts
    print 'Search for > '
    STDIN.flush

    response = STDIN.gets.chomp
    @args = response.split(/\s+/)
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
    dir = DIR[-1] == '/' ? DIR : "#{DIR}/"
    path.gsub(dir, '')
  end

  def file_name(path)
    File.basename(path, '.*')
  end

  def prompt_to_play
    display_files

    config = if files.empty?
               if wide
                 {
                   s: '(S)earch',
                   q: '(Q)uit',
                 }

               else
                 {
                   w: '(W)iden',
                   s: '(S)earch',
                   q: '(Q)uit',
                 }
               end

             elsif wide
               {
                 p: '(P)lay',
                 f: '(F)ilter',
                 m: '(M)ix',
                 n: '(N)arrow',
                 s: '(S)earch',
                 q: '(Q)uit',
               }

             else
               {
                 p: '(P)lay',
                 f: '(F)ilter',
                 m: '(M)ix',
                 w: '(W)iden',
                 s: '(S)earch',
                 q: '(Q)uit',
               }
             end

    case prompt_user(config)
    when 'f'
      select_files

    when 'm'
      shuffle_files

    when 'n'
      @wide = false
      search_for_files

    when 'p'
      @play = true

    when 'q'
      puts 'bye'
      exit

    when 's'
      @args = []
      create_regex
      search_for_files

    when 'w'
      @wide = true
      search_for_files

    end
  end

  def display_files
    puts
    puts '-----------------------------------------------------'
    puts files.map.with_index { |f, i| "#{i+1}. #{file_with_dir(f)}" }
    puts '-----------------------------------------------------'
    puts
  end

  def prompt_user(config)
    prompt = config.values.join(' ')
    response_regex = /#{config.keys.map(&:to_s).join('|')}/i

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
    config = {
      y: "#{file_with_dir(file)} (Y)es",
      n: '(N)o',
      q: '(Q)uit',
    }

    case prompt_user(config)
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

  def file_args
    urls.inject([]) { |s, url| s << %("#{url}") }.join(' ')
  end

  def urls
    files.map { |file| "file://#{file}" }
  end
end

Play.new(ARGV)
