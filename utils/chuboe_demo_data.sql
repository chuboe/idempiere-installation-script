--step one: change the below 'ChangeMe' to your company's name
--step two: execute the script using: 

--use this script to update gardenworld names to reflect your company
CREATE OR REPLACE FUNCTION chuboe_demo_name () RETURNS text AS $$
SELECT 'ChangeMe'::text --put your company's name here - example: GeorgeDistribution
$$ LANGUAGE sql;

--use this script to update gardenworld names to reflect your company
CREATE OR REPLACE FUNCTION chuboe_demo_abbv () RETURNS text AS $$
SELECT 'ChangeMe'::text --put your company's abbreviation here - example: GDist
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION chuboe_demo_client () RETURNS numeric AS $$
SELECT 11::numeric --change if updating a different client
$$ LANGUAGE sql;

--sample update/replace statement if needed
--update ad_role set name = replace(name,'GWorld','YourWorld') where ad_client_id = XX and name like '%GWorld%';

--update client
update ad_client
set value = chuboe_demo_name(),
name = chuboe_demo_name(),
description = chuboe_demo_name()
where ad_client_id = chuboe_demo_client();

--update passwords to append abbreviation
update ad_user
set password = password || '_' || chuboe_demo_abbv()
where password is not null 
and ad_client_id in (chuboe_demo_client(),0);

--update calendar
update C_Calendar
set name = chuboe_demo_name() || ' Calendar'
where ad_client_id=chuboe_demo_client();

--update schema
update C_AcctSchema
set name = chuboe_demo_name() || ' US Dollar',
costingmethod = 'A',
autoperiodcontrol='N'
where ad_client_id = chuboe_demo_client();

--update roles
update ad_role
set name = chuboe_demo_name() || ' Admin',
description = chuboe_demo_name() || ' Admin'
where ad_client_id = chuboe_demo_client() and name like '%Admin';

update ad_role
set name = chuboe_demo_name() || ' User',
description = chuboe_demo_name() || ' User'
where ad_client_id = chuboe_demo_client() and name like '%User';

--update users
update ad_user
set name = chuboe_demo_name() || ' Admin',
description = chuboe_demo_name() || ' Admin',
email = 'Admin@'||chuboe_demo_name() || '.com'
where ad_client_id = chuboe_demo_client() and name like '%Admin';

update ad_user
set name = chuboe_demo_name() || ' User',
description = chuboe_demo_name() || ' User',
email = 'User@'||chuboe_demo_name() || '.com'
where ad_client_id = chuboe_demo_client() and name like '%User';

--update BPs
update c_bpartner
set name = chuboe_demo_name() || ' Admin',
description = chuboe_demo_name() || ' Admin',
value = chuboe_demo_name() || ' Admin'
where ad_client_id = chuboe_demo_client() and value like '%Admin';

update c_bpartner
set name = chuboe_demo_name() || ' User',
description = chuboe_demo_name() || ' User',
value = chuboe_demo_name() || ' User'
where ad_client_id = chuboe_demo_client() and value like '%User';

