Declare @PrimaryServername nVarchar (50) = '$(PrimaryServername)'
Declare @SecondaryServername nVarchar (50) = '$(SecondaryServername)'
Declare @AGname1 nVarchar (30) = '$(AG1name)'
Declare @Port nVarchar (10) = '5022'
Declare @DomainName nVarchar (50) = '$(DomainName)'
Declare @Domain nVarchar(max)
Declare @SQL nVarchar (max)

set @Domain = '.' + @DomainName + ':' + @Port

set @SQL = N'
	if exists (SELECT name FROM  master.sys.availability_groups where name like ''%AG1'')
		begin
			print ''Availability Group 1 already exists'';
		end
	else
		create availability group [' + @AGname1 + '] WITH (DB_FAILOVER = ON, AUTOMATED_BACKUP_PREFERENCE = PRIMARY) for
		replica on N''' + @PrimaryServername + ''' with (
		endpoint_url = N''TCP://' + SUBSTRING(@PrimaryServername, 1, CHARINDEX('\', @PrimaryServername)-1)+  @Domain + ''',
		failover_mode = automatic,
		availability_mode = synchronous_commit,
		backup_priority = 50,
		secondary_role (
		allow_connections = no
		),
		seeding_mode = automatic
		),
		N''' + @SecondaryServername + ''' with (
		endpoint_url = N''TCP://' + SUBSTRING(@SecondaryServername, 1, CHARINDEX('\', @SecondaryServername)-1) +  @Domain + ''',
		failover_mode = automatic,
		availability_mode = synchronous_commit,
		backup_priority = 50,
		secondary_role (
		allow_connections = no
		),
		seeding_mode = automatic
		)'


set @SQL = @SQL

print @SQL;
EXECUTE sp_executesql @SQL;
