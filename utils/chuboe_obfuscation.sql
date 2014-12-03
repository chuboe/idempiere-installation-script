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
name = 'bp' || bp2.c_bpartner_id, 
description = null, 
name2 = null, 
taxId = null, 
url = null
;

-- Business Partner Bank Account
update C_BP_BankAccount
set a_name = 'test', 
a_street = 'test',
a_city = 'test',
a_state = 'test',
a_zip = 'test',
a_ident_dl = 'test',
a_email = 'test',
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
name='bplocation' || bpl2.c_bpartner_location_id, 
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
Address1='1313 Mockingbird Ln', 
Address2=null, 
Address3=null, 
Address4=null,
city=null,
postal=null,
c_region_id=null,
c_country_id=120
;

-- Bank Account
update C_BankAccount ba
set AccountNo = 'BankAcct: '||ba.c_bankaccount_id
;

-- Recreate index that were dropped above
CREATE INDEX ad_user_email ON ad_user USING btree (email);