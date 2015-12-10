class Spelunk
  class Event
    attr_accessor :type, :path, :lineno, :method_id, :defined_class
    attr_accessor :bnd, :object, :return_value

    def self.from_tp(tp)
      event               = new
      event.type          = tp.event
      event.path          = File.expand_path(tp.path)
      event.lineno        = tp.lineno
      event.method_id     = tp.method_id
      event.defined_class = tp.defined_class
      event.bnd           = tp.binding
      event.object        = tp.self
      event.return_value  = tp.return_value if event.return?
      event
    end

    def self.new_toplevel
      event           = new
      event.type      = :line
      event.path      = '...'
      event.lineno    = 1
      event.method_id = :main
      event.bnd       = TOPLEVEL_BINDING
      event.object    = TOPLEVEL_BINDING.eval('self')
      event
    end

    def return?
      type == :return || type == :c_return || type == :b_return
    end
  end
end
