module Pq
  class Migration < ActiveRecord::Migration
    def self.run_dsl(dsl)
      eval dsl
    end
  end
end
