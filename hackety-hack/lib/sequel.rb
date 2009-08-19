require 'sequel/core_ext'
require 'sequel/database'
require 'sequel/connection_pool'
require 'sequel/schema'
require 'sequel/dataset'
require 'sequel/model'
require 'sequel/sqlite'
require 'sequel/http'

module Sequel #:nodoc:
  def self.connect(url)
    Database.connect(url)
  end
end
