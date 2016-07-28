require 'rubygems'

# catalog_scraper_rakefile_path =
# 	File.expand_path(
# 		File.join(
# 			'..', '..', '..', 'catalog_scraper', 'bin', 'rakefile'
# 		),
# 		File.dirname(__FILE__)
# 	)
# p catalog_scraper_rakefile_path

# load catalog_scraper_rakefile_path

# load rakefile in order to load all of the dependencies 
# (there are some dependencies that are not gems)

# TODO: isolate dependency loading for 'catalog_scraper' gem into another file, so it can be easily loaded here.
# (or have a full-on gem-style setup, so I can require the library in a reasonable way.)

# ==================

# NOTE: can't actually load the rakefile here, because loading 'rake' inhibits Sinatra from starting



require 'bundler'
Bundler.require(:default)
require 'bundler/setup'

# other libs for 'catalog_scraper'
require 'yaml'
require 'csv'
require 'set'
require 'open-uri'

# other libs for this main thing
require 'json'

Dir.chdir File.expand_path(File.dirname(__FILE__)) do
	# Files for the web app specifically
	require_all '../models'



	# Files to load up 'catalog_scraper', which is basically a gem

	# NOTE: 'catalog_scraper' files use the 'PATH_TO_ROOT' constant, which is pretty bad, because I'm just polluting the global namespace with that constant. Need to move that into a module or something.

	# Must expand '..' shortcut into a proper path. But that results in a shorter string.
	PATH_TO_ROOT = File.expand_path '../..', '../../catalog_scraper/bin/rakefile'


	# files
	Dir.chdir PATH_TO_ROOT do
		require_all './lib/SummerResearch'
	end
	
	
	set :public_folder, File.join(File.dirname(__FILE__), '..', 'static')
end



get '/' do
	
	# haml 'foo'
	# erb :index
	
	File.read(File.expand_path('index.html', settings.public_folder))
	# just vendor the static index.html page for now
	
end

# TODO: update ruby soon.  2.3.0 is apparently outdated now.




# ===== REST API =====


get '/api/test' do
	data = {'hello world!' => 42}
	
	
	JSON.generate(data)
end





# TODO: figure out a better way to declare these variables.
# don't want to have to duplicate this logic from the rakefile
# need to store these constants in a file that's easily loadable from here,
# and the 'catalog_scraper' rakefile.

filepath = File.expand_path('bin/data/required_courses.yaml', PATH_TO_ROOT)
required_courses ||= YAML.load_file(filepath)

SQLITE_DATABASE_FILEPATH = File.expand_path('bin/example.db', PATH_TO_ROOT)
catalog = SummerResearch::Catalog.new(SQLITE_DATABASE_FILEPATH)

# NOTE: can't use instance variables because of weird DSL scoping side-effects

get '/api/foo.json' do
	data = catalog.course_info('CS 101')
	
	
	JSON.generate data.to_h
end

get '/api/foo2.json' do
	
	data = [
		[150, 300],
		[300, 300],
		[450, 300]
	].collect{ |pair|
		{ 'x' => pair[0], 'y' => pair[1] }
	}
	
	
	JSON.generate data
end


# code copied over from the rakefile for 'catalog_scraper'
# not final implementation, just a sketch of getting program overview
get '/api/required_courses/ComputerScienceBS' do
	puts "=== setup data"
	# search for relevant programs of study
	
	list_of_degrees = [
		"Computer Science",
		"Information Technology",
		"Electrical Engineering",
		"Biology",
		"Psychology"
	]
	
	degrees = SummerResearch.search_programs_of_study(list_of_degrees)
	
	
	count = degrees.keys.size
	puts "#{count} programs found for search query."
	
	
	programs_of_study = degrees
	
	# TODO: output data on different degrees to different folders.
	
	program_name = "Computer Science, BS"
	url = programs_of_study[program_name]
	
	
	fragment = SummerResearch.requirements_subtree(url)
	
	course_list = SummerResearch.get_all_weird_link_urls(fragment)
	
	p course_list.first.class
	data = 
		course_list.collect do |catalog_link| 
			# catalog_link.to_h
			{  "id" => catalog_link.id  }
		end
	
	JSON.generate data
end






model = Models::ComputerScience_BS.new()

get '/api/program_of_study/CS_BS' do
	model.json
end

get '/api/program_of_study/CS_BS/all' do
	model.json_list_all_courses
end




# bin/database.log
# what the heck is this file? what is it a log of? SQLite? Mongo?
# man, this configuration is messed up...
