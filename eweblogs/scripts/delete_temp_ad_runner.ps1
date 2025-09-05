param (
  [Parameter(Mandatory=$true)]
  [string]$GH_TOKEN,
  [Parameter(Mandatory=$true)]
  [string]$secretId
)
$secretValue = (aws secretsmanager get-secret-value --secret-id $secretId | ConvertFrom-Json).SecretString | ConvertFrom-Json
$ad_user = "$($secretValue.shortname)\$($secretValue.username)"
$ad_pass = $secretValue.password

$current_dir = Get-Location
$repo = $current_dir -replace "-actions.*"
$repo_dir = $repo+'-ad-temp'
$existing_repo = $repo.split('\')[1]
$runner_name = $repo_dir.split('\')[1]

$Header = @{"Accept" = "application/vnd.github+json"; "Authorization" = "Bearer ${GH_TOKEN}"; "X-GitHub-Api-Version" = "2022-11-28"}
$CallTokenApi = Invoke-RestMethod -Method POST -Header $Header -uri "https://api.github.com/repos/emisgroup/$existing_repo/actions/runners/registration-token" -Proxy "http://185.46.212.92:443"



cd $repo_dir
./config.cmd remove --token $CallTokenApi.token
start-sleep -Seconds 30
cd ..
rm -r $repo_dir -Force