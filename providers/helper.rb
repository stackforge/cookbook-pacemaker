include Chef::Mixin::ShellOut

def resource_exists?(name)
  cmd = Mixlib::ShellOut.new("crm configure show | grep #{name}")
  cmd.environment['HOME'] = ENV.fetch('HOME', '/root')
  cmd.run_command
  begin
    cmd.error!
    true
  rescue
    false
  end
end

def resource_running?(name)
  cmd = shell_out! "crm", "resource", "status", name
  Chef::Log.info cmd.stdout
  cmd.stdout.include? "resource #{name} is running"
end

