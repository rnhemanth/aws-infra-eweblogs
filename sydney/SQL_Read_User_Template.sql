USE [master]

EXEC sp_configure 'show advanced options',1
RECONFIGURE WITH OVERRIDE
GO
EXEC sp_configure 'xp_cmdshell',1
RECONFIGURE WITH OVERRIDE
GO

--ADD AUTH USERS--

if exists (select * from sys.server_principals where name = N'domain\read-only')
drop login [domain\read-only]

Create login [domain\read-only] from windows with default_database=[Master], default_language=[British]

declare @databasename varchar(100), @command nvarchar(2000)
declare AllDatabasecursor cursor for select name from sys.databases
open alldatabasecursor
fetch next from ALLDatabaseCursor into @DatabaseName
while @@FETCH_STATUS = 0
begin
select @command =
'use ' +@databasename+ '
if exists (select * from sys.database_principals where name = N''domain\read-only'')
drop user [domain\read-only]
Create user [domain\read-only] for login [domain\read-only]
exec sp_addrolemember N''db_datareader'', N''domain\read-only''
'

exec sp_executesql @command

fetch next from Alldatabasecursor into @Databasename
end
close alldatabasecursor deallocate alldatabasecursor
set nocount off

RECONFIGURE WITH OVERRIDE
GO
