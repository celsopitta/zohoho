module Zohoho 
  require 'httparty'
  require 'nokogiri'
  require 'json'

  class Recruit
    include HTTParty
    
    def set_default_timeout(t)
      default_timeout t
    end
    
    def initialize(username, password, apikey, type = 'json')
      @type = type
      @conn = Zohoho::Connection.new 'zohopeople', username, password, apikey
    end
    
    def auth_url
      @conn.ticket_url
    end
    
    def candidates_url(type = @type)
      "http://recruit.zoho.com/ats/private/#{type}/Candidates/getRecords?apikey=#{@conn.api_key}&ticket=#{@conn.ticket}"
    end
    
    def get_candidates(conditions = {:fromIndex => 1, :toIndex => 100})
      (@type == 'json' ? JSON.parse(self.class.get(candidates_url+"&#{conditions.to_params}")) : Nokogiri::XML.parse(self.class.get(candidates_url, conditions)))
    end
    
    def candidates(conditions = {})
      @candidates = get_candidates(conditions)
    end
    
    def get_parsed_candidates(conditions)
      raw_candidates = candidates(conditions)
      @candidates = raw_candidates["response"]["result"]["Candidates"]["row"]
      
      #extracts the relevant data
      @candidates.collect! do |candidate|
        @hash = {}
        candidate["FL"].collect do |pair|
          pair = pair.to_a
          @hash[pair.last.last.to_s] = pair.first.last
        end
        @hash
      end
      @candidates
    end
  end
end