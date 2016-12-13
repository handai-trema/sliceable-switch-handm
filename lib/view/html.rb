require 'json'
require 'slice'
#pushnode(i,"HOST",false,node)
#pushnode(i,"EDGE",true,node)
#pushedge(i-1,i%11,edge)
  # Topology controller's GUI (graphviz).
  class Html
    def initialize()#(output = 'topology.html')
      @nodes=[]
      @edges=[]
    end
    def self.update(slices)
      puts slices
      slices.each do |each|
        puts each
        each.ports.each do |each2|
          each.mac_addresses(each2).each do |each3|
            puts each3
          end
        end
      end
    end
  end
=begin
    # rubocop:disable AbcSize
    def update(_event, _changed, topology)
      @nodes=[]
      topology.switches.each_with_object({}) do |each,tmp|
	pushnode(each,false) 
      end
      topology.hosts.each_with_object([]) do |each|
	pushnode(each.to_s,true)
      end 
 
      topology.links.each do |each|
	pushedge(each.dpid_a,each.dpid_b)
      end
      topology.hslinks.each do |each|
	pushedge(each.mac_address.to_s,each.dpid)
      end
      @edges = @edges.uniq
      output()
    end
  private
  def output()
    base =File.read("./lib/view/create_vis_base.txt")
    base2 =File.read("./lib/view/create_vis_base2.txt")
    result= base+JSON.generate(@nodes)+";\n edges ="+JSON.generate(@edges)+base2
    File.write(@output, result)
  end
  def pushnode(id,ishost)
    if ishost then
      @nodes.push({id:id,label:id,image:"./lib/view/laptop.png",shape:'image'}) 
    else
      @nodes.push({id:id,label:id.to_hex,image:"./lib/view/switch.png",shape:"image"})
    end
  end
  def pushedge(from,to)
    @edges.push({from:from,to:to})
  end
end
=end

