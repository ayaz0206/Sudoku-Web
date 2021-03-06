require 'sinatra'
require 'sinatra/partial'
require 'rack-flash'

configure :production do
	require 'newrelic_rpm'
end

require_relative './lib/sudoku'
require_relative './lib/cell'
require_relative './helpers/application'

enable :sessions
set :session_secret, "Cool. This is the secret key."
use Rack::Flash 
set :partial_template_engine, :erb



def random_sudoku
	seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
	sudoku = Sudoku.new(seed.join)
	sudoku.solve!
	sudoku.to_s.chars
end

def puzzle(sudoku)
	new_sudoku = sudoku.dup
	# random = [*0..81].sample(20)
	random = [*0..81].sample(rand(20..35))
	random.each {|i| new_sudoku[i] = ""}
	new_sudoku
end

def box_order_to_row_order(cells)
	boxes = cells.each_slice(9).to_a
	(0..8).to_a.inject([]) {|memo, i|
	first_box_index = i / 3 * 3
	three_boxes = boxes[first_box_index, 3]
	three_rows_of_three = three_boxes.map do |box|
		row_number_in_a_box = i % 3
		first_cell_in_the_row_index = row_number_in_a_box * 3
		box[first_cell_in_the_row_index, 3]
end
	memo += three_rows_of_three.flatten
	}
end

def generate_new_puzzle_if_necessary
	return if session[:current_solution]
	sudoku = random_sudoku
	session[:solution] = sudoku
	session[:puzzle] = puzzle(sudoku)
	session[:current_solution] = session[:puzzle]
end

def prepare_to_check_solution
	@check_solution = session[:check_solution]
	if @check_solution
		flash.now[:notice] = "Incorrect values are highlighted in yellow"
	end
	session[:check_solution] = nil 
end

get '/' do
	prepare_to_check_solution
	generate_new_puzzle_if_necessary
	@current_solution = session[:current_solution] || session[:puzzle]
	@solution = session[:solution]
	@puzzle = session[:puzzle]

	erb :index
end

get '/solution' do
	@check_solution= false
	@current_solution = session[:solution]
	@puzzle = session[:puzzle]
	@solution = session[:solution]
	erb :index
end

get '/check' do
	@check_solution= true
	@current_solution = session[:solution]
	@puzzle = session[:puzzle]
	@solution = session[:solution]
	erb :index
	redirect to ("/")
end


get '/restart' do
	session[:current_solution] = nil
	redirect to ("/")
end

post '/' do
	cells = box_order_to_row_order(params["cell"])
	session[:current_solution] = cells.map {|value| value.to_i }.join
	session[:check_solution] = true
	redirect to("/")
end

