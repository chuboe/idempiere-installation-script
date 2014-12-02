-- WARNING - only execute this script against a temp or development database. 
-- DO NOT EXECUTE against a production database.

-- Note: this list is not complete; however, it does give you an idea of how to accomplish the task.

--ACTION - remove change log entries

-- Business Partner 
update C_BPartner bp
set 
name = 'bp' || bp2.c_bpartner_id, 
description = null, 
name2 = null, 
taxId = null, 
url = null
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
from ad_user u2
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