require_relative File::join(%w(.. resource))

class Pacemaker::Resource::Clone < Pacemaker::Resource
  register_type 'clone'

  attr_accessor :primitive

end
