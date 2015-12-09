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
    self.path   = path
    self.events = []
  end

  def raw_body
    @raw_body ||= File.read path
  end

  def process?(event)
    event[:path] == path
  end
end
