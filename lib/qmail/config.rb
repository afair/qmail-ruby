module Qmail
  class Config
    @options = {}

    def self.options
      @options
    end

    def self.setup
      instance_eval ### In progress
    end



  end
end
