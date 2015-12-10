class Spelunk
  class Stackframe
    attr_accessor :event

    def initialize(event:)
      self.event = event
    end

    def line(event)
      self.event = event
    end

    def bnd()          event.bnd          end
    def object()       event.object       end
    def lineno()       event.lineno       end
    def path()         event.path         end
    def method_id()    event.method_id    end

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
end
