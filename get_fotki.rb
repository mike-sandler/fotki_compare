require 'net/ftp'
require 'ruby-progressbar'
USERNAME = 'my_username'
PASSWORD = 'my_password'

class Fotki
  def initialize
    @ftp = Net::FTP.new('ftp.fotki.com')

    @ftp.login(USERNAME, PASSWORD)

    @ftp.chdir('public')
  end

  # get list of everything in directory, trimmed of first three lines (total, ., ..)
  def get_list(dir = nil)
    @ftp.ls(dir)[3..-1]
  end

  # parse list into directories and files
  def get_dirs_and_files(list, path)
    path ||= '.'
    dirs = []
    files = []
    list.each{|l|
      parsed = l.split ' '
      if parsed.size != 9
        puts "parsed line '#{list}' into something that wasn't 9 pieces"
      end
      if parsed[0][0] == 'd'
        dirs << "#{path}/#{parsed[8]}"
      else
        files << ["#{path}/#{parsed[8]}", parsed[4]]
      end
    }
    [dirs, files]
  end

  # check if local file matches
  def local_file_matches?(filename, size)
    unless File.exists? filename
      puts "Missing #{filename}"
      return false
    else
      local_size = File.size filename
      unless local_size == size.to_i
        puts "File #{filename} remote size is #{size}, local size is #{local_size}"
        return false
      end
    end
    true
  end

  def get_all_files(start_dir = nil)
    #puts "get_all_files called with #{start_dir}"
    list = get_list start_dir
    dirs, files = get_dirs_and_files(list, start_dir)
    dirs.each {|d|
      files.concat(get_all_files d)
    }
    files
  end

  def determine_missing
    files = get_all_files
    pbar = ProgressBar.create(:total => files.size)
    errors = []
    files.each{|(f, size)|
      pbar.increment
      unless local_file_matches?(f, size)
        errors << f
      end
    }
    errors
  end
end

fotki = Fotki.new
errors = fotki.determine_missing
errors.each{ |e| puts e }
