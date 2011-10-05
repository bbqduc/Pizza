require './pizza'

enable :sessions
use Rack::Session::Cookie, 
	:key => 'ASDASD',
	:domain => 'localhost',
	:path => '/',
	:expire_after => 14400,
	:secret => 'secret_stuff'
			

run PizzaPalvelu.new
