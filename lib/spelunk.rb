require 'rouge'
require 'io/console'
require 'spelunk/event'
require 'spelunk/stackframe'
require 'pp'

# KNOWN EVENTS http://www.rubydoc.info/stdlib/core/TracePoint
# :line :class :end :call :return :c_call :c_return :raise
# :b_call :b_return :thread_begin :thread_end

class Spelunk
  attr_accessor :path, :stackframes, :current_index, :processable_events

  def initialize(path)
    self.path        = path
    self.stackframes = [Stackframe.new(event: Event.new_toplevel)]
    self.current_index = 0
    self.processable_events = {
      line: ->(event) {
        # (execute code on a new line)
        self.current_index = nil
        stackframes.last.line(event)
      },
      class: ->(event) {
        # (start a class or module definition)
        self.current_index = nil
        stackframes.push(Stackframe.new(event: event))
      },
      end: ->(event) {
        # (finish a class or module definition)
        self.current_index = nil
        stackframes.pop
      },
      call: ->(event) {
        # call a Ruby method
        self.current_index = nil
        stackframes.push(Stackframe.new(event: event))
      },
      return: ->(event) {
        # return from a Ruby method
        self.current_index = nil
        stackframes.pop
      },
      b_call: ->(event) {
        # event hook at block entry
        self.current_index = nil
        stackframes.push(Stackframe.new(event: event))
      },
      b_return: ->(event) {
        # event hook at block ending
        self.current_index = nil
        stackframes.pop
      },
    }
  end

  def raw_body
    @raw_body ||= File.read path
  end

  def process?(event)
    event.path == path && processable_events.key?(event.type)
  end

  def process(event)
    processable_events.fetch(event.type).call(event)
  end

  def current
    stackframes[current_index]
  end

  def each(&block)
    stackframes.each &block
  end

  def up!
    self.current_index = [stackframes.length-1, current_index+1].min
    self
  end

  def down!
    self.current_index = [0, current_index-1].max
    self
  end

  def current_index
    @current_index ||= stackframes.length-1
  end
end
