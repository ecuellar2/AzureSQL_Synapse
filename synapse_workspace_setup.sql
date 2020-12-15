--Synapse OPENROWSET WITHOUT data_source, right click sql on demand
CREATE CREDENTIAL [https://<storage_account>.dfs.core.windows.net/<container>] WITH IDENTITY='Managed Identity'
select * from sys.credentials

--OPENROWSET  with data_source, used in CREATE VIEW, CREATE EXTERNAL TABLE
--Also used for  SELECT * FROM OPENROWSET(BULK 'foo/*.parquet', DATA_SOURCE = 'x', FORMAT='PARQUET') as rows
CREATE DATABASE SCOPED CREDENTIAL SynapseIdentity WITH IDENTITY = 'Managed Identity'; -- new syntax 
CREATE DATABASE SCOPED CREDENTIAL SynapseIdentity WITH IDENTITY = 'Managed Service Identity'; -- legacy syntax
select * from sys.database_scoped_credentials

--To run pipelines that reference a SQL pool, the workspace identity needs access
CREATE USER [<workspacename>] FROM EXTERNAL PROVIDER;
GRANT CONTROL ON DATABASE::<databasename> TO <workspacename>;


select * from sys.external_file_formats 
select * from sys.external_data_sources
select * from sys.external_tables

IF EXISTS (SELECT * FROM sys.credentials WHERE name = 'https://xx.dfs.core.windows.net/container')
DROP CREDENTIAL [https://xx.dfs.core.windows.net/container]
CREATE CREDENTIAL [https://xx.dfs.core.windows.net/container] WITH IDENTITY='SHARED ACCESS SIGNATURE',  SECRET = '?sv=%3D'

CREATE EXTERNAL DATA SOURCE [storage_acct]  WITH (TYPE = HADOOP, LOCATION = N'abfss://container@accountname.dfs.core.windows.net',  CREDENTIAL = [mi_cred])

CREATE EXTERNAL TABLE dbo.table_name
( [id] [smallint] NULL,
[value]  [varchar](50) NULL)
WITH ( LOCATION = 'parquet/testdata/',
DATA_SOURCE = [storage_accta],
FILE_FORMAT = [ParquetFormat] );

CREATE VIEW name_vw AS SELECT * FROM 
OPENROWSET(BULK '/parquet/testdata/*.parquet', DATA_SOURCE = 'accountname',FORMAT='PARQUET') AS [r];
