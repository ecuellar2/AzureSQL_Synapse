--https://www.sqlservercentral.com/articles/azure-elastic-jobs
----------------------------------------------------------
in master db
CREATE LOGIN ElasticJobMaster WITH PASSWORD = '';  --ElasticJobMaster will run on the job database
CREATE LOGIN ElasticJobUser WITH PASSWORD = '';  --ElasticJobUser will run the queries on each target database
----------------------------------------------------------
USE jobs_db
CREATE USER ElasticJobMaster FOR LOGIN ElasticJobMaster WITH DEFAULT_SCHEMA = dbo;
EXEC sp_addrolemember N'db_owner', N'ElasticJobMaster';
--CREATE MASTER KEY ENCRYPTION BY PASSWORD='xx'; --step not needed, db had key
-- passwords must match login 
CREATE DATABASE SCOPED CREDENTIAL ElasticJobMasterCredential WITH IDENTITY = 'ElasticJobMaster', SECRET = ''; 
CREATE DATABASE SCOPED CREDENTIAL ElasticJobUserCredential WITH IDENTITY = 'ElasticJobUser', SECRET = ''; 
----------------------------------------------------------
use target_db
CREATE USER ElasticJobUser FOR LOGIN ElasticJobUser WITH DEFAULT_SCHEMA = dbo;
EXEC sp_addrolemember N'db_datareader', N'ElasticJobUser';
EXEC sp_addrolemember N'db_datawriter', N'ElasticJobUser';
EXEC sp_addrolemember N'db_owner', N'ElasticJobUser';  -- just for testing
----------------------------------------------------------
--USE jobs_db    switch to job database 
EXEC jobs.sp_add_target_group '_dev';
EXEC jobs.sp_add_target_group_member
@target_group_name='_dev',
@target_type='SqlDatabase',
@server_name='xxx.database.windows.net',
@database_name='target_db'

--confirmed works
SELECT * FROM jobs.target_groups WHERE target_group_name='_dev';
SELECT * FROM jobs.target_group_members WHERE target_group_name='_dev';

EXEC jobs.sp_add_job @job_name='_dev_test', @description='create test table in db'

-- Add job step for create table
EXEC jobs.sp_add_jobstep @job_name='_dev_test',
@command=N'IF NOT EXISTS (SELECT * FROM sys.tables 
           	WHERE object_id = object_id(''Test''))
CREATE TABLE [dbo].[Test]([TestId] [int] NOT NULL);',
@credential_name='ElasticJobUserCredential',
@target_group_name='_dev'

EXEC jobs.sp_start_job '_dev_test' 
select * from jobs.job_executions 


-------------------------
select * from jobs.jobs
EXEC jobs.sp_delete_job @job_name=''

SELECT * FROM jobs.target_groups 
EXEC jobs.sp_delete_target_group @target_group_name = 'target_group_name'

select * from  sys.database_scoped_credentials 

SELECT * FROM jobs.target_group_members WHERE target_group_name='';

-- Execute the latest version of a job and receive the execution id
declare @je uniqueidentifier
exec jobs.sp_start_job 'CreateTableTest', @job_execution_id = @je output
select @je

select * from jobs.job_executions where job_execution_id = 'guid'

