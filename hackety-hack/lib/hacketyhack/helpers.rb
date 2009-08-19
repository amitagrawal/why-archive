module Camping::Base
  def redirect(*a)
    script(:language => "Javascript") do
      url = a.first.is_a?(String) ? a.first : R(*a)
      self << <<-END
        window.location = "#{url}"
      END
    end
  end
  def hackety_get(name)
    path = File.join(HACKETY_USER, name + '.rb')
    app = {:name => name,
      :script => File.read(path)}
    m, = *app[:script].match(/\A(([ \t]*#.+)\r?\n)+/)
    app[:mtime] = File.mtime(path)
    app[:desc] = m.gsub(/^[ \t]*#+[ \t]*/, '') if m
    app
  end
  def hackety_put(name, script)
    File.open(File.join(HACKETY_USER, name + '.rb'), 'w') do |f|
      f << script
    end
  end
  def hackety_delete(name)
    fname = File.join(HACKETY_USER, name + '.rb')
    File.delete(fname)
  end
  def hackety_run(code)
    $sandbox << Thread.start { Camping::Sandbox.new.evaluate(code) }
  end
  def static path
    File.open(File.join(HACKETY_HOME, 'static', path), 'rb') { |f| f.read }
  end
end

