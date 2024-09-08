template 'metadata.json' do
	path "/var/www/html/metadata.json"
	source 'metadata.json.erb'
	owner 'root'
	group 'root'
	mode 0700
end

template 'metadata.ext.json' do
	path "/var/www/html/metadata.ext.json"
	source 'metadata.ext.json.erb'
	owner 'root'
	group 'root'
	mode 0700
end

cookbook_file '/var/www/html/tradecartel-icon.png' do
	source "tradecartel-icon.png"
	owner 'root'
	group 'root'
	mode 0700
end

cookbook_file '/var/www/html/tradecartel-logo.png' do
	source "tradecartel-logo.png"
	owner 'root'
	group 'root'
	mode 0700
end

template 'index.html.erb' do
	path "/var/www/html/index.html"
	source 'index.html.erb'
	owner 'root'
	group 'root'
	mode 0700
end

script "update_web" do
	interpreter "bash"
	user "root"
	cwd "/root"
	code <<-EOH
		chown -Rf www-data.www-data /var/www/html
	EOH
end