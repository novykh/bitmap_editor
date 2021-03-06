require 'matrix'

class BitmapEditor
  WHITE = "O"

  CMD_ARGS_REGEXES = {
    "I" => /^[1-9][0-9]*\s[1-9][0-9]*$/,
    "L" => /^[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/,
    "V" => /^[1-9][0-9]*\s[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/,
    "H" => /^[1-9][0-9]*\s[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/,
    "F" => /^[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/,
  }.freeze

  attr_reader :matrix, :rows, :columns

  def run(file)
    raise StandardError.new("Please provide correct file") if file.nil? || !File.exists?(file)

    File.open(file).each_with_index do |line, i|
      cmd, args = parse_line(line, i + 1)

      case cmd
        when "I"
          build_matrix(*args)
        when "S"
          return print_result
        when "C"
          ensure_matrix { clear_matrix }
        when "L"
          ensure_matrix { draw_pixel(*args) }
        when "V"
          ensure_matrix { draw_vertical_segment(*args) }
        when "H"
          ensure_matrix { draw_horizontal_segment(*args) }
        when "F"
          ensure_matrix { bucket_fill(*args) }
        else
          raise InvalidCommandError.new("Unrecognised command `#{cmd}` - accepts I, S, C, L, V, H")
      end
    end
  end

  private

  def parse_line(line, line_num)
    line.chomp!
    raise InvalidCommandError.new("Empty line in file - line #{line_num} :(") if line.empty?

    cmd, args = line.split(/\s/, 2)
    validate_cmd_args(cmd, args, line_num)

    args = args.split(/\s/) unless args.nil?
    [cmd, args]
  end

  def validate_cmd_args(cmd, args, line_num)
    regex = CMD_ARGS_REGEXES[cmd]
    raise InvalidArgumentError.new("Invalid arguments for `#{cmd}` command - line #{line_num}") if regex && args !~ regex
    true
  end

  def build_matrix(c, r)
    raise MatrixNoDupError.new("Cannot create multiple images, sorry :)") unless matrix.nil?
    @rows = r.to_i
    @columns = c.to_i

    @matrix = Matrix.build(rows, columns) {|m| WHITE}
  end

  def clear_matrix
    @matrix = Matrix.build(rows, columns) {|m| WHITE}
  end

  def draw_pixel(column, row, color)
    update_matrix(color, {
      start_row: coerce_to_cell_idx(row),
      start_column: coerce_to_cell_idx(column)
    })
  end

  def draw_vertical_segment(column, start_row, end_row, color)
    update_matrix(color, {
      start_column: coerce_to_cell_idx(column),
      start_row: coerce_to_cell_idx(start_row),
      end_row: coerce_to_cell_idx(end_row)
    })
  end

  def draw_horizontal_segment(start_column, end_column, row, color)
    update_matrix(color, {
      start_row: coerce_to_cell_idx(row),
      start_column: coerce_to_cell_idx(start_column),
      end_column: coerce_to_cell_idx(end_column)
    })
  end

  def update_matrix(color, start_row:nil, end_row:nil, start_column:nil, end_column:nil)
    arr = matrix.to_a
    end_row ||= start_row
    end_column ||= start_column

    raise InvalidArgumentError.new("Start row out of bounds") if start_row > rows
    raise InvalidArgumentError.new("End row smaller than start row") if end_row < start_row
    raise InvalidArgumentError.new("End row out of bounds") if end_row > rows

    raise InvalidArgumentError.new("Start column out of bounds") if start_column > columns
    raise InvalidArgumentError.new("End column smaller than start column") if end_column < start_column
    raise InvalidArgumentError.new("End column out of bounds") if end_column > columns


    for r in start_row..end_row do
      for c in start_column..end_column do
        arr[r][c] = color;
      end
    end

    @matrix = Matrix[*arr]
  end

  def bucket_fill(column, row, color)
    arr = matrix.to_a

    column = coerce_to_cell_idx(column)
    row = coerce_to_cell_idx(row)
    previous_color = arr[row][column]

    arr = fill_around(arr, column, row, color, previous_color)
    @matrix = Matrix[*arr]
  end

  def fill_around(arr, column, row, color, target_color)
    if arr[row][column] == target_color
      arr[row][column] = color
    else
      return arr
    end

    start_row = row > 0 ? row - 1 : 0
    end_column = column < columns - 1 ? column + 1 : columns - 1
    end_row = row < rows - 1 ? row + 1 : rows - 1
    start_column = column > 0 ? column - 1 : 0

    if start_column == 0 && end_column == columns - 1 && start_row == 0 && end_row == rows - 1
      return arr
    end

    for i in start_column..end_column do
      arr = fill_around(arr, i, start_row, color, target_color)
    end

    for i in start_row..end_row do
      arr = fill_around(arr, end_column, i, color, target_color)
    end

    for i in start_column..end_column do
      arr = fill_around(arr, i, end_row, color, target_color)
    end

    for i in start_row..end_row do
      arr = fill_around(arr, start_column, i, color, target_color)
    end

    arr
  end


  def ensure_matrix(&block)
    raise MatrixNotPresentError.new("Tried to run a command on an image without creating it first :(") if matrix.nil?

    yield
  end

  def print_result
    puts "There is no image" and return if matrix.nil?

    matrix_string = matrix.to_a.map{|r| r.join("")}.join("\n")
    puts matrix_string
    return matrix_string
  end

  def coerce_to_cell_idx(num)
    num.to_i - 1
  end
end

class InvalidCommandError < StandardError; end
class InvalidArgumentError < StandardError; end
class MatrixNoDupError < StandardError; end
class MatrixNotPresentError < StandardError; end
