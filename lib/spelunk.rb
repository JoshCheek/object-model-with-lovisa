require 'rouge'
require 'io/console'
require 'pp'

# :enabled?,
# :event,
# :lineno,
# :path,
# :method_id,
# :defined_class,
# :binding,
# :self,
# :return_value,
# :raised_exception]]

class Spelunk
  attr_accessor :path, :events, :current_index

  def initialize(path)
    self.path          = path
    self.events        = []
    self.current_index = 0
  end

  def raw_body
    @raw_body ||= File.read path
  end

  def record(event)
    type = event[:event]
    unless type == :c_call || type == :c_return
      events << event
    end
  end

  def done?
    event.nil?
  end

  def event
    events[current_index]
  end

  def highlighted
    highlighted_body(event)
  end

  def forward
    self.current_index += 1
  end

  def backward
    self.current_index -= 1
  end

  def highlighted_body(event)
    # =====  highlighted code =====
    line        = event.fetch :lineno, -1
    min_index   = [line-10, 0].max
    max_index   = min_index+20

    highlighted_body = highlight_ruby(raw_body)
    editor_view = highlighted_body.lines.map.with_index(1) { |code, lineno|
      gutter = "   \e[34m"
      gutter = "\e[41;37m ->" if line == lineno
      gutter + ("%4d\e[0m: #{code}\r" % lineno)
    }.join

    # =====  truncate the code  =====
    height, width = $stdin.winsize
    rhs_cols = width - 40
    truncate_code = "\e[0m" << height.times.map do |y|
      "\e[#{y+1};40H" << (" "*rhs_cols)
    end.join

    # =====  binding  =====
    binding = event[:binding]
    locals = binding.local_variables.map { |name|
      [name, binding.local_variable_get(name)]
    }.to_h

    locals_view = highlight_ruby(locals.pretty_inspect).lines.map.with_index(1) do |line, line_number|
      "\e[#{line_number};40H#{line.chomp}"
    end.join
    # go to column 40

    # =====  Reset cursor  =====
    reset_cursor = "\e[#{editor_view.lines.count};1H"

    # =====  All together  =====
    editor_view + truncate_code + locals_view + reset_cursor
  end

  def highlight_ruby(ruby_code)
    formatter   = Rouge::Formatters::Terminal256.new theme: 'molokai'
    lexer       = Rouge::Lexers::Ruby.new
    tokens      = lexer.lex ruby_code
    formatter.format(tokens)
  end
end
