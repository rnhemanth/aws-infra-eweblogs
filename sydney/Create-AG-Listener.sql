Declare @AGname nVarchar (30) = '$(AGname)'
Declare @Port nVarchar (30) = '$(Port)'
Declare @IPs nVarchar (200) = '$(IPlist)'
Declare @SQL nvarchar (max)

set @SQL = N'
	ALTER AVAILABILITY GROUP [' + @AGname + ']
	ADD LISTENER ''' + @AGname + ''' ( WITH IP ( ' + @IPs + ' ) , PORT = ' + @Port + ' );
';
execute sp_executesql @SQL;
