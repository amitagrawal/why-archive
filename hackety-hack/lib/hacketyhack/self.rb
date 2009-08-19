module HacketyHack
  PREFS = {}
  SHARES = {}

  class << self
    def tutor_on?
      PREFS['tutor'] == 'on'
    end

    def tutor=(state)
      PREFS['tutor'] = state
      save_prefs
    end

    def tutor_lesson
      (PREFS['tut_lesson'] || 0).to_i
    end

    def tutor_lesson=(n)
      PREFS['tut_lesson']=n
      save_prefs
    end

    def tutor_page
      PREFS['tut_page'] || '/start'
    end

    def tutor_page=(p)
      PREFS['tut_page']=p
      save_prefs
    end

    def dewikify(str)
      str.split(/\s*?(\{{3}(?:.+?)\}{3})|\n\n/m).map do |para|
        next if para.empty?
        if para =~ /\{{3}(?:\s*\#![^\n]+)?(.+?)\}{3}/m
          Hpricot { pre($1) }.to_s.gsub(/ +#=\&gt;.+$/, '<span class="outputs">\0</span>').
            gsub(/ +# .+$/, '<span class="comment">\0</span>').to_s
        else
          case para
          when /\A \* (.+)/m
            txt = Hpricot { ul { $1.split(/^ \* /).map { |x| li x } } }.to_s
          when /\A==== (.+) ====/
            txt = Hpricot { h4($1) }.to_s
          when /\A=== (.+) ===/
            txt = Hpricot { h3($1) }.to_s
          when /\A== (.+) ==/
            txt = Hpricot { h2($1) }.to_s
          when /\A= (.+) =/
            txt = Hpricot { h1($1) }.to_s
          else
            txt = Hpricot { p(para) }.to_s
          end
          txt.gsub(/`(.+?)`/m, '<code>\1</code>').gsub(/\[\[BR\]\]/i, '<br />').
            gsub(/'''(.+?)'''/m, '<strong>\1</strong>').gsub(/''(.+?)''/m, '<em>\1</em>').
            gsub(/\[\[(\S+?) (.+?)\]\]/m, '<a href="\1">\2</a>').
            gsub(/\(\!\)/m, '<img src="/static/exclamation.png" />').
            gsub(/\!\\(\S+\.png)\!/, '<img class="inline" src="/static/\1" />').
            gsub(/\!(\S+\.png)\!/, '<img src="/static/\1" />')
        end
      end.join
    end
    
    def load_tutor(str)
      index = []
      i = 0
      lessons =
        (str.split(/^(=+ .+?) =+/)[1..-1]/2).map do |k,v|
          n = k[/^=+/].length
          k.gsub!(/^=+ /, '')
          if k.gsub!(/^([^:]+): /, '')
            sub = "<h4>#$1</h4>"
            index << [i, k] if n == 1
          end
          i += 1
          "#{sub}<h#{n}>#{k}</h#{n}>#{dewikify(v)}"
        end
      [index, lessons]
    end

    def get_tutor_html(i)
      lesson = win_vars(HacketyHack::TUTOR[i])
      if i < HacketyHack::TUTOR.length - 1
        lesson += "<div class='nextpage'><a href='javascript:;' onclick='tutor_next()'>Continue &rarr;</a></div>"
      end
      lesson
    end

    def load_docs(str)
      (str.split(/^= (.+?) =/)[1..-1]/2).map do |k,v|
        sparts = v.split(/^== (.+?) ==/)
        sections = (sparts[1..-1]/2).map do |k2,v2|
          meth = v2.split(/^=== (.+?) ===/)
          [k2[/^(?:The )?(\S+)/, 1],
           {'title' => k2,
            'description' => dewikify(meth[0]),
            'methods' => (meth[1..-1]/2).map { |_k,_v| [_k, dewikify(_v)] }}]
        end
        [k, {'description' => dewikify(sparts[0]), 'sections' => sections, 'class' => "toc" + k.downcase.gsub(/\W+/, '')}]
      end
    end

    def save_prefs
      preft = HacketyDB["HACKETY_PREFS"]
      preft.delete
      PREFS.each do |k, v|
        preft.insert(:name => k, :value => v)
      end
      nil
    end

    def load_prefs
      HacketyDB["HACKETY_PREFS"].each do |row|
        PREFS[row[:name]] = row[:value] unless row[:value].strip.empty?
      end
      PREFS['tutor'] = 'off'
    end

    def load_shares
      SHARES.clear
      HacketyDB["HACKETY_SHARES"].each do |row|
        SHARES["#{row[:title]}:#{row[:klass]}"] = row[:active]
      end
    end

    def add_share(title, klass)
      share = {:title => title, :klass => klass, :active => 1}
      HacketyDB["HACKETY_SHARES"].insert(share)
      SHARES["#{title}:#{klass}"] = 1
    end

    def check_share(title, klass)
      SHARES["#{title}:#{klass}"]
    end

    def win_vars(str)
      str.gsub(/%DESKTOP%/, ENV['DESKTOP']).
        gsub(/%USERNAME%/) { HacketyHack::PREFS['hh_username'] }.
        gsub(/%APPDATA%/, ENV['APPDATA']).
        gsub(/%MYDOCUMENTS%/, ENV['MYDOCUMENTS']).
        gsub(/%HACKETY_USER%/) { HACKETY_USER }
    end

    def win_path(str)
      win_vars(str.gsub(/\\/, '/'))
    end
  end
end

