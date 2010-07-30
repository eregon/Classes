require_relative 'matrix'

module Math
  # Pascal's triangle

  # by definition, from wikipedia
  # Very fast (773 in 1s)
  def pascal_normal(n)
    c = Array.new(n+1) { |i| Array.new(i+1) }
    (0..n).each { |i|
      c[i][0], c[i][i] = 1, 1
      (1...i).each { |j|
        c[i][j] = c[i-1][j-1] + c[i-1][j]
      }
    }
    c
  end
  module_function :pascal_normal

  # Matthew Moss
  # Quite fast (513 in 1s)
  def pascal_inject(n)
    rows = [[1]]
    row = rows[0]
    1.upto(n) {
      row = row.inject([0]) { |m, o| m[0...-1] << (m[-1] + o) << o }
      rows << row
    }
    rows
  end
  module_function :pascal_inject

  # Eregon
  # Very slow (32 in 1s)
  def pascal_matrix(n)
    matrix = EMatrix.new(n+1) { |i, j|
      (i == j+1) ? i : 0
    }
    r = matrix.exp(n+1)
    r.to_a.map { |row| row.reject { |e| e == 0 } }
  end
  module_function :pascal_matrix

  def show_pascal_triangle(rows)
    len = rows[-1].map { |e| e.to_s.length }.max
    max_len = rows[-1].join(" "*len).length
    rows.each { |row|
      puts row.join(" "*len).center(max_len)
    }
  end
  module_function :show_pascal_triangle
end