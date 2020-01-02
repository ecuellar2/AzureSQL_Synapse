CREATE EXTERNAL FILE FORMAT uncompressedparquet
WITH (  
    FORMAT_TYPE = PARQUET  
  --   [ , DATA_COMPRESSION = {  
  --      'org.apache.hadoop.io.compress.SnappyCodec'  
  --    | 'org.apache.hadoop.io.compress.GzipCodec'      }  
  -- ]
);  
 
CREATE EXTERNAL FILE FORMAT snappyparquet
WITH (  
    FORMAT_TYPE = PARQUET,  
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
);  
 
CREATE EXTERNAL FILE FORMAT gzipparquet
WITH (  
    FORMAT_TYPE = PARQUET,  
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.GzipCodec'
);  
 
CREATE EXTERNAL DATA SOURCE ext_adlsgen2_source WITH 
(TYPE = hadoop, LOCATION = 'abfss://filesystem@account.dfs.core.windows.net', CREDENTIAL = msi_cred);
 
CREATE EXTERNAL TABLE [ext].[tablename_ext] 
(
column           VARCHAR   (200)
)
WITH
(
    LOCATION = 'lake/curated/folderpath/',
    DATA_SOURCE = ext_adlsgen2_source,
    FILE_FORMAT = uncompressedparquet,
    REJECT_TYPE = value,
    REJECT_VALUE = 0
); 
 
select COUNT_BIG(*) from [dbo].[table]
 
Example using copy syntax (newer method):
COPY INTO [dest_table]
FROM 'https://account.dfs.core.windows.net/filesystem/folder/*.parquet'
WITH (
    FILE_FORMAT = [uncompressedparquet],
    CREDENTIAL = (IDENTITY='Managed Identity')
)

--Call procedure below to load DB table from external table that is referencing adls gen2.
----------------------------------------------------------------
 
IF OBJECT_ID ('dbo.Polybase','P') IS NOT NULL
DROP PROCEDURE [dbo].[Polybase];
GO
CREATE PROCEDURE [dbo].[Polybase]
AS
BEGIN
 
IF OBJECT_ID ('dbo.table','U') IS NOT NULL
DROP TABLE [dbo].[table]
 
CREATE TABLE [dbo].[table]
WITH
( 
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
)
AS SELECT * FROM [ext].[table] 
END;
