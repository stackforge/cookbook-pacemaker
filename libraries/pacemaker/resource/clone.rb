require File.expand_path('../resource', File.dirname(__FILE__))

class Pacemaker::Resource::Clone < Pacemaker::Resource
  register_type 'clone'

  attr_accessor :primitive

end
