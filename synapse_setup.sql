Logins and users:
Login into server xxx.database.windows.net master DB using dw_user admin account. Run commands below.

CREATE LOGIN loader_user WITH PASSWORD = 'putpwhere'; 
CREATE USER loader_user FOR LOGIN loader_user; 
EXEC sp_addrolemember 'dbmanager', 'loader_user';  -- for auto scaling

Log into DB as dw_user admin account. Run commands below.
CREATE USER loader_user FOR LOGIN loader_user;
GRANT CONTROL ON DATABASE::[dbname] to loader_user; 

CREATE MASTER KEY;  

Polybase steps:
Log in as AD account into dwdb :
CREATE USER [adf_name] FROM EXTERNAL PROVIDER;  
GRANT CONTROL ON DATABASE::[db_name] to [adf_name] ;

User access steps:
CREATE USER [AD_GROUP_NAME] FROM EXTERNAL PROVIDER; --- may be needed in master first
EXEC sp_addrolemember 'db_owner', 'AD_GROUP_NAME';

CREATE SCHEMA [etl];

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
