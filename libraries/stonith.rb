module PacemakerStonithHelper
  @@stonith_agents = nil

  def self.stonith_agent_valid?(agent)
    if agent.nil? || agent.empty?
      false
    else
      if @@stonith_agents.nil?
        out = %x{stonith -L}
        if $?.success?
          @@stonith_agents = out.split("\n")
        end
      end

      !@@stonith_agents.nil? && @@stonith_agents.include?(agent)
    end
  end

  def self.assert_stonith_agent_valid(agent)
    unless stonith_agent_valid? agent
      raise "STONITH fencing agent #{agent} is not available!"
    end
  end
end
