define :pacemaker_vip_primitive, :cb_network => nil, :hostname => nil, :domain => nil, :op => nil do
  network = params[:cb_network]
  net_db = data_bag_item('crowbar', "#{network}_network")
  raise "#{network}_network data bag missing?!" unless net_db
  fqdn = "#{params[:hostname]}.#{params[:domain]}"
  unless net_db["allocated_by_name"][fqdn]
    raise "Missing allocation for #{fqdn} in #{network} network"
  end
  ip_addr = net_db["allocated_by_name"][fqdn]["address"]

  primitive_name = "vip-#{params[:cb_network]}-#{params[:hostname]}"

  # Allow one retry, to avoid races where two nodes create the primitive at the
  # same time when it wasn't created yet (only one can obviously succeed)
  pacemaker_primitive primitive_name do
    agent "ocf:heartbeat:IPaddr2"
    params ({
      "ip" => ip_addr,
    })
    op params[:op]
    action :create
    retries 1
    retry_delay 5
  end

  # we return the primitive name so that the caller can use it as part of a
  # pacemaker group if desired
  primitive_name
end
