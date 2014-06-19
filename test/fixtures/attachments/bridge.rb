#!/usr/local/bin/ruby

system 'say', 'What is your name?'
answer = STDIN.gets.chomp
if answer.match "[no|NO]"
  system 'say' ,'AAAAAARRRRRRG!'
else
  system 'say', 'You may cross'
end

