require File::join(File.dirname(__FILE__), %w(.. resource))

class Pacemaker::Resource::Clone < Pacemaker::Resource
  register_type 'clone'

  attr_accessor :primitive

end
