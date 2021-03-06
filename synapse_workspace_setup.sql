--Synapse OPENROWSET WITHOUT data_source, right click sql on demand
CREATE CREDENTIAL [https://<storage_account>.dfs.core.windows.net/<container>] WITH IDENTITY='Managed Identity' -- this step is for serverless only
select * from sys.credentials

--OPENROWSET  with data_source, used in CREATE VIEW, CREATE EXTERNAL TABLE
--Also used for  SELECT * FROM OPENROWSET(BULK 'foo/*.parquet', DATA_SOURCE = 'x', FORMAT='PARQUET') as rows
--steps below for dedicated and serverless pools
CREATE MASTER KEY; -- if needed
CREATE DATABASE SCOPED CREDENTIAL SynapseIdentity WITH IDENTITY = 'Managed Identity'; -- new syntax 
CREATE DATABASE SCOPED CREDENTIAL SynapseIdentity WITH IDENTITY = 'Managed Service Identity'; -- legacy syntax
GRANT REFERENCES  ON DATABASE SCOPED CREDENTIAL ::[xx] TO [x]; -- for users that do not have access to the workspace but have DB level permission to serverless pool
select * from sys.database_scoped_credentials

--To run pipelines that reference a dedicated SQL pool, the workspace identity needs access
CREATE USER [<workspacename>] FROM EXTERNAL PROVIDER;
GRANT CONTROL ON DATABASE::<databasename> TO <workspacename>;

-- non admin permissions
CREATE USER [xx] FROM EXTERNAL PROVIDER;
EXEC sp_addrolemember 'db_datareader', 'xx'; -- dedicated pool
GRANT ALTER ANY EXTERNAL DATA SOURCE TO [xx]; -- to create external tables in dedicated pool
GRANT ALTER ANY EXTERNAL FILE FORMAT TO [xx]; -- to create external tables in dedicated pool
GRANT SHOWPLAN TO [xx];   --- to use EXPLAIN [WITH_RECOMMENDATIONS] in dedicated pool

-- To view sys objects in dedicated pool
GRANT VIEW DATABASE STATE TO [xx];  
GRANT VIEW DEFINITION TO [xx];

ALTER ROLE db_ddladmin ADD MEMBER xxx;      -- when using serverless pool don't use default or master hive db
GRANT ADMINISTER DATABASE BULK OPERATIONS TO [xx]; -- for OPENROWSET in serverless pool 


--Use this only if you want to grant full access to all serverless SQL pools in the workspace
use master
CREATE LOGIN [xx] FROM EXTERNAL PROVIDER;
ALTER SERVER ROLE sysadmin ADD MEMBER [xx];

select * from sys.external_file_formats 
CREATE EXTERNAL FILE FORMAT uncompressedparquet WITH ( FORMAT_TYPE = PARQUET);  
CREATE EXTERNAL FILE FORMAT snappyparquet WITH (  FORMAT_TYPE = PARQUET, DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec');  

select * from sys.external_data_sources -- remove TYPE parameter below for serverless
CREATE EXTERNAL DATA SOURCE [storage_acct]  WITH (TYPE = HADOOP, LOCATION = N'abfss://container@accountname.dfs.core.windows.net',  CREDENTIAL = [mi_cred])


select * from sys.external_tables
CREATE EXTERNAL TABLE dbo.table_name -- dedicated pool example 
( [id] [smallint] NULL,
[value]  [varchar](50) NULL)
WITH ( LOCATION = 'parquet/testdata/',
DATA_SOURCE = [storage_acct],
FILE_FORMAT = [ParquetFormat] );

CREATE EXTERNAL TABLE dbo.ext_table_deleteme -- serverless pool example
( [id] [int] ,
[value]  [varchar](50) )
WITH ( LOCATION = 'parquet/testdata/',
DATA_SOURCE = [storage_acct],
FILE_FORMAT = [ParquetFormat] );

-- OPENROWSET only supported in serverless pool 
CREATE VIEW name_vw AS SELECT * FROM 
OPENROWSET(BULK '/parquet/testdata/*.parquet', DATA_SOURCE = 'accountname',FORMAT='PARQUET') AS [r];

-- if sas token needed
IF EXISTS (SELECT * FROM sys.credentials WHERE name = 'https://xx.dfs.core.windows.net/container')
DROP CREDENTIAL [https://xx.dfs.core.windows.net/container]
CREATE CREDENTIAL [https://xx.dfs.core.windows.net/container] WITH IDENTITY='SHARED ACCESS SIGNATURE',  SECRET = '?sv=%3D'


 /*
Create container using same name as workspace in storage account. 
This account appears used only for synapse logging such as pool logs, metadata, metastore definition. 
Create workspace. This step gives storage blob data contributor RBAC to  MI in the container in storage account.
Leave enabled:  Allow pipelines (running as workspace's system assigned identity) to access SQL pools.
Select the Managed virtual network enable (check all) during creation, can't be change later.

After deployment:
Add dev groups to workspace, spark, sql admin in workspace.
Add the dev group as contributor for the synapse resource RBAC. (may not be needed) for azure runtime to enable interactive authoring 
Go to firewall, enable "allow azure resources to access workspace"
Create linked services.
Enable interactive authoring with 60 min timeout.
Update SQL active directory admin.
Confirm settings needed for workspace firewall config.
Go to workspace, click managed private endpoint, click add.
Create spark pools. Run show databases command to assure metastore access works. Test a data frame.
val df = spark.read.format("delta").load("abfss://container@account.dfs.core.windows.net/folderpath/")

Create SQL pool. 
-- do this for workspace MI in all sql pool 
CREATE USER [workspacename] FROM EXTERNAL PROVIDER;
GRANT CONTROL ON DATABASE::dbname TO workspacename;
Grant permissions. In serverless SQL pool Synapse Administrators are granted dbo. In dedicated SQL pools Active Directory Admin is dbo.

Serverless SQL pool
use master
CREATE LOGIN [alias@domain.com] FROM EXTERNAL PROVIDER;
use yourdb -- Use your database name
CREATE USER alias FROM LOGIN [alias@domain.com];


Dedicated pool
--Create user and permissions in the database
CREATE USER [<alias@domain.com>] FROM EXTERNAL PROVIDER;




       
          
          
 */
