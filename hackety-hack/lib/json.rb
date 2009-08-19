require 'json/lexer'
require 'json/objects'

def JSON.parse(str)
  JSON::Lexer.new(str).nextvalue
end