require 'yaml'

module Arison
  class Util
    # Get database profile from config file
    # @param config_path [String] Path to YAML config file
    # @param profile [String] Profile name to load
    # @return [Hash, nil] Profile configuration or nil if not found
    def self.get_profile(config_path, profile)
      return nil unless File.exist?(config_path)

      begin
        @config = YAML.safe_load(File.read(config_path), permitted_classes: [Symbol])
        @config[profile]
      rescue => e
        warn "Failed to load config from #{config_path}: #{e.message}"
        nil
      end
    end

    # Parse JSON or JSONL (newline-delimited JSON) string
    # @param buffer [String] JSON or JSONL string
    # @return [Array, Hash] Parsed data
    def self.parse_json(buffer)
      begin
        data = JSON.parse(buffer)
      rescue JSON::ParserError => e
        # If single JSON parse fails, try JSONL format
        data = []
        buffer.lines.each do |line|
          next if line.strip.empty?
          begin
            data << JSON.parse(line)
          rescue JSON::ParserError => parse_error
            warn "Failed to parse line: #{line.strip} - #{parse_error.message}"
          end
        end
      end
      data
    end

    # Infer database column type from value
    # @param k [String] Column name
    # @param v [Object] Value to infer type from
    # @return [String, nil] Column type or nil for id columns
    def self.get_type(k, v)
      if v.nil?
        'string'
      elsif k =~ /^id$/i
        nil
      elsif v.class == String
        to_time_or_nil(v).nil? ? 'string' : 'datetime'
      elsif v.class == TrueClass || v.class == FalseClass
        'boolean'
      elsif v.class == Integer
        'integer'
      elsif v.class == Float
        'float'
      elsif v.class == Array || v.class == Hash
        'text'
      elsif v.respond_to?(:strftime)
        'datetime'
      else
        'string'
      end
    end

    # Convert string to Time object if valid datetime, otherwise return nil
    # @param value [String] String to convert
    # @return [Time, nil] Time object or nil if invalid
    def self.to_time_or_nil(value)
      return nil unless value.is_a?(String)
      return nil if value.length < 4
      return nil if value.slice(0, 4) !~ /^[0-9][0-9][0-9][0-9]/

      begin
        time = value.to_time
        time.to_i >= 0 ? time : nil
      rescue => e
        nil
      end
    end
  end
end
