--Assumes all active master roles should have access to all processes that are not accessible from menu. This ensures all buttons and print formats work as expected.
INSERT INTO AD_Process_Access
(AD_Process_ID, AD_Role_ID,
 AD_Client_ID, AD_Org_ID, IsActive, Created, CreatedBy, Updated, UpdatedBy, IsReadWrite)
SELECT DISTINCT p.AD_Process_ID, r.AD_Role_ID,
 r.ad_client_id, 0, 'Y', now(), 100, now(), 100, 'Y'
FROM AD_Process p
--LEFT JOIN AD_Role r on r.AD_Role_ID = 1000003 --SET ROLE HERE--
LEFT JOIN AD_Role r on r.IsMasterRole = 'Y' and r.isactive='Y'
WHERE p.AD_Process_ID NOT IN
(
SELECT AD_Process_ID FROM AD_Menu WHERE AD_Process_ID IS NOT NULL
)
AND p.AD_Process_ID NOT IN
(
SELECT AD_Process_ID FROM AD_Process_Access where AD_Role_ID = r.AD_Role_ID
)
;
