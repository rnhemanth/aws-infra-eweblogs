###################################################################
#                Update Agent Job Owners
###################################################################
Param(
   [Parameter(Position=1)]
   [string]$ReplicaServer

)

$ServerName = @($ReplicaServer)

foreach ($instance in $ServerName) {

            try {
                    Write-host 'Updating AgentJob Permisisons for:' $instance  -fore Green
                    Invoke-DbaQuery -SqlInstance $instance -Query "If exists (SELECT s.name AS JobName,job_id, l.name AS JobOwner
                    FROM msdb..sysjobs s
LEFT JOIN master.sys.syslogins l ON s.owner_sid = l.sid
WHERE l.name <> 'sa' or l.name is null)

begin

declare
    @jobid varchar(max),
	    @SQLScript NVarchar(4000)
declare DBCursor cursor local fast_forward for

SELECT job_id
FROM msdb..sysjobs s
LEFT JOIN master.sys.syslogins l ON s.owner_sid = l.sid
WHERE l.name <> 'sa' or l.name is null

open DBCursor

fetch next from DBCursor into @jobid

while @@Fetch_Status = 0
begin

  --Build up the statement to execute.
	set @SQLScript =
		N'EXEC msdb.dbo.sp_update_job @job_id=N'''+ @jobid + ''',
		@owner_login_name=N''sa'''

	execute sp_executesql @SQLscript
		--print @SQLscript

  fetch next from DBCursor into @jobid
end
end
"

            }
            Catch {
                    Write-Host "##vso[task.complete result=Failed;]"
                    Write-Host $_.Exception.Message -ForegroundColor Red

            }
        }
