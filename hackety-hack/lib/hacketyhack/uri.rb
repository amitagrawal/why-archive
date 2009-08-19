class URI::HTTP
  def [](a)
    Camping.qsp(query)[a]
  end
end
