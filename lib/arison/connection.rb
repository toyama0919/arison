module Arison
  class Connection
    def initialize(config: DEFAULT_CONFIG_FILE_PATH, profile: DEFAULT_CONFIG_PROFILE)
      profile = Util.get_profile(config, profile)
      @core = Core.new(profile)
    end

    def import(table, data)
      @core.import(table, data)
    end
  end
end
