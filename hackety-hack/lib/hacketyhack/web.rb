module Web
def self.unescapeHTML(string)
  string.gsub(/&(.*?);/n) do
    match = $1.dup
    case match
    when /\Aamp\z/ni           then '&'
    when /\Aquot\z/ni          then '"'
    when /\Agt\z/ni            then '>'
    when /\Alt\z/ni            then '<'
    when /\A#0*(\d+)\z/n       then
      if Integer($1) < 256
        Integer($1).chr
      else
        if Integer($1) < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
          [Integer($1)].pack("U")
        else
          "&##{$1};"
        end
      end
    when /\A#x([0-9a-f]+)\z/ni then
      if $1.hex < 256
        $1.hex.chr
      else
        if $1.hex < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
          [$1.hex].pack("U")
        else
          "&#x#{$1};"
        end
      end
    else
      "&#{match};"
    end
  end
end
class Feed
  attr_accessor :title, :link, :description, :items
  def initialize(doc)
    @title = Web::Bit.new(Web.unescapeHTML((doc/"feed/title, channel/title").text))
    link = doc.at("feed/link, channel/link")
    @link = link['href'] || link.inner_text
    @description = Web::Bit.new(Web.unescapeHTML((doc/"feed/tagline, channel/description").text))
    @items = []
    (doc/"feed/entry, item").each do |item|
      link = item.at("/link")
      @items << Item.new(
        Web.unescapeHTML((item/"/title").text),
        link['href'] || link.inner_text,
        Web.unescapeHTML((item/"content, content:encoded, description").text))
    end
  end
  def to_html
    feed = self
    Web.Bit {
      h5 "Web::Feed from #{feed.link}"
      h1 { self << feed.title }
      p { self << feed.description } unless feed.description.blank?
      self << feed.items.map { |item| item.to_html }.join
    }
  end
  def self.parse(data)
    doc = Hpricot::XML(data)
    if doc.at("/rss, /feed, rdf:rdf, rdf:RDF")
      Web::Feed.new(doc)
    elsif link = doc.at("link[@type='application/atom+xml'], link[@type='application/rss+xml']")
      Web.fetch(URI.join(data.base_uri.to_s, URI(link['href'])), :as => Web::Feed)
    else
      doc
    end
  end
  def each(&blk)
    items.each(&blk)
  end
end
class Item
  attr_accessor :title, :link, :description
  def to_s; "(Web::Item)" end
  def initialize(t, l, d)
    @title, @link, @description = Web::Bit.new(t), l, Web::Bit.new(d)
  end
  def to_html
    item = self
    Web.Bit {
      div.entry { 
        p { strong { 
          a(:href => item.link, :title => item.link) { self << item.title }
          puts " Web::Item" 
        } }
        self << item.description
      }
    }
  end
end
def self.google(search, opts = {})
  if search.respond_to? :join
    search = search.join(" ")
  end
  opts[:limit] ||= 10
  url = "num=#{opts[:limit]+3}"
  if opts[:exact]
    search = "\"#{search}\""
  end
  if opts[:page].to_i > 1
    url += "&start=#{opts[:limit] * (opts[:page].to_i - 1)}"
  end
  if opts[:site]
    if opts[:site].respond_to?(:join)
      search += "( site:#{opts[:site].join(' | site:')} )"
    else
      search += " site:#{opts[:site]}"
    end
  end
  ggl = Hpricot(Web.fetch("http://www.google.com/search?q=#{URI.escape(search)}&#{url}"))
  (ggl/"div.g")[0,opts[:limit]].map do |ele|
    Item.new(ele.at("a").inner_text, ele.at("a")['href'], (ele/("font".."font/br")).to_html)
  end
end
def self.delicious_search(search, opts = {})
  if search.respond_to? :join
    search = search.join(" ")
  end
  opts[:limit] ||= 10
  url = "setcount=#{opts[:limit]}"
  if opts[:exact]
    search = "\"#{search}\""
  end
  if opts[:page].to_i > 1
    url += "&page=#{opts[:page]}"
  end
  dls = Hpricot(Web.fetch("http://del.icio.us/search?p=#{URI.escape(search)}&#{url}"))
  ((dls/"ol.posts").last/"li.post").map do |ele|
    meta = (ele/".meta")
    (meta/"a[@href]").each { |x| x.raw_attributes['href'] = "http://del.icio.us/#{x['href']}" }
    Item.new(ele.at("a").inner_text, ele.at("a")['href'], meta.to_html)
  end
end
def self.yahoo(search, opts = {})
  if search.respond_to? :join
    search = search.join(" ")
  end
  opts[:limit] ||= 10
  url = "n=#{opts[:limit]}"
  if opts[:exact]
    search = "\"#{search}\""
  end
  if opts[:page].to_i > 1
    url += "&b=#{opts[:limit] * (opts[:page].to_i - 1)}"
  end
  if opts[:site]
    url += "&vs=#{URI.escape([*opts[:site]].join(" | "))}"
  end
  yahoo = Hpricot(Web.fetch("http://search.yahoo.com/search?p=#{URI.escape(search)}&#{url}"))
  (yahoo/"div#yschweb li").map do |ele|
    Item.new(ele.at(".yschttl").inner_text, ele.at(".yschttl")['href'], (ele/".yschabstr").to_html)
  end
end
class << self
  def table(name)
    Hacker(HacketyHack::PREFS['hh_username']).load_table(name)  
  end

  def page(name = nil, &blk)
    b = WebPage(name, &blk)
    $stdout.write b
    b
  end
  
  def popup(name = nil, &blk)
    page = WebPage(name, &blk)
    x = "#{page}"
    js %[
      $('#popup').html(#{x.to_json});
      $('#popup input#cancel').click(close_popup_hackety_hack);
      $('#popup input#save').click(save_popup_hackety_hack);
      $('#popup input#ok').click(save_popup_hackety_hack);
      $('#popup input[@type="button"]').click(pressed_popup_hackety_hack);
      $('#popup a.link_to').click(function(){
        $('input#clicked').val($(this).text());
        save_popup_hackety_hack();
      });
      $('#popup_hackety_hack').show();
    ]
    while js("$('#popup_hackety_hack').css('display')") == 'block'
      b = js2("event_popup_hackety_hack()")
      if b and page.opts[:button_handlers] and page.opts[:button_handlers][b]
        frm = js2("popup_hackety_form()")
        frm[b] = 'Clicked'
        page.opts[:button_handlers][b][frm]
      end
      sleep 0.2
    end
    data = js2("popup_hackety_form()")
    raise Quit if data.empty?
    if name
      if data.detect { |k,v| not v.blank? }
        Table(name).save(data)
      end
    end
    js("$('#popup').html('')")
    data['clicked'] or data
  end
  
  JSON_MIME_TYPES = ["application/x-javascript", "application/x-json", "application/json"]
  XML_MIME_TYPES = ["application/rdf+xml", "application/rss+xml", "application/atom+xml", "application/xml", "text/xml"]
  [JSON_MIME_TYPES, XML_MIME_TYPES].each do |ary|
    ary.map! { |str| /^#{Regexp::quote(str)}/ }
  end
  def fetch(uri, opts = {})
    opts[:fetch] = true
    data = download(uri, opts)
    unless opts[:as]
      opts[:as] =
        case data.content_type
        when *JSON_MIME_TYPES; JSON
        when *XML_MIME_TYPES; Web::Feed
        end
    end
    if opts[:as]
      if opts[:as].respond_to? :parse
        obj = opts[:as].parse(data)
        OpenURI::Meta.init(obj, data)
        obj
      elsif opts[:as] == String
        data
      else
        raise ArgumentError, "Web.fetch can't load into the #{opts[:as]} class"
      end
    else
      data
    end
  end
  
  def download(url, opts = {}, &blk)
    unless opts.is_a? Hash
      opts = {:save_as => opts}
    end
    opts[:limit] ||= 10
    if opts[:limit].zero?
      raise LoadError, "Too many redirects, the file cannot be downloaded."
    end
    if opts[:save_as] and blk
      raise ArgumentError, "Web.download cannot take both a filename and a block."
    end
    uri, ret = URI(url.to_s), nil
    uri = URI("http://#{url}") if uri.class == URI::Generic and (url = url.to_s) =~ /^\w/ 
    say "Downloading #{uri}"
    klass = Net::HTTP
    if HacketyHack::PREFS["hh_proxy"]
      proxy_uri = URI(HacketyHack::PREFS["hh_proxy"])
      proxy_user, proxy_pass = uri.userinfo.split(/:/) if proxy_uri.userinfo
      klass = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, proxy_user, proxy_pass)
    end
    klass.start(uri.host, uri.port) do |http|
      http.request_get(uri.request_uri, {'User-Agent' => "Hackety Hack v#{HacketyHack::VERSION}", 'Accept' => '*/*', 'Host' => uri.host}) do |r|
        ret =
        case r
        when Net::HTTPSuccess
          len = 0
          progress = proc do |chunk|
            len += chunk.length
            if r.content_length
              say "Downloading %s (%0.1f%%)" % [opts[:save_as], ((len * 1.0) / r.content_length) * 100]
            else
              say "Downloading %s" % [opts[:save_as]]
            end
          end
          if blk
            opts[:save_as] = File.basename(uri.path)
            r.read_body do |chunk|
              blk[chunk]
              progress[chunk]
            end
            nil
          elsif opts[:fetch]
            output = ''
            opts[:save_as] = File.basename(uri.path)
            r.read_body do |chunk|
              output += chunk
              progress[chunk]
            end
            output
          else
            opts[:save_as] ||= File.basename(uri.path)
            save_as = File.expand_path(opts[:save_as], DOWNLOADS_DIR)
            save_part = "#{save_as}.part"
            begin
              File.open(save_part, 'wb') do |f|
                r.read_body do |chunk|
                  f.write(chunk)
                  progress[chunk]
                end
              end
              File.move(save_part, save_as)
            ensure
              File.delete(save_part) if File.exists?(save_part)
            end
            nil
          end
        when Net::HTTPRedirection
          say "The web address is #{r.message.downcase}."
          if r.header['Location']
            opts[:limit] -= 1
            Web.download(r.header['Location'], opts, &blk)
          end
        when Net::HTTPNotFound
          complain "That web address doesn't exist."
        else
          complain "There was a problem with that web address: #{r.message}"
        end
        if ret
          ret.extend OpenURI::Meta
          ret.instance_eval {
            @base_uri = uri
            @meta = {}
          }
          r.each {|name,value| ret.meta_add_field name, value }
        end
      end
    end
    ret
  end
end
def self.Bit &blk
  Web::Bit.new(Camping::Page.build(:mixin => Web::Bit::Custom, &blk).to_s)
end
end

class Web::Bit < String
  def words
    scan(/\b\w+\b/)
  end
  def to_html
    self
  end
end

module Web::PageLayout
  def theme name = nil
    style :type => "text/css" do
      self << <<-END
        div.webpage {
          font-family: verdana, arial, sans-serif;
          border: inset 1px;
          padding: 6px;
          background: white url(/static/hackety-fade.png) repeat-x;
        }
        div.webpage > div.wrap > div.banner {
          color: black;
          padding: 16px 20px;
          background: url(/static/hackety-hand-br.png) 36px 12px no-repeat;
          width: 440px;
          margin: 10px auto;
        }
        div.webpage div.banner h1,
        div.webpage div.banner h2 {
          font-weight: normal;
          text-align: left;
          color: #113;
          padding-left: 90px;
          margin: 0;
        }
        div.webpage div.banner h2 {
          font-size: 12px;
        }
        div.webpage > div.wrap > div.column {
          float: left;
          width: 100%;
          margin-left: -156px;
          border-right: solid 156px transparent;
          margin-right: -156px;
        }
        div.webpage > div.wrap > div.column h1 {
          margin: 5px 0;
          color: #D72;
          font-weight: bold;
          font-size: 20px;
          text-align: left;
        }
        div.webpage > div.wrap > div.column h2 {
          margin: 5px 0;
          color: #D27;
          font-weight: normal;
          font-size: 13px;
          text-align: left;
        }
        div.webpage > div.wrap > div.column > div.box {
          background: white;
          padding: 12px 6px;
          margin-left: 156px;
        }
        div.webpage > div.wrap > div.column + div.column {
          margin: 0; padding: 6px;
          float: right;
          width: 140px;
          border: none;
        }
        div.webpage > div.wrap > div.column + div.column h1 {
          font-size: 12px;
        }
        div.webpage > div.wrap > div.column + div.column > div.box {
          font-size: 11px;
          margin: 0;
          text-align: left;
        }
        div.webpage > div.wrap > div.column + div.column > div.box ol {
          list-style: none;
        }
      END
    end
  end
  def banner &blk
    div.banner &blk
  end
  def column &blk
    div.column do
      div.box(&blk)
    end
  end
end

module Web::Bit::Custom
  attr_accessor :name, :opts
  def title(str)
    h1 str, :class => "title"
  end
  def subtitle(str)
    h2 str, :class => "subtitle"
  end
  def para(str)
    p str
  end
  def editline(name)
    div.required do
      label name, :for => name
      input :type => 'text', :name => name
    end
  end
  def scrollbox(name = 'scrollbox')
    div(:class => "scrollboxclass", :id => name) {}
  end
  def update(name, obj)
    html = HTML(obj)
    js("$('div##{name}').append('<div class=\"scrollboxitem\">' + #{html.to_s.dump} + '</div>').get(0).scrollTop = 99999999")
  end
  def editbox(name = 'Editbox')
    div.required do
      label name, :for => name
      textarea :rows => 5, :cols => 30, :name => name
    end
  end
  BUTTON_NAMES = {:cancel => 'Cancel', :ok => 'OK'}
  def buttons(*names, &blk)
    @opts[:button_handlers] ||= {}
    if names.empty?
      # TODO: Get rid of!!
      div.buttons! do
        meta_def(:cancel) { input.cancel! :type => 'button', :value => 'Cancel' }
        meta_def(:save) { input.save! :type => 'button', :value => 'Save' }
        meta_def(:ok) { input.ok! :type => 'button', :value => 'OK' }
        instance_eval &blk
        meta_undef(:cancel)
        meta_undef(:save)
        meta_undef(:ok)
      end
    else
      div.buttons! do
        names.each do |x|
          n = BUTTON_NAMES[x] || x.to_s.capitalize
          @opts[:button_handlers][n] = blk
          input(:id => x.to_s, :type => 'button', :value => n)
        end
      end
    end
  end
  def bullets(&blk)
    ul do
      instance_eval %{
        def tag!(*a, &b)
          if a[0] != :li && a[0] != :input
            li { tag!(*a, &b) }
          else
            super(*a, &b)
          end
        end
      }
      instance_eval &blk
      meta_undef(:tag!)
    end
  end
  def list(&blk)
    ol do
      instance_eval %{
        def tag!(*a, &b)
          if a[0] != :li && a[0] != :input
            li { tag!(*a, &b) }
          else
            super(*a, &b)
          end
        end
      }
      instance_eval &blk
      meta_undef(:tag!)
    end
  end
  def puts(*a)
    a.each { |x| text(HTML(x)); br }
    nil
  end
  def print(*a)
    a.each { |x| text(HTML(x)) }
    nil
  end
  def link_to(name)
    unless @hidden_link_input
      input.clicked! :type => 'hidden', :name => 'clicked'
      @hidden_link_input = true
    end
    a.link_to name, :href => 'javascript:;'
  end
  def save
    puts "Saved"
  end
end

def WebPage(name = nil, &blk)
  Camping::Page.build(:mixin => [Web::Bit::Custom, Web::PageLayout]) do
    self.name = name
    div.webpage do
      div.wrap do
        instance_eval(&blk)
        br :clear => "all"
      end
    end
  end
end
