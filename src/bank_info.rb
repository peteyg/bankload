class BankInfo
    attr_accessor :name, :routingNumber, :accountNumber, :userID, :password, :accountType
    
    def initialize(name, accountType, routingNumber, accountNumber, userID, password)
        @name = name
        @routingNumber = routingNumber
        @accountNumber = accountNumber
        @userID = userID
        @password = password
        @accountType = accountType.kind_of?(Symbol) ? accountType : accountType.to_sym #legal values are :creditCard, :checking, :savings
    end
    
    def to_json(*a)
        {
            'json_class'   => self.class.name, # = 'BankInfo'
            'data'         => [ @name, @accountType, @routingNumber, @accountNumber, @userID, @password ]
        }.to_json(*a)        
    end
    
    def self.json_create(o)
        new(*o['data'])
    end
end
