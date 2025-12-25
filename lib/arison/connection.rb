module Arison
  # Connection class manages database connections with profile support
  class Connection
    attr_reader :core

    # Initialize connection with config file or direct profile
    # @param config [String] Path to YAML config file
    # @param profile [String, Hash] Profile name or direct profile hash
    def initialize(config: DEFAULT_CONFIG_FILE_PATH, profile: DEFAULT_CONFIG_PROFILE)
      @profile = resolve_profile(config, profile)

      if @profile.nil?
        raise ArgumentError, "Profile '#{profile}' not found in #{config}"
      end

      @core = Core.new(@profile)
    end

    # Import data into table
    # @param table [String] Table name
    # @param data [Array<Hash>] Array of data hashes to import
    def import(table, data)
      @core.import(table, data)
    end

    private

    # Resolve profile from config file or use direct hash
    # @param config [String] Path to config file
    # @param profile [String, Hash] Profile name or hash
    # @return [Hash, nil] Resolved profile configuration
    def resolve_profile(config, profile)
      if profile.is_a?(Hash)
        # Direct profile hash provided
        profile
      elsif profile.is_a?(String)
        # Load from config file
        Util.get_profile(config, profile)
      else
        nil
      end
    end
  end
end
