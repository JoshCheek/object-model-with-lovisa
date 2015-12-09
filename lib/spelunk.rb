require 'rouge'
require 'io/console'
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


# EVENT ATTRIBUTES
#   :enabled?,
#   :event,
#   :lineno,
#   :path,
#   :method_id,
#   :defined_class,
#   :binding,
#   :object,
#   :return_value,
#   :raised_exception]]

# $myfile = File.open("/Users/josh/code/jsl/object-model-with-lovisa/out", "a")
# at_exit { $myfile.close }

class Spelunk
  class Stackframe
    attr_accessor :event
    def initialize(event:nil)
      self.event = event
    end

    def line(event)
      self.event = event
    end

    def return_value() event.fetch :return_value end
    def bnd()          event.fetch :binding      end
    def object()       event.fetch :object       end
    def lineno()       event.fetch :lineno       end
    def path()         event.fetch :path         end
    def method_id()    event.fetch :method_id    end

    def ivars
      object.instance_variables.map { |name|
        [name, object.instance_variable_get(name)]
      }.to_h
    end

    def locals
      bnd.local_variables.map { |name|
        [name, bnd.local_variable_get(name)]
      }.to_h
    end
  end

  attr_accessor :path, :stackframes, :current_index, :processable_events

  def initialize(path)
    self.path        = path
    self.stackframes = [Stackframe.new]
    self.current_index = 0
    self.processable_events = {
      line: ->(event) {
        # (execute code on a new line)
        current.line(event)
      },
      class: ->(event) {
        # (start a class or module definition)
        stackframes.push(Stackframe.new(event: event))
      },
      end: ->(event) {
        # (finish a class or module definition)
        stackframes.pop
      },
      call: ->(event) {
        # call a Ruby method
        stackframes.push(Stackframe.new(event: event))
      },
      return: ->(event) {
        # return from a Ruby method
        stackframes.pop
      },
      b_call: ->(event) {
        # event hook at block entry
        stackframes.push(Stackframe.new(event: event))
      },
      b_return: ->(event) {
        # event hook at block ending
        stackframes.pop
      },
    }
  end

  def raw_body
    @raw_body ||= File.read path
  end

  def process?(event)
    event[:path] == path && processable_events.key?(event[:event])
  end

  def process(event)
    processable_events.fetch(event[:event]).call(event)
  end

  def current
    stackframes[current_index]
  end

  def up!
    self.current_index = [stackframes.length-1, current_index+1].min
    self
  end

  def down!
    self.current_index = [0, current_index-1].max
    self
  end

  def right!
    # noop for now
    self
  end

  def left!
    # noop for now
    self
  end
end
