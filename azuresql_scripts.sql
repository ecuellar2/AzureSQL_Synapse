--delete tokens below for data studio token issue
%userprofile%\AppData\Roaming\azuredatastudio\Azure Accounts
--connect using MI
Server=xxx.database.windows.net,1433;Initial Catalog=db_name;


-- permissions list
SELECT users.name as user_name, users.uid as user_id, db_principal.name, db_principal.type_desc 
FROM sys.sysusers users  right  JOIN  sys.database_role_members rolemember ON users.uid = rolemember.member_principal_id 
JOIN sys.database_principals db_principal ON rolemember.role_principal_id =  db_principal.principal_id order by 1

-- permissions for a role 
SELECT p.[name] AS 'PrincipalName'
      ,p.[type_desc] AS 'PrincipalType'
      ,dbp.[permission_name]
      ,dbp.[state_desc]
      ,so.[Name] AS 'ObjectName'
      ,so.[type_desc] AS 'ObjectType'
  FROM [sys].[database_permissions] dbp LEFT JOIN [sys].[objects] so
    ON dbp.[major_id] = so.[object_id] LEFT JOIN [sys].[database_principals] p
    ON dbp.[grantee_principal_id] = p.[principal_id] LEFT JOIN [sys].[database_principals] p2
    ON dbp.[grantor_principal_id] = p2.[principal_id]
	where p.[name]  in ( 'user_name', 'role_name')
	
---------------------------------------------------------------------------------------------------------------------
--- active sesions and queries
select * FROM sys.dm_exec_sessions where original_login_name = 'xxx'-- use this to get session_id and use in query below

SELECT sqltext.TEXT, req.session_id, req.status, req.command, req.cpu_time, req.total_elapsed_time
FROM sys.dm_exec_requests req CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext where session_id = xxx
---------------------------------------------------------------------------------------------------------------------
-- check dependencies on table 
SELECT 
referencing_object_name = o.name, 
referencing_object_type_desc = o.type_desc, 
referenced_object_name = referenced_entity_name, 
referenced_object_type_desc = o1.type_desc 
FROM sys.sql_expression_dependencies sed 
INNER JOIN sys.objects o 
ON sed.referencing_id = o.[object_id] 
LEFT OUTER JOIN sys.objects o1 
ON sed.referenced_id = o1.[object_id] 
WHERE referenced_entity_name = 'tablename'


-- get all places where a column is being referenced as dependency
SELECT SCHEMA_NAME(schema_id)+'.'+[name] as objectname
,type_desc ,referenced_schema_name AS SchemaName
,referenced_entity_name AS TableName ,referenced_minor_name  AS ColumnName
  FROM [sys].[all_objects] ob cross apply sys.dm_sql_referenced_entities ( SCHEMA_NAME(schema_id)+'.'+[name], 'OBJECT') e
  where is_ms_shipped = 0 and type_desc in ('AGGREGATE_FUNCTION'
,'SQL_SCALAR_FUNCTION'
,'SQL_INLINE_TABLE_VALUED_FUNCTION'
,'SQL_STORED_PROCEDURE'
,'SQL_TABLE_VALUED_FUNCTION'
,'SQL_TRIGGER'
,'VIEW')
and name !='sp_upgraddiagrams'
and referenced_entity_name  = ''  -- table
and referenced_schema_name = ''  --- schema
--and referenced_minor_name = 'columnname' 
order by 5
---------------------------------------------------------------------------------------------------------------------
-- get all columns for a table
  SELECT TABLE_SCHEMA ,
       TABLE_NAME ,
       COLUMN_NAME ,
       ORDINAL_POSITION ,
       COLUMN_DEFAULT ,
       DATA_TYPE ,
       CHARACTER_MAXIMUM_LENGTH ,
       NUMERIC_PRECISION ,
       NUMERIC_PRECISION_RADIX ,
       NUMERIC_SCALE ,
       DATETIME_PRECISION
FROM   INFORMATION_SCHEMA.COLUMNS where table_name = ''

-- get all indexes
select s.name, t.name as table_name, i.name, c.name as column_name from sys.tables t
inner join sys.schemas s on t.schema_id = s.schema_id
inner join sys.indexes i on i.object_id = t.object_id
inner join sys.index_columns ic on ic.object_id = t.object_id
inner join sys.columns c on c.object_id = t.object_id and ic.column_id = c.column_id
where i.index_id > 0    
 and i.type in (1, 2) -- clustered & nonclustered only
 --and i.is_primary_key = 0 -- do not include PK indexes
 and i.is_unique_constraint = 0 -- do not include UQ
 and i.is_disabled = 0
 and i.is_hypothetical = 0
 and ic.key_ordinal > 0
order by t.name

--List All ColumnStore Indexes and tables
SELECT OBJECT_SCHEMA_NAME(OBJECT_ID) SchemaName,
 OBJECT_NAME(OBJECT_ID) TableName,
 i.name AS IndexName, i.type_desc IndexType
FROM sys.indexes AS i 
WHERE is_hypothetical = 0 AND i.index_id <> 0 
 AND i.type_desc IN ('CLUSTERED COLUMNSTORE','NONCLUSTERED COLUMNSTORE')
----------------------------------------------------------------------------------------------
--  Getting table record counts
	SELECT SCHEMA_NAME(schema_id) AS [SchemaName],
	[Tables].name AS [TableName],
	SUM([Partitions].[rows]) AS [TotalRowCount]
	FROM sys.tables AS [Tables]
	JOIN sys.partitions AS [Partitions]
	ON [Tables].[object_id] = [Partitions].[object_id]
	AND [Partitions].index_id IN ( 0, 1 )
	-- WHERE [Tables].name = N'name of the table'
	GROUP BY SCHEMA_NAME(schema_id), [Tables].name
	order by [TableName] asc
----------------------------------------------------------------------------------------------
SSRS queries
select * from Subscriptions
select top 10 * from ExecutionLog3 where ItemPath like ('%Report%') order by TimeStart desc
select * from ReportSchedule where SubscriptionID = 'xxxx'
select * from event 
----------------------------------------------------------------------------------------------
-- How to cleanly compile procedures
IF OBJECT_ID('dbo.uspGetEmployeeDetails') IS NULL -- Check if SP Exists
 EXEC('CREATE PROCEDURE dbo.uspGetEmployeeDetails AS SET NOCOUNT ON;') -- Create dummy/empty SP
GO 
ALTER PROCEDURE dbo.uspGetEmployeeDetails -- Alter the SP Always
GO
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- Jobs 
SELECT
ja.job_id,
j.name AS job_name,
ja.start_execution_date,      
ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
Js.step_name, msdb.dbo.agent_datetime(js.last_run_date,js.last_run_time) AS LastRunDate
FROM msdb.dbo.sysjobactivity ja 
LEFT JOIN msdb.dbo.sysjobhistory jh 
ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j 
ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js
ON ja.job_id = js.job_id
AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
and j.name = 'Job name'

select * from catalog.executions where status = 2
select * from catalog.event_messages where operation_id = 116081 order by message_time desc

-- Invalid objects
SELECT 
    QuoteName(OBJECT_SCHEMA_NAME(referencing_id)) + '.' 
        + QuoteName(OBJECT_NAME(referencing_id)) AS ProblemObject,
    o.type_desc,
    ISNULL(QuoteName(referenced_server_name) + '.', '')
    + ISNULL(QuoteName(referenced_database_name) + '.', '')
    + ISNULL(QuoteName(referenced_schema_name) + '.', '')
    + QuoteName(referenced_entity_name) AS MissingReferencedObject
FROM sys.sql_expression_dependencies sed
LEFT JOIN sys.objects o ON sed.referencing_id=o.object_id
WHERE
    (is_ambiguous = 0)
    AND (OBJECT_ID(ISNULL(QuoteName(referenced_server_name) + '.', '')
    + ISNULL(QuoteName(referenced_database_name) + '.', '')
    + ISNULL(QuoteName(referenced_schema_name) + '.', '')
    + QuoteName(referenced_entity_name)) IS NULL)
ORDER BY
    ProblemObject,
    MissingReferencedObject
