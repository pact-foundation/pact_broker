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

def nodes_connected_to_node node, links
  unique_nodes links.select{|l|l.include?(node)}
end

def nodes_connected_to_nodes_within_pool nodes, links, node_pool
  nodes.collect{ | node | nodes_connected_to_node(node, links) }.flatten & node_pool
end

def split_into_clusters links
  node_pool =  unique_nodes links
  groups = []

  while node_pool.any?
    group = []
    groups << group
    connected_nodes = [node_pool.first]

    while connected_nodes.any?
      group.concat(connected_nodes)
      node_pool = node_pool - connected_nodes
      connected_nodes = nodes_connected_to_nodes_within_pool connected_nodes, links, node_pool
    end
  end

  groups
end

links = [Link.new('A', 'B'), Link.new('A', 'C'), Link.new('C', 'D'), Link.new('D', 'E'), Link.new('E','A'),
  Link.new('Y', 'Z'), Link.new('X', 'Y'),
  Link.new('M', 'N'), Link.new('N', 'O'), Link.new('O', 'P'), Link.new('P','Q')]


groups = split_into_clusters links

puts groups.collect{ | group| "group = #{group.join(" ")}"}






