require 'spelunk'

# * Keybindings to swap display: (s)elf, (l)ocals, (i)nstance, (b)inding, (c)allstack, ...
# * add cutoff top/bottom

# Display options:
#   The stack style:
#     show line number, method name, current return value (mimic a stackframe)
#     * Get access to the return value
#   Self:
#     display self
# don't require the whole program to fit on the screen
# display the returns better


class Spelunk
  class CLI
    DEFAULT_KEYS         = Hash.new :noop
    DEFAULT_KEYS["q"]    = :exit
    DEFAULT_KEYS[3.chr]  = :interrupt # C-c
    DEFAULT_KEYS[4.chr]  = :next      # C-d
    DEFAULT_KEYS["s"]    = :self
    DEFAULT_KEYS["l"]    = :locals
    DEFAULT_KEYS["i"]    = :instance_variables
    DEFAULT_KEYS["b"]    = :binding
    DEFAULT_KEYS["c"]    = :callstack
    DEFAULT_KEYS["\e[A"] = :up
    DEFAULT_KEYS["\e[B"] = :down
    DEFAULT_KEYS["\e[C"] = :right
    DEFAULT_KEYS["\e[D"] = :left
    DEFAULT_KEYS["\r"]   = :next
    DEFAULT_KEYS["\n"]   = :next

    DISPLAYS                      = Hash.new { |h, k| raise "No key #{k.inspect} in #{h.inspect}" }
    DISPLAYS[:callstack]          = :callstack
    DISPLAYS[:self]               = :self
    DISPLAYS[:locals]             = :locals
    DISPLAYS[:instance_variables] = :instance_variables
    DISPLAYS[:binding]            = :binding

    attr_accessor :stdin, :stdout, :stderr, :argv
    attr_accessor :filename, :spelunk, :height, :width, :keys
    attr_accessor :display, :callstack_index

    def initialize(stdin, stdout, stderr, argv, initial_display=:callstack, keys=DEFAULT_KEYS)
      self.stdin              = stdin
      self.stdout             = stdout
      self.stderr             = stderr
      self.argv               = argv
      self.keys               = keys
      self.filename           = File.expand_path(argv[0])
      self.spelunk            = Spelunk.new filename
      self.display            = initial_display
      self.callstack_index    = 0
      self.height, self.width = stdin.winsize
    end

    def event(event)
      return unless spelunk.process? event
      display_screen(event)
      loop do
        key = keys[stdin.readpartial(100)]
        case key
        when :noop, :next
          break nil
        when :quit
          break key
        when :interrupt
          Process.kill 'INT', Process.pid
        when :self, :locals, :instance_variables, :binding, :callstack
          self.display = key
        when :up
          self.callstack_index = [stack.length-1, callstack_index+1].min
        when :down
          self.callstack_index = [0, callstack_index-1].max
        when :right
          # currently nothing to do
        when :left
          # currently nothing to do
        end
      end
    end

    private

    def display_screen(event)
      topleft    = "\e[H"
      clear      = "\e[2J"
      newline    = "\r\n"
      event_name = "\e[45m#{event[:event]}\e[49m"
      prompt     = "\e[41;37m Press a key \e[49;37m"
      output     = "" << topleft << clear << highlighted_body(event) << newline << newline << event_name << newline << prompt
      stdout.print(output)
    end

    def highlighted_body(event)
      linenum_width = 3
      arrow_width   = 4
      gutter_width  = arrow_width + linenum_width
      code_width    = spelunk.raw_body.lines.max_by(&:size).chomp.size
      code_width   += code_width + gutter_width

      editor_view = editor_view(event, arrow_width)
      editor_view << locals_view(event) << reset_cursor(editor_view)
    end

    def reset_cursor(editor_view)
      "\e[#{editor_view.lines.count};1H"
    end

    def locals_view(event)
      binding = event[:binding]
      locals = binding.local_variables.map { |name| [name, binding.local_variable_get(name)] }.to_h
      locals_view = highlight_ruby locals.pretty_inspect do |line, line_number|
        "\e[#{line_number};40H#{line.chomp}"
      end
    end

    def highlight_ruby(ruby_code, &block)
      formatter   = Rouge::Formatters::Terminal256.new theme: 'molokai'
      lexer       = Rouge::Lexers::Ruby.new
      tokens      = lexer.lex ruby_code
      formatter.format(tokens).lines.map.with_index(1, &block).join
    end

    def editor_view(event, arrow_width)
      line        = event.fetch :lineno, -1
      line        = event.fetch :lineno, -1
      min_index   = [line-10, 0].max
      max_index   = min_index+20

      editor_view = highlight_ruby(spelunk.raw_body) do |code, lineno|
        format = "%#{arrow_width}s"
        gutter = (format % '') + "\e[34m"
        gutter = "\e[41;37m" + (format % ' -> ') if line == lineno
        gutter + ("%4d\e[0m: #{code}\r" % lineno)
      end
    end
  end
end
