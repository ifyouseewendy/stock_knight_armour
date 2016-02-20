class Array
  def avg
    return 0 if count == 0
    (sum.to_f / count).round(2)
  end
end
