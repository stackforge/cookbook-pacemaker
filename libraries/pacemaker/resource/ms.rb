require File.expand_path('clone', File.dirname(__FILE__))

class Pacemaker::Resource::MasterSlave < Pacemaker::Resource::Clone
  TYPE = 'ms'
  register_type TYPE

  #include Pacemaker::Mixins::Resource::Meta

  attr_accessor :rsc
end
