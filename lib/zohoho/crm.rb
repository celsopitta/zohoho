module Zohoho 
  require 'httparty'
  require 'json'
  require 'xmlsimple'
  
  class Crm
    include HTTParty
    
    def initialize(username, password, apikey, ticket_str)
      @conn = Zohoho::Connection.new 'CRM', username, password, apikey, ticket_str
    end
    
    def auth_url
      @conn.ticket_url
    end
    
    def contact(name)
      first_name, last_name = parse_name(name)
      contacts = find_contacts_by_last_name(last_name)
      contacts.select! {|c|
        if c['First Name'].nil? then c['First Name'] = '' end
        first_name.match(c['First Name'])
      } 
      contacts.first
    end 

    def add_contact(name)
      first_name, last_name = parse_name(name)
      xmlData = parse_data({'First Name' => first_name, 'Last Name' => last_name}, 'Contacts')  
     record = @conn.call('Contacts', 'insertRecords', {:xmlData => xmlData, :newFormat => 1}, :post) 
     record['Id']    
    end

    # lead eh criado quando usuario faz simulacao no site e fornece info de contato
    def add_lead_xml(xmlData)

      record = @conn.call('Leads', 'insertRecords', {:xmlData => xmlData, :newFormat => 1}, :post)
      record['Id']
    end

    def update_lead_xml(lead_id, xmlData)

      record = @conn.call('Leads', 'updateRecords', {:xmlData => xmlData, :newFormat => 1, :id => lead_id}, :post)
      record['Id']
    end

    def update_potential_xml(potential_id, xmlData)

      record = @conn.call('Potentials', 'updateRecords', {:xmlData => xmlData, :newFormat => 1, :id => potential_id}, :post)
      record['Id']
    end

    def update_contact_xml(contact_id, xmlData)

      record = @conn.call('Contacts', 'updateRecords', {:xmlData => xmlData, :newFormat => 1, :id => contact_id}, :post)
      record['Id']
    end

    # converte lead e adiciona proposta
    def converte_lead_proposta(lead_id, hashProposta, assign_to)
      xmlData = parse_data_2({'createPotential' => true, 'assignTo' =>  assign_to, 'notifyLeadOwner' => true,
                            'notifyNewEntityOwner'=> true },
                             hashProposta,
                             'Potentials')
      pp xmlData
      id = @conn.call('Leads', 'convertLead', {:xmlData => xmlData, :newFormat => 1, :leadId=> lead_id }, :post)
      id
    end

    # converte lead
    def convert_lead(lead_id, assign_to)
      xmlData = parse_data({'createPotential' => false, 'assignTo' =>  assign_to, 'notifyLeadOwner' => true,
                            'notifyNewEntityOwner'=> true }, 'Potentials')
      id = @conn.call('Leads', 'convertLead', {:xmlData => xmlData, :newFormat => 1, :leadId=> lead_id }, :post)
      id
    end

    # clicou em quero e preencheu formulario, virou cliente e adicionou proposta
    def add_proposta_xml(xmlData)
      #first_name, last_name = parse_name(name)
      #xmlData = parse_data({'Potential Name' => first_name, "Stage" => "Closed Won", "Data de Fechamento" => "10/10/2012"  }, 'Potentials')
      record = @conn.call('Potentials', 'insertRecords', {:xmlData => xmlData, :newFormat => 1}, :post)
      record['Id']
    end

   # lead eh criado quando usuario faz simulacao no site e fornece info de contato
    def add_lead(name)
      first_name, last_name = parse_name(name)
      xmlData = parse_data({'First Name' => first_name, 'Last Name' => last_name}, 'Leads')
     record = @conn.call('Leads', 'insertRecords', {:xmlData => xmlData, :newFormat => 1}, :post)
     record['Id']
    end


   # clicou em quero e preencheu formulario, virou cliente
   # NAO USAR, QUANDO CONVERTE LEAD ELE VIRA CLIENTE               
    def add_cliente(name)
      first_name, last_name = parse_name(name)
      xmlData = parse_data({'First Name' => first_name, 'Last Name' => last_name}, 'Contacts')
     record = @conn.call('Contacts', 'insertRecords', {:xmlData => xmlData, :newFormat => 1}, :post)
     record['Id']
    end


    def post_note(entity_id, note_title, note_content)
      xmlData = parse_data({'entityId' => entity_id, 'Note Title' => note_title, 'Note Content' => note_content}, 'Notes')
      record = @conn.call('Notes', 'insertRecords', {:xmlData => xmlData, :newFormat => 1}, :post) 
      record['Id']
    end

    def parse_data(data, entry)
      fl = data.map {|e| Hash['val', e[0], 'content', e[1]]}
      row = Hash['no', '1', 'FL', fl]
      data = Hash['row', row]
      XmlSimple.xml_out(data, :RootName => entry)
    end


    def parse_name(name)
      match_data = name.match(/\s(\S*)$/)
      match_data.nil? ? last_name = name : last_name = match_data[1]

      match_data = name.match(/^(.*)\s/)
      match_data.nil? ? first_name = '' : first_name = match_data[1]

      return first_name, last_name
    end


    def parse_data_2(row1, row2, entry)

      fl1 = row1.map {|e| Hash['val', e[0], 'content', e[1]]}
      row = Hash['no', '1', 'option', fl1]
      row1 = Hash['row', row]

      fl2 = row2.map {|e| Hash['val', e[0], 'content', e[1]]}
      row = Hash['no', '2', 'FL', fl2]
      row2 = Hash['row', row]

      XmlSimple.xml_out([row1,row2], :RootName => entry).gsub("<anon>\n","").gsub("</anon>\n", "")

    end

    def get_by_id(scope, id)

      @conn.call(scope, 'getRecordById', :id => id, :newFormat => 1, :selectColumns => 'All')
    end

    def find_by_tag(scope, from_index, to_index)


      @conn.call(scope, 'getRecords', :fromIndex => from_index, :toIndex => to_index)
    end

    def find_by_email(scope,email)
      search_condition = "(Email|=|#{email})"
      @conn.call(scope, 'getSearchRecords', :searchCondition => search_condition, :selectColumns => 'All')
    end

    private

    def find_contacts_by_last_name(last_name)
      search_condition = "(Contact Name|ends with|#{last_name})"
      @conn.call('Contacts', 'getSearchRecords', :searchCondition => search_condition, :selectColumns => 'All')
    end
    
  end 
end
