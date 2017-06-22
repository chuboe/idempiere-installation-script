-- WARNING - only execute this script against a temp or development database. 
-- DO NOT EXECUTE against a production database.

-- Note: this list is not complete; however, it does give you an idea of how to accomplish the task.
-- Please be quick to let me know if you want to add statements to this script!!

--ACTION - remove BP Bank records and BP Shipping records and Payment Transaction text fields

-- There is no need for changelog to be included in the obfuscated database
delete from ad_changelog;

-- Drop the following indexes to make the updates faster. They will be recreated at the end of the script
drop INDEX ad_user_email;

-- Business Partner 
update C_BPartner bp
set 
value = 'bp' || bp.c_bpartner_id, 
name = 'bp' || bp.c_bpartner_id, 
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
a_email = 'test@idempiere.com',
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

update AD_User u
set 
Password='password', 
Email='test@idempiere.com',  
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
a_email  = 'test@idempiere.com',
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
a_email  = 'test@idempiere.com',
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

-- Recreate index that were dropped above
CREATE INDEX ad_user_email ON ad_user USING btree (email);