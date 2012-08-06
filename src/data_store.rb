require 'rubygems'
require 'crypt/blowfish'
require 'json'
require_relative './bank_info.rb'

module DataStore
    
    def DataStore.write( infoArray, key )
        outString = JSON infoArray
        
        # figure out the destination file
        blowfish = Crypt::Blowfish.new(key)
        encrypted = blowfish.encrypt_string(outString)
        0 < File.open('datastore.dat', 'w') {|f| f.write(encrypted) }
    end
    
    def DataStore.read( key, filename = nil )
        encrypted = ""
        # figure out the destination file
        blowfish = Crypt::Blowfish.new(key)
        File.open(filename || 'datastore.dat', 'rb') { |f| 
            encrypted = f.read
        }
        inString = blowfish.decrypt_string(encrypted)
        begin
            data = JSON inString
            return data, "Success"
        rescue JSON::ParserError
            return nil, "Invalid Password"
        end

    end
    
    def DataStore.add( key )
        # read in the current file
        info, msg = DataStore.read(key)
        abort msg if info == nil

        
        # ask for the various pieces of data
        name = ask("Enter name:  ") { |q| 
            q.whitespace = :chomp
        }
        
        accountType = nil
        choose do |menu|
            menu.prompt = "Checking or Credit Card?  "

            menu.choices(:checking,:creditCard) do |command| 
                accountType = command  
            end
        end
        p accountType
        
        routingNumber = nil
        if (accountType == :checking)
            routingNumber = ask("Enter routing number:  ") { |q| 
                q.whitespace = :chomp
            }
        end

        accountNumber = ask("Enter account number:  ") { |q| 
            q.whitespace = :chomp
        }
        
        userID = ask("Enter user ID:  ") { |q| 
            q.whitespace = :chomp
        }

        
        begin
            pass1 = ask("Enter password:  ") { |q| 
                q.echo = "*" 
                q.whitespace = :chomp
            }
            
            pass2 = ask("Repeat password:  ") { |q| 
                q.echo = "*" 
                q.whitespace = :chomp
            }
            invalidPass = ( pass1 != pass2 )
        end while invalidPass && agree("Passwords didn't match. Try again?  ", true)
        
        abort "Passwords didn't match. Not creating account.\nGood-bye." if invalidPass
        
        newInfo = BankInfo.new(name, accountType, routingNumber, accountNumber, userID, pass1)
        # write out the new file
        info << newInfo
        DataStore.write( info, key )        
        say("Account added for: " + name)
    end
end
