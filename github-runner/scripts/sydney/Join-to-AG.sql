Declare @AGname nVarchar (30) = '$(AGname)'
Declare @SQL nvarchar (max)

IF EXISTS (SELECT name FROM sys.availability_groups WHERE name LIKE @AGname)
  SELECT name FROM sys.availability_groups WHERE name LIKE @AGname
else
  BEGIN
    SELECT SERVERPROPERTY ('IsHadrEnabled');
    set @SQL = N'alter availability group [' + @AGname + ']
      join;
    alter availability group [' + @AGname + ']
      grant create any database;
    ';
    execute sp_executesql @SQL;
  END
