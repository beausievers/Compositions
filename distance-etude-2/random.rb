def box_mueller(mean = 0.0, stddev = 1.0)
  x1 = 0.0, x2 = 0.0, w = 0.0

  until w > 0.0 && w < 1.0
    x1 = 2.0 * rand - 1.0
    x2 = 2.0 * rand - 1.0
    w = (x1 * x2) + (x2 * x2)
  end

  w = Math.sqrt(-2.0 * Math.log(w) / w)
  r = x1 * w

  mean + r * stddev
end

def gaussian_in_range(mean = 0.0, std = 1.0, min = -1.0, max = 1.0)
  begin
    x = box_mueller(mean, std)
  end while x < min || x > max
  x
end
