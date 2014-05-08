require 'set'

class Link
  def initialize from, to
    @from = from
    @to = to
  end

  def include? endpoint
    @from == endpoint || @to == endpoint
  end

  def to_s
    "#{@from} - #{@to}"
  end

  def to_a
    [@from, @to]
  end

end

def unique_nodes links
  links.collect(&:to_a).flatten.uniq.sort
end

def nodes_connected_to_node node
  unique_nodes @links.select{|l|l.include?(node)}
end

def nodes_connected_to_nodes nodes
  nodes.collect{ | node | nodes_connected_to_node(node) }.flatten & @nodes
end

def remove_nodes_from_pool nodes
  nodes.each do | node |
    @nodes.delete node
  end
end


@links = [Link.new('A', 'B'), Link.new('A', 'C'), Link.new('C', 'D'), Link.new('D', 'E'), Link.new('E','A'),
  Link.new('Y', 'Z'), Link.new('X', 'Y'),
  Link.new('M', 'N'), Link.new('N', 'O'), Link.new('O', 'P'), Link.new('P','Q')]

@nodes =  unique_nodes @links

groups = []

while @nodes.any?
  group = []
  groups << group
  connections = [@nodes.first]
  group.concat connections

  while connections.any?
    remove_nodes_from_pool connections
    connections = nodes_connected_to_nodes connections
    group.concat(connections)
  end

end

puts groups.collect{ | group| "group = #{group.join(" ")}"}






