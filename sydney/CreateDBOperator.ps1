###################################################################
#                Create DB Operator Account
###################################################################
Param(
   [Parameter(Position=1)]
   [string]$PrimaryServer,

   [Parameter(Position=2)]
   [string]$SecondaryServer

)

$ServerName = @($PrimaryServer, $SecondaryServer)

foreach ($instance in $ServerName) {

            try {
                    Write-host 'Checking Sys.Operators for required Operator Account for:' $instance  -fore Green
                    Import-Module dbatools -erroraction SilentlyContinue

                    Invoke-DbaQuery -SqlInstance $instance -Query "
If not exists (select * from  msdb.dbo.sysoperators where name = 'SQL Job Failure')
begin
EXEC msdb.dbo.sp_add_operator @name=N'SQL Job Failure',
		@enabled=1,
		@weekday_pager_start_time=90000,
		@weekday_pager_end_time=180000,
		@saturday_pager_start_time=90000,
		@saturday_pager_end_time=180000,
		@sunday_pager_start_time=90000,
		@sunday_pager_end_time=180000,
		@pager_days=0,
		@email_address=N'grouphostedengineeringdatabaseadministrationteam@emishealth.com',
		@category_name=N'[Uncategorized]'
end
"

            }
            Catch {

                    Write-Host $_.Exception.Message -ForegroundColor Red

            }
        }
