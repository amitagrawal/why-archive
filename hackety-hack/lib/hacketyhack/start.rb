HACKETYHACK_NET = "hacketyhack.net"
HACKETY_HOME = File.expand_path('../../..', __FILE__)

# platform-specific directories
case PLATFORM when /win32/
  HOME = ENV['USERPROFILE'].gsub(/\\/, '/')
  ENV['MYDOCUMENTS'] = HacketyHack.read_shell_folder('Personal')
  ENV['APPDATA'] = HacketyHack.read_shell_folder('AppData')
  ENV['DESKTOP'] = HacketyHack.read_shell_folder('Desktop')
  HACKETY_USER = 
    begin
      HacketyHack.win_path(Win32::Registry::HKEY_CURRENT_USER.open('Software\Hackety.org\Hackety Hack').read_s('HackFolder'))
    rescue
      HacketyHack.win_path('%APPDATA%/Hackety Hack')
    end
else
  ENV['DESKTOP'] = File.join(ENV['HOME'], "Desktop")
  ENV['APPDATA'] = ENV['HOME']
  ENV['MYDOCUMENTS'] = ENV['HOME']
  HACKETY_USER = File.join(ENV['HOME'], ".hacketyhack")
end

DOWNLOADS_DIR = File.join(HACKETY_USER, 'Downloads')
File.makedirs(DOWNLOADS_DIR)
CACHE_DIR = File.join(HACKETY_USER, 'Cache')
File.makedirs(CACHE_DIR)
HacketyDB = Sequel::SQLite::Database.new(:database => File.join(HACKETY_USER, "+TABLES"))
HacketyDB.extend HacketyDbMixin

# start up
module HacketyHack
  DOCS = load_docs(File.read(File.join(HACKETY_HOME, 'static', 'docs.txt')))
  TUTOR_INDEX, TUTOR = load_tutor(File.read(File.join(HACKETY_HOME, 'static', 'tutor.txt')))
end
HacketyDB.init
Dir.chdir(HACKETY_USER)
