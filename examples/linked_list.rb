class Node
  def initialize(value)
    @value = value
    @next_node = nil
  end

  def add(node)
    if @next_node == nil
      @next_node = node
    else
      @next_node.add(node)
    end
  end

  def get_value(index, current=0)
    if index == current
      @value
    elsif @next_node == nil
      nil
    else
      @next_node.get_value(index, current+1)
    end

  end
end


head = Node.new("This is the first node")

head.add(Node.new("This is the second Node"))
head.add(Node.new("This is the third  Node"))
head.add(Node.new("This is the fourth Node"))
head.add(Node.new("This is the fifth Node"))
head.add(Node.new("This is the sixth Node"))

head.get_value(2)
head.get_value(7)
head.get_value(0)

