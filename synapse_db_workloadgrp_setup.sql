/*

Install-Module  Az.Accounts
Import-Module Az.Accounts
Connect-AzAccount
Install-Module Az.Sql
Import-Module Az.Sql
Select-AzSubscription -SubscriptionId GetFromPortal
Set-AzSqlServer -ResourceGroupName rgnamehere -ServerName servername -AssignIdentity     
Use only first part of server name without .database.windows.net
Then assign Storage Blob Data Contributor role in storageaccount to SQL DW Database server 


*/




Logins and users:
Login into server xxx.database.windows.net master DB using dw_user admin account. Run commands below.

CREATE LOGIN xx WITH PASSWORD = 'putpwhere'; 
CREATE USER xx FOR LOGIN loader_user; 
EXEC sp_addrolemember 'dbmanager', 'xx';  -- for auto scaling if needed

Log into DB as dw_user admin account. Run commands below.
CREATE USER xx FOR LOGIN loader_user;
GRANT CONTROL ON DATABASE::[dbname] to xx; 

CREATE MASTER KEY;  

Polybase steps:
Log in as AD account into dwdb :
CREATE USER [adf_name] FROM EXTERNAL PROVIDER;  
GRANT CONTROL ON DATABASE::[db_name] to [adf_name] ;

User access steps:
CREATE USER [AD_GROUP_NAME] FROM EXTERNAL PROVIDER; --- may be needed in master first
EXEC sp_addrolemember 'db_owner', 'AD_GROUP_NAME';

CREATE SCHEMA [etl];
GRANT CONTROL ON SCHEMA::[etl] to [ad_group_name];

CREATE WORKLOAD GROUP wlgname WITH
( REQUEST_MIN_RESOURCE_GRANT_PERCENT = 10
 , MIN_PERCENTAGE_RESOURCE = 80                      
 , REQUEST_MAX_RESOURCE_GRANT_PERCENT = 12
 ,CAP_PERCENTAGE_RESOURCE = 90)

/* 
Guarantee Concurrency = MIN_PERCENTAGE_RESOURCE / REQUEST_MIN_RESOURCE_GRANT_PERCENT = 80/10 = 8 slots @ 10% 
REQUEST_MIN_RESOURCE_GRANT_PERCENT must be higher than .75, and a factor of .25, as well as a factor of you min_percentage_resource.
CAP_PERCENTAGE_RESOURCE is the max resources the workload group can have.
*/

create workload Classifier loader_user_wlgname
WITH ( WORKLOAD_GROUP = 'wlgname'
,MEMBERNAME = 'loader_user' );

--To drop a group ( the classifiers of a group must be dropped first)
--DROP WORKLOAD CLASSIFIER xxx;


-- Workload Groups Examples

CREATE WORKLOAD GROUP low
WITH
(
MIN_PERCENTAGE_RESOURCE = 0
, CAP_PERCENTAGE_RESOURCE = 50
, REQUEST_MIN_RESOURCE_GRANT_PERCENT = 0.75
, REQUEST_MAX_RESOURCE_GRANT_PERCENT = 3
, QUERY_EXECUTION_TIMEOUT_SEC = 3600
);


CREATE WORKLOAD GROUP high
WITH
(
MIN_PERCENTAGE_RESOURCE = 40
, CAP_PERCENTAGE_RESOURCE = 85
, REQUEST_MIN_RESOURCE_GRANT_PERCENT = 10.00
, REQUEST_MAX_RESOURCE_GRANT_PERCENT = 20
, QUERY_EXECUTION_TIMEOUT_SEC = 0
);

CREATE WORKLOAD GROUP user_low
WITH
(
MIN_PERCENTAGE_RESOURCE = 0
, CAP_PERCENTAGE_RESOURCE = 20
, REQUEST_MIN_RESOURCE_GRANT_PERCENT = 0.75
, REQUEST_MAX_RESOURCE_GRANT_PERCENT = 3
, QUERY_EXECUTION_TIMEOUT_SEC = 1800
);


CREATE WORKLOAD GROUP user_high
WITH
(
MIN_PERCENTAGE_RESOURCE = 15
, CAP_PERCENTAGE_RESOURCE = 50
, REQUEST_MIN_RESOURCE_GRANT_PERCENT = 0.75
, REQUEST_MAX_RESOURCE_GRANT_PERCENT = 9
, QUERY_EXECUTION_TIMEOUT_SEC = 0
);

-- View Workload Groups
SELECT group_id
, name
, importance
, min_percentage_resource
, parallelism = min_percentage_resource / request_min_resource_grant_percent
, cap_percentage_resource
, request_min_resource_grant_percent
, request_max_resource_grant_percent
, query_execution_timeout_sec
, query_wait_timeout_sec
FROM sys.workload_management_workload_groups;

-- View Workload Classifiers

SELECT WC.classifier_id, WC.name, WC.group_name, WC.importance, WC.is_enabled, CD.classifier_type, CD.classifier_value
FROM sys.workload_management_workload_classifiers WC
INNER JOIN sys.workload_management_workload_classifier_details CD ON WC.classifier_id = CD.classifier_id;

