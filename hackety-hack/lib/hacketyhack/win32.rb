require 'Win32API'
require 'win32/registry'

module HacketyHack
  SHGetFolderPath = Win32API.new "shell32.dll", "SHGetFolderPath", %w[P I P I P], "I"
  class << self
    def read_shell_folder(name)
      x =
        case name
        when "Personal"; 0x05
        when "AppData";  0x1A
        when "Desktop";  0x00
        end
      path = " " * 256
      SHGetFolderPath.call(0, x, 0, 0, path)
      path.strip.gsub("\0", "").gsub(/\\/, '/')
    end
  end
end
