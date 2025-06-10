Declare @PrimaryServername nVarchar (50) = '$(PrimaryServername)'
Declare @SecondaryServername nVarchar (50) = '$(SecondaryServername)'
Declare @RSServer nVarchar (50) = '$(RSServername)'
Declare @AGname1 nVarchar (30) = '$(AG1name)'
Declare @AGname2 nVarchar (30) = '$(AG2name)'
Declare @EnvironmentType nVarchar (20) = '$(EnvType)' --EN:England GPLive, NI:Northern Ireland, CM:CCMH, JY:Jersey, IM:Isle of Man, GI:Gibraltar.
Declare @Port nVarchar (10) = '5022'

Declare @Domain nVarchar(max)
Declare @DomainName nVarchar (50) = '$(DomainName)'
Declare @SQL nVarchar (max)
Declare @SQLAG2 nVarchar (max)

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

If ((@EnvironmentType in ('EN','NI') or ((@EnvironmentType in ('CM','CS') and Len(@RSServer) > 0))) and @AGname1 not like '%AG2') 
	begin
		set @SQL = @SQL +
		',
		N''' + @RSServer + ''' with (
		endpoint_url = N''TCP://' + SUBSTRING(@RSServer, 1, CHARINDEX('\', @RSServer)-1) +  @Domain + ''',
		failover_mode = manual,
		availability_mode = asynchronous_commit,
		backup_priority = 50,
		secondary_role (
		allow_connections = all
		),
		seeding_mode = automatic
		)
		'
	end


set @SQLAG2 = N'
	if exists (SELECT name FROM  master.sys.availability_groups where name like ''%AG2'')
		begin
			print ''Availability Group 2 already exists'';
		end
	else
		create availability group [' + @AGname2 + '] WITH (DB_FAILOVER = ON, AUTOMATED_BACKUP_PREFERENCE = PRIMARY) for
		replica on N''' + @PrimaryServername + ''' with (
		endpoint_url = N''TCP://' + SUBSTRING(@PrimaryServername, 1, CHARINDEX('\', @PrimaryServername)-1) +  @Domain + ''',
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

set @SQL = @SQL + @SQLAG2

print @SQL;
EXECUTE sp_executesql @SQL;
