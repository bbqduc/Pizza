require './datamodel'
require './cart'
require 'digest/sha2'

DataMapper::Model.raise_on_save_failure = true

module Controller
	def Controller.ValidatePriceString(string)
		match = /[0-9]+(\.[0-9]+)?/.match(string)
		return match != nil && match[0] == string
	end
	def Controller.ValidateAmountString(string)
		match = /[0-9]+/.match(string)
		return match != nil && match[0] == string
	end
	def Controller.SetPassword(customer, password)
		salt = '' 
		64.times { salt << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
		hash = Digest::SHA512.hexdigest("#{password}:#{salt}")
		customer.passhash = hash
		customer.salt = salt
	end
	def Controller.ValidateAdmin(name, password)
		if name != 'admin'
			return false
		end
		return Controller.ValidateUser(name, password)
	end

	def Controller.ValidateUser(name, password)
		user = Customer.first(:username => name)
		if user == nil
			return false
		end
		salt = user.attributes[:salt]
		hash = Digest::SHA512.hexdigest("#{password}:#{salt}")
		if hash == user.attributes[:passhash]
			return true
		else
			return false
		end
	end

	def Controller.CheckValidUserInfo(username, password, name, address, phone)
		if username.empty? or password.empty? or name.empty? or address.empty? or phone.empty? or !Controller.ValidateAmountString(phone)
			return false
		else
			return true
		end
	end

	def Controller.AddUser(username, password, name, address, phone)
		user = Customer.first(:username => username)
		if user != nil or !Controller.CheckValidUserInfo(username, password, name, address, phone) 
			return false
		end

		newcustomer = Customer.new
		newcustomer.attributes = {
			:name => name,
			:address => address,
			:phone => phone,
			:username => username,
		}
		Controller.SetPassword(newcustomer, password)

		return newcustomer.save
	end

	def Controller.getCustomerByUserName(username)
		return Customer.first(:username => username)
	end

	def Controller.getProductID(name)
		return Product.first(:name => name).attributes[:id]
	end

	def Controller.getProductByID(id)
		return Product.get(id)
	end

	def Controller.getIngredientID(name)
		return Ingredient.first(:name => name).attributes[:id]
	end

	def Controller.addProduct(name, price)
		product = Product.first(:name => name)
		if product != nil
			return false
		end
		newproduct = Product.new
		newproduct.attributes = {
			:name => name,
			:price => price,
			:available => true
		}
		return newproduct.save
	end

	def Controller.setIngredientAmount(productID, ingredientID, amount)
		product = Product.get(productID)
		ingredient = Ingredient.get(ingredientID)
		ingredient_amounts = IngredientAmount.get(:product => product, :ingredient => ingredient)
		if(ingredient_amounts == nil)
			ingredient_amounts = IngredientAmount.new;
			ingredient_amounts.attributes = {
				:product => product,
				:ingredient => ingredient,
				:amount => amount
			}
			ingredient_amounts.save
		end
	end

	def Controller.addIngredient(name, price)
		ingredient = Ingredient.first(:name => name)
		if ingredient != nil
			return false
		end
		ingredient = Ingredient.new
		ingredient.attributes = {
			:name => name,
			:price => price,
			:available => true
		}
		return ingredient.save
	end

	def Controller.getIngredientAmounts(productID)
		product = Product.get(productID)
		return product.ingredient_amounts
	end

	def Controller.getProducts
		return Product.all
	end

	def Controller.getIngredients
		return Ingredient.all
	end

	def Controller.getOpenOrders
		return Order.all(:deliveryDate => nil, :order => [:orderDate.desc])
	end

	def Controller.getClosedOrders
		return Order.all(:conditions => ["delivery_date IS NOT NULL"], :order => [:orderDate.desc])
	end

	def Controller.getCartPrice(cart)
		price = BigDecimal("0.0")
		cart.get_product_ids.each_index do |i|
			product = Product.get(cart.get_product_ids[i])
			tempPrice = product.attributes[:price]
			cart.get_extras[i].each do |j|
				ingredient = Ingredient.get(j[0])
				tempPrice += ingredient.attributes[:price] * Integer(j[1])
			end
			price += Integer(cart.get_product_amounts[i]) * tempPrice
		end
		return price
	end

	def Controller.orderCart(username, cart_string)
		cart = Cart.new
		cart.from_string(cart_string)
		customer = Customer.first(:username => username)
		orderprice = Controller.getCartPrice(cart)
		order = Order.new
		order.attributes = {
			:customer => customer,
			:orderDate => Time.now,
			:totalPrice => orderprice
		}
		if orderprice == 0 then
			return false
		end
		order.save

		cart.get_product_ids.each_index do |i|
			productamount = ProductAmount.new
			product = Controller.getProductByID(cart.get_product_ids[i])
			productamount.attributes = {
				:order => order,
				:product => product,
				:amount => cart.get_product_amounts[i]
			}
			productamount.save
			cart.get_extras[i].each do |j|
				extra = Extra.new
				ingredient = Ingredient.get(j[0])
				extra.attributes = {
					:ingredient => ingredient,
					:product_amount => productamount,
					:amount => j[1]
				}
				extra.save
			end

		end
		return true
	end

	def Controller.getTimeString(time)
		return time.strftime("%Y-%m-%d %T")
	end

	def Controller.stringToDate(string)
		return DateTime.strptime(string, "%Y-%m-%d %T")
	end

	def Controller.getOrderByID(orderid)
		return Order.get(orderid)
	end
	def Controller.setDeliveryDate(orderid, datestring)
		begin
			order = Controller.getOrderByID(orderid)
			order.update(:deliveryDate => Controller.stringToDate(datestring))
		rescue ArgumentError
			return false
		end
		return true
	end

end
