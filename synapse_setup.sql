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

