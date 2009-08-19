class Channel
  include YamlService
  attr_reader :owner, :name
  def initialize(owner, name)
    @owner = owner
    @name = name
    @url = "http://#{@owner}.#{HACKETYHACK_NET}/channels"
    @since = 0
    @received = {}
  end
  def inspect
    "(Channel #{@owner}'s #{@name})"
  end
  def start
    fetch_uri(:Post, nil, {'title' => @name})
    self
  end
  def hear
    JSON.parse(fetch_uri(:Get, @name)).map do |m|
      next if @received[m["id"]]
      @received[m["id"]] = true
      begin
        m["object"] = YAML.load(m["object"])
      rescue => e
        m["object"] = e
      end
      Message.new(m)
    end.compact.sort_by { |x| x.at }
  end
  def say(obj)
    fetch_uri(:Put, @name, YAML.dump(obj))
    true
  end

  class Message
    attr_accessor :object, :hacker, :at, :id
    def initialize(opts = {})
      @object = opts['object']
      @hacker = opts['hacker']
      @at = opts['at']
      @id = opts['id']
    end
    def to_html
      m = self
      Web.Bit do
        div.chanmsg do
          div.says "#{m.hacker} says:"
          div.indent { puts m.object }
        end
      end
    end
  end
end

