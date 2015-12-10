require 'rouge'
require 'io/console'
require 'spelunk/event'
require 'spelunk/stackframe'
require 'pp'

# KNOWN EVENTS http://www.rubydoc.info/stdlib/core/TracePoint
# :line         execute code on a new line
# :class        start a class or module definition
# :end          finish a class or module definition
# :call         call a Ruby method
# :return       return from a Ruby method
# :c_call       call a C-language routine
# :c_return     return from a C-language routine
# :raise        raise an exception
# :b_call       event hook at block entry
# :b_return     event hook at block ending
# :thread_begin event hook at thread beginning
# :thread_end   event hook at thread ending

# $myfile = File.open("/Users/josh/code/jsl/object-model-with-lovisa/out", "a")
# at_exit { $myfile.close }

class Spelunk
  attr_accessor :path, :stackframes, :current_index, :processable_events

  def initialize(path)
    self.path        = path
    self.stackframes = [Stackframe.new(event: Event.new_toplevel)]
    self.current_index = 0
    self.processable_events = {
      line:     ->(event) { stackframes.last.line event },                   # execute code on a new line
      class:    ->(event) { stackframes.push Stackframe.new(event: event) }, # start a class or module definition
      end:      ->(event) { stackframes.pop },                               # finish a class or module definition
      call:     ->(event) { stackframes.push Stackframe.new(event: event) }, # call a Ruby method
      return:   ->(event) { stackframes.pop },                               # return from a Ruby method
      b_call:   ->(event) { stackframes.push Stackframe.new(event: event) }, # event hook at block entry
      b_return: ->(event) { stackframes.pop },                               # event hook at block ending
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
end
