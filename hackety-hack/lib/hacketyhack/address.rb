def Address(str)
  Address.new(str)
end
class Address < String
  def to_html
   addr = self
   pict = Picture(Web.fetch("http://api.local.yahoo.com/MapsService/V1/mapImage?appid=YahooDemo&image_width=474&location=#{URI.escape(addr)}", :as => Hpricot).at("result").inner_text).to_html
   Web.Bit do
     text pict
     small "#{addr}"
   end
  rescue
    addr = self
    Web.Bit do
      puts "Map for address "
      strong addr
      puts " could not be found."
    end
  end
end
