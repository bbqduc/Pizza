require './datamodel'
require 'digest/sha2'

module Controller

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

		newcustomer.save

		return true
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
		newproduct.save
		return true
	end

	def Controller.addIngredients(productID, ingredientID, amount)
		product = Product.get(productID)
		ingredient = Ingredient.get(ingredientID)
		product.ingredients.push()
	end

	def Controller.getIngredients(productID)
		product = Product.get(productID)
		return product.ingredients

	end

	def Controller.getProducts
		return Product.all
	end


end
