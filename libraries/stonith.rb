module PacemakerStonithHelper
  @@stonith_plugins = nil

  def self.stonith_plugin_valid?(plugin)
    if plugin.nil? || plugin.empty?
      false
    else
      if @@stonith_plugins.nil?
        out = %x{stonith -L}
        if $?.success?
          @@stonith_plugins = out.split("\n")
        end
      end

      !@@stonith_plugins.nil? && @@stonith_plugins.include?(plugin)
    end
  end

  def self.assert_stonith_plugin_valid(plugin)
    unless stonith_plugin_valid? plugin
      raise "STONITH plugin #{plugin} is not available!"
    end
  end
end
