require './datamapper_setup'

class Customer
	include DataMapper::Resource

	property :id,		Serial
	property :username,	String, :required => true, :unique => true
	property :passhash,	String, :required => true, :length => 128
	property :salt,		String, :required => true, :length => 64
	property :name,		String, :required => true
	property :address,	String, :required => true
	property :phone,	String, :required => true

	has n, :orders
end

class Ingredient
	include DataMapper::Resource

	property :id,		Serial
	property :name,		String, :required => true, :unique => true
	property :price,	Decimal, :required => true, :scale => 2, :precision => 5
	property :available,	Boolean, :required => true, :index => true

	has n, :ingredient_amounts
	has n, :extras
end

class Product
	include DataMapper::Resource

	property :id,		Serial
	property :name,		String, :required => true, :unique => true
	property :price,	Decimal, :required => true, :scale => 2, :precision => 5
	property :available,	Boolean, :required => true, :index => true

	has n, :ingredient_amounts
	has n, :product_amounts

end

class Order
	include DataMapper::Resource
	
	property :id,		Serial
	property :orderDate,	DateTime, :required => true, :index => true
	property :deliveryDate,	DateTime, :index => true
	property :totalPrice,	Decimal, :required => true, :scale => 2, :precision => 5

	belongs_to :customer

	has n, :product_amounts
end

class ProductAmount
	include DataMapper::Resource

	property :id,		Serial
	property :amount,	Integer

	belongs_to :order
	belongs_to :product

	has n, :extras

end

class IngredientAmount
	include DataMapper::Resource

	property :id,		Serial
	property :amount,	Integer

	belongs_to :ingredient
	belongs_to :product
end

class Extra
	include DataMapper::Resource

	property :id,		Serial
	property :amount,	Integer

	belongs_to :ingredient
	belongs_to :product_amount
end

DataMapper.finalize
DataMapper.auto_upgrade!
