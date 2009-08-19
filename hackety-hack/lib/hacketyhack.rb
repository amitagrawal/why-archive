%w[
  metaid
  yaml_service
  digest/md5
  net/http
  irb/ruby-lex
  hpricot
  json
  open-uri
  stringio
  tempfile
  sequel
  thread
  uri
  ftools
  mimickirb
].
each(&method(:require))

Object.send :remove_const, :STDERR
Object.send :const_set, :STDERR, StringIO.new
Object.send :remove_const, :STDOUT
Object.send :const_set, :STDOUT, StringIO.new
Object.send :remove_const, :STDIN
Object.send :const_set, :STDIN, StringIO.new

case PLATFORM when /win32/
  require 'hacketyhack/win32'
end

$sandbox = []
IRBalike = MimickIRB.new

module HacketyHack
  VERSION = "0.5"
end

%w[
  hacketyhack/self
  hacketyhack/string
  hacketyhack/fixnum
  hacketyhack/time
  hacketyhack/inspect
  hacketyhack/uri
  hacketyhack/exc
  hacketyhack/html
  camping

  hacketyhack/address
  hacketyhack/channel
  hacketyhack/hacker
  hacketyhack/kernel
  hacketyhack/picture
  hacketyhack/sandbox
  hacketyhack/table
  hacketyhack/web

  hacketyhack/helpers
  hacketyhack/controllers
  hacketyhack/views
  hacketyhack/start
].
each(&method(:require))
