class Hacker
  include YamlService
  attr_accessor :name
  def initialize(who)
    @name = who
    @url = "http://#{who}.#{HACKETYHACK_NET}"
  end
  def inspect
    "(Hacker #{@name.inspect})"
  end
  def load_program(prog)
    eval(fetch_uri(:Get, "/programs/#{prog}"), TOPLEVEL_BINDING)
  end
  def share_program(prog, code)
    path = "/programs/#{prog}"
    begin
      JSON.parse(fetch_uri(:Post, path, 'code' => code))['version']
    rescue FetchError
      if ask_ok("You already have a program called `#{prog}` shared.  Add this as a new version?")
        JSON.parse(fetch_uri(:Put, path, code))['version']
      end
    end
  end
  def programs
    JSON.parse(fetch_uri(:Get, "/programs"))
  end
  def share_table(name)
    if HacketyHack.check_share(name, 'Table')
      raise SharedAlreadyError, "The `#{name}` table is already shared."
    else
      from, to = Table(name), Web.table(name)
      to.bulk_insert(from.to_a)
      HacketyHack.add_share(name, 'Table')
    end
  end
  def load_table(name)
    db = Sequel::HTTP::Database.new(:database => "#@url/tables")
    db[name]
  end
  def channel(title)
    Channel.new(@name, title)
  end
end
class Program
  attr_reader :hacker, :at, :description, :version, :title
  def initialize(h, a, d, v, t)
    @hacker, @at, @description, @version, @title = h, a, d, v, t
  end
end
def Hacker(who)
  Hacker.new(who)
end
