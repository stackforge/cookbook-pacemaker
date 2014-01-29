require 'shellwords'
require_relative File::join(%w(.. resource))

class Pacemaker::Resource::Primitive < Pacemaker::Resource
  TYPE = 'primitive'

  register_type TYPE

  attr_accessor :agent, :params, :meta, :op

  def initialize(*args)
    super(*args)

    @agent = nil
  end

  def self.from_chef_resource(resource)
    primitive = new(resource.name)
    %w(agent params meta op).each do |data|
      value = resource.send(data.to_sym)
      writer = (data + '=').to_sym
      primitive.send(writer, value)
    end
    return primitive
  end

  def parse_definition
    unless definition =~ /\Aprimitive (\S+) (\S+)/
      raise Pacemaker::CIBObject::DefinitionParseError, \
        "Couldn't parse definition '#{definition}'"
    end
    self.name  = $1
    self.agent = $2

    %w(params meta).each do |data_type|
      hash = self.class.extract_hash(definition, data_type)
      writer = (data_type + '=').to_sym
      send(writer, hash)
    end

    # FIXME: deal with op
  end

  def params_string
    self.class.params_string(params)
  end

  def meta_string
    self.class.meta_string(meta)
  end

  def op_string
    self.class.op_string(op)
  end

  def definition_string
    return <<EOF
primitive #{name} #{agent} \\
        #{params_string} \\
        #{meta_string} \\
        #{op_string}
EOF
  end

  def crm_configure_command
    args = %w(crm configure primitive)
    args << [name, agent, params_string, meta_string, op_string]
    args.join " "
  end

  def self.params_string(params)
    return "" if ! params or params.empty?
    s = " params"
    params.sort.each do |key, value|
      s << %' #{key}="#{value}"'
    end
    s
  end

  def self.meta_string(meta)
    return "" if ! meta or meta.empty?
    s = " meta"
    meta.sort.each do |key, value|
      s << %' #{key}="#{value}"'
    end
    s
  end

  def self.op_string(ops)
    return "" if ! ops or ops.empty?
    s = " op"
    ops.sort.each do |op, attrs|
      s << " #{op}"
      attrs.sort.each do |key, value|
        s << %' #{key}="#{value}"'
      end
    end
    s
  end

  # CIB object definitions look something like:
  #
  # primitive keystone ocf:openstack:keystone \
  #         params os_username="crowbar" os_password="crowbar" os_tenant_name="openstack" \
  #         meta target-role="Started" is-managed="true" \
  #         op monitor interval="10" timeout=30s \
  #         op start interval="10s" timeout="240" \
  #
  # This method extracts a Hash from one of the params / meta / op lines.
  def self.extract_hash(obj_definition, data_type)
    unless obj_definition =~ /^\s+#{data_type} (.+?)(\s*\\)?$/
      raise "Couldn't retrieve #{data_type} for '#{name}' CIB object from [#{obj_definition}]"
    end

    h = {}
    Shellwords.split($1).each do |kvpair|
      unless kvpair =~ /^(.+?)=(.+)$/
        raise "Couldn't understand '#{kvpair}' for #{data_type} section of '#{name}' primitive"
      end
      h[$1] = $2.sub(/^"(.*)"$/, "\1")
    end
    h
  end

end
