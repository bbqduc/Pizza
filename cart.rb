class Cart
	def initialize
		@product_ids = Array.new
		@product_amounts = Array.new
		@extras = Array.new
	end

	def to_string
		string = ""
		@product_ids.each_index do |i|
			string += @product_ids[i].to_s + "|"
			string += @product_amounts[i].to_s + "|"
			@extras[i].each_index do |j|
				string += @extras[i][j][0].to_s + "," + @extras[i][j][1].to_s
				if j != @extras[i].size-1
					string += ","
				end
			end
			string += "$"
		end
		return string
	end

	def from_string(string)
		string ||= ""
		cart = Cart.new
		products = string.split('$')
		products.each_index do |i|
			j = products[i].split('|')
			@product_ids.push(Integer(j[0]))
			@product_amounts.push(Integer(j[1]))
			@extras.push(Array[])
			if(j.size() > 2)
				temp_extras = j[2].split(',')

				temp_extras.each_index do |k|
					if k % 2 == 0 then
						@extras[i].push(Array[ Integer(temp_extras[k]), Integer(temp_extras[k+1]) ])
					end
				end
			end

		end
		return cart
	end

	def set_product_amount(product_id, product_amount, extras)
		extras.sort!
		@product_ids.each_index do |i|
			if @product_ids[i] == product_id and @extras[i] == extras then
				@product_amounts[i] = product_amount
				return
			end
		end
		@product_ids.push(product_id)
		@product_amounts.push(product_amount)
		@extras.push(extras)

	end

	def add_product_amount(product_id, product_amount, extras)
		extras.sort!
		product_id = Integer(product_id)
		@product_ids.each_index do |i|
			if @product_ids[i] == product_id and @extras[i].to_s == extras.to_s then
				@product_amounts[i] += Integer(product_amount)
				return
			end
		end
		@product_ids.push(product_id)
		@product_amounts.push(Integer(product_amount))
		@extras.push(extras)

	end

	def get_product_ids
		return @product_ids
	end

	def get_product_amounts
		return @product_amounts
	end

	def get_extras
		return @extras
	end

end

#cart = Cart.new

#cart.from_string("1|1|$")

#cart.set_product_amount(3, 10, [[1,2], [3,4] ])
#cart.add_product_amount(1, 1, [])
#cart.add_product_amount(3, 1, [])

#print cart.to_string
#print "\n"

#cart2 = Cart.new
#cart2.add_product_amount(3, 1, [])

#print cart2.to_string
#print "\n"
