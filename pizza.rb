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
		validinput = !params[:productname].empty?

		ingredients = Controller.getIngredients

		ingredients.each do |ingredient| 
			if !Controller.ValidateAmountString(params["ingr_#{ingredient.attributes[:id]}"] || "0")
				validinput = false
			end
		end

		if !Controller.ValidatePriceString(params[:productprice])
			validinput = false
		end

		if !validinput or !product.save then
			erb :displaymessage, :layout => :adminlayout, :locals => {:message => "Invalid field entries detected!", :backlink => "/admin/edit/#{params[:productid]}"}
		else

			product.save

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
	end

	get '/admin/addingr' do
		erb :addingredient, :locals => {:ingredient => nil, :username => session[:name]}, :layout => :adminlayout
	end

	post '/admin/addingr' do
		validinput = !params[:ingrname].empty? && Controller.ValidatePriceString(params[:ingrprice])
		if !validinput or !Controller.addIngredient(params[:ingrname], params[:ingrprice]) then
			erb :displaymessage, :layout => :adminlayout, :locals => {:message => "Invalid field entries detected!", :backlink => "/admin/editingr/#{params[:ingredientid]}"}
		else
			redirect '/admin/manage'
		end
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
			erb :displaymessage, :layout => :adminlayout, :locals => {:message => "Invalid Date string!", :backlink => "/admin/deliver/#{params[:orderid]}"}
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
			session[:name] = params[:username]
			erb :displaymessage, :layout => :userlayout, :locals => {:username => session[:name], :message => "Success!", :backlink => "/"}
		else	
			erb :displaymessage, :locals => {:message => "Failure!", :backlink => "/register"}
		end
	end

	get '/login' do
		erb :login
	end

	post '/login' do
		if Controller.ValidateUser(params[:username], params[:password]) then
			session[:name] = params[:username]
			redirect '/'
		else
			erb :displaymessage, :locals => {:message => "Invalid username or password!", :backlink => "/register"}
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
		validinput = true

		cart = Cart.new
		cart.from_string(session[:basket])

		cart.get_product_amounts.each_index do |i|
			if !Controller.ValidateAmountString(params["productamount#{i.to_s}"])
				validinput = false
			end
		end

		if !Controller.ValidatePriceString(params[:productprice])
			validinput = false
		end

		if !validinput then
			if session[:name] != nil then
				erb :displaymessage, :layout => :userlayout, :locals => {:username => session[:name], :message => "Invalid field entries detected!", :backlink => "/basket"}
			else
				erb :displaymessage, :locals => {:message => "Invalid field entries detected!", :backlink => "/basket"}
			end
		else
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
					erb :displaymessage, :locals => {:message => "Ordering failed!", :backlink => "/basket"}
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

		begin
			ingredients = Controller.getIngredients
			ingredients.each do |ingredient| 
				amount = Integer (params["ingr_#{ingredient.attributes[:id]}"] || 0)
				if(amount > 0) then
					extras.push(Array[ Integer(ingredient.attributes[:id]), amount])
				end
			end
			productamount = Integer(params[:productamount])
			cart.add_product_amount(params[:productid], productamount, extras)
			session[:basket] = cart.to_string
			redirect '/'

		rescue
			if session[:name] != nil then
				erb :displaymessage, :locals => {:message => "Please type only numbers in the amount-fields!", :backlink => "/basket/add/#{params[:productid]}"}
			else
				erb :displaymessage, :layout => :userlayout, :locals => {:username => session[:name], :message => "Please type only numbers in the amount-fields!", :backlink => "/basket/add/#{params[:productid]}"}
			end
		end
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

		backlink = "/profile/#{params[:username]}"
		if session[:name] != 'admin' && Controller.ValidateUser(params[:username], params[:oldpassword]) then
			customer = Controller.getCustomerByUserName(params[:username])
			if customer == nil
				redirect '/'
			end
			if !Controller.CheckValidUserInfo(session[:name], params[:oldpassword], params[:name], params[:address], params[:phone])
				erb :displaymessage, :locals => {:message => "Invalid field entries detected!", :backlink => backlink} 
			else
				customer.name = params[:name]
				customer.address = params[:address]
				customer.phone = params[:phone]
				if not params[:newpassword].empty?
					Controller.setPassword(customer, params[:newpassword])
				end
				customer.save
				redirect backlink
			end
		else
			erb :displaymessage, :locals => {:message => "Old password was incorrect!", :backlink => backlink}
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

		validinput = !params[:productname].empty?

		ingredients = Controller.getIngredients

		ingredients.each do |ingredient| 
			if !Controller.ValidateAmountString(params["ingr_#{ingredient.attributes[:id]}"] || "0")
				validinput = false
			end
		end

		if !Controller.ValidatePriceString(params[:productprice])
			validinput = false
		end

		if !validinput then
			erb :displaymessage, :layout => :adminlayout, :locals => {:message => "Invalid field entries detected!", :backlink => "/admin/edit/#{params[:productid]}"}
		else

			product = Product.get(params[:productid])
			if product == nil then
				redirect '/admin/manage'
			end

			product.name = params[:productname]
			product.price = params[:productprice]

			product.save

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

		validinput = !params[:ingrname].empty? && Controller.ValidatePriceString(params[:ingrprice])
		if !validinput then
			erb :displaymessage, :layout => :adminlayout, :locals => {:message => "Invalid field entries detected!", :backlink => "/admin/editingr/#{params[:ingredientid]}"}
		else
			ingredient.name = params[:ingrname]
			ingredient.price = params[:ingrprice]
			ingredient.save
			redirect '/admin/manage'
		end
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
