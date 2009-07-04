$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'parkaby'
Parkaby::Frameworks::Rails.activate!