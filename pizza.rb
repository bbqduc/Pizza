require 'sinatra'
require 'erb'
require './controller'

class PizzaPalvelu < Sinatra::Base
	get '/' do
		@products = Controller.getProducts()
		erb :products
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
end
