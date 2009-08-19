module Camping::Controllers
  class Wakeup
    def get; end
  end
  
  class IRB < R '/irb'
    def get
      $sandbox << Thread.start do
        js("$('#waitingInfo').html('').show();")
        answer = 
          begin
            $stdout, $stderr = StringIO.new, StringIO.new
            def $stdout.print(*args)
              write(*args)
              nil
            end
            def $stdout.puts(*args)
              args.each { |x| print("#{x}\n") }
              nil
            end
            obj = IRBalike.run(@input['cmd']).inspect
            $stdout.flush
            $stdout.rewind
            output = $stdout.read
            "#{output}=> #{obj}"
          rescue MimickIRB::Empty
            "Reset"
          rescue MimickIRB::Continue
            ".."
          rescue Object => e
            e.friendly
          end
        js("$('#waitingInfo').hide(); window.irb.reply(" + answer.to_json + ")")
      end
    end
  end
  
  class Eval < R '/eval'
    def get
      hackety_run(@input['cmd'])
    end
  end
  
  class EvalCancel < R '/eval/cancel'
    def get
      $sandbox.each { |th| th.raise(Quit) }.clear
    end
  end
  
  class Learn
    def get
      HacketyHack.tutor = 'on'
      redirect HacketyHack.tutor_page
    end
  end
  
  class LearnClose
    def get
      HacketyHack.tutor = 'off'
    end
  end
  
  class Tutor < R '/tutor/(\d+)'
    def get(n)
      HacketyHack.tutor_lesson = n.to_i
      HacketyHack.get_tutor_html(n.to_i)
    end
  end

  class TutorIndex < R '/tutor/index'
    def get
      tutor_index
    end
  end

  class Console
    def get
      IRBalike.started = Time.now
      console
    end
  end
  
  class Static < R '/static/(.+)'
    def get(path)
      static path
    end
  end
  
  class Downloads < R '/Downloads/(.+)'
    def get(path)
      File.open(File.join(DOWNLOADS_DIR, path), 'rb') { |f| f.read }
    end
  end
  
  class Xxx < R '/XXX/(.+)'
    def get(path)
      File.open(path, 'rb') { |f| f.read }
    end
  end
  
  class Cache < R '/Cache/(.+)'
    def get(path)
      File.open(File.join(CACHE_DIR, path), 'rb') { |f| f.read }
    end
  end
  
  class Import
    def get
      div { puts @input.inspect }
    end
  end

  class Start < R '/', '/start'
    def get
      @title = 'Welcome!'
      @apps = Dir[File.join(HACKETY_USER, '*.rb')].map do |app|
        hackety_get(File.basename(app, '.rb'))
      end
      @tables = HacketyDB.tables
      show :start
    end
  end
  
  class Prefs
    def get
      @title = "Your Setup"
      show :prefs
    end
  end

  class PrefSave
    def get
      HacketyHack::PREFS.merge!(@input)
      HacketyHack.save_prefs
      show :prefs
    end
  end

  class New < R '/new'
    def get
      @title = 'Creating a New Program'
      @app = {:name => 'New'}
      show :edit
    end
  end
  
  class Edit < R '/edit/(.+)'
    def get(name)
      @title = "Editing #{name}"
      @app = hackety_get(name)
      show :edit
    end
  end
  
  class Share < R '/share/(.+)'
    def get(name)
      @app = hackety_get(name)
      hackety_run %{
        v = Hacker("#{HacketyHack::PREFS['hh_username']}").share_program("#{@app[:name]}.rb", #{@app[:script].dump})
        puts "Shared #{@app[:name]} (version \#{v}) on HacketyHack.net."
      }
    end
  end
  
  class Run < R '/run/(.+)'
    def get(name)
      @app = hackety_get(name)
      hackety_run(@app[:script])
    end
  end
  
  class Delete < R '/delete/(.+)'
    def get(name)
      hackety_delete(name)
      redirect Start
    end
  end
  
  class Save < R '/(save|new)/(.+)'
    def get(save_type, name)
      unless File.exists? File.join(HACKETY_USER, name + ".rb") and save_type == 'new'
        hackety_put(name, @input['script'])
        div { h1 'Saved' }
      else
        'FAILED'
      end
    end
  end
  
  class Help < R '/help', '/help/(.+)'
    def get(topic = nil)
      help topic
    end
  end
  
  class TableDelete < R '/table-delete/(.+)'
    def get(name)
      HacketyDB.drop_table(name)
      redirect Start
    end
  end
  
  class TableShare < R '/table-share/(.+)'
    def get(name)
      hackety_run %{
        v = Hacker("#{HacketyHack::PREFS['hh_username']}").share_table(#{name.dump})
        puts "Shared table #{name} on HacketyHack.net. \#{v}"
      }
    end
  end
  
  class Cheat
    def get
      xhtml_transitional do
        head do
          style <<-END, :type => "text/css"
            body { margin: 0; padding: 0; overflow-x: hidden; }
          END
          title "The Hackety Hack Cheat Sheet"
        end
        body { img :src => "/static/cheatsheet-1.png" }
      end
    end
  end
  
end

