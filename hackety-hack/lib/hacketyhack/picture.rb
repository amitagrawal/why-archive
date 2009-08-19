class Picture
  yaml_as "tag:hacketyhack.net,2007:picture"
  attr_accessor :path
  def initialize(p)
    @path = p
  end
  def inspect
    "(Picture #@path)"
  end
  # # Messing with data: URIs
  # def to_html
  #   require 'base64'
  #   mime = "image/#{File.extname(@path)[1..-1].downcase}"
  #   path = @path
  #   Web.Bit do
  #     dat = File.open(path, 'rb') { |f| f.read }
  #     dat = Base64.encode64(dat).delete("\n")
  #     img :src => "data:#{mime};base64,#{Camping.escape(dat)}"
  #   end
  # end
  # def yaml_initialize(tag, val)
  #   @path = File.join(CACHE_DIR, val['name'])
  #   File.open(@path, 'wb') { |f| f << val['data'] }
  # end
  def to_html
    path = @path
    Web.Bit do
      path = "/XXX/#{path}" if path !~ %r!^\w+://!
      img :src => path
    end
  end
end
def Picture(path)
  Picture.new(path)
end
