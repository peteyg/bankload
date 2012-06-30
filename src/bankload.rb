#!/usr/bin/ruby
require_relative './fetch.rb'
require 'ofx'
require 'pathname'
require 'highline/import'


if ARGV.length < 1
    abort "Usage: bankload.rb <start date>\n bankload.rb add - adds an account"
end

mode = nil
startDate = nil
endDate = nil

if "add".casecmp(ARGV[0]) == 0
    mode = :add
else
    mode = :download
    startDate = ARGV[0].to_date
    endDate = Date.today
end

# get the password to the datastore, but hide the typed input
key = ask("Enter key:  ") { |q| 
	q.echo = "*" 
	q.whitespace = :chomp
}

if (mode == :add)
    DataStore.add(key)
    Process.exit
end

# Load the settings file if it exists
SETTINGS_FILENAME = 'bankload.settings'
load SETTINGS_FILENAME if File.exists?(SETTINGS_FILENAME)

# Make sure the settings hash exists
if !defined? SETTINGS
	SETTINGS = {}
end

info, msg = DataStore.read(key)
abort msg if info == nil
info.each{ |i|
    puts "Retrieving transactions from #{i.name} since #{startDate}"

    # download the statement 
    statement = fetch_transactions(i, startDate, endDate)
    if !statement
        puts "No statement downloaded"
        next
    end
    
    #report on what we got back
    expectedMsgType = (i.accountType == :creditCard) ? OFX::CreditCardStatementMessageSet : OFX::BankingMessageSet
    transactionMsg = statement.message_sets.find { |x| x.kind_of?(expectedMsgType) }.responses[0]
    
    puts transactionMsg.status.kind_of?(OFX::Success) ?
        "Retrieved #{transactionMsg.transactions ? transactionMsg.transactions.length : 0} transactions from #{i.name}" :
        "ERROR: Failed to retrieve transactions for #{i.name}"
    
    # save the ofx file
    fileName = i.name + startDate.to_s + "_" + endDate.to_s + ".ofx"
    outPath = Pathname(SETTINGS["downloadPath"] || "") + fileName 
    File.open(outPath, 'w') {|f| f.write(statement) }
    puts "Saved: " + outPath.to_s
} if info
