require 'sinatra'
require 'erb'
require './controller'

class PizzaPalvelu < Sinatra::Base
	get '/' do
		@products = Controller.getProducts
		if(session[@name] == nil) then
			erb :products
		else if(session[@name] != 'admin') then
			erb :products, :layout => :userlayout
		else
			redirect '/admin'
		end
	end
end

#before '/admin/*' do
	#	authenticate!
#end

get '/admin' do
	@open_orders = Controller.getOpenOrders
	erb :open_orders, :layout => :adminlayout
	# admin front page	
	# show open orders
	# show 20 latest closed orders maybe?
end

get '/admin/orders' do 
	@open_orders = Controller.getOpenOrders
	@closed_orders = Controller.getClosedOrders
	erb :all_orders, :layout => :adminlayout
end

get '/admin/addproduct' do
	@ingredients = Controller.getIngredients
	erb :addproduct, :layout => :adminlayout, :locals => {:product => nil}
end

post '/admin/addproduct' do

end

get '/admin/addingr' do
	erb :addingredient, :locals => {:ingredient => nil}, :layout => :adminlayout
end

post '/admin/addingr' do
	if Controller.addIngredient(params[:ingrname], params[:ingrprice]) then
		"Success!"
	else
		"Failure!"
	end
end

get '/admin/manage' do 
	@products = Controller.getProducts
	@ingredients = Controller.getIngredients
	erb :admin_manage, :layout => :adminlayout
end

get '/logout' do
	session[@name] = nil
	redirect '/'
end

get '/register' do
	erb :register
end

post '/register' do
	if Controller.AddUser(params[:username], params[:password], params[:name], params[:address], params[:phone]) then
		"Success!"
	else
		"Failure!"

	redirect '/'
end

get '/login' do
	erb :login
end

post '/login' do
	if Controller.ValidateUser(params[:username], params[:password]) then
		session[@name] = params[:username]
		redirect '/'
	else
		"Invalid username or password!"
	end
end

get '/account' do
	# order history
	# edit contact information
	# change password
end

get '/basket' do
	# edit contents
	# order
end

end
