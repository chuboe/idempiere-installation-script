# Summary
The purpose of this app is to show an example of how you can write to an iDempiere table using postgrest.org from a linux script.

## Notes
- enabled native sequences
- updated primary key with default value from sequence
- defaulted createdby and updatedby to 100 and pushed to the db (needs better solution)
- defaulted ad_org_id = 0 and pushed ot the db

## References
- https://github.com/chuboe/idempiere-installation-script/blob/master/utils/chuboe_postgrest_install.sh
