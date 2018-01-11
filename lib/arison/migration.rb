module Arison
  class Migration < ActiveRecord::Migration[4.2]
    def self.run_dsl(dsl)
      eval dsl
    end
  end
end
