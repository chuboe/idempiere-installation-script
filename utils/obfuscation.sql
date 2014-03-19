-- WARNING - only execute this script against a temp or development database. 
-- DO NOT EXECUTE against a production database.

-- Note: this list is not complete; however, it does give you an idea of how to accomplish the task.

-- Business Partner 
update C_BPartner bp
set (name, description, name2, alias, acronym, taxId, url, emailConfirm, XName)
= ( select 'bp' || bp2.c_bpartner_id, 'bp' || bp2.c_bpartner_id, null, null, null, null, null, null, null
    from c_bpartner bp2
    where bp2.c_bpartner_id = bp.c_bpartner_id)
;

-- Business Partner Location
update C_BPartner_Location bpl
set (name, Phone, LocCompanyName, Alias, Acronym, Phone2, Fax, BPAcronym, BPAlias, Description, PreAlertEmails, FedTaxID, EmailConfirm, EmailInvoice)
= ( select 'bplocation' || bpl2.c_bpartner_location_id, '512 555-5555', null, null, null, null, null, null, null, null, null, null, null, null
    from c_bpartner_location bpl2
    where bpl2.c_bpartner_location_id = bpl.c_bpartner_location_id)
;

-- User
update AD_User u
set (Name, Description)
= ( select 'user' || u.ad_user_id, 'user' || u.ad_user_id
    from ad_user u2
    where u2.ad_user_id = u.ad_user_id)
where name <> 'SuperUser'
  and ((c_bpartner_id is null) 
    or (
      SELECT xbp.ISEMPLOYEE 
      FROM C_BPARTNER xbp 
      WHERE u.C_BPartner_ID = xbp.C_BPARTNER_ID) = 'N')
;

update AD_User u
set (Password, Email, Phone, Email2, Phone2, Fax, Mobile, EmailConfirm, SIFBCCEmail, EmailUserPW, EmailUser, EmailVerify, BackUpPassword, Birthday)
= ( select 'password', 'test@idempiere.com', '512 555-5555', null, null, null, null, null, null, null, null, null, null, null
    from ad_user u2
    where u2.ad_user_id = u.ad_user_id)
;

-- Location
update C_Location loc
set (Address1, Address2, Address3, Address4)
= ( select '1313 Mockingbird Ln', null, null, null
    from c_location loc2
    where loc2.c_location_id = loc.c_location_id)
;

-- Bank Account
update C_BankAccount ba
set AccountNo = 'BankAcct: '||ba.c_bankaccount_id
;