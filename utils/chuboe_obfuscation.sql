-- WARNING - only execute this script against a temp or development database. 
-- DO NOT EXECUTE against a production database.

-- Note: this list is not complete; however, it does give you an idea of how to accomplish the task.
-- Please be quick to let me know if you want to add statements to this script!!

--ACTION - remove BP Bank records and BP Shipping records and Payment Transaction text fields

-- There is no need for changelog to be included in the obfuscated database
delete from ad_changelog;

-- List of custom tables (search ChangeMe - fields that might need to be uncommented)
--delete from chuboe_trialbalance_detail;
--delete from chuboe_trialbalance_hdr;

-- Update fields marked as encrypted or secure
----select distinct
----'update '||t.tablename||' set '||c.columnname||' = ''111'';'
----from ad_field f
----join ad_column c on f.ad_column_id = c.ad_column_id
----join ad_table t on c.ad_table_id = t.ad_table_id
----where (c.IsSecure='Y' or f.IsEncrypted='Y')
----and t.isview='N'
----and lower(c.columnname) not like '%_id'
----and c.columnname <> 'IsNoExpire'
----and c.columnname <> 'IsNoPasswordReset'
----;
update AD_Client set RequestUser = '111';
update AD_Client set RequestUserPW = '111';
update AD_Client set SMTPHost = '111';
update AD_StorageProvider set Folder = '111';
update AD_StorageProvider set Password = '111';
update AD_StorageProvider set URL = '111';
update AD_StorageProvider set UserName = '111';
update AD_System set DBAddress = '111';
update AD_System set DBInstance = '111';
update AD_System set EncryptionKey = '111';
update AD_System set LDAPDomain = '111';
update AD_System set LDAPHost = '111';
update AD_System set Password = '111';
update AD_System set SupportEMail = '111';
update AD_System set UserName = '111';
update AD_User set Answer = '111';
update AD_User set EMailUser = '111';
update AD_User set EMailUserPW = '111';
update AD_User set LDAPUser = '111';
update AD_User set Password = '111';
update AD_User set Salt = '111';
update AD_User set SecurityQuestion = '111';
update AD_User set UserPIN = '111';
update APP_Application set Password = '111';
update C_AddressValidationCfg set HostAddress = '111';
update C_AddressValidationCfg set ProxyAddress = '111';
update C_AddressValidationCfg set ProxyLogon = '111';
update C_AddressValidationCfg set ProxyPassword = '111';
update C_AddressValidation set ConnectionKey = '111';
update C_AddressValidation set ConnectionPassword = '111';
update C_BankAccount_Processor set Password = '111';
update C_BankAccount_Processor set Password1 = '111';
update C_BankStatementLoader set HostAddress = '111';
update C_BankStatementLoader set Password = '111';
update C_BankStatementLoader set PIN = '111';
update C_BankStatementLoader set ProxyAddress = '111';
update C_BankStatementLoader set ProxyLogon = '111';
update C_BankStatementLoader set ProxyPassword = '111';
update C_BP_BankAccount set AccountNo = '111';
update C_BP_ShippingAcct set DutiesShipperAccount = '111';
update C_BP_ShippingAcct set ShipperAccount = '111';
update C_BP_ShippingAcct set ShipperMeter = '111';
update C_PaymentProcessor set CC_LocalRespDir = '111';
update C_PaymentProcessor set CC_Password = '111';
update C_PaymentProcessor set CC_Port = '111';
update C_PaymentProcessor set CC_PrivateKey = '111';
update C_PaymentProcessor set CC_PrivateKeyPass = '111';
update C_PaymentProcessor set CC_PublicKey = '111';
update C_PaymentProcessor set CC_RemoteDir = '111';
update C_PaymentProcessor set CC_RemoteRespDir = '111';
update C_PaymentProcessor set CC_RemoteRespDir_DLC = '111';
update C_PaymentProcessor set HostAddress = '111';
update C_PaymentProcessor set ProxyAddress = '111';
update C_PaymentProcessor set ProxyLogon = '111';
update C_PaymentProcessor set ProxyPassword = '111';
update C_Payment set CreditCardVV = '111';
update EXP_Processor set Account = '111';
update EXP_Processor set Host = '111';
update EXP_Processor set PasswordInfo = '111';
update IMP_Processor set Account = '111';
update IMP_Processor set Host = '111';
update IMP_Processor set PasswordInfo = '111';
update LSG_SMSProcessor set Password = '111';
update LTX_Indexing_Conf set Password = '111';
update M_InOut set DateAcct = '111';
update M_ShippingProcessorCfg set HostAddress = '111';
update M_ShippingProcessorCfg set ProxyAddress = '111';
update M_ShippingProcessorCfg set ProxyLogon = '111';
update M_ShippingProcessorCfg set ProxyPassword = '111';
update M_ShippingProcessor set ConnectionKey = '111';
update M_ShippingProcessor set ConnectionPassword = '111';
update M_ShippingTransaction set ShipperAccount = '111';
update W_Store set WStoreUserPW = '111';

-- Drop the following indexes to make the updates faster. They will be recreated at the end of the script
drop INDEX ad_user_email;

-- Business Partner 
update C_BPartner bp
set 
value = 'bp' || bp.c_bpartner_id, 
name = 'bp' || bp.c_bpartner_id, 
--chuboe_name_first = '', --ChangeMe
--chuboe_name_last = '', --ChangeMe
description = null, 
name2 = null, 
taxId = null, 
url = null
;

-- Business Partner Bank Account
update C_BP_BankAccount
set a_name = 'test', 
a_street = '2 Lafayette St',
a_city = 'New York',
a_state = 'NY',
a_zip = '10007',
a_ident_dl = 'test',
a_email = 'test@idempeieieire.com',
a_ident_ssn = 'test',
a_country = 'test',
customerpaymentprofileid = 'test',
creditcardnumber = 'test',
routingno = 'test',
accountno = 'test',
creditcardvv = 'test',
creditcardexpmm = 1,
creditcardexpyy = 1
;

-- Business Partner Shipper Account
update C_BP_ShippingAcct
set 
shipperaccount = 'test',
dutiesshipperaccount = 'test',
shippermeter = 'test'
;

-- Business Partner Location
update C_BPartner_Location bpl
set 
name='bplocation' || bpl.c_bpartner_location_id, 
Phone='555-555-5555', 
Phone2=null, 
Fax=null
;

-- User
update AD_User u
set 
Name='user' || u.ad_user_id, 
Description='user' || u.ad_user_id
where u.name <> 'SuperUser'
  and ((u.c_bpartner_id is null) 
    or (
      SELECT xbp.ISEMPLOYEE 
      FROM C_BPARTNER xbp 
      WHERE u.C_BPartner_ID = xbp.C_BPARTNER_ID) = 'N')
;

-- Employee
update AD_User u
set 
Name='employee' || u.ad_user_id, 
Description='employee' || u.ad_user_id
where u.name <> 'SuperUser'
  and ((u.c_bpartner_id is null) 
    or (
      SELECT xbp.ISEMPLOYEE 
      FROM C_BPARTNER xbp 
      WHERE u.C_BPartner_ID = xbp.C_BPARTNER_ID) = 'Y')
;

update AD_User u
set 
Password='password', 
Email='test@idempeieieire.com',  
Phone='512 555-5555', 
Phone2=null, 
Fax=null, 
EmailUserPW=null, 
EmailUser=null, 
EmailVerify=null, 
Birthday=null
;

-- Location
update C_Location loc
set 
Address1='2 Lafayette St', 
Address2='#5', 
Address3=null, 
Address4=null,
city='New York',
postal='10007',
c_region_id=108,
c_country_id=100
;

-- Bank Account
update C_BankAccount ba
set AccountNo = 'BankAcct: '||ba.c_bankaccount_id
;

update C_PaymentTransaction
set 
description = 'test',
a_city  = 'New York',
a_country  = 'US',
a_email  = 'test@idempeieieire.com',
a_ident_dl  = 'test',
a_ident_ssn = 'test',
a_name  = 'test',
a_state  = 'NY',
a_zip  = '10007',
accountno  = 'test',
creditcardexpmm = 1,
creditcardexpyy = 1,
creditcardnumber  = 'test',
creditcardvv  = 'test',
ponum  = 'test',
r_authcode  = 'test',
r_info  = 'test',
r_pnref  = 'test',
r_respmsg  = 'test',
r_result  = 'test',
r_voidmsg  = 'test',
routingno = 'test',
voiceauthcode = 'test'
;

update c_payment
set 
description = 'test',
a_city  = 'New York',
a_country  = 'NY',
a_email  = 'test@idempeieieire.com',
a_ident_dl  = 'test',
a_ident_ssn = 'test',
a_name  = 'test',
a_state  = 'NY',
a_zip  = '10007',
accountno  = 'test',
creditcardexpmm = 1,
creditcardexpyy = 1,
creditcardnumber  = 'test',
creditcardvv  = 'test',
ponum  = 'test',
r_authcode  = 'test',
r_info  = 'test',
r_pnref  = 'test',
r_respmsg  = 'test',
r_result  = 'test',
r_voidmsg  = 'test',
routingno = 'test',
voiceauthcode = 'test'
;

update ad_client 
set 
smtphost ='', 
requestemail = '', 
requestuser = '', 
requestuserpw = '' 
;

commit;

-- Recreate index that were dropped above
CREATE INDEX ad_user_email ON ad_user USING btree (email);

commit;
