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
    DEFAULT_KEYS["\e[A"] = :up
    DEFAULT_KEYS["\e[B"] = :down
    DEFAULT_KEYS["\r"]   = :next
    DEFAULT_KEYS["\n"]   = :next
    DEFAULT_KEYS["k"]    = :up
    DEFAULT_KEYS["j"]    = :down
    DEFAULT_KEYS["n"]    = :next

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
      bottom_left = "\e[#{height};1H"
      up          = "\e[A"
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
        current_line:  event.lineno,
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
          xpos:    display_xpos,
          ypos:    display_ypos,
          spelunk: spelunk,
        )
      else raise "WHAT?! #{display.inspect}"
      end

      # nav
      output << bottom_left << up << up
      output << event_name << newline
      output << prompt
      output << reset

      stdout.print(output)
    end

    def display_callstack(xpos:, ypos:, spelunk:)
      out = "\e[#{ypos};#{xpos}H\e[45m  CALLSTACK  \e[49m"
      out << spelunk.each.map.with_index { |frame, i|
        ypos += 1
        name = frame.method_id || frame.object.inspect
        line = "\e[#{ypos};#{xpos}H\e[34m#{i.to_s.<<(":").ljust(3)}\e[39m  line=#{frame.lineno.to_s.ljust(3)} #{name}"
        if spelunk.current == frame
          bnd_height, bnd_out = binding_with_info(
            xpos:  xpos,
            ypos:  ypos+=1,
            frame: spelunk.current,
            indentation: '     ',
          )
          ypos += bnd_height
          line << bnd_out
        end
        line
      }.join
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
      formatter   = Rouge::Formatters::Terminal256.new theme: 'molokai'
      lexer       = Rouge::Lexers::Ruby.new
      tokens      = lexer.lex ruby_code
      formatter.format(tokens).lines.each(&:chomp!).map.with_index(1, &block).join
    end

    def binding_with_info(xpos:, ypos:, frame:, indentation:'')
      ivars  = frame.ivars
      locals = frame.locals

      at = ->(y, x) { "\e[#{y + ypos - 1};#{xpos + x - 1}H" }

      out = ''
      height = 0
      out << at[height+=1, 1] << "#{indentation}\e[45m SELF \e[49m"
      out << at[height+=1, 1] << "#{indentation}  \e[46mClass:\e[49m"
      out << at[height+=1, 1] << "#{indentation}    #{frame.object.class}"
      out << at[height+=1, 1] << "#{indentation}  \e[46mInstance Variables\e[49m"
      out << highlight_ruby(ivars.pretty_inspect) { |line, line_number|
        height += 1
        at[line_number+height-1, 1] << "#{indentation}    #{line.chomp}"
      }
      out << at[height, 1] << "#{indentation}\e[45m LOCALS \e[49m" <<
        highlight_ruby(locals.pretty_inspect) { |line, line_number|
          height+=1
          at[height+line_number-1, 1] << indentation << '  ' << line.chomp
        }
      [height, out]
    end
  end
end
