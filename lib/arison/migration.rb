module Arison
  if ActiveRecord::VERSION::MAJOR >= 5
    class Migration < ActiveRecord::Migration[4.2]
      def self.run_dsl(dsl)
        eval dsl
      end
    end
  else
    class Migration < ActiveRecord::Migration
      def self.run_dsl(dsl)
        eval dsl
      end
    end
  end
end
