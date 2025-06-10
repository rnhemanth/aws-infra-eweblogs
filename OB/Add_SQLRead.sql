-------------------------------------------
-- On primary and secondary replica --
-------------------------------------------

USE [master]
GO
CREATE LOGIN [NETBIOSNAME\lad-sql-read] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO

GRANT VIEW ANY DEFINITION to [NETBIOSNAME\lad-sql-read]
GRANT VIEW SERVER STATE to  [NETBIOSNAME\lad-sql-read]
