
-- users and roles 
SELECT DP1.name AS DatabaseRoleName,   
   isnull (DP2.name, 'No members') AS DatabaseUserName   
 FROM sys.database_role_members AS DRM  
 RIGHT OUTER JOIN sys.database_principals AS DP1  
   ON DRM.role_principal_id = DP1.principal_id  
 LEFT OUTER JOIN sys.database_principals AS DP2  
   ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R'
ORDER BY DP1.name;  

-- db permissions 
SELECT pr.principal_id, pr.name, pr.type_desc, pr.authentication_type_desc, pe.state_desc, pe.permission_name, sch.name
FROM sys.database_principals AS pr  
JOIN sys.database_permissions AS pe ON pe.grantee_principal_id = pr.principal_id
left outer JOIN sys.schemas  as sch on pe.major_id = sch.schema_id
where pr.name not in ('public')

--SQL DW
select COUNT_BIG(1) from sql dw table
EXEC sp_spaceused N'schema.table';  

--  Active Connections
SELECT * FROM sys.dm_pdw_exec_sessions where status <> 'Closed' and session_id <> session_id();

-- Monitor active queries
SELECT *
FROM sys.dm_pdw_exec_requests
WHERE status not in ('Completed','Failed','Cancelled')
  AND session_id <> session_id()
ORDER BY submit_time DESC;

-- Find top 10 queries longest running queries
SELECT TOP 10 *
FROM sys.dm_pdw_exec_requests
ORDER BY total_elapsed_time DESC;

-- Monitor waiting queries
SELECT waits.session_id,
      waits.request_id,  
      requests.command,
      requests.status,
      requests.start_time,  
      waits.type,
      waits.state,
      waits.object_type,
      waits.object_name
FROM   sys.dm_pdw_waits waits
   JOIN  sys.dm_pdw_exec_requests requests
   ON waits.request_id=requests.request_id
WHERE 1=1 
--and waits.request_id = 'QID####'
ORDER BY waits.object_name, waits.object_type, waits.state;



-- View RunTime values
SELECT wg.group_id
, wg.name
, effective_min_percentage_resource
, requested_parallelism = min_percentage_resource / request_min_resource_grant_percent
, effective_parallelism = min_percentage_resource * (effective_request_min_resource_grant_percent / 100)
, effective_cap_percentage_resource
, effective_request_min_resource_grant_percent
, effective_request_max_resource_grant_percent
, total_queued_request_count
, total_shared_resource_requests
, total_queued_request_count
, total_request_execution_timeouts
, total_resource_grant_timeouts
FROM sys.dm_workload_management_workload_groups_stats st
INNER JOIN sys.workload_management_workload_groups wg ON st.group_id = wg.group_id
ORDER BY wg.group_id;

/*Use below if more than 60M records
Stage in etl schema as DISTRIBUTION ROUND_ROBIN (default), CLUSTERED COLUMNSTORE (default) > DISTRIBUTION HASH, CLUSTERED COLUMNSTORE
Use below if less than 60M records
Stage in etl schema as DISTRIBUTION ROUND_ROBIN, HEAP > DISTRIBUTION HASH, CLUSTERED COLUMNSTORE
*/

-- permissions for a schema
DECLARE @SCHEMA varchar(255) = 'schema_name'
SELECT DISTINCT
CASE WHEN prmssn.state = 'D' then 'Deny'  WHEN prmssn.state = 'R' THEN 'REVOKE' WHEN prmssn.state = 'G' THEN 'Grant'   ELSE  ' Grant With Grant Option' end as permissionstate,
grantor_principal.name AS [Grantor],
prmssn.permission_name AS [name],
class_desc,Grantees.grantee
FROM
sys.schemas AS s
INNER JOIN sys.database_permissions AS prmssn ON prmssn.major_id=s.schema_id AND prmssn.minor_id=0 AND prmssn.class=3
INNER JOIN sys.database_principals AS grantor_principal ON grantor_principal.principal_id = prmssn.grantor_principal_id
INNER JOIN sys.database_principals AS grantee_principal ON grantee_principal.principal_id = prmssn.grantee_principal_id
INNER JOIN (SELECT
grantee_principal.name AS [Grantee]
FROM
sys.schemas AS s
INNER JOIN sys.database_permissions AS prmssn ON prmssn.major_id=s.schema_id AND prmssn.minor_id=0 AND prmssn.class=3
INNER JOIN sys.database_principals AS grantee_principal ON grantee_principal.principal_id = prmssn.grantee_principal_id
WHERE
(s.name= @SCHEMA)) as Grantees
on Grantees.grantee = grantee_principal.name
WHERE
((s.name=@SCHEMA))

-- list of tables
select schema_name(schema_id) as schema_name, name from sys.tables where name like ('%test%')

-- table record counts 
SELECT sm.name [schema] ,
tb.name logical_table_name ,
SUM(rg.total_rows) total_rows
FROM sys.schemas sm
INNER JOIN sys.tables tb ON sm.schema_id = tb.schema_id
INNER JOIN sys.pdw_table_mappings mp ON tb.object_id = mp.object_id
INNER JOIN sys.pdw_nodes_tables nt ON nt.name = mp.physical_name
INNER JOIN sys.dm_pdw_nodes_db_column_store_row_group_physical_stats rg
ON rg.object_id = nt.object_id
AND rg.pdw_node_id = nt.pdw_node_id
AND rg.distribution_id = nt.distribution_id
WHERE 1 = 1
GROUP BY sm.name, tb.name
order by 3
====================================
-- serverless sql pool monitor query history, everything that has run for the last 30 days. 

SELECT * FROM (SELECT *, COUNT(*) OVER() AS total_count, ROW_NUMBER() OVER( ORDER BY r.start_time desc) as [rownum] FROM 
(SELECT req.status as [status],req.transaction_id as [request_id],'SQL On-demand' as [SQL Resource],
s.login_name as [login_name],CAST(s.session_id as VARCHAR) as [session_id],
req.start_time as [submit_time],req.start_time as [start_time],
Null as [end_time],req.command as [command_clause],
SUBSTRING(sqltext.text,(req.statement_start_offset/2)+1,
((CASE req.statement_end_offset WHEN -1 THEN DATALENGTH(sqltext.text) 
ELSE req.statement_end_offset END - req.statement_start_offset)/2) + 1) as [command],
req.total_elapsed_time as [duration],'N/A' as [queued_duration],
req.total_elapsed_time as [running_duration],'N/A' as [data_processed_in_MB],
'N/A' as [group_name],'N/A' as [source],'N/A' as [pipeline],'N/A' as [importance],
'N/A' as [classifier_name],'N/A' as [data_processed_in_bytes] 
FROM sys.dm_exec_requests req 
CROSS APPLY sys.dm_exec_sql_text(sql_handle) sqltext 
JOIN sys.dm_exec_sessions s ON req.session_id = s.session_id  and s.session_id not in 
(select distinct Session_Id FROM sys.dm_exec_requests req 
CROSS APPLY sys.dm_exec_sql_text(sql_handle) sqltext 
WHERE SUBSTRING(sqltext.text,(req.statement_start_offset/2)+1,
((CASE req.statement_end_offset WHEN -1 THEN DATALENGTH(sqltext.text)
ELSE req.statement_end_offset END - req.statement_start_offset) / 2) + 1)  like'%@@Azure.Synapse.Monitoring.SQLQuerylist%')
UNION SELECT h.status as [status],h.transaction_id as [request_id],'SQL On-Demand' as [SQL Resource],
h.login_name as [login_name],'N/A' as [session_id],h.start_time as [submit_time],h.start_time as [start_time],
h.end_time as [end_time],h.command as [command_clause],h.query_text as [command],
h.total_elapsed_time_ms as [duration],'N/A' as [queued_duration],h.total_elapsed_time_ms as [running_duration],
CAST(h.data_processed_mb as VARCHAR) as [data_processed_in_MB],'N/A' as [group_name],
'N/A' as [source],'N/A' as [pipeline],'N/A' as [importance],'N/A' as [classifier_name],
'N/A' as [data_processed_in_bytes] FROM sys.dm_exec_requests_history h) as r 
where ((r.start_time >= CONVERT(datetime,'2020-12-14T11:54:21Z') 
and r.start_time <= CONVERT(datetime,'2021-01-13T11:54:21Z')))) as final_dataset_output 
WHERE final_dataset_output.rownum between 0 and 100

