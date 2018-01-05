class BitmapEditor2
  WHITE = "O"

  CMD_ARGS_REGEXES = {
    "I" => /^[1-9][0-9]*\s[1-9][0-9]*$/,
    "L" => /^[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/,
    "V" => /^[1-9][0-9]*\s[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/,
    "H" => /^[1-9][0-9]*\s[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/
  }.freeze

  def initialize
    @rules = []
  end

  attr_reader :rows, :columns, :rules

  def run(file)
    raise StandardError.new("Please provide correct file") if file.nil? || !File.exists?(file)

    File.open(file).each_with_index do |line, i|
      cmd, args = parse_line(line, i + 1)

      case cmd
        when "I"
          raise MatrixNoDupError.new("Cannot create multiple images, sorry :)") unless rows.nil? || columns.nil?

          @columns, @rows = args.map(&:to_i)
        when "C"
          ensure_matrix { set_clear_matrix_rule }
        when "L"
          ensure_matrix { set_draw_pixel_rule(*args) }
        when "V"
          ensure_matrix { set_draw_vertical_segment_rule(*args) }
        when "H"
          ensure_matrix { set_draw_horizontal_segment_rule(*args) }
        when "S"
          return print_result(construct_matrix_string)
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

  def set_clear_matrix_rule
    set_rule(WHITE, {
      start_row: 0,
      end_row: coerce_to_cell_idx(rows),
      start_column: 0,
      end_column: coerce_to_cell_idx(columns)
    })
  end

  def set_draw_pixel_rule(column, row, color)
    set_rule(color, {
      start_row: coerce_to_cell_idx(row),
      start_column: coerce_to_cell_idx(column)
    })
  end

  def set_draw_vertical_segment_rule(column, start_row, end_row, color)
    set_rule(color, {
      start_column: coerce_to_cell_idx(column),
      start_row: coerce_to_cell_idx(start_row),
      end_row: coerce_to_cell_idx(end_row)
    })
  end

  def set_draw_horizontal_segment_rule(start_column, end_column, row, color)
    set_rule(color, {
      start_row: coerce_to_cell_idx(row),
      start_column: coerce_to_cell_idx(start_column),
      end_column: coerce_to_cell_idx(end_column)
    })
  end

  def set_rule(color, start_row:nil, end_row:nil, start_column:nil, end_column:nil)
    end_row ||= start_row
    end_column ||= start_column

    raise InvalidArgumentError.new("Start row out of bounds") if start_row > rows
    raise InvalidArgumentError.new("End row smaller than start row") if end_row < start_row
    raise InvalidArgumentError.new("End row out of bounds") if end_row > rows

    raise InvalidArgumentError.new("Start column out of bounds") if start_column > columns
    raise InvalidArgumentError.new("End column smaller than start column") if end_column < start_column
    raise InvalidArgumentError.new("End column out of bounds") if end_column > columns

    rules.unshift({
      start_row: start_row,
      end_row: end_row,
      start_column: start_column,
      end_column: end_column,
      color: color
    })
  end

  def ensure_matrix(&block)
    raise MatrixNotPresentError.new("Tried to run a command on an image without creating it first :(") if rows.nil? || columns.nil?

    yield
  end

  def print_result(result)
    puts "There is no image" and return if rows.nil? || columns.nil?

    puts result
    return result
  end

  def construct_matrix_string
    matrix = []
    matrix_string = (0..rows - 1).map {|r|
      matrix[r] ||= []

      (0..columns - 1).map {|c|
        rule = rules.find {|rule|
          rule[:start_row] <= r && rule[:end_row] >= r &&
          rule[:start_column] <= c && rule[:end_column] >= c
        }

        matrix[r][c] = rule && rule[:color] || WHITE;
      }.join("")
    }.join("\n")
  end

  def coerce_to_cell_idx(num)
    num.to_i - 1
  end
end

class InvalidCommandError < StandardError; end
class InvalidArgumentError < StandardError; end
class MatrixNoDupError < StandardError; end
class MatrixNotPresentError < StandardError; end
