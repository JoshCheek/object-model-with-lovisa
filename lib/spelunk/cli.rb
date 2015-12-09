require 'spelunk'

class Spelunk
  class CLI
    attr_reader :stdin, :stdout, :stderr, :argv
    attr_reader :filename, :spelunk

    def initialize(stdin, stdout, stderr, argv)
      @stdin    = stdin
      @stdout   = stdout
      @stderr   = stderr
      @argv     = argv
      @filename = File.expand_path(argv[0])
      @spelunk  = Spelunk.new filename
    end

    def event(event)
      print "\r"
      return unless spelunk.process? event
      event_name = event[:event]
      stdout.print "\e[H\e[2J#{highlighted_body event}\n\n\r\e[45m#{event_name}\r\n\n"
      stdout.print "\e[41;37m Press a key \e[0m"
      char = stdin.getc
      direction = :forward
      if char == "\e"
        stdin.getc # [
        direction = {
          'A' => :backward,
          'B' => :forward,
          'C' => :forward,
          'D' => :backward,
        }[stdin.getc] # A / B / C / D
      elsif char == "k"
        direction = :backward
      elsif char == "q" || char.ord == 3 # C-c
        :done
      end
    end

    private

    def highlighted_body(event)
      # =====  highlighted code =====
      line        = event.fetch :lineno, -1
      min_index   = [line-10, 0].max
      max_index   = min_index+20

      highlighted_body = highlight_ruby(spelunk.raw_body)
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
end
