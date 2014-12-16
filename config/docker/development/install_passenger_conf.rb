#!/usr/local/bin/ruby

require 'rubygems'
require 'phusion_passenger'
PhusionPassenger.locate_directories
PhusionPassenger.require_passenger_lib "constants"
PhusionPassenger.require_passenger_lib "platform_info/ruby"
File.open('/etc/httpd/conf.d/passenger.conf', 'w') { |file|
    file.write("LoadModule passenger_module #{PhusionPassenger.apache2_module_path}\n<IfModule mod_passenger.c>\n  PassengerRoot #{PhusionPassenger.source_root}\n  PassengerDefaultRuby #{PhusionPassenger::PlatformInfo.ruby_command}\n</IfModule>\n")
}
