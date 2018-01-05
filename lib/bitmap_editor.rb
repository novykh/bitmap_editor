require 'matrix'

class BitmapEditor
  WHITE = "O"

  CMD_ARGS_REGEXES = {
    "I" => /^[1-9][0-9]*\s[1-9][0-9]*$/,
    "L" => /^[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/,
    "V" => /^[1-9][0-9]*\s[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/,
    "H" => /^[1-9][0-9]*\s[1-9][0-9]*\s[1-9][0-9]*\s[A-Z]$/
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

  def print_result
    puts "There is no image" and return if matrix.nil?

    matrix_string = matrix.to_a.map{|r| r.join("")}.join("\n")
    puts matrix_string
  end
end

class InvalidCommandError < StandardError; end
class InvalidArgumentError < StandardError; end
class MatrixNoDupError < StandardError; end
