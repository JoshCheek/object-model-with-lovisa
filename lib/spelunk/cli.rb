require 'spelunk'

# Add cutoff top/bottom
# Display options:
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
    DEFAULT_KEYS["\r"]   = :next
    DEFAULT_KEYS["\n"]   = :next
    DEFAULT_KEYS["n"]    = :next

    # inverted b/c we draw it down from the top
    DEFAULT_KEYS["\e[A"] = :down
    DEFAULT_KEYS["\e[B"] = :up
    DEFAULT_KEYS["k"]    = :down
    DEFAULT_KEYS["j"]    = :up

    DISPLAYS             = Hash.new { |h, k| raise "No key #{k.inspect} in #{h.inspect}" }
    DISPLAYS[:callstack] = :callstack

    attr_accessor :stdin, :stdout
    attr_accessor :filename, :spelunk, :height, :width, :keys
    attr_accessor :display

    def initialize(stdin, stdout, stderr, argv, initial_display=DISPLAYS[:callstack], keys=DEFAULT_KEYS)
      self.stdin              = stdin
      self.stdout             = stdout
      self.keys               = keys
      self.filename           = File.expand_path(argv[0])
      self.spelunk            = Spelunk.new filename
      self.display            = initial_display
      self.height, self.width = stdin.winsize
    end

    def event(event)
      return unless spelunk.process? event
      spelunk.process(event)
      loop do
        display_screen(event)
        key = keys[stdin.readpartial(100)]
        case key
        when :noop      then # noop
        when :next      then break nil
        when :exit      then return key
        when :interrupt then Process.kill 'INT', Process.pid
        when :up        then spelunk.up!
        when :down      then spelunk.down!
        end
      end
    end

    private

    def display_screen(event)
      topleft     = "\e[H"
      clear       = "\e[2J"
      newline     = "\r\n"
      event_name  = "\e[45m#{event.type}\e[49m"
      prompt      = "\e[41;37m Press a key \e[49;37m"
      down        = "\e[B"
      reset       = "\e[0m"

      raw_code          = spelunk.raw_body
      code_first_lineno = 1
      code_last_lineno  = raw_code.lines.length

      # reset
      output = ""
      output << topleft << clear

      # gutter
      linenum_width = 3
      arrow_width   = 4
      gutter_width  = linenum_width + arrow_width + 2 # 1 for the colon, 1 for the empty col between arrow and num
      output << highlighted_gutter(
        current_line:  spelunk.current.lineno,
        linenum_width: linenum_width,
        arrow_width:   arrow_width,
        xpos:          1,
        ypos:          1,
        first_num:     code_first_lineno,
        last_num:      code_last_lineno,
      )

      # code
      output << highlighted_code(
        raw_code: raw_code,
        xpos:     gutter_width+1,
        ypos:     1,
      )

      # custom display
      display_xpos = 1 + gutter_width + raw_code.lines.max_by(&:length).chomp.length
      display_ypos = 1

      case display
      when DISPLAYS[:callstack]
        output << display_callstack(
          xpos:    display_xpos+1,
          ypos:    display_ypos,
          spelunk: spelunk,
        )
      else raise "WHAT?! #{display.inspect}"
      end

      # nav
      output << "\e[#{1+code_last_lineno};1H" << down
      output << prompt
      output << reset

      stdout.print(output)
    end

    def display_callstack(xpos:, ypos:, spelunk:)
      out = "\e[#{ypos};#{xpos}H\e[46;37m  CALLSTACK  \e[49;39m"
      out << spelunk.each.map { |frame|
        ypos += 1
        is_current = spelunk.current == frame
        name = frame.method_id || frame.object.inspect
        line = "\e[#{ypos};#{xpos}H\e[34m#{frame.lineno.to_s.<<(":").rjust(3)}\e[39m #{"\e[41;37m " if is_current}#{name}#{" \e[49;39m" if is_current}"
        if is_current
          bnd_height, bnd_out = binding_with_info(
            xpos:  xpos,
            ypos:  ypos+1,
            frame: spelunk.current,
            indentation: '     ',
          )
          ypos += bnd_height
          line << bnd_out
        end
        line
      }.join

      last_returned = (spelunk.last && spelunk.last.last_returned)
      out << "\e[#{ypos+=1};#{xpos}H\e[34m#{last_returned[:from]} returned: #{last_returned[:value].inspect}" if last_returned
      out
    end


    def highlighted_gutter(linenum_width:, arrow_width:, xpos:, ypos:, first_num:, last_num:, current_line:)
      colour       = "\e[34m"
      highlighted  = "" << colour

      position_format = "\e[%d;#{xpos}H"
      arrow_format    = "%#{arrow_width}s"
      num_format      = "%#{linenum_width}s:"

      first_num.upto(last_num).map do |lineno|
        if current_line == lineno
          arrow = "\e[41;37m#{arrow_format % ' -> '}\e[49;39m#{colour}"
        else
          arrow = arrow_format % ''
        end
        highlighted << (position_format % (lineno+ypos-1)) << arrow << (num_format % lineno)
      end

      highlighted
    end

    def highlighted_code(xpos:, ypos:, raw_code:)
      highlight_ruby(raw_code) do |line, lineno|
        "\e[#{lineno + ypos - 1};#{xpos}H#{line}"
      end
    end

    def highlight_ruby(ruby_code, &block)
      formatter = Rouge::Formatters::Terminal256.new theme: 'molokai'
      lexer     = Rouge::Lexers::Ruby.new
      tokens    = lexer.lex ruby_code
      formatter.format(tokens).lines.map(&:chomp).map.with_index(1, &block).join
    end

    def binding_with_info(xpos:, ypos:, frame:, indentation:'')
      at      = ->(y, x) { "\e[#{y + ypos - 1};#{xpos + x - 1}H" }
      out     = ''
      height  = 0
      binding = { locals: frame.locals,
                  self: { class: frame.object.class,
                          ivars: frame.ivars }}
      out << highlight_ruby(binding.pretty_inspect) { |line, line_number|
        height = line_number-1
        at[line_number, 1] << "#{indentation}#{line.chomp}"
      }
      [height, out]
    end
  end
end
