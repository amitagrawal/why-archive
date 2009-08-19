module Kernel
  def js2(str)
    JSON.parse(js("toJsonString(#{str})"))
  end
  def say(*args)
    str = args.join.to_html
    str = "&nbsp;" if str.empty?
    js("$('#waitingInfo').html(" + str.to_json + ")")
    nil
  end
  def ask(*args)
    msg = args.join
    output = js("hacketyPrompt(" + msg.to_json + ")")
    raise Quit if output.empty?
    if output =~ /^[a-z]:\/\//
      output = URI(output)
    end
    output
  end
  def every(i, &blk)
    $sandbox <<
      Thread.start(i) do |x|
        loop do
          sleep(x) 
          blk[]
        end
      end
  end
  def gets
    ask("Enter something:")
  end
  def puts(*args)
    $stdout.puts(*args)
  end
  def print(*args)
    $stdout.print(*args)
  end
  def p(*args)
    puts(*args.map { |x| x.inspect })
  end
  def write(*args)
    args.each { |x| $stdout << x }
  end
  def abort(*args)
    msg = args.join
    raise Quit, msg
  end
  def exit(*args)
    raise Quit
  end
  def complain(*args)
    msg = args.join
    raise Complaint, msg
  end
end

# Object.blank?
 class Object
   def blank?
     if respond_to? :empty?
       empty?
     elsif respond_to? :zero?
       zero?
     else
       !self
     end
   end
 end
 
# manners
def HTML(str)
  Hpricot.fixup((str.respond_to?(:to_html) ? str : str.to_s).to_html)
end
