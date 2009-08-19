class Camping::Sandbox
  def evaluate(str)
    s = proc { |x| js("$('#stdout').html(" + x.to_json + ")") }
    $stdout, $stderr = StringIO.new, StringIO.new
    def $stdout.print(*args)
      args.each do |x|
        self <<
          case x
          when String
            HTML(x).gsub(/\r?\n/, '<br />').
              gsub(/(^| )( +)/) { $1 + ("&nbsp;" * $2.length) }
          else
            HTML(x)
          end
      end
      nil
    end
    def $stdout.puts(*args)
      ary = []
      args.each { |x| ary += [x, "\n"] }
      self.print *ary
      nil
    end
    eval(str, TOPLEVEL_BINDING)
    $stdout.flush
    $stdout.rewind
    output = $stdout.read
    if output.empty?
      js("close_popup_hackety_hack()")
    else
      s[output]
    end
  rescue Quit, Complaint => e
    msg = e.says
    if msg and msg != e.class.name
      s[msg]
    else
      js("$('#stdout').hide()")
    end
  rescue Object => e
    s[HTML(e)]
  ensure
    $sandbox.each { |th| th.raise(Quit) if th != Thread.current }.clear
  end
end
