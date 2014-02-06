require File.expand_path('../resource', File.dirname(__FILE__))

class Pacemaker::Resource::Clone < Pacemaker::Resource
  TYPE = 'clone'
  register_type TYPE

  attr_accessor :primitive

end
