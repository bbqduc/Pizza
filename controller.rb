require './datamodel'
require 'digest/sha2'

module Controller
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

	def Controller.AddUser(username, password, name, address, phone)
		user = Customer.first(:username => username)
		if user != nil
			return false
		end
		salt = '' 
		64.times { salt << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
		hash = Digest::SHA512.hexdigest("#{password}:#{salt}")

		newcustomer = Customer.new
		newcustomer.attributes = {
			:name => name,
			:address => address,
			:phone => phone,
			:username => username,
			:passhash => hash,
			:salt => salt
		}

		return newcustomer.save
	end

	def Controller.getProductID(name)
		return Product.first(:name => name).attributes[:id]
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
			:price => price
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
			:price => price
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
		return Order.all(:conditions => [":deliveryDate IS NOT NULL"], :order => [:orderDate.desc])
	end


end
