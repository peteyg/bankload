require 'rubygems'
require 'ofx'
require_relative './data_store.rb'



def fetch_transactions(bankInfo, startDate, endDate)
    #setup the institution and client objects
    institutionID =  (bankInfo.name == 'Chase') ?
        OFX::FinancialInstitutionIdentification.new('B1', '10898') :
        OFX::FinancialInstitutionIdentification.new('Citigroup', '24909')
    
    financial_institution = OFX::FinancialInstitution.get_institution(bankInfo.name)
    client = OFX::FinancialClient.new([[institutionID,
                                      OFX::UserCredentials.new(bankInfo.userID, bankInfo.password)]], OFX::ApplicationIdentification.new('QWIN', '1900'))

    # build the request document
    requestDocument = financial_institution.create_request_document
    requestDocument.message_sets << client.create_signon_request_message(institutionID.financial_institution_identifier)

    if bankInfo.accountType == :creditCard
        message_set = build_credit_card_message_set(bankInfo, startDate, endDate)
    else
        message_set = build_banking_message_set(bankInfo, startDate, endDate)
    end
    requestDocument.message_sets << message_set
    
    
    #send the request and return the result
    financial_institution.sendAndGetResponseBody(requestDocument)
end
        
    
def build_banking_message_set(bankInfo, startDate, endDate)
    banking_message_set = OFX::BankingMessageSet.new
    statement_request = OFX::BankingStatementRequest.new
    statement_request.client_cookie = 4
    statement_request.transaction_identifier = OFX::TransactionUniqueIdentifier.new
    statement_request.account = OFX::BankingAccount.new
    statement_request.account.bank_identifier = bankInfo.routingNumber
    statement_request.account.branch_identifier = nil
    statement_request.account.account_identifier = bankInfo.accountNumber
    statement_request.account.account_type = :checking
    statement_request.account.account_key = nil
    
    statement_request.include_transactions = true
    statement_request.included_range = (startDate)..(endDate)
    
    banking_message_set.requests << statement_request
    banking_message_set
end

def build_credit_card_message_set(bankInfo, startDate, endDate)
    cc_message_set = OFX::CreditCardStatementMessageSet.new
    statement_request = OFX::CreditCardStatementRequest.new
    
    statement_request.transaction_identifier = OFX::TransactionUniqueIdentifier.new
    statement_request.account = OFX::CreditCardAccount.new
    statement_request.account.account_identifier = bankInfo.accountNumber
    
    statement_request.include_transactions = true
    statement_request.included_range = (startDate)..(endDate)
    
    cc_message_set.requests << statement_request
    cc_message_set
end
