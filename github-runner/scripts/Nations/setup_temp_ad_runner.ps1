param (
  [Parameter(Mandatory=$true)]
  [string]$GH_TOKEN,
  [Parameter(Mandatory=$true)]
  [string]$secretId
)


$gh_runner_version = "2.317.0"

$secretValue = (aws secretsmanager get-secret-value --secret-id $secretId | ConvertFrom-Json).SecretString | ConvertFrom-Json
$ad_user = "$($secretValue.shortname)\directory-admin"
$ad_pass = $secretValue.password

$current_dir = Get-Location
$repo = $current_dir -replace "-actions.*"
$repo_dir = $repo+'-ad-temp'
$existing_repo = $repo.split('\')[1]
$runner_name = $repo_dir.split('\')[1]

$Header = @{"Accept" = "application/vnd.github+json"; "Authorization" = "Bearer ${GH_TOKEN}"; "X-GitHub-Api-Version" = "2022-11-28"}
$CallTokenApi = Invoke-RestMethod -Method POST -Header $Header -uri "https://api.github.com/repos/emisgroup/$existing_repo/actions/runners/registration-token" -Proxy "http://185.46.212.92:443"

mkdir $repo_dir; cd $repo_dir
Copy-Item -Path C:\Agents\actions-runner-win-x64-$gh_runner_version.zip -Destination .
Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-$gh_runner_version.zip", "$PWD")
rm .\actions-runner-win-x64-$gh_runner_version.zip
Set-Content "$($repo_dir)\.env" "https_proxy=http://185.46.212.92:443"
Add-Content "$($repo_dir)\.env" "no_proxy=localhost"
./config.cmd --url "https://github.com/emisgroup/$existing_repo" --token $CallTokenApi.token --replace --name "$($runner_name)" --work _work --runasservice --unattended --labels prd,ad
$service = Get-Content .\.service -Raw

$runnerAccount = New-Object System.Security.Principal.NTAccount -ArgumentList $ad_user
$itemList = gci -Path $repo_dir -Recurse
$acl = Get-Acl -Path $repo_dir
$ar = New-Object System.Security.AccessControl.FileSystemAccessRule($ad_user, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($ar)
Set-Acl -Path $repo_dir -AclObject $acl
$runnerAccount = New-Object System.Security.Principal.NTAccount -ArgumentList $ad_user
foreach ($item in $itemList) {
      $acl = Get-Acl -Path $item.FullName
      $acl.SetOwner($runnerAccount)
      Set-Acl -Path $item.FullName -AclObject $acl
  }
sc.exe config $service obj=$ad_user password=$ad_pass
Restart-Service -Name $service