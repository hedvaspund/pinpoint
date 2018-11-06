require 'active_record'
require_relative './models/user'
require_relative './models/account'

def db_configuration #TBD : move to initializer
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end
 
ActiveRecord::Base.establish_connection(db_configuration["development"])
 
User.delete_all

3.times do 
  print "Give me username: "
  username = gets.chomp
   
  print "Give me password: "
  password = gets.chomp

  user = User.new(username: username, password: password)
  
  user.save!
  prng = Random.new
  user.reload
  Account.create(user_id: user.id, amount: prng.rand(1000) - 500)
end

puts "Number of users in your database: #{User.count}"
puts "Bye!"