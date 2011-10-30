require 'sinatra'
require 'erb'
require './controller'

class PizzaPalvelu < Sinatra::Base
	get '/' do
		@products = Product.all(:available => true)
		if(session[:name] == nil) then
			erb :products, :locals => {:username => session[:name]}
		else 
			if(session[:name] != 'admin') then
				erb :products, :layout => :userlayout, :locals => {:username => session[:name]}
			else
				redirect '/admin'
			end
		end
	end

	before '/admin*' do
		if(session[:name] != 'admin')
			redirect '/'
		end
	end

	get '/admin' do
		@open_orders = Controller.getOpenOrders
		erb :open_orders, :locals => {:username => session[:name]}, :layout => :adminlayout
		# admin front page	
		# show open orders
		# show 20 latest closed orders maybe?
	end

	get '/admin/orders' do 
		@open_orders = Controller.getOpenOrders
		@closed_orders = Controller.getClosedOrders
		erb :all_orders, :locals => {:username => session[:name]}, :layout => :adminlayout

	end

	get '/admin/addproduct' do
		@ingredients = Controller.getIngredients
		erb :addproduct, :locals => {:product => nil, :username => session[:name]}, :layout => :adminlayout
	end

	post '/admin/addproduct' do
		product = Product.new
		product.attributes = {
			:name => params[:productname],
			:price => params[:productprice],
			:available => true
		}
		product.save
		ingredients = Controller.getIngredients

		ingredients.each do |ingredient| 
			amount = Integer(params["ingr_#{ingredient.attributes[:id]}"]) || 0
			if(amount > 0) then
				ingredient_amount = IngredientAmount.new
				ingredient_amount.attributes = {
					:product => product,
					:ingredient => ingredient,
					:amount => amount
				}
				ingredient_amount.save
			end
		end
		redirect '/admin/manage'
	end

	get '/admin/addingr' do
		erb :addingredient, :locals => {:ingredient => nil, :username => session[:name]}, :layout => :adminlayout
	end

	post '/admin/addingr' do
		if Controller.addIngredient(params[:ingrname], params[:ingrprice]) then
			"Success!"
		else
			"Failure!"
		end
		redirect '/admin/manage'
	end

	get '/admin/manage' do 
		@products = Controller.getProducts
		@ingredients = Controller.getIngredients
		erb :admin_manage, :locals => {:username => session[:name]}, :layout => :adminlayout
	end

	get '/admin/deliver/:orderid' do
		erb :deliver, :locals => {:orderid => params[:orderid], :username => session[:name]}, :layout => :adminlayout
	end

	post '/admin/deliver/:orderid' do
		if Controller.setDeliveryDate(params[:orderid], params[:deliverydate]) then
			redirect '/admin/orders'
		else
			"FAIL!"
		end
	end

	get '/logout' do
		session[:name] = nil
		session[:basket] = ""
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
		end

		redirect '/'
	end

	get '/login' do
		erb :login
	end

	post '/login' do
		if Controller.ValidateUser(params[:username], params[:password]) then
			session[:name] = params[:username]
			redirect '/'
		else
			"Invalid username or password!"
		end
	end

	get '/basket' do
		# edit contents
		# order
		cart = Cart.new
		cart.from_string(session[:basket])
		if(session[:name] == nil) then
			erb(:basket, :locals => { :cart => cart })
		else 
			if(session[:name] != 'admin') then
				erb(:basket, :layout => :userlayout, :locals => { :cart => cart, :username => session[:name] })
			else
				redirect '/admin'
			end
		end
	end

	post '/basket' do
		cart = Cart.new
		cart.from_string(session[:basket])

		cart.get_product_amounts.each_index do |i|
			if Integer(params["productamount"+i.to_s]) > 0 then
				cart.get_product_amounts[i] = params["productamount"+i.to_s]
			else
				cart.get_product_amounts.delete_at(i)
				cart.get_extras.delete_at(i)
				cart.get_product_ids.delete_at(i)
			end
		end

		session[:basket] = cart.to_string

		if params[:buttonpressed] == "Order" then
			redirect '/order'
		else
			redirect '/basket'
		end
	end

	get '/order' do
		if session[:name] == nil then
			redirect '/login'
		else 
			if session[:name] != 'admin' then
				if Controller.orderCart(session[:name], session[:basket]) then
					session[:basket] = ""
					redirect "/profile/#{session[:name]}"
				else
					"Ordering failed!
				<a href='/basket'>Back</a>"
				end
			else
				redirect '/admin'
			end
		end
	end

	get '/vieworder/:orderid' do
		order = Order.get(params[:orderid])
		if order == nil || session[:name] != 'admin' && order.customer.username != session[:name] then
			redirect '/'
		end
		if(session[:name] != 'admin') then
			erb :ordercontent, :layout => :userlayout, :locals => {:order => order, :username => session[:name]}
		else
			erb :ordercontent, :layout => :adminlayout, :locals => {:order => order, :username => session[:name]}
		end
	end


	get '/basket/add/:productid' do
		product = Controller.getProductByID(params[:productid])
		@ingredients = Ingredient.all(:available => true)
		if(session[:name] == nil) then
			erb(:addtobasket, :locals => { :product => product })
		else 
			if(session[:name] != 'admin') then
				erb(:addtobasket, :layout => :userlayout, :locals => { :product => product, :username => session[:name] })
			else
				redirect '/admin'
			end
		end
	end

	post '/basket/add/:productid' do
		product = Controller.getProductByID(params[:productid])
		if product == nil or product.available == false or session[:name] == 'admin'
			redirect '/'
		end
		cart = Cart.new
		session[:basket] ||= ""
		cart.from_string(session[:basket])
		extras = []

		ingredients = Controller.getIngredients
		ingredients.each do |ingredient| 
			amount = Integer(params["ingr_#{ingredient.attributes[:id]}"]) || 0
			if(amount > 0) then
				extras.push(Array[ Integer(ingredient.attributes[:id]), amount])
			end
		end

		cart.add_product_amount(params[:productid], params[:productamount], extras)
		session[:basket] = cart.to_string
		redirect '/'
	end

	get '/profile/:username' do
		if session[:name] != 'admin' && session[:name] != params[:username] then
			redirect '/'
		end
		customer = Controller.getCustomerByUserName(params[:username])
		if(session[:name] != 'admin') then
			erb :account, :layout => :userlayout, :locals => {:customer => customer, :username => session[:name]}
		else
			erb :account, :layout => :adminlayout, :locals => {:customer => customer, :username => session[:name]}
		end
	end

	post '/profile/:username' do
		if session[:name] != 'admin' && session[:name] != params[:username] then
			redirect '/'
		end

		if session[:name] != 'admin' && Controller.ValidateUser(params[:username], params[:oldpassword]) then
			customer = Controller.getCustomerByUserName(params[:username])
			if customer == nil
				redirect '/'
			end
			customer.name = params[:name]
			customer.address = params[:address]
			customer.phone = params[:phone]
			if not params[:newpassword].empty?
				Controller.setPassword(customer, params[:newpassword])
			end
			customer.save
			redirect "/profile/#{params[:username]}"
		else
			"Password incorrect!
			<a href='/profile/#{params[:username]}'>Back</a>"
		end

	end

	get '/admin/edit/:productid' do
		@ingredients = Controller.getIngredients
		product = Product.get(params[:productid])
		if product == nil then
			redirect '/admin/manage'
		end

		erb :editproduct, :layout => :adminlayout, :locals => {:product => product, :username => session[:name]}
	end

	post '/admin/edit/:productid' do
		product = Product.get(params[:productid])
		if product == nil then
			redirect '/admin/manage'
		end

		if not params[:productname].empty?
			product.name = params[:productname]
		end

		if not params[:productname].empty?
			product.price = params[:productprice]
		end

		product.save

		ingredients = Controller.getIngredients

		ingredients.each do |ingredient| 
			amount = Integer(params["ingr_#{ingredient.attributes[:id]}"]) || 0
			ingredient_amount = IngredientAmount.first(:product => product, :ingredient => ingredient)
			if(amount > 0) then
				ingredient_amount ||= IngredientAmount.new
				ingredient_amount.attributes = {
					:product => product,
					:ingredient => ingredient,
					:amount => amount
				}
				ingredient_amount.save
			else
				if ingredient_amount != nil then
					ingredient_amount.destroy
				end
			end
			
		end

		redirect '/admin/manage'
	end

	get '/admin/editingr/:ingredientid' do
		ingredient = Ingredient.get(params[:ingredientid])
		if ingredient == nil then
			redirect '/admin/manage'
		end

		erb :editingredient, :layout => :adminlayout, :locals => {:ingredient => ingredient, :username => session[:name]}
	end

	post '/admin/editingr/:ingredientid' do
		ingredient = Ingredient.get(params[:ingredientid])
		if ingredient == nil then
			redirect '/admin/manage'
		end

		if not params[:ingrname].empty?
			ingredient.name = params[:ingrname]
		end

		if not params[:ingrprice].empty?
			ingredient.price = params[:ingrprice]
		end

		product.save
	end

	get '/admin/toggleavail/:productid' do
		product = Product.get(params[:productid])
		if product != nil then
			product.available = !product.available
			product.save
		end
		redirect '/admin/manage'
	end

	get '/admin/toggleavailingr/:ingredientid' do
		ingredient = Ingredient.get(params[:ingredientid])
		if ingredient != nil then
			ingredient.available = !ingredient.available
			ingredient.save
		end
		redirect '/admin/manage'
	end
end
