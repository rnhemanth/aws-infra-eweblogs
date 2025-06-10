-------------------------------------------
-- On primary and secondary replica --
-------------------------------------------

USE [master]
GO
CREATE LOGIN [NETBIOSNAME\USERNAME] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[British]
GO

GRANT VIEW ANY DEFINITION to [NETBIOSNAME\USERNAME]
GRANT VIEW SERVER STATE to  [NETBIOSNAME\USERNAME]
