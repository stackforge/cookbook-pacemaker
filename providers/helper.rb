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
