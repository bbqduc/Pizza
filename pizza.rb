require 'sinatra'
require 'erb'
require './controller'

class PizzaPalvelu < Sinatra::Base
	get '/' do
		@products = Controller.getProducts()
		if(session[@user] != 'admin')
			erb :products
		else
	end

	before '/admin/*' do
		authenticate!
	end

	get '/admin' do
		openOrders = controller.getOpenOrders()
		# admin front page	
		# show open orders
		# show 20 latest closed orders maybe?
	end

	get '/admin/orders' do 

	end


	get '/logout' do
		session[@name] = nil
		redirect '/'
	end

	get '/register' do
		erb :register
	end

	post '/register' do
		if Controller.AddUser(params[:username], params[:password], params[:name], params[:address], params[:phone])
			"Success!"
		else
			"Failure!"
		end
	end

	get '/login' do
		erb :login
	end

	post '/login' do
		if Controller.ValidateUser(params[:username], params[:password])
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
