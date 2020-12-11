require 'yaml'

module Arison
  class Util
    def self.get_profile(config_path, profile)
      @config = YAML.load_file(config_path)
      @config[profile]
    end

    def self.parse_json(buffer)
      begin
        data = JSON.parse(buffer)
      rescue => e
        data = []
        buffer.lines.each do |line|
          data << JSON.parse(line)
        end
      end
      data
    end

    def self.get_type(k, v)
      if v.nil?
        %Q{string}
      elsif k =~ /^id$/i
        nil
      elsif v.class == String
        to_time_or_nil(v).nil? ? %Q{string} : %Q{datetime}
      elsif v.class == TrueClass || v.class == FalseClass
        %Q{boolean}
      elsif v.class == Integer
        %Q{integer}
      elsif v.class == Float
        %Q{float}
      elsif v.class == Array || v.class == Hash
        %Q{text}
      elsif v.respond_to?(:strftime)
        %Q{datetime}
      end
    end

    def self.to_time_or_nil(value)
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