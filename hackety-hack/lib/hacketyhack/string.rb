class String
  def starts?( beginning )
    self[0, beginning.length] == beginning
  end
  def ends?( ending )
    self[-ending.length, ending.length] == ending
  end
  def remove( phrase )
    r = dup
    r[phrase] = ""
    r
  end
  def to_html
    Hpricot.xs(self)
  end
end

# symbols and strings hash the same
class Symbol; def hash; to_s.hash; end; end
