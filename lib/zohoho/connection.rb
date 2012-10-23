module Zohoho 
  require 'httparty'
  require 'json'
  
  class Connection
    include HTTParty
    default_timeout 40
    
    def initialize(service_name, username, password, apikey)
      @service_name, @username, @password, @api_key = service_name, username, password, apikey
    end 
    
    def ticket_url
      #"https://accounts.zoho.com/login?servicename=#{@service_name}&FROM_AGENT=true&LOGIN_ID=#{@username}&PASSWORD=#{@password}"
       "https://accounts.zoho.com/apiauthtoken/nb/create?SCOPE=ZohoCRM/crmapi&EMAIL_ID=#{@username}&PASSWORD=#{@password}"
    end 
    
    def api_key
      @api_key
    end 
    
    def zoho_uri
      zoho_uri = "https://#{@service_name.downcase}.zoho.com/#{@service_name.downcase}/private/xml"
    end
    
    def ticket
      Regexp.last_match(1) if self.class.get(ticket_url).to_s =~ /TICKET=(\w+)/
    end 
    
    def call(entry, api_method, query = {}, http_method = :get)
      login = {
        :scope => "crmapi",
        :authtoken => "029db8e03e2c8ea5706fb0c078827df5",
        :apikey => api_key,
        :ticket => "029db8e03e2c8ea5706fb0c078827df5"
      }    
      query.merge!(login)
     url = [zoho_uri, entry, api_method].join('/')

     pp url
     case http_method
       when :get
         req = self.class.get(url, :query => query)
         puts "teste"
         pp query
         pp req
         raw = JSON.parse(req.parsed_response.to_json)
        parse_raw_get(raw, entry)    
      when :post
        raw = JSON.parse(self.class.post(url, :body => query).parsed_response.to_json)
        pp raw
	      parse_raw_post(raw)
      else
        raise "#{http_method} is not a recognized http method"
      end      
    end 
    
    private
    
    def parse_raw_get(raw, entry)
      return [] if raw['response']['result'].nil?
      rows = raw['response']['result'][entry]['row'] 
      rows = [rows] unless rows.class == Array
      rows.map {|i|
        raw_to_hash i['FL']
      }
    end
    
    def parse_raw_post(raw)
      if !raw['response'].nil?
        pp raw['response']
        pp raw['response']['result']

      	record = raw['response']['result']['recorddetail']
      	raw_to_hash record['FL']
      else
        # TODO ARRUMAR RECORD PARA OUTROS TIPOS DE DADOS
        pp raw
	      record = raw['success']
	      [record["Contact"]["__content__"],record["Potential"]["__content__"]]
      end
    end
    
    def raw_to_hash_param(raw)
      raw.map! {|r| [r['param'], r['__content__']]}
      Hash[raw]
    end

    def raw_to_hash(raw)
      raw.map! {|r| [r['val'], r['__content__']]}
      Hash[raw]
    end
    
  end 
end
