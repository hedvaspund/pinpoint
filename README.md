apache web server should run on port 80
add virtual host for : bank-example.com to apache conf files
set your /etc/hosts file with the host name


# clone from github
# run bundler
# DATABASE : postgress 
bundle exec rake db:create 
bundle exec rake db:migrate
# set 3 users
bundle exec ruby app/main.rb
# run bank server
bundle exec ruby bank_server.rb

