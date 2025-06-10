-------------------------------------------
-- On primary and secondary replica --
-------------------------------------------

USE [master]
GO
CREATE LOGIN [NETBIOSNAME\gp-sql-read] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO

GRANT VIEW ANY DEFINITION to [NETBIOSNAME\gp-sql-read]
GRANT VIEW SERVER STATE to  [NETBIOSNAME\gp-sql-read]
