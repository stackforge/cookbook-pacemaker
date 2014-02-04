require 'shellwords'
require File::join(File.dirname(__FILE__), %w(.. resource))

class Pacemaker::Resource::Primitive < Pacemaker::Resource
  TYPE = 'primitive'

  register_type TYPE

  attr_accessor :agent, :params, :meta, :op

  def initialize(*args)
    super(*args)

    @agent = nil
  end

  def self.from_chef_resource(resource)
    new(resource.name).copy_attrs_from_chef_resource(resource, *%w(agent params meta op))
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

    self.op = {}
    %w(start stop monitor).each do |op|
      self.op[op] = self.class.extract_hash(definition, "op #{op}")
    end
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
    "params " +
    params.sort.map do |key, value|
      %'#{key}="#{value}"'
    end.join(' ')
  end

  def self.meta_string(meta)
    return "" if ! meta or meta.empty?
    "meta " +
    meta.sort.map do |key, value|
      %'#{key}="#{value}"'
    end.join(' ')
  end

  def self.op_string(ops)
    return "" if ! ops or ops.empty?
    ops.sort.map do |op, attrs|
      attrs.empty? ? nil : "op #{op} " + \
      attrs.sort.map do |key, value|
        %'#{key}="#{value}"'
      end.join(' ')
    end.compact.join(' ')
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
    unless obj_definition =~ /\s+#{data_type} (.+?)\s*\\?$/
      return {}
    end

    h = {}
    Shellwords.split($1).each do |kvpair|
      break if kvpair == 'op'
      unless kvpair =~ /^(.+?)=(.+)$/
        raise "Couldn't understand '#{kvpair}' for '#{data_type}' section "\
          "of #{name} primitive (definition was [#{obj_definition}])"
      end
      h[$1] = $2.sub(/^"(.*)"$/, "\1")
    end
    h
  end

end
