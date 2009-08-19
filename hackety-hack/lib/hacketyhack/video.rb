class Video
  attr_accessor :path
  def initialize(p)
    @path = p
  end
  def inspect
    "(Video #@path)"
  end
  def to_html
    src = Camping.escape(File.expand_path(@path)).gsub(/\//, '\\\\')
    name = File.basename(@path).gsub(/\W+/, '_')
    path = @path
    if File.exists?(File.expand_path(@path))
      Web.Bit do
        @auto_validation = false
        tag! :embed, :src => "/static/ufo.swf", :width => "500", :height => "400",
          :bgcolor => "#FFFFFF", :type => "application/x-shockwave-flash",
          :pluginspage => "http://www.macromedia.com/go/getflashplayer",
          :flashvars => "file=#{src}&autostart=true"
      end
    else
      Web.Bit { p { "Video #{strong(path)} not found" } }
    end
  end
end
def Video(path)
  Video.new(path)
end
