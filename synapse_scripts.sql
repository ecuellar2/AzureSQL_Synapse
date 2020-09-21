--SQL DW
select top 100* from dbo.Query_stats_active_requests where classifier_Name is null or classifier_name not in ('username') order by status
select top 100* from sys.workload_management_workload_classifiers 
select top 100* from sys.dm_workload_management_workload_groups_stats
select top 100* from  sys.dm_pdw_exec_sessions where login_name not in ('user') order by status
select top 100* from  sys.workload_management_workload_groups
select top 100* from sys.dm_pdw_exec_requests
select COUNT_BIG(1) from sql dw table
EXEC sp_spaceused N'schema.table';  

/*Use below if more than 60M records
Stage in etl schema as DISTRIBUTION ROUND_ROBIN (default), CLUSTERED COLUMNSTORE (default) > DISTRIBUTION HASH, CLUSTERED COLUMNSTORE
Use below if less than 60M records
Stage in etl schema as DISTRIBUTION ROUND_ROBIN, HEAP > DISTRIBUTION HASH, CLUSTERED COLUMNSTORE
*/



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
SELECT pr.principal_id, pr.name, pr.type_desc,   
    pr.authentication_type_desc, pe.state_desc, pe.permission_name  
FROM sys.database_principals AS pr  
JOIN sys.database_permissions AS pe  
    ON pe.grantee_principal_id = pr.principal_id

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
--Synapse
-- create credentials for container using sql on demand
IF EXISTS (SELECT * FROM sys.credentials WHERE name = 'https://xx.dfs.core.windows.net/container')
DROP CREDENTIAL [https://xx.dfs.core.windows.net/container]
Go

CREATE CREDENTIAL [https://xx.dfs.core.windows.net/container]
WITH IDENTITY='SHARED ACCESS SIGNATURE',  
SECRET = '?sv=%3D'
Go
