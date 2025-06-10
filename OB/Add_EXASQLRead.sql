-------------------------------------------
-- On primary and secondary replica --
-------------------------------------------

USE [master]
GO
CREATE LOGIN [NETBIOSNAME\exa-sql-read] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO
DENY CONNECT SQL TO [NETBIOSNAME\exa-sql-read]  -- Note, deny connect on primary/secondary
GO
ALTER SERVER ROLE [dbcreator] ADD MEMBER [NETBIOSNAME\exa-sql-read]
GO

GRANT VIEW ANY DEFINITION to [NETBIOSNAME\exa-sql-read]
GRANT VIEW SERVER STATE to  [NETBIOSNAME\exa-sql-read]
