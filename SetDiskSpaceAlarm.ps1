# Replace "smtp.domain.com" with your mail server name
Add-Type -AssemblyName System.Net.Mail

$smtp = New-Object System.Net.Mail.SmtpClient("smtp.domain.com")

# Set thresholds (in gigabytes) for C: drive and for the remaining drives
$driveCthreshold = 10
$threshold = 60

# Replace settings below with your e-mails
$emailFrom = "DBServer@domain.com"
$emailTo = "email2@domain.com"

# Get SQL Server hostname
$hostname = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Name

# Get all drives with free space less than a threshold. Exclude System Volumes
$Results = Get-CimInstance -ClassName Win32_Volume -Filter "SystemVolume='False' AND DriveType=3" | Where-Object {`
	($_.FreeSpace/1GB -lt  $driveCthreshold -and $_.DriveLetter -eq "C:") -or ($_.FreeSpace/1GB -lt  $threshold -and $_.DriveLetter -ne "C:" )
}

ForEach ($Result In $Results){
	$drive = $Result.DriveLetter
	$space = $Result.FreeSpace
	$thresh = if($drive -eq 'C:'){$driveCthreshold} else {$threshold}

	# Send e-mail if the free space is less than threshold parameter
	$smtp.Send(
	$emailFrom,
	$emailTo,
	# E-mail subject
	"Disk $drive on $hostname has less than $thresh GB of free space left ",
	# E-mail body
	("{0:N0}" -f [math]::truncate($space/1MB))+" MB")
}