template 'vars.sh' do
	path "/root/vars.sh"
	source 'vars.sh.erb'
	owner 'root'
	group 'root'
	mode 0700
end

template 'address.sh' do
	path "/root/address.sh"
	source 'address.sh.erb'
	owner 'root'
	group 'root'
	mode 0700
end

template 'operationalcrt.sh' do
	path "/root/operationalcrt.sh"
	source 'operationalcrt.sh.erb'
	owner 'root'
	group 'root'
	mode 0700
end

template 'syncblock.sh' do
	path "/root/syncblock.sh"
	source 'syncblock.sh.erb'
	owner 'root'
	group 'root'
	mode 0700
end

script "address" do
	only_if  { ::File.exists?("/root/address.sh")}
	interpreter "bash"
	user "root"
	cwd "/root"
	code "./address.sh"
end

script "operationalcrt" do
	only_if  { ::File.exists?("/root/operationalcrt.sh")}
	interpreter "bash"
	user "root"
	cwd "/root"
	code "./operationalcrt.sh"
end