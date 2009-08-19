class FetchError < StandardError; end
class SharedAlreadyError < StandardError; end

module YamlService
  def make_qs(hsh, prefix = [])
    hsh.map do |k, v|
      ary = prefix + [k]
      case v
      when Hash
        make_qs(v, ary)
      else
        ok = Camping.escape(ary.first) +
          ary[1..-1].map { |x| "[#{Camping.escape(x)}]" }.join
        "#{ok}=#{Camping.escape(v)}"
      end
    end.join("&")
  end
  
  def fetch_uri(meth, path = nil, params = nil)
    if meth == :Get
      Kernel.say("Checking HacketyHack.net")
    else
      Kernel.say("Sending to HacketyHack.net")
    end
    url = URI("#{@url}/#{path}")
    body, content_type = nil, nil
    case params
    when String
      body = params
    when Hash
      qs = make_qs(params)
      if meth == :Get
        url.query = qs
      else
        body, content_type = qs, 'application/x-www-form-urlencoded'
      end
    end
    req = Net::HTTP.const_get(meth).new(url.path)
    if body
      req.body = body
      req.content_type = content_type if content_type
    end
    if HacketyHack::PREFS['hh_username']
      req.basic_auth HacketyHack::PREFS['hh_username'], HacketyHack::PREFS['hh_pass']
    end
    res = nil
    Net::HTTP.new(url.host, url.port).start {|http|
      res = http.request(req)
    }
    case res
    when Net::HTTPOK, Net::HTTPCreated
      if res.content_type == "text/yaml"
        YAML.load(res.body)
      else
        res.body
      end
    when Net::HTTPBadRequest
      raise FetchError, res.body
    else
      if res.content_type == "text/yaml"
        raise YAML.load(res.body)
      else
        raise LoadError, res.body
      end
    end
  end
end

