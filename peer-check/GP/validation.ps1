Param(
   [Parameter(Position=1)]
   [string]$s3Bucket,

   [Parameter(Position=2)]
   [string]$PD,

   [Parameter(Position=3)]
   [string]$DefaultSecretName
)

# Import the Active Directory module
Import-Module -Name ActiveDirectory

# Retrieve default secret from Secret Manager
$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $DefaultSecretName).SecretString

# Retrieve domain details
$DomainNetBios = (Get-ADDomain -Identity $FetchedDefault.domain).NetBIOSName
$DomainName = (Get-ADDomain -Identity $FetchedDefault.domain).DistinguishedName
$Domain = "OU="+$PD+",OU=GP,OU="+$DomainNetBios+","+$DomainName

# Get only the DNSHostName property for computers in the OU and its child OUs recursively, excluding clusters
$computers = Get-ADComputer -Filter {(servicePrincipalName -like "*WSMAN*")} -SearchBase $Domain -SearchScope Subtree -Property DNSHostName | Select-Object -ExpandProperty DNSHostName

# Domain user credetials
$username = $FetchedDefault.shortname+"\"+$FetchedDefault.username
$password = ConvertTo-SecureString $FetchedDefault.password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Run script on each computer
foreach ($computer in $computers) {
  if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
    # Create a script block to be executed on the remote computer
    $scriptBlock = {
      param($s3Bucket,$PD)
      # Create the folder called "peer-check" in C:\
      $folderPath = "C:\peer-check"
      New-Item -ItemType Directory -Path $folderPath -Force

      # Copy files from S3 bucket to C:\peer-check
      $sourcePath = "s3://$s3Bucket/scripts/GP"
      $destinationPath = "$folderPath"
      aws s3 cp "$($sourcePath)/XML" "$destinationPath\XML" --recursive
      aws s3 cp "$($sourcePath)/report.ps1" $destinationPath
      aws s3 cp "$($sourcePath)/compliance.ps1" $destinationPath
      Write-Output "peer-check files copied from $($s3Bucket)"

      # Run report.ps1 in C:\peer-check\
      $reportScriptPath = Join-Path $folderPath "report.ps1"
      & $reportScriptPath $credential

      # Run compliance.ps1 in C:\peer-check\
      $complianceScriptPath = Join-Path $folderPath "compliance.ps1"
      & $complianceScriptPath

      # Copy the contents of C:\peer-check\result to S3 bucket under the folder PD\hostname
      $hostname = $env:COMPUTERNAME
      $resultPath = "C:\peer-check\result"
      $s3DestinationPath = "s3://$s3Bucket/$PD/"
      aws s3 cp $resultPath $s3DestinationPath --recursive
      Write-Output "results copied to $($s3Bucket)/$($PD)/"
    }

    # Invoke the script block on the remote computer
    Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ArgumentList $s3Bucket,$PD
  }
  else {
    Write-Output "Server '$computer' is not reachable."
  }
}
