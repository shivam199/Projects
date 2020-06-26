######################################################################################################################
#			Author: Jose Andres Torres
#			Reviewer: BaR Design and Engineering team
#			Version Date: 10/22/2019
#			Enroll or Un-enroll physical servers from a Veeam protection group
#           Enroll or Un-enroll virtual servers from a Veeam protection group
#           Capacity Reports
#           FETB Reports
#           New Legal HF2 Veeam Environment
######################################################################################################################

####################################################################################################################################################################################################################################################################################
# Install from Powershell Gallery https://www.powershellgallery.com/packages/PSWriteColor
# Install-Module -Name PSWriteColor
# Import-Module PSWriteColor
# Add-PSSnapin VeeamPSSnapin #Need to be executed from Veeam VBR powershell Veeam PSSnapIn gives access to the Veeam Backup & Replication cmdlets library
# Install-Module PSJsonCredential # for Json credentials
#I leveraged an open-source PowerShell module (https://github.com/jdhitsolutions/PSJsonCredential) to allow for credential files to be utilized, and not have a clear-text password in use. 
####################################################################################################################################################################################################################################################################################


####################################################################################################################################################################################################################################################################################
#Global Variables###################################################################################################################################################################################################################################################################
####################################################################################################################################################################################################################################################################################
$global:ServerExecuteProgram = "vmbar01.amr.corp.intel.com"
$global:ServerCred="vmbar01.amr.corp.intel.com"

$global:LogResultsRobocopy = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\Results-Copy.txt'
$global:LogMatchedFiles = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\MatchedFiles.txt'
$global:MatchedNamesNoLines = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\MatchedNamesNoLines.txt'

$global:LogNull = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt'
#$Log = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\Results-Agent.txt' #Log results of install
$global:Log2 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\Result-Access.txt' #Log results of install

$global:ServerLogName = "vmbar01.amr.corp.intel.com"
$global:LogAuditCSVFFile = "Logs-VeeamBackups-Enroll-Unenroll.csv"
$global:LogAuditCSVFolderPath = 'e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs'
$global:CompleteLogAuditCSVPathFile = "\\" + $ServerLogName + "\" + $LogAuditCSVFolderPath + "\" + $LogAuditCSVFFile

$global:ServerLogSecondaryName = "fm1svmon100.amr.corp.intel.com"
$global:ServerLogSecondaryCopyLocation = "P$\Logs-Veeam-Enroll-UnEnroll"
$global:CompleteLogSecondaryFolderLocation = "\\" + $ServerLogSecondaryName + "\" + $ServerLogSecondaryCopyLocation + "\" + $LogAuditCSVFFile

$global:FolderLocationofCSVs = "\\" + $VBRNameGlobal + "\" + $PathVBRFileCSV + "\" + $File_Extension # folder location of the files with extension .csv

########Global variables for viewbackupstatus#############################################################################################################################################################################
$global:ServersTXTFull = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt" #default location of the txt servers.txt
$global:PathTXTFolder = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\BackupStatus\TXT" #folder path location of the vbr list and any other txt file also the one gets created from servers.txt
$global:NewServerList = "servers"
$global:VBRListFilename = "VBRs.txt"
$global:VBRListCapacityFilename = "VBRCapacity.txt"
$global:FilesFolderPath = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\BackupStatus\Files"
$global:RemoteBackupStatusFolderName = ("BackupStatus_")
$global:RemoteBackupStatusPath = ("c$\temp" + "\" + $global:RemoteBackupStatusFolderName)
$global:CSVReportsFolderPath = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\BackupStatus\ReportsCSV"
$global:CSVFileName = ("BackupStatus_") #need to concatenate the veeam vbr before the CSV FileName
$global:HTMLReportsFolderPath = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\BackupStatus\ReportsHTML"
$global:HTMLFileName = ("BackupStatus_HTML_") #need to concatenate the veeam vbr before the HTML FileName
$global:CSVDiskUsageReportsFolderPath = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\DiskUsage\Reports\CSV" #folder to store the disk usage reports
$global:CSVDiskUsageFileName = ("_DiskUsage_Report_") #need to concatenate the veeam vbr before the CSV FileName
$global:HTMLDiskUsageReportsFolderPath = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\DiskUsage\Reports\HTML" #folder to store the disk usage reports
$global:HTMLDiskUsageFileName = ("_DiskUsage_Report_") #need to concatenate the veeam vbr before the HTML FileName
$global:PathHTMLCapacityFolder = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CapacityRepoProxy\Reports" #folder to store the capacity repo proxy reports

########Global variables for Capacity One For All################################################################################################################################################################
$global:ScriptFolderPath = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup" #FullPath
$global:pathTemplateRepos = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\OneForAllCapacity\Files\Template"
$global:pathTempFiles = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\OneForAllCapacity\Files\TempFiles"
$global:pathServerOneForAllHTML = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\OneForAllCapacity\Reports\HTML"
$global:pathServerOneForAllCSV = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\OneForAllCapacity\Reports\CSV"
$global:CSVFile = "DiskUsageRepos_Report_"

########Global variables for ImageLevelBackups################################################################################################################################################################
$global:PathTXTImageFolder = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ImageLevel\TXT" #folder path location of the vbr list and any other txt file also the one gets created from servers.txt
$global:NewEnrollImageList='EnrollImage'
$global:NewUnenrollImageList='UnenrollImage'


###########################################################################################################################################################################################################
#region import credtials and assign
<# 
Import-Module ("\\"+$global:ServerCred+"\"+'e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Credentials\PSJsonCredential\PSJsonCredential.psd1')
$CredentialKey = 'PSCredentialKey1'
$AMRCredentialFile = Get-ChildItem -Path ("\\"+$global:ServerCred+"\"+'e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Credentials\user.json')
$global:AMRCredential = Import-PSCredentialFromJson -Path $AMRCredentialFile -Key $CredentialKey 
#>
#end region
#################################################################################################################################################################################################################################################################################################################################

#################################################################################################################################################################################################################################################################################################################################
#################################################################################################################################################################################################################################################################################################################################
#Functions
#################################################################################################################################################################################################################################################################################################################################

function AboutJAt
{
    cls
    WRITE-HOST "##################################################" -ForegroundColor White
    WRITE-HOST "#" -ForegroundColor White -NoNewline; 			  WRITE-HOST "    Author: Jose Andres Torres                  "        -ForegroundColor Green -NoNewline; Write-Host "#" -ForegroundColor White
    WRITE-HOST "#" -ForegroundColor White -NoNewline;			  WRITE-HOST "    Intel Team: BaR Design and Engineering      "        -ForegroundColor Cyan -NoNewline; Write-Host "#" -ForegroundColor White
    WRITE-HOST "#" -ForegroundColor White -NoNewline;			  WRITE-HOST "    Date: $Today                   "                        -ForegroundColor Magenta -NoNewline; Write-Host "#" -ForegroundColor White
    WRITE-HOST "#" -ForegroundColor White -NoNewline;			  WRITE-HOST "    Applicaiton developed for internal use      "        -ForegroundColor Yellow -NoNewline; Write-Host "#" -ForegroundColor White
    WRITE-HOST "##################################################" -ForegroundColor White
}#fin aboutjat

function CreateMenuPhysicalVirtual
{ #fucnion CreateMenuPhysicalVirtual
    
    CLS    
    Write-Host "=========="  -ForegroundColor White -NoNewline; Write-Host " Menu: Physical or Virtual "        -ForegroundColor Cyan   -NoNewline; Write-Host "=========="              -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1: Press '1' Physical Server(s) Agent Level"   -ForegroundColor Yellow -NoNewline; WRITE-HOST " |"            -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2: Press '2' Virtual Server(s)  Image Level"    -ForegroundColor Yellow -NoNewline; WRITE-HOST " |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M: Press 'M' Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "           |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q: Press 'Q' to Quit."             -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                       |"  -ForegroundColor White;
    Write-Host "===============================================" -ForegroundColor White    
} #CreateMenuPhysicalVirtual

function CreateMenuWindowsLinux
{ #fucnion CreateMenuWindowsLinux
    
    CLS    
    Write-Host "========"  -ForegroundColor White -NoNewline; Write-Host " Menu: Choose OPerating System "  -ForegroundColor Cyan   -NoNewline; Write-Host "========="              -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1: Press '1' Windows Server(s)"  -ForegroundColor Yellow -NoNewline; WRITE-HOST "               |"            -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2: Press '2' Linux Server(s)"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "                 |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M: Press 'M' Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "            |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q: Press 'Q' to Quit."           -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                        |"  -ForegroundColor White;
    Write-Host "================================================" -ForegroundColor White    
} #end CreateMenuWindowsLinux

function MenuReports
{ 
    
    CLS    
    Write-Host "=================="  -ForegroundColor White -NoNewline; Write-Host " Menu: View Reports "                 -ForegroundColor Cyan   -NoNewline; Write-Host "=================="              -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1: Press '1' Most Recent Backup"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "                      |"            -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2: Press '2' Capacity Local Environment & Proxies"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 3: Press '3' Capacity VCCE Environment & Proxies"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 4: Press '4' Capacity One for All (Repos & VCCE)"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 5: Press '5' Disk Space Usage (FETB) - Windows"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "       |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M: Press 'M' Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                    |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q: Press 'Q' to Quit."               -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                |"  -ForegroundColor White;
    Write-Host "========================================================" -ForegroundColor White    
} #end MenuReports

function MenuOneForAll
{ 
    
    CLS    
    Write-Host "=============="  -ForegroundColor White -NoNewline; Write-Host " Menu: Capacity One For All "                 -ForegroundColor Cyan   -NoNewline; Write-Host "=============="    -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1: Press '1' One For All"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "                             |"            -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2: Press '2' One For All - Send Email"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "                |"           -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M: Press 'M' Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                    |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q: Press 'Q' to Quit."               -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                |"  -ForegroundColor White;
    Write-Host "========================================================" -ForegroundColor White    
} #end MenuOneForAll



function MenuSingleMultipeVBR
{ 
    
    CLS    
    Write-Host "===================="  -ForegroundColor White -NoNewline; Write-Host " Menu: View Backup Status "                 -ForegroundColor Cyan   -NoNewline; Write-Host "===================="              -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1: Press '1' Most Recent Backup - Single Environment Search"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"            -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2: Press '2' Most Recent Backup - Multiple Environment Search"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "  |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M: Press 'M' Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                              |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q: Press 'Q' to Quit."               -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                          |"  -ForegroundColor White;
    Write-Host "==================================================================" -ForegroundColor White    
} #end MenuSingleMultipeVBR

function MenuViewBackupStatusEnv
{ #fucnion MenuViewBackupStatusEnv
        
    CLS    
    Write-Host "====================="  -ForegroundColor White -NoNewline; Write-Host " Menu: View Backup Status"        -ForegroundColor Cyan   -NoNewline; Write-Host "====================="              -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1: Press '1' Bangalore SRR                    ->  BGSSVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2: Press '2' Chandler CH2                     ->  CH2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 3: Press '3' Folsom FM1                       ->  FM1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 4: Press '4' Folsom FM7 Pre-Prod              ->  FM7SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 5: Press '5' Hawthorn Farms HF2               ->  HF2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 6: Press '6' Hawthorn Farms HF2 Legal         ->  HF2SVBR200"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 7: Press '7' Ronler Acres RA2                 ->  RA2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 8: Press '8' Santa Clara SC8                  ->  SC8SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 9: Press '9' Shanghai Zizhou SHZ1             ->  SHZ1SVBR100"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "   |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M: Press 'M' Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                               |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q: Press 'Q' to Quit."           -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                           |"  -ForegroundColor White;
    Write-Host "===================================================================" -ForegroundColor White
    Write-Host "Remember to update the servers.txt file with the Server name(s)" -ForegroundColor Black -BackgroundColor White;	
} #end MenuViewBackupStatusEnv



function CreateMenuPrincipal ($Title,$MenuItems,$TitleColor,$LineColor,$MenuItemColor)
{ #funcion    
    CLEAR-HOST
    $input = "-1";    
    [string]$Title = "$Title"
    $TitleCount = $Title.Length
    $LongestMenuItem = ($MenuItems | Measure-Object -Maximum -Property Length).Maximum
    if  ($TitleCount -lt $LongestMenuItem)
    {
        $reference = $LongestMenuItem
    }
    else
        {$reference = $TitleCount}
        $reference = $reference + 10
        $Line = "═"*$reference
        $TotalLineCount = $Line.Length
        $RemaniningCountForTitleLine = $reference - $TitleCount
        $RemaniningCountForTitleLineForEach = $RemaniningCountForTitleLine / 2
        $RemaniningCountForTitleLineForEach = [math]::Round($RemaniningCountForTitleLineForEach)
        $LineForTitleLine = "`0"*$RemaniningCountForTitleLineForEach
        $Tab = "`t"
        Write-Host "╔" -NoNewline -f $LineColor;Write-Host $Line -NoNewline -f $LineColor;Write-Host "╗" -f $LineColor
        if($RemaniningCountForTitleLine % 2 -eq 1)
        {
            $RemaniningCountForTitleLineForEach = $RemaniningCountForTitleLineForEach - 1
            $LineForTitleLine2 = "`0"*$RemaniningCountForTitleLineForEach
            Write-Host "║" -f $LineColor -nonewline;Write-Host $LineForTitleLine -nonewline -f $LineColor;Write-Host $Title -f $TitleColor -nonewline;Write-Host $LineForTitleLine2 -f $LineColor -nonewline;Write-Host "║" -f $LineColor
        }
        else
        {
            Write-Host "║" -nonewline -f $LineColor;Write-Host $LineForTitleLine -nonewline -f $LineColor;Write-Host $Title -f $TitleColor -nonewline;Write-Host $LineForTitleLine -nonewline -f $LineColor;Write-Host "║" -f $LineColor
        }
            Write-Host "╠" -NoNewline -f $LineColor;Write-Host $Line -NoNewline -f $LineColor;Write-Host "╣" -f $LineColor
            $i = 1
        foreach($menuItem in $MenuItems)
        {
            $number = $i++
            $RemainingCountForItemLine = $TotalLineCount - $menuItem.Length -9
            $LineForItems = "`0"*$RemainingCountForItemLine
            Write-Host "║" -nonewline -f $LineColor ;Write-Host $Tab -nonewline;Write-Host $number"." -nonewline -f $MenuItemColor;Write-Host $menuItem -nonewline -f $MenuItemColor;Write-Host $LineForItems -nonewline -f $LineColor;Write-Host "║" -f $LineColor
        }
        Write-Host "╚" -NoNewline -f $LineColor;Write-Host $Line -NoNewline -f $LineColor;Write-Host "╝" -f $LineColor
}#end fuction create menu prncipal

function CreateMenuEnroll
{
        
    CLS    
    Write-Host "===================="  -ForegroundColor White -NoNewline; Write-Host " Menu: Veeam Environment Enroll"        -ForegroundColor Cyan   -NoNewline; Write-Host "===================="              -ForegroundColor White;
    #Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 0: Press '0' LAB FM7                          ->  FM7SVBRLAB200"  -ForegroundColor Yellow -NoNewline; WRITE-HOST " |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1:  Press '1'    Bangalore SRR                    ->  BGSSVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2:  Press '2'    Chandler CH2                     ->  CH2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 3:  Press '3'    Dalian DL1                       ->  DL1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 4:  Press '4'    Folsom FM1                       ->  FM1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 5:  Press '5'    Folsom FM7 Non-Prod              ->  FM7SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 6:  Press '6'    Hawthorn Farms HF2               ->  HF2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 7:  Press '7'    Hawthorn Farms HF2 Non-Prod      ->  HF2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 8:  Press '8'    Hawthorn Farms HF2 Legal         ->  HF2SVBR200"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 9:  Press '9'    Penang PG12                      ->  PG12SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "   |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 10: Press '10'   Ronler Acres RA2                 ->  RA2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 11: Press '11'   Rio Rancho RR7                   ->  RR7SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 12: Press '12'   Santa Clara SC8                  ->  SC8SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 13: Press '13'   Shanghai Zizhou SHZ1             ->  SHZ1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "   |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M:  Press 'M'    Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                               |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q:  Press 'Q'    to Quit."           -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                           |"  -ForegroundColor White;
    Write-Host "=======================================================================" -ForegroundColor White
    Write-Host "Remember to update the servers.txt file with the ServerNB name(s)" -ForegroundColor Black -BackgroundColor White;	
} #end function CreateMenuEnroll

function CreateMenuFETB
{
        
    CLS    
    Write-Host "===================="  -ForegroundColor White -NoNewline; Write-Host " Menu: Veeam Environment FETB"        -ForegroundColor Cyan   -NoNewline; Write-Host "===================="              -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 0:  Press '0'  Alternate Location               ->  FQDN"  -ForegroundColor Yellow -NoNewline; WRITE-HOST "          |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1:  Press '1'  Bangalore SRR                    ->  BGSSVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2:  Press '2'  Chandler CH2                     ->  CH2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 3:  Press '3'  Folsom FM1                       ->  FM1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 4:  Press '4'  Folsom FM7 Pre-Prod              ->  FM7SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 5:  Press '5'  Hawthorn Farms HF2               ->  HF2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 6:  Press '6'  Hawthorn Farms HF2 Legal         ->  HF2SVBR200"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 7:  Press '7'  Ronler Acres RA2                 ->  RA2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 8:  Press '8'  Santa Clara SC8                  ->  SC8SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 9:  Press '9'  Shanghai Zizhou SHZ1             ->  SHZ1SVBR100"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "   |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M:  Press 'M'  Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                               |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q:  Press 'Q'  to Quit."           -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                           |"  -ForegroundColor White;
    Write-Host "=====================================================================" -ForegroundColor White
    Write-Host "Remember to update the servers.txt file with the Server name(s)" -ForegroundColor Black -BackgroundColor White;	
} #end function CreateMenuFETB


function CreateMenuLocalCapacity
{ #function CreateMenuLocalCapacity
        
    CLS    
    Write-Host "================="  -ForegroundColor White -NoNewline; Write-Host " Menu: Veeam Environment - Capacity"  -ForegroundColor Cyan   -NoNewline; Write-Host "================="              -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 0:  Press '0'  Alternate Location               ->  FQDN      "     -ForegroundColor Yellow -NoNewline;       WRITE-HOST "    |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1:  Press '1'  Bangalore SRR                    ->  BGSSVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2:  Press '2'  Chandler CH2                     ->  CH2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 3:  Press '3'  Dalian DL1                       ->  DL1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 4:  Press '4'  Folsom FM1                       ->  FM1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 5:  Press '5'  Folsom FM1 SAP                   ->  FM1SVBR500"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 6:  Press '6'  Folsom FM7 Non-Prod              ->  FM7SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 7:  Press '7'  Folsom FM7 SAP                   ->  FM7SVBR500"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 8:  Press '8'  Hawthorn Farms HF2               ->  HF2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 9:  Press '9'  Hawthorn Farms HF2 Legal         ->  HF2SVBR200"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 10: Press '10' Ocotillo OC8                     ->  OC8SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 11: Press '11' Penang PG12                      ->  PG12SVBR100"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "   |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 12: Press '12' Rio Rancho RR7                   ->  RR7SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 13: Press '13' Ronler Acres RA2                 ->  RA2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 14: Press '14' Santa Clara SC8                  ->  SC8SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 15: Press '15' Shanghai Zizhou SHZ1             ->  SHZ1SVBR100"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "   |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M:  Press 'M'  Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                               |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q:  Press 'Q'  to Quit."           -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                           |"  -ForegroundColor White;
    Write-Host "=====================================================================" -ForegroundColor White
    #Write-Host "Remember to update the servers.txt file with the Server name(s)" -ForegroundColor Black -BackgroundColor White;	
} #end CreateMenuLocalCapacity

function CreateMenuVCCE
{ #function CreateMenuVCCE
        
    CLS    
    Write-Host "=================="  -ForegroundColor White -NoNewline; Write-Host " Menu: VCCE Environment - Capacity"        -ForegroundColor Cyan   -NoNewline; Write-Host "=================="              -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1: Press '1' Chandler CH2                     ->  CH2SVCCE100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "      |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2: Press '2' Folsom FM1                       ->  FM1SVCCE100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "      |"           -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 3: Press '3' Hawthorn Farms HF2               ->  HF2SVCCE100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "      |"           -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 4: Press '4' Penang PG12                      ->  PG12SVCCE100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M: Press 'M' Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                                  |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q: Press 'Q' to Quit."           -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                              |"  -ForegroundColor White;
    Write-Host "======================================================================" -ForegroundColor White    
} #end CreateMenuVCCE


function CreateMenuAMRED
{ #fucnion CreateMenuAMRED
    
    CLS    
    Write-Host "=============="  -ForegroundColor White -NoNewline; Write-Host " Menu: Choose Domain "  -ForegroundColor Cyan   -NoNewline; Write-Host "=============="              -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1: Press '1' Enroll it into AMR Backups"  -ForegroundColor Yellow -NoNewline; WRITE-HOST "       |"            -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2: Press '2' Enroll it into ED Backups"    -ForegroundColor Yellow -NoNewline; WRITE-HOST "        |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M: Press 'M' Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "             |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q: Press 'Q' to Quit."           -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                         |"  -ForegroundColor White;
    Write-Host "=================================================" -ForegroundColor White    
} #end CreateMenuAMRED

function CreateMenuUnenroll
{ #funcion CreateMenuUnenroll
   
    CLS    
    Write-Host "==================="  -ForegroundColor White -NoNewline; Write-Host " Menu: Veeam Environment Un-Enroll"        -ForegroundColor Cyan   -NoNewline; Write-Host "==================="              -ForegroundColor White;
    #Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 0: Press '0' LAB FM7                          ->  FM7SVBRLAB200"  -ForegroundColor Yellow -NoNewline; WRITE-HOST " |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 1:  Press '1'    Bangalore SRR                    ->  BGSSVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"             -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 2:  Press '2'    Chandler CH2                     ->  CH2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 3:  Press '3'    Dalian DL1                       ->  DL1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 4:  Press '4'    Folsom FM1                       ->  FM1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 5:  Press '5'    Folsom FM7 Non-Prod              ->  FM7SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 6:  Press '6'    Hawthorn Farms HF2               ->  HF2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;    
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 7:  Press '7'    Hawthorn Farms HF2 Legal         ->  HF2SVBR200"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 8:  Press '8'    Penang PG12                      ->  PG12SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 9:  Press '9'    Ronler Acres RA2                 ->  RA2SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 10: Press '10'   Rio Rancho RR7                   ->  RR7SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 11: Press '11'   Santa Clara SC8                  ->  SC8SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "     |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " 12: Press '12'   Shanghai Zizhou SHZ1             ->  SHZ1SVBR100"     -ForegroundColor Yellow -NoNewline; WRITE-HOST "    |"           -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " M:  Press 'M'    Go back to Main Menu"               -ForegroundColor Green  -NoNewline; WRITE-HOST "                                |"  -ForegroundColor White;
    Write-Host "|"         -ForegroundColor White -NoNewline; Write-Host " Q:  Press 'Q'    to Quit."           -ForegroundColor Magenta  -NoNewline; WRITE-HOST "                                            |"  -ForegroundColor White;
    Write-Host "========================================================================" -ForegroundColor White
    Write-Host "Remember to update the servers.txt file with the ServerNB name(s)" -ForegroundColor Black -BackgroundColor White;	   
} #end funcion CreateMenuUnenroll

function ValidateAllowedUser
{
    #Subroutine para validar si el usuario es parte de BaR team groups
    
    CLS
    $domain = $env:UserDomain #AMR
    $domain = $domain.trim().tolower()
    $global:ShortIDSID = $env:UserName #ad_jatorres
    $global:ShortIDSID = $global:ShortIDSID.trim().tolower()
    $global:UsuarioGlobal = ($domain + "\" + $global:ShortIDSID) 
    $filePathAllowedUsers = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Credentials\AllowedUsers\AllowedUsers.txt'   
    
    #################Trim section################################################################################
    $Loadfile = GC $filePathAllowedUsers
    if (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
    {
            $Loadfile = $Loadfile.Trim()
    } # fin (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
    $Loadfile > $filePathAllowedUsers
###############################################################################################################

#################Remove Empty LInes############################################################################
    $file = $filePathAllowedUsers
    (gc $file) | ? {$_.trim() -ne "" } | set-content $file
    $content = [System.IO.File]::ReadAllText($file)
    $content = $content.Trim()
    [System.IO.File]::WriteAllText($file, $content)
###############################################################################################################
    $isInGroup = ""
    # Valida y busca que el user exista en la lista allowed users
    Get-Content $filePathAllowedUsers ` | %{ $isInGroup = $false } ` { $isInGroup = $isInGroup -or $_.Contains($global:ShortIDSID) } ` { return $isInGroup > $LogNull }    
   
    if ($isInGroup -eq 'true') # idsid si existe
    {
        LoadUserCredentials
        RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU
    }#fin if
    else
    {    
    cls
    WRITE-HOST "No Access! " -ForegroundColor Red -NoNewline; WRITE-HOST "You do NOT have admin rights to run this application." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;
    [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = "" ; Protection_Group = "" ; Status = 'Error: Access Denied'; Date = $DT ; Code = $LASTEXITCODE } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
    Start-Sleep -S 10
    EXIT
    }#fin else
} # fin function ValidateUserActiveDirectory

#Temp removed to avoid importing Active directory direct calls
<# function ValidateUserActiveDirectory
{
    #Subroutine para validar si el usuario es miembro de alguno de los 4 groups antes de abrir el menu si no existe se va al else y da access errror
    
    #How to install the PowerShell Active Directory module https://4sysops.com/wiki/how-to-install-the-powershell-active-directory-module/
    #whoami = amr\ad_jatorres for command prompt    
    CLS
    $domain = $env:UserDomain #AMR
    $domain = $domain.trim().tolower()
    $global:ShortIDSID = $env:UserName #ad_jatorres
    $global:ShortIDSID = $global:ShortIDSID.trim().tolower()
    $global:UsuarioGlobal = ($domain + "\" + $global:ShortIDSID)    
    $group1 = "Avamar_AMR"
    $group2 = "Backup Admins"
    $group3 = "Backup Second Level Support"
    #$group4 = "AvamarL2_AMR"
    
    #Get-ADGroup -Filter {name -like "*AVAMAR_AMR"} | Get-ADGroupMember #DISPLAYS THE ACCOUNTS NESTED INSIDE THE GROUP
    $members1 = Get-ADGroupMember -Identity $group1 -Recursive | Select -ExpandProperty Name #Displays all the members under this group account
    $members2 = Get-ADGroupMember -Identity $group2 -Recursive | Select -ExpandProperty Name #Displays all the members under this group account
    $members3 = Get-ADGroupMember -Identity $group3 -Recursive | Select -ExpandProperty Name #Displays all the members under this group account
    #$members4 = Get-ADGroupMember -Identity $group4 -Recursive | Select -ExpandProperty Name #Displays all the members under this group account
    
    ForEach ($user in $global:ShortIDSID) 
    {
        If ($members1 -contains $user -or $members2 -contains $user -or $members3 -contains $user ) #TRUE MEMBER
        {
            $isInGroup = 'true'
            #Write-Host "$user exists in the group" "$isInGroup"            
      
         } 
        Else #NOT A MEMBER
        {
            $isInGroup = 'false'
            #Write-Host "$user does NOT exists in the group" "$isInGroup"            
        }
    } # fin foreach

    if ($isInGroup -eq 'true')
    {
        RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU
    }#fin if
    else
    {    
    cls
    WRITE-HOST "No Access! " -ForegroundColor Red -NoNewline; WRITE-HOST "You do NOT have admin rights to run this application." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;
    [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = "" ; Protection_Group = "" ; Status = 'Error: Access Denied'; Date = $DT ; Code = $LASTEXITCODE } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
    Start-Sleep -S 10
    EXIT
    }#fin else
} # fin function ValidateUserActiveDirectory #>


function ValidateRemoteAccess($VBRName)
{	
    NET USE \\$VBRName\V$ /USER:$UsernameGlobal $PasswordGlobal
    $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
    CLS      
	# Let's Check exit code
    If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
		{#if            
            $RoboCopyMessage = "EXITCODE: 0, Succeeded" #actualiza para el log2
            Write-Output "Access Audit: $(get-date -format "MM-dd-yyyy HH:mm")" | Out-File -FilePath $Log2 -Append # Write header on report
	        $A = "$DT $RoboCopyMessage $VBRName $UsernameGlobal "; Add-Content "$Log2" $A #updates access file results
            #Disconnects
            Start-Sleep -s 1                                        
            NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects            
		}# end if last exitcode
    else
    {   
        $RoboCopyMessage = "EXITCODE: $LASTEXITCODEGlobal, Access Denied/Error" #actualiza para el log2        
        Write-Output "Access Audit: $(get-date -format "MM-dd-yyyy HH:mm")" | Out-File -FilePath $Log2 -Append # Write header on report
	    $A = "$DT $RoboCopyMessage $VBRName $Username "; Add-Content "$Log2" $A #updates access file results        
        cls
        WRITE-HOST "Access Denied! " -ForegroundColor Red -NoNewline; WRITE-HOST "You do NOT have admin rights to run this application." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;
        $VBRShortname = $VBRNameGlobal.split('.')[0]
        [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = "" ; Status = 'Error: Access Denied'; Date = $DT ; Code = $LASTEXITCODE } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation        
        Start-Sleep -S 10
        EXIT                
    }    
}#cierra funcion

Function ChecksIfFileIsLocked 
{
    [cmdletbinding()]
    Param 
    (
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName','PSPath')]
        [string[]]$Path
    )
    
    Process 
    {
        ForEach ($Item in $Path) 
        {
            #Ensure this is a full path
            $Item = Convert-Path $Item
            #Verify that this is a file and not a directory
            If ([System.IO.File]::Exists($Item)) 
            {
                Try 
                {
                    $FileStream = [System.IO.File]::Open($Item,'Open','Write')
                    $FileStream.Close()
                    $FileStream.Dispose()
                    $IsLocked = $False #file is not locked and new logs can be added
                    $global:IsLocked2 = 'No'
                } 
                Catch [System.UnauthorizedAccessException] 
                {
                    $IsLocked = 'AccessDenied'
                } 
                Catch 
                {
                    $IsLocked = $True #file is locked and cannot be updated
                    $global:IsLocked2 = 'Yes'
                }
                # [pscustomobject]@{ File = $Item ; IsLocked = $IsLocked } #display name and status if locked is true and not locked is false
            }
        }
    }
}

function LogsSecondaryCopy
{
    Copy-Item $CompleteLogAuditCSVPathFile -Destination $CompleteLogSecondaryFolderLocation -Recurse #copy the log output from the barjat to -Destination fm1svmon100
}

function RemoveLocalFilesWindowsAMR
{        
        New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull               #creates a new file to clear the contents form servers list locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.txt -Recurse              #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv -Recurse              #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP03.csv -Recurse              #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP05.csv -Recurse              #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\MergedFile.txt -Recurse                  #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Recurse                 #removes it locally       
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Recurse               #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt -Recurse                 #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv -Recurse                #removes it locally
        Remove-Item $global:LogResultsRobocopy -Recurse                                                          #removes it locally
        Remove-Item $global:Log2 -Recurse                                                                        #removes it locally
}

function RemoveLocalFilesWindowsED
{        
        New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull               #creates a new file to clear the contents form servers list locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP02-ED.txt -Recurse           #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP02-ED.csv -Recurse           #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP04-ED.csv -Recurse           #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP06-ED.csv -Recurse           #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\MergedFile.txt -Recurse                  #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Recurse                 #removes it locally       
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Recurse               #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt -Recurse                 #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv -Recurse                #removes it locally
        Remove-Item $global:LogResultsRobocopy -Recurse                                                          #removes it locally
        Remove-Item $global:Log2 -Recurse                                                                        #removes it locally
}



function RemoveLocalFilesWindowsNonProd
{        
        New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull               #creates a new file to clear the contents form servers list locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP03-NonProd.txt -Recurse           #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP03-NonProd.csv -Recurse           #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\MergedFile.txt -Recurse                  #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Recurse                 #removes it locally       
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Recurse               #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt -Recurse                 #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv -Recurse                #removes it locally
        Remove-Item $global:LogResultsRobocopy -Recurse                                                          #removes it locally
        Remove-Item $global:Log2 -Recurse                                                                        #removes it locally
}


function RemoveLocalFilesWindowsEDNonProd
{        
        New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull               #creates a new file to clear the contents form servers list locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP04-NonProd-ED.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP04-NonProd-ED.csv -Recurse                #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\MergedFile.txt -Recurse                  #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Recurse                 #removes it locally       
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Recurse               #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt -Recurse                 #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv -Recurse                #removes it locally
        Remove-Item $global:LogResultsRobocopy -Recurse                                                          #removes it locally
        Remove-Item $global:Log2 -Recurse                                                                        #removes it locally
}


function RemoveLocalFilesLinuxAMR
{        
        New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull               #creates a new file to clear the contents form servers list locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv -Recurse                #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\MergedFile.txt -Recurse                  #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Recurse                 #removes it locally       
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Recurse               #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt -Recurse                 #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv -Recurse                #removes it locally
        Remove-Item $global:LogResultsRobocopy -Recurse                                                          #removes it locally
        Remove-Item $global:Log2 -Recurse                                                                        #removes it locally
}

function RemoveLocalFilesLinuxED
{        
        New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull               #creates a new file to clear the contents form servers list locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP02-ED.txt -Recurse           #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP02-ED.csv -Recurse           #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\MergedFile.txt -Recurse                  #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Recurse                 #removes it locally       
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Recurse               #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt -Recurse                 #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv -Recurse                #removes it locally
        Remove-Item $global:LogResultsRobocopy -Recurse                                                          #removes it locally
        Remove-Item $global:Log2 -Recurse                                                                        #removes it locally
}


function RemoveLocalFilesLinuxAMRNonProd
{        
        New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull               #creates a new file to clear the contents form servers list locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP03-NonProd.txt -Recurse           #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP03-NonProd.csv -Recurse           #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\MergedFile.txt -Recurse                  #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Recurse                 #removes it locally       
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Recurse               #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt -Recurse                 #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv -Recurse                #removes it locally
        Remove-Item $global:LogResultsRobocopy -Recurse                                                          #removes it locally
        Remove-Item $global:Log2 -Recurse                                                                        #removes it locally
}


function RemoveLocalFilesLinuxEDNonProd
{        
        New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull               #creates a new file to clear the contents form servers list locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Logs\LogNull.txt -Recurse                #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP04-NonProd-ED.txt -Recurse           #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP04-NonProd-ED.csv -Recurse           #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\MergedFile.txt -Recurse                  #removes it locally
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Recurse                 #removes it locally       
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Recurse               #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt -Recurse                 #removes it locally        
        Remove-Item e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv -Recurse                #removes it locally
        Remove-Item $global:LogResultsRobocopy -Recurse                                                          #removes it locally
        Remove-Item $global:Log2 -Recurse                                                                        #removes it locally
}


function UpdateCSVJobs($TypeAMRED)
{	
    
    If ( ((Get-ChildItem -Force ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull)) -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull)))) ) #checks the folder is not empty and that the file is not empty
    {
            cls
            WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
            PAUSE    
    } #fin if

     else # "The File is NOT empty"
    {

    
                    # parameters and variables#
                    ####################################################################################################################   
                    $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                    $ServersList = $ServersList.Trim().ToLower() | Sort-Object -Unique #trim leading and trailing spaces, lowers, sorts and removes duplicates
                    $ServersFile = "servers.txt"
                    $SourceFolderServersFile = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List"
                    $SourcePathServersFile = $SourceFolderServersFile + "\" + $ServersFile # Source Path    	
            
                    $SourceFileLocationVBR = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    
                    $VBRDestination = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    

       
                    $DestinationLocalPC = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # sets the varible for the file location
    
                    $SourceFolder = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # Source Folder
    
                    $MergedFile = "MergedFile.txt" # Source File  
                    $SourcePathMergedFile = $SourceFolder + "\" + $MergedFile # Source folder Path for Merged File  
    
                    $WindowsPRGP01 = "Windows-PRGP01.csv" # Source File
                    $SourcePathWindowsPRGP01 = $SourceFolder + "\" + $WindowsPRGP01 # Source Path

                    $WindowsPRGP01TXT = "Windows-PRGP01.txt" # Source File
                    $SourcePathWindowsPRGP01TXT = $SourceFolder + "\" + $WindowsPRGP01TXT # Source Path

                    $WindowsPRGP03 = "Windows-PRGP03.csv" # Source File
                    $SourcePathWindowsPRGP03 = $SourceFolder + "\" + $WindowsPRGP03 # Source Path

                    $WindowsPRGP03TXT = "Windows-PRGP03.txt" # Source File
                    $SourcePathWindowsPRGP03TXT = $SourceFolder + "\" + $WindowsPRGP03TXT # Source Path

                    $WindowsPRGP05 = "Windows-PRGP05.csv" # Source File
                    $SourcePathWindowsPRGP05 = $SourceFolder + "\" + $WindowsPRGP05 # Source Path

                    $WindowsPRGP05TXT = "Windows-PRGP05.txt" # Source File
                    $SourcePathWindowsPRGP05TXT = $SourceFolder + "\" + $WindowsPRGP05TXT # Source Path
    
                    $SortedUniqueFile = "SortedUniqueFile.txt" # Source File  
                    $SourcePathSortedUnique = $SourceFolder + "\" + $SortedUniqueFile # Source folder Path for sorted and unique text
    
                    ######ED###############################################################################################################
                    $WindowsPRGP02ED = "Windows-PRGP02-ED.csv" # Source File
                    $SourcePathWindowsPRGP02ED = $SourceFolder + "\" + $WindowsPRGP02ED # Source Path    
                    $WindowsPRGP02EDTXT = "Windows-PRGP02-ED.txt" # Source File
                    $SourcePathWindowsPRGP02EDTXT = $SourceFolder + "\" + $WindowsPRGP02EDTXT # Source Path


                    $WindowsPRGP04ED = "Windows-PRGP04-ED.csv" # Source File
                    $SourcePathWindowsPRGP04ED = $SourceFolder + "\" + $WindowsPRGP04ED # Source Path    
                    $WindowsPRGP04EDTXT = "Windows-PRGP04-ED.txt" # Source File
                    $SourcePathWindowsPRGP04EDTXT = $SourceFolder + "\" + $WindowsPRGP04EDTXT # Source Path


                    $WindowsPRGP06ED = "Windows-PRGP06-ED.csv" # Source File
                    $SourcePathWindowsPRGP06ED = $SourceFolder + "\" + $WindowsPRGP06ED # Source Path    
                    $WindowsPRGP06EDTXT = "Windows-PRGP06-ED.txt" # Source File
                    $SourcePathWindowsPRGP06EDTXT = $SourceFolder + "\" + $WindowsPRGP06EDTXT # Source Path
    
       
                    ####################################################################################################################
                    if ($ProdorNon -eq "HFNonProd") # si es si es HF NoN prod
                    {
                            cls
                            #write-host ("es HF2 Non Prod")
                            #PAUSE
                    } #fin del if condicion $OptionMenuEnroll = 6
                    else # si no es 6 entonces todas las demas son produccion
                    {
                
                                    if ($TypeAMRED -eq "AMR")
                                    {
                                                    NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal
                                                    $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
                                                    cls                           
	                                                # Let's Check exit code
                                                    If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
		                                            {#if
			
                                                                    #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
                                                                    Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$WindowsPRGP01" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                                                    $ServerCount1 = (@(Get-Content $DestinationLocalPC\$WindowsPRGP01).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv).Length)
                        
                                                                    Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$WindowsPRGP03" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                                                    $ServerCount3 = (@(Get-Content $DestinationLocalPC\$WindowsPRGP03).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv).Length)

                                                                    Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$WindowsPRGP05" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                                                    $ServerCount5 = (@(Get-Content $DestinationLocalPC\$WindowsPRGP05).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv).Length)
                        
                                                                    if ($ServerCount1 -le 500) #PRGP01
                                                                    {
                                                                                    Rename-Item $SourcePathWindowsPRGP01 $SourcePathWindowsPRGP01TXT #converts csv to txt file to remove format                                  
                                                                                    $ServersTxtFile = Get-Content $SourcePathServersFile #get contents of new servers to add                                    
                                                                                    $ConvertedCsvToTxtFile = Get-Content $SourcePathWindowsPRGP01TXT #get contents of servers currently being backed up that was converted from csv to txt    
                                                                                    New-Item -ItemType file $SourcePathMergedFile -force > $LogNull #creates a new file to combine merged info from $ServersTxtFile and  $ConvertedCsvToTxtFile
                                                                                    cls
                                                                                    ####Combine Merge Files############################################################################################################3
                                                                                    Add-Content $SourcePathMergedFile $ConvertedCsvToTxtFile #txt list of being backed up servers
                                                                                    Add-Content $SourcePathMergedFile $ServersTxtFile #txt list of new servers to add
                                                                                ######################################################################################################################################3
                                    
                                                                                ############## $trim() is a method Remove spaces from the beginning and end of the string##############################
                                    
                                                                                ForEach ($Name in gc $SourcePathMergedFile)
                                                                                {#for
                                                                                            $Name.trim() >> 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt'
                                                                                }
                                                                                 ################################################################################################################################################

                                                                                ############Change text contents to Lower Case########################################################################################################################
                                                                                (Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Raw).ToLower() | Out-File e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Force
                                        
                                                                                ##############################################################################################################################################################

                                                                                #############Find lines with text while ignoring blank lines. Remove the blank lines from the text################################################
                                                                                #gc e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt | where {$_ -ne ""} > e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\new.txt

                                                                                Select-String -Pattern "\w" -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt  | ForEach-Object { $_.line } | Set-Content -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt
                                    
                                                                                ######################################################################################################################################

                                                                                #############Strip Empty Lines End of File#######################################################################################################################
                                                                                $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' #This will only strip the empty lines from the end of the file
                                                                                $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                                                                [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                                                                #######################################################################################################################################################
                                                                        
                                                                                ##############Sort and Remove Duplicates ########################################################################################################################
                                                                                $SortedFile = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' | Sort-Object -Unique #sorts the new txt file and remove duplicates combined txts
                                                                                New-Item -ItemType file $SourcePathSortedUnique -force > $LogNull #creates new file to add the sorted data
                                                                                Add-Content $SourcePathSortedUnique $SortedFile #agrega la info ordenada y sin duplicates al archivo que fue recreado para esto
                                                                                ###########################################################################################################################################################
                                                                         
                                                                                New-Item -ItemType file $SourcePathWindowsPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT
                                                                                $CSVCleanFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                                                                $ConvertSortedUniqueFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt'
                                                                                Rename-Item $ConvertSortedUniqueFile $CSVCleanFile #converts from txt to csv file


                                                                                ################# Removes Lines and Empty##########################################################################################################
                                                                                $sourceFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                                                                $destPath = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'

                                                                                foreach($line in [System.IO.File]::ReadLines($sourceFile))
                                                                                {
                                                                                            if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                                                                            {
                                                                                                    $line >> $destPath
                                                                                            }
                                                                                 }#end foreach
                                                                                ######################################################################################################################################################
                                    
                                                                                New-Item -ItemType file $SourcePathWindowsPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT                                    
                                                                                $RenameCSVCleanNoLinesFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'
                                                                                $RenameWindowsPRGP01TxTtoCSV = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv'

                                                                                Rename-Item $RenameCSVCleanNoLinesFile $RenameWindowsPRGP01TxTtoCSV #assigns the final name to csv file to get it ready to copy back to vbr

                                                                                #########################Strip Empty Lines End of File#######################################################################################################################
                                                                                $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv' #This will only strip the empty lines from the end of the file
                                                                                $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                                                                [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                                                                #######################################################################################################################################################
                                                                                $PathVBRFileCSV = 'v$\Inventory\Physical-Clients-CSV\Windows-PRGP01.csv'
                                                                                $PathVBRFileCSVOld = 'v$\Inventory\Physical-Clients-CSV\Windows-PRGP01.csv.old'
                                                                                Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV \\$VBRNameGlobal\$PathVBRFileCSVOld  #renames csv file on vbr to old before copying the new one                                    
                                                                                robocopy.exe $SourceFolder \\$VBRNameGlobal\$VBRDestination\ $WindowsPRGP01 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr
                                                                                cls
                                                                                ################rescans protection group#################################################################################################################
                                                            
                                                                                $PathVBRRToCopFilePS1 = 'V$\Inventory\Physical-Clients-CSV'
                                                                                $FileRescanWindowsPRGP01PS1 = 'ReScanWindowsPRGP01.ps1'
                                                                                $FullPathRescanFilePS1 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ReScanProtectionGroups\'
                                                                                $FullPathRescanFilePS1VBR = 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1'  
                                                                        
                                                                                robocopy.exe $FullPathRescanFilePS1 \\$VBRNameGlobal\$PathVBRRToCopFilePS1\ $FileRescanWindowsPRGP01PS1 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr                                                                                                           
                                                                                cls
                                                                                $filelocationname = 'powershell.exe /c V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1'
                                                                                $global:WMIResult = ([WMICLASS]"\\$VBRNameGlobal\ROOT\CIMV2:win32_process").Create($filelocationname) #ejecuta el ReScanWindowsPRGP01 para actualizar los grupos con el rescan
                                                                                $WMIResult.ReturnValue > $LogNull;

                                                                                #e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\.\PsExec64.exe \\$VBRNameGlobal -u UsernameGlobal -p $PasswordGlobal /accepteula -h /s cmd /c powershell.exe -ExecutionPolicy Bypass -file 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1' 2> $LogNull este lo pongo en comentarions porque vy a usar wmiclass
                                                                                cls
                                                                        ################END rescans protection group#####################################################################################################################################################################################################################################

                                                                                if ($WMIResult.ReturnValue -eq 0) #revisar el resultado de $WMIResult.ReturnValue si es cero todo perfecto
                                                                                {                                                                                
                                                                                                cls
                                                                                                WRITE-HOST $WMIResult.ReturnValue "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " The server(s) Enrolled - listed below." -ForegroundColor White;                                                                                                                                                                                                                        
                                                                                                $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                                                                $ServersList.Trim().ToLower() | Format-List -Property *                                                                        
                                                                                                Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP01.csv.old -Recurse #removes it form the VBR server                                                                                                
                                                                                                
                                                                                                $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                                                                $VBRShortname = $VBRNameGlobal.split('.')[0]                                                                                                
                                                                                                
                                                                                                ChecksIfFileIsLocked $CompleteLogAuditCSVPathFile
                                                                                                if ($Islocked2 -eq 'No') #no está abierto ni lockeado entonces SI se puede escribir
                                                                                                {
                                                                                                    foreach ($Servername in $ServersList)
                                                                                                    {                                                                                
                                                                                                        [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP01' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                                                                    } #fin foreach to update logs

                                                                                                    LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                                                                                } #fin if (global:Islocked2 -eq 'No' #no está abierto ni lockeado entonces SI se puede escribir
                                                                                                else
                                                                                                {
                                                                                                } # fin else de que IsLocked2 = Yes osea no se puede escribir                                                                                                
                                                                                                
                                                                                                #Disconnects
                                                                                                Start-Sleep -s 1                                        
                                                                                                NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                                        
                                                                                                RemoveLocalFilesWindowsAMR #removes all the local files temporarily used                                                                                                
                                                                                                PAUSE
                                                                                                EXIT                                        
                                                                                } #fin if ($WMIResult.ReturnValue -eq 0) osea si corrieo el rescan bien
                                                                                else
                                                                                {
                                                                                                Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP01.csv.old -Recurse #removes it form the VBR server
                                                                                                Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1 -Recurse #removes it form the VBR server                                                                                                                                        
                                                                                                #Disconnects
                                                                                                Start-Sleep -s 1                                        
                                                                                                NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects
                                                                                                RemoveLocalFilesWindowsAMR #removes all the local files temporarily used
                                                                                                cls
                                                                                                WRITE-HOST $WMIResult.ReturnValue "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "There is an issue." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;
                                                                                                Start-Sleep -S 10
                                                                                                EXIT
                                                                                } # el $WMIResult.ReturnValue no fue igual a 0 hubo algun error

                                                            ####################################################################################################################################################################################################################################
                                    
                        }# fin if if ($ServerCount1 -le 500) #PRGP01
                        elseif($ServerCount3 -le 500) #Windows-PRGP03'
                        {
                           $VBRShortname = $VBRNameGlobal.split('.')[0]
                           [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP03' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                                                                                                        
                        }# fin else if
                        elseif($ServerCount5 -le 500) #Windows-PRGP05'
                        {

                          $VBRShortname = $VBRNameGlobal.split('.')[0]
                          [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP05' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                                                                                                                                 

                        }# fin else if
                        else
                        {
                            cls
                            WRITE-HOST "Backup Job Full! " -ForegroundColor Red -NoNewline; WRITE-HOST "It has reached the maximum number of servers inside a group" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                            
                            $VBRShortname = $VBRNameGlobal.split('.')[0]
                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP01' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP03' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP05' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                            LogsSecondaryCopy #copies a secondary version of the logs to a different location
                            Start-Sleep -S 10
                            EXIT
                            #remove1
                            #remove2
                            #remove3

                        } #fin else           
                        
		            }# end if last exitcode
                    else
                    {   
                      cls
                      WRITE-HOST "Application didn't run. This session will close in 10 seconds" -ForegroundColor Red
                      Start-Sleep -S 10
                      EXIT                     
                    }  #end else LASTEXITCODE AMR 
    
    }#end if TypeAMRED AMR
    elseif ($TypeAMRED -eq "ED")
   {


                                        NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal
                                        $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
                                        cls                           
	                                    # Let's Check exit code
                                        If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
		                                {#if
			
                                                #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
                                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$WindowsPRGP02ED" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                                $ServerCount1 = (@(Get-Content $DestinationLocalPC\$WindowsPRGP02ED).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv).Length)
                        
                                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$WindowsPRGP04ED" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                                $ServerCount3 = (@(Get-Content $DestinationLocalPC\$WindowsPRGP04ED).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv).Length)

                                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$WindowsPRGP06ED" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                                $ServerCount5 = (@(Get-Content $DestinationLocalPC\$WindowsPRGP06ED).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP01.csv).Length)
                        
                                                if ($ServerCount1 -le 500)
                                                {
                                                            Rename-Item $SourcePathWindowsPRGP02ED $SourcePathWindowsPRGP02EDTXT #converts csv to txt file to remove format                                  
                                                            $ServersTxtFile = Get-Content $SourcePathServersFile #get contents of new servers to add                                    
                                                            $ConvertedCsvToTxtFile = Get-Content $SourcePathWindowsPRGP02EDTXT #get contents of servers currently being backed up that was converted from csv to txt    
                                                            New-Item -ItemType file $SourcePathMergedFile -force > $LogNull #creates a new file to combine merged info from $ServersTxtFile and  $ConvertedCsvToTxtFile
                                                            cls
                                                            ####Combine Merge Files############################################################################################################3
                                                            Add-Content $SourcePathMergedFile $ConvertedCsvToTxtFile #txt list of being backed up servers
                                                            Add-Content $SourcePathMergedFile $ServersTxtFile #txt list of new servers to add
                                                            ######################################################################################################################################3
                                    
                                                            ############## $trim() is a method Remove spaces from the beginning and end of the string##############################
                                    
                                                            ForEach ($Name in gc $SourcePathMergedFile)
                                                            {#for
                                                                        $Name.trim() >> 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt'
                                                            }
                                                            ################################################################################################################################################

                                                            ############Change text contents to Lower Case########################################################################################################################
                                                            (Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Raw).ToLower() | Out-File e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Force
                                        
                                                            ##############################################################################################################################################################

                                                            #############Find lines with text while ignoring blank lines. Remove the blank lines from the text################################################
                                                            #gc e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt | where {$_ -ne ""} > e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\new.txt

                                                            Select-String -Pattern "\w" -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt  | ForEach-Object { $_.line } | Set-Content -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt
                                    
                                                            ######################################################################################################################################

                                                            #############Strip Empty Lines End of File#######################################################################################################################
                                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' #This will only strip the empty lines from the end of the file
                                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                                            #######################################################################################################################################################
                                                                        
                                                            ##############Sort and Remove Duplicates ########################################################################################################################
                                                            $SortedFile = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' | Sort-Object -Unique #sorts the new txt file and remove duplicates combined txts
                                                            New-Item -ItemType file $SourcePathSortedUnique -force > $LogNull #creates new file to add the sorted data
                                                            Add-Content $SourcePathSortedUnique $SortedFile #agrega la info ordenada y sin duplicates al archivo que fue recreado para esto
                                                            ###########################################################################################################################################################
                                                                         
                                                            New-Item -ItemType file $SourcePathWindowsPRGP02EDTXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT
                                                            $CSVCleanFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                                            $ConvertSortedUniqueFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt'
                                                            Rename-Item $ConvertSortedUniqueFile $CSVCleanFile #converts from txt to csv file


                                                            ################# Removes Lines and Empty##########################################################################################################
                                                            $sourceFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                                            $destPath = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'

                                                            foreach($line in [System.IO.File]::ReadLines($sourceFile))
                                                            {
                                                                        if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                                                        {
                                                                                $line >> $destPath
                                                                        }
                                                            }#end foreach
                                                            ######################################################################################################################################################
                                    
                                                            New-Item -ItemType file $SourcePathWindowsPRGP02EDTXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT                                    
                                                            $RenameCSVCleanNoLinesFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'
                                                            $RenameWindowsPRGP02EDTxTtoCSV = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP02-ED.csv'

                                                            Rename-Item $RenameCSVCleanNoLinesFile $RenameWindowsPRGP02EDTxTtoCSV #assigns the final name to csv file to get it ready to copy back to vbr

                                                            #########################Strip Empty Lines End of File#######################################################################################################################
                                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP02-ED.csv' #This will only strip the empty lines from the end of the file
                                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                                            #######################################################################################################################################################
                                                            $PathVBRFileCSV = 'v$\Inventory\Physical-Clients-CSV\Windows-PRGP02-ED.csv'
                                                            $PathVBRFileCSVOld = 'v$\Inventory\Physical-Clients-CSV\Windows-PRGP02-ED.csv.old'
                                                            Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV \\$VBRNameGlobal\$PathVBRFileCSVOld  #renames csv file on vbr to old before copying the new one                                    
                                                            robocopy.exe $SourceFolder \\$VBRNameGlobal\$VBRDestination\ $WindowsPRGP02ED /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr
                                                            cls

                                                            ################rescans protection group#################################################################################################################
                                                            $PathVBRRToCopFilePS1 = 'V$\Inventory\Physical-Clients-CSV'
                                                            $FileRescanWindowsPRGP02EDPS1 = 'ReScanWindowsPRGP02ED.ps1'
                                                            $FullPathRescanFilePS1 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ReScanProtectionGroups\'
                                                            $FullPathRescanFilePS1VBR = 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP02ED.ps1'  
                                                                        
                                                            robocopy.exe $FullPathRescanFilePS1 \\$VBRNameGlobal\$PathVBRRToCopFilePS1\ $FileRescanWindowsPRGP02EDPS1 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr                                                                                                           
                                                            cls
                                                            $filelocationnameED = 'powershell.exe /c V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP02ED.ps1'
                                                            $global:WMIResult = ([WMICLASS]"\\$VBRNameGlobal\ROOT\CIMV2:win32_process").Create($filelocationnameED) #ejecuta el ReScanWindowsPRGP02ED para actualizar los grupos con el rescan
                                                            $WMIResult.ReturnValue > $LogNull;
                                                            #e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\.\PsExec64.exe \\$VBRNameGlobal -u UsernameGlobal -p $PasswordGlobal /accepteula -h /s cmd /c powershell.exe -ExecutionPolicy Bypass -file 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP02ED.ps1' 2> $LogNull #Not being used using WMIResult instead
                                                            cls
                                                            ################END rescans protection group#####################################################################################################################################################################################################################################

                                                            if ($WMIResult.ReturnValue -eq 0) #revisar el resultado de $WMIResult.ReturnValue si es cero todo perfecto
                                                            {                                                                                
                                                                        cls                                                                                                                                                                                                                
                                                                        WRITE-HOST $WMIResult.ReturnValue "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " The server(s) Enrolled - listed below." -ForegroundColor White;
                                                                        #$ServersList.Trim().ToLower() | Format-List -Property *                                                                        
                                                                        echo $ServersList.Trim().ToLower() | sort -unique  #despliega la lista de servers que fueron agregados
                                                                        
                                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP02-ED.csv.old -Recurse #removes it form the VBR server                                                                        

                                                                        $VBRShortname = $VBRNameGlobal.split('.')[0]
                                                                        foreach ($Servername in $ServersList)
                                                                        {                                                                                
                                                                                [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP02-ED' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                                                
                                                                        } #fin foreach to update logs                                            
                                                                                                                                                
                                                                        #Disconnects
                                                                        Start-Sleep -s 1                                        
                                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                                                                                                                                                                                       
                                                                        RemoveLocalFilesWindowsED #removes all the local files temporarily used
                                                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                                                        PAUSE
                                                                        EXIT                                        
                                                            } #fin if ($WMIResult.ReturnValue -eq 0) osea si corrieo el rescan bien
                                                            else
                                                            {                                                                        
                                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP02-ED.csv.old -Recurse #removes it form the VBR server
                                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP02ED.ps1 -Recurse #removes it form the VBR server
                                                                        
                                                                        #Disconnects
                                                                        Start-Sleep -s 1                                        
                                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects
                                                                        RemoveLocalFilesWindowsED #removes all the local files temporarily used
                                                                        cls                                                                        
                                                                        WRITE-HOST $WMIResult.ReturnValue "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "There is an issue." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;
                                                                        Start-Sleep -S 10
                                                                        EXIT
                                                            } #fin del else

                                                            ########################################################################################################################################################################################################
                                    
                        }# fin if
                        elseif($ServerCount3 -le 500) #PRG04-ED
                        {
                            $VBRShortname = $VBRNameGlobal.split('.')[0]
                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP04-ED' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                   
                        }# fin else if
                        elseif($ServerCount5 -le 500) #PRG06-ED
                        {

                            $VBRShortname = $VBRNameGlobal.split('.')[0]
                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP06-ED' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation

                        }# fin else if
                        else
                        {
                            cls
                            WRITE-HOST "Backup Job Full! " -ForegroundColor Red -NoNewline; WRITE-HOST "It has reached the maximum number of servers inside a group" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;
                            $VBRShortname = $VBRNameGlobal.split('.')[0]
                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP02-ED' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP04-ED' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP06-ED' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                            
                            
                            RemoveLocalFilesWindowsED #removes all the local files temporarily used                            
                            #Disconnects
                            Start-Sleep -s 1                                        
                            NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects
                            LogsSecondaryCopy #copies a secondary version of the logs to a different location
                            Start-Sleep -S 10
                            EXIT
                            #remove1
                            #remove2
                            #remove3
                        } #fin else
                                            
                        
		            }# end if last exitcode
                    else
                    {   
                      cls
                      WRITE-HOST "Application didn't Run: This session will close in 10 seconds" -ForegroundColor Red
                      Start-Sleep -S 10
                      EXIT                   
                    }  #end else LASTEXITCODE ED

   }#end else if TypeAMRED ED
    } # fin del else condicion $OptionMenuEnroll
 } #fin else file not empty          
}#cierra funcion UpdateCSVJobs


########################################################################################################################################################################################################################################################################################################################################################################################################################################
########################################################################################################################################################################################################################################################################################################################################################################################################################################
####Functions NOn Prod Backup Jobs naming convention##############################

function AddWindowsPhysicalAMRNonprod ($VBRName)
{

    If ( ((Get-ChildItem -Force 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List') -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt'.Trim().ToLower()))) ) #checks the folder is not empty and that the file is not empty
    {
            cls
            WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
            PAUSE    
    } #fin if

     else # "The File is NOT empty"
    {

    
                    # parameters and variables#
                    ########################################################################################################################################################################################################################################   
                    $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                    $ServersList = $ServersList.Trim().ToLower() | Sort-Object -Unique #trim leading and trailing spaces, lowers, sorts and removes duplicates
                    $ServersFile = "servers.txt"
                    $SourceFolderServersFile = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List"
                    $SourcePathServersFile = $SourceFolderServersFile + "\" + $ServersFile # Source Path    	
            
                    $SourceFileLocationVBR = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    
                    $VBRDestination = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    

       
                    $DestinationLocalPC = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # sets the varible for the file location
    
                    $SourceFolder = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # Source Folder
    
                    $MergedFile = "MergedFile.txt" # Source File  
                    $SourcePathMergedFile = $SourceFolder + "\" + $MergedFile # Source folder Path for Merged File  
    
                    $LinuxPRGP01 = "Windows-PRGP03-NonProd.csv" # Source File
                    $SourcePathLinuxPRGP01 = $SourceFolder + "\" + $LinuxPRGP01 # Source Path

                    $LinuxPRGP01TXT = "Windows-PRGP03-NonProd.txt" # Source File
                    $SourcePathLinuxPRGP01TXT = $SourceFolder + "\" + $LinuxPRGP01TXT # Source Path

                    $SortedUniqueFile = "SortedUniqueFile.txt" # Source File  
                    $SourcePathSortedUnique = $SourceFolder + "\" + $SortedUniqueFile # Source folder Path for sorted and unique text
                    ########################################################################################################################################################################################################################################
                    NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal
                    $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
                    cls                           
                    # Let's Check exit code
                    If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    {#if			
                                #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$LinuxPRGP01" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                $ServerCount1 = (@(Get-Content $DestinationLocalPC\$LinuxPRGP01).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv).Length)

                                if ($ServerCount1 -le 500) #PRGP01 es menor y si entra
                                {
                                    
                                            Rename-Item $SourcePathLinuxPRGP01 $SourcePathLinuxPRGP01TXT #converts csv to txt file to remove format                                  
                                            $ServersTxtFile = Get-Content $SourcePathServersFile #get contents of new servers to add                                    
                                            $ConvertedCsvToTxtFile = Get-Content $SourcePathLinuxPRGP01TXT #get contents of servers currently being backed up that was converted from csv to txt    
                                            New-Item -ItemType file $SourcePathMergedFile -force > $LogNull #creates a new file to combine merged info from $ServersTxtFile and  $ConvertedCsvToTxtFile
                                            cls
                                            ####Combine Merge Files########################################################################################################################################################################################################################################################
                                            Add-Content $SourcePathMergedFile $ConvertedCsvToTxtFile #txt list of being backed up servers
                                            Add-Content $SourcePathMergedFile $ServersTxtFile #txt list of new servers to add
                                            ################################################################################################################################################################################################################################################################################
                                    
                                            ############## $trim() is a method Remove spaces from the beginning and end of the string#######################################################################################################################################################################################
                                    
                                            ForEach ($Name in gc $SourcePathMergedFile)
                                            {#for
                                                        $Name.trim() >> 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt'
                                            } #fin Foreach ($Name in gc $SourcePathMergedFile)
                                            ################################################################################################################################################################################################################################################################################################

                                            ############Change text contents to Lower Case###################################################################################################################################################################################################################################################
                                            (Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Raw).ToLower() | Out-File e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Force                                        
                                            ################################################################################################################################################################################################################################################################################################

                                            #############Find lines with text while ignoring blank lines. Remove the blank lines from the text################################################
                                            #gc e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt | where {$_ -ne ""} > e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\new.txt
                                            Select-String -Pattern "\w" -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt  | ForEach-Object { $_.line } | Set-Content -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt                                    
                                            ###############################################################################################################################################################################################################################################################################################

                                            #############Strip Empty Lines End of File#######################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            ####################################################################################################################################################################################################################################
                                                                        
                                            ##############Sort and Remove Duplicates ###########################################################################################################################################################################################
                                            $SortedFile = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' | Sort-Object -Unique #sorts the new txt file and remove duplicates combined txts
                                            New-Item -ItemType file $SourcePathSortedUnique -force > $LogNull #creates new file to add the sorted data
                                            Add-Content $SourcePathSortedUnique $SortedFile #agrega la info ordenada y sin duplicates al archivo que fue recreado para esto
                                            ###################################################################################################################################################################################################################################
                                                                         
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT
                                            $CSVCleanFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $ConvertSortedUniqueFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt'
                                            Rename-Item $ConvertSortedUniqueFile $CSVCleanFile #converts from txt to csv file

                                            ################# Removes Lines and Empty##########################################################################################################################################################################################
                                            $sourceFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $destPath = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'

                                            foreach($line in [System.IO.File]::ReadLines($sourceFile))
                                            {
                                                        if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                                        {
                                                                    $line >> $destPath
                                                        } #fin if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                            }#end foreach ($line in [System.IO.File]::ReadLines($sourceFile))
                                            ########################################################################################################################################################################################################################################################################################################
                                    
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT                                    
                                            $RenameCSVCleanNoLinesFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'
                                            $RenameLinuxPRGP01TxTtoCSV = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP03-NonProd.csv'
                                            Rename-Item $RenameCSVCleanNoLinesFile $RenameLinuxPRGP01TxTtoCSV #assigns the final name to csv file to get it ready to copy back to vbr

                                            #########################Strip Empty Lines End of File##########################################################################################################################################################################################################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP03-NonProd.csv' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            #################################################################################################################################################################################################
                                            $PathVBRFileCSV = 'v$\Inventory\Physical-Clients-CSV\Windows-PRGP03-NonProd.csv'
                                            $PathVBRFileCSVOld = 'v$\Inventory\Physical-Clients-CSV\Windows-PRGP03-NonProd.csv.old'
                                            Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV \\$VBRNameGlobal\$PathVBRFileCSVOld  #renames csv file on vbr to old before copying the new one                                    
                                            robocopy.exe $SourceFolder \\$VBRNameGlobal\$VBRDestination\ $LinuxPRGP01 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr
                                            cls
                                            ################rescans protection group#####################################################################################################################################################################################################################################################################################################################
                                                            
                                            $PathVBRRToCopFilePS1 = 'V$\Inventory\Physical-Clients-CSV'
                                            $FileRescanLinuxPRGP01PS1 = 'ReScanWindowsPRGP03NonProd.ps1'
                                            $FullPathRescanFilePS1 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ReScanProtectionGroups\'
                                            $FullPathRescanFilePS1VBR = 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP03NonProd.ps1'  
                                                                        
                                            robocopy.exe $FullPathRescanFilePS1 \\$VBRNameGlobal\$PathVBRRToCopFilePS1\ $FileRescanLinuxPRGP01PS1 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr                                                                                                           
                                            cls
                                            $filelocationname = 'powershell.exe /c V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP03NonProd.ps1'
                                            $global:WMIResult = ([WMICLASS]"\\$VBRNameGlobal\ROOT\CIMV2:win32_process").Create($filelocationname) #ejecuta el ReScanWindowsPRGP01 para actualizar los grupos con el rescan
                                            #e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\.\PsExec64.exe \\$VBRNameGlobal -u UsernameGlobal -p $PasswordGlobal /accepteula -h /s cmd /c powershell.exe -ExecutionPolicy Bypass -file 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1' 2> $LogNull este lo pongo en comentarions porque vy a usar wmiclass
                                            cls
                                            ################END rescans protection group###########################################################################################################################################################################################################################################################################################################################################################################################################################################################################

                                            if ($WMIResult.ReturnValue -eq 0) #revisar el resultado de $WMIResult.ReturnValue si es cero todo perfecto
                                            {                                                                                
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " The server(s) Enrolled - listed below." -ForegroundColor White;                                                                                                                                                                                                                        
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $ServersList.Trim().ToLower() | Format-List -Property *                                                                        
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP03-NonProd.csv.old -Recurse #removes it form the VBR server                                                                                                
                                                                                                
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $VBRShortname = $VBRNameGlobal.split('.')[0]                                                                                                
                                                        foreach ($Servername in $ServersList)
                                                        {                                                                                
                                                                    [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP03-NonProd' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                        } #fin foreach to update logs                                                                                                 
                                                                                                
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                                        
                                                        RemoveLocalFilesWindowsNonProd #removes all the local files temporarily used
                                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                                        PAUSE
                                                        EXIT                                        
                                            } #fin if ($WMIResult.ReturnValue -eq 0) osea si corrieo el rescan bien
                                            else
                                            {
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP03-NonProd.csv.old -Recurse #removes it form the VBR server
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP03NonProd.ps1 -Recurse #removes it form the VBR server                                                                                                                                        
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                        
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "There is an issue." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                                                        
                                                        Start-Sleep -S 10
                                                        RemoveLocalFilesWindowsNonProd #removes all the local files temporarily used
                                                        EXIT
                                            } #fin else $WMIResult.ReturnValue no fue igual a 0 hubo algun error

                                            ########################################################################################################################################################################################################################################################

                                } #fin if ($ServerCount1 -le 500) #PRGP01
                                else #csv tiene el maximo de servers
                                {
                                        cls
                                        WRITE-HOST "Backup Job Full! " -ForegroundColor Red -NoNewline; WRITE-HOST "It has reached the maximum number of servers inside a group" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                            
                                        $VBRShortname = $VBRNameGlobal.split('.')[0]
                                        [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP03-NonProd' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                            
                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                        Start-Sleep -S 10
                                        EXIT
                                } #fin else csv tiene maximo de servers                       
                                                                                    
                    } # fin if (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    else
                    {                       
                            cls
                            WRITE-HOST "Application didn't run. This session will close in 10 seconds" -ForegroundColor Red
                            Start-Sleep -S 10
                            EXIT                        
                    } #fin else el net connect dio un error (($LASTEXITCODEGlobal -eq 0)) resultado NO es Cero

    } #fin else # "The File is NOT empty"
} #fin function AddWindowsPhysicalAMRNonprod


function AddWindowsPhysicalEDNonprod ($VBRName)
{

    If ( ((Get-ChildItem -Force 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List') -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt'.Trim().ToLower()))) ) #checks the folder is not empty and that the file is not empty
    {
            cls
            WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
            PAUSE    
    } #fin if

     else # "The File is NOT empty"
    {

    
                    # parameters and variables#
                    ########################################################################################################################################################################################################################################   
                    $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                    $ServersList = $ServersList.Trim().ToLower() | Sort-Object -Unique #trim leading and trailing spaces, lowers, sorts and removes duplicates
                    $ServersFile = "servers.txt"
                    $SourceFolderServersFile = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List"
                    $SourcePathServersFile = $SourceFolderServersFile + "\" + $ServersFile # Source Path    	
            
                    $SourceFileLocationVBR = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    
                    $VBRDestination = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    

       
                    $DestinationLocalPC = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # sets the varible for the file location
    
                    $SourceFolder = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # Source Folder
    
                    $MergedFile = "MergedFile.txt" # Source File  
                    $SourcePathMergedFile = $SourceFolder + "\" + $MergedFile # Source folder Path for Merged File  
    
                    $LinuxPRGP01 = "Windows-PRGP04-NonProd-ED.csv" # Source File
                    $SourcePathLinuxPRGP01 = $SourceFolder + "\" + $LinuxPRGP01 # Source Path

                    $LinuxPRGP01TXT = "Windows-PRGP04-NonProd-ED.txt" # Source File
                    $SourcePathLinuxPRGP01TXT = $SourceFolder + "\" + $LinuxPRGP01TXT # Source Path

                    $SortedUniqueFile = "SortedUniqueFile.txt" # Source File  
                    $SourcePathSortedUnique = $SourceFolder + "\" + $SortedUniqueFile # Source folder Path for sorted and unique text
                    ########################################################################################################################################################################################################################################
                    NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal
                    $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
                    cls                           
                    # Let's Check exit code
                    If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    {#if			
                                #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$LinuxPRGP01" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                $ServerCount1 = (@(Get-Content $DestinationLocalPC\$LinuxPRGP01).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv).Length)

                                if ($ServerCount1 -le 500) #PRGP01 es menor y si entra
                                {
                                    
                                            Rename-Item $SourcePathLinuxPRGP01 $SourcePathLinuxPRGP01TXT #converts csv to txt file to remove format                                  
                                            $ServersTxtFile = Get-Content $SourcePathServersFile #get contents of new servers to add                                    
                                            $ConvertedCsvToTxtFile = Get-Content $SourcePathLinuxPRGP01TXT #get contents of servers currently being backed up that was converted from csv to txt    
                                            New-Item -ItemType file $SourcePathMergedFile -force > $LogNull #creates a new file to combine merged info from $ServersTxtFile and  $ConvertedCsvToTxtFile
                                            cls
                                            ####Combine Merge Files########################################################################################################################################################################################################################################################
                                            Add-Content $SourcePathMergedFile $ConvertedCsvToTxtFile #txt list of being backed up servers
                                            Add-Content $SourcePathMergedFile $ServersTxtFile #txt list of new servers to add
                                            ################################################################################################################################################################################################################################################################################
                                    
                                            ############## $trim() is a method Remove spaces from the beginning and end of the string#######################################################################################################################################################################################
                                    
                                            ForEach ($Name in gc $SourcePathMergedFile)
                                            {#for
                                                        $Name.trim() >> 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt'
                                            } #fin Foreach ($Name in gc $SourcePathMergedFile)
                                            ################################################################################################################################################################################################################################################################################################

                                            ############Change text contents to Lower Case###################################################################################################################################################################################################################################################
                                            (Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Raw).ToLower() | Out-File e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Force                                        
                                            ################################################################################################################################################################################################################################################################################################

                                            #############Find lines with text while ignoring blank lines. Remove the blank lines from the text################################################
                                            #gc e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt | where {$_ -ne ""} > e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\new.txt
                                            Select-String -Pattern "\w" -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt  | ForEach-Object { $_.line } | Set-Content -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt                                    
                                            ###############################################################################################################################################################################################################################################################################################

                                            #############Strip Empty Lines End of File#######################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            ####################################################################################################################################################################################################################################
                                                                        
                                            ##############Sort and Remove Duplicates ###########################################################################################################################################################################################
                                            $SortedFile = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' | Sort-Object -Unique #sorts the new txt file and remove duplicates combined txts
                                            New-Item -ItemType file $SourcePathSortedUnique -force > $LogNull #creates new file to add the sorted data
                                            Add-Content $SourcePathSortedUnique $SortedFile #agrega la info ordenada y sin duplicates al archivo que fue recreado para esto
                                            ###################################################################################################################################################################################################################################
                                                                         
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT
                                            $CSVCleanFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $ConvertSortedUniqueFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt'
                                            Rename-Item $ConvertSortedUniqueFile $CSVCleanFile #converts from txt to csv file

                                            ################# Removes Lines and Empty##########################################################################################################################################################################################
                                            $sourceFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $destPath = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'

                                            foreach($line in [System.IO.File]::ReadLines($sourceFile))
                                            {
                                                        if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                                        {
                                                                    $line >> $destPath
                                                        } #fin if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                            }#end foreach ($line in [System.IO.File]::ReadLines($sourceFile))
                                            ########################################################################################################################################################################################################################################################################################################
                                    
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT                                    
                                            $RenameCSVCleanNoLinesFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'
                                            $RenameLinuxPRGP01TxTtoCSV = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP04-NonProd-ED.csv'
                                            Rename-Item $RenameCSVCleanNoLinesFile $RenameLinuxPRGP01TxTtoCSV #assigns the final name to csv file to get it ready to copy back to vbr

                                            #########################Strip Empty Lines End of File##########################################################################################################################################################################################################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Windows-PRGP04-NonProd-ED.csv' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            #################################################################################################################################################################################################
                                            $PathVBRFileCSV = 'v$\Inventory\Physical-Clients-CSV\Windows-PRGP04-NonProd-ED.csv'
                                            $PathVBRFileCSVOld = 'v$\Inventory\Physical-Clients-CSV\Windows-PRGP04-NonProd-ED.csv.old'
                                            Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV \\$VBRNameGlobal\$PathVBRFileCSVOld  #renames csv file on vbr to old before copying the new one                                    
                                            robocopy.exe $SourceFolder \\$VBRNameGlobal\$VBRDestination\ $LinuxPRGP01 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr
                                            cls
                                            ################rescans protection group#####################################################################################################################################################################################################################################################################################################################
                                                            
                                            $PathVBRRToCopFilePS1 = 'V$\Inventory\Physical-Clients-CSV'
                                            $FileRescanLinuxPRGP01PS1 = 'ReScanWindowsPRGP04NonProdED.ps1'
                                            $FullPathRescanFilePS1 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ReScanProtectionGroups\'
                                            $FullPathRescanFilePS1VBR = 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP04NonProdED.ps1'  
                                                                        
                                            robocopy.exe $FullPathRescanFilePS1 \\$VBRNameGlobal\$PathVBRRToCopFilePS1\ $FileRescanLinuxPRGP01PS1 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr                                                                                                           
                                            cls
                                            $filelocationname = 'powershell.exe /c V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP04NonProdED.ps1'
                                            $global:WMIResult = ([WMICLASS]"\\$VBRNameGlobal\ROOT\CIMV2:win32_process").Create($filelocationname) #ejecuta el ReScanWindowsPRGP01 para actualizar los grupos con el rescan
                                            #e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\.\PsExec64.exe \\$VBRNameGlobal -u UsernameGlobal -p $PasswordGlobal /accepteula -h /s cmd /c powershell.exe -ExecutionPolicy Bypass -file 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1' 2> $LogNull este lo pongo en comentarions porque vy a usar wmiclass
                                            cls
                                            ################END rescans protection group###########################################################################################################################################################################################################################################################################################################################################################################################################################################################################

                                            if ($WMIResult.ReturnValue -eq 0) #revisar el resultado de $WMIResult.ReturnValue si es cero todo perfecto
                                            {                                                                                
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " The server(s) Enrolled - listed below." -ForegroundColor White;                                                                                                                                                                                                                        
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $ServersList.Trim().ToLower() | Format-List -Property *                                                                        
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP04-NonProd-ED.csv.old -Recurse #removes it form the VBR server                                                                                                
                                                                                                
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $VBRShortname = $VBRNameGlobal.split('.')[0]                                                                                                
                                                        foreach ($Servername in $ServersList)
                                                        {                                                                                
                                                                    [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP04-NonProd-ED' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                        } #fin foreach to update logs                                                                                                 
                                                                                                
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                                        
                                                        RemoveLocalFilesWindowsEDNonProd #removes all the local files temporarily used
                                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                                        PAUSE
                                                        EXIT                                        
                                            } #fin if ($WMIResult.ReturnValue -eq 0) osea si corrieo el rescan bien
                                            else
                                            {
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP04-NonProd-ED.csv.old -Recurse #removes it form the VBR server
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Windows-PRGP04-NonProd-ED.ps1 -Recurse #removes it form the VBR server                                                                                                                                        
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                        
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "There is an issue." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                                                        
                                                        Start-Sleep -S 10
                                                        RemoveLocalFilesWindowsEDNonProd #removes all the local files temporarily used
                                                        EXIT
                                            } #fin else $WMIResult.ReturnValue no fue igual a 0 hubo algun error

                                            ########################################################################################################################################################################################################################################################

                                } #fin if ($ServerCount1 -le 500) #PRGP01
                                else #csv tiene el maximo de servers
                                {
                                        cls
                                        WRITE-HOST "Backup Job Full! " -ForegroundColor Red -NoNewline; WRITE-HOST "It has reached the maximum number of servers inside a group" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                            
                                        $VBRShortname = $VBRNameGlobal.split('.')[0]
                                        [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Windows-PRGP04-NonProd-ED' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                            
                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                        Start-Sleep -S 10
                                        EXIT
                                } #fin else csv tiene maximo de servers                       
                                                                                    
                    } # fin if (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    else
                    {                       
                            cls
                            WRITE-HOST "Application didn't run. This session will close in 10 seconds" -ForegroundColor Red
                            Start-Sleep -S 10
                            EXIT                        
                    } #fin else el net connect dio un error (($LASTEXITCODEGlobal -eq 0)) resultado NO es Cero

    } #fin else # "The File is NOT empty"
} #fin function AddWindowsPhysicalEDNonprod


########################################################################################################################################################################################################################################################################################################################################################################################################################################
########################################################################################################################################################################################################################################################################################################################################################################################################################################



function AddServer($VBRName)
{#funcion AddServer  
      do
        { #do This menau CreateMenuAMRED
            CreateMenuAMRED
            $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
            switch ($OptionMenuAMRED)
            { #switch CreateMenuAMRED
                '1' #this option 1 is to enroll it AMR backup job
                {                    
                        UpdateCSVJobs -TypeAMRED "AMR" #corre funcion actualizar csvs

                } #option 1 switch MenuAMRED

                '2' #this option 2 is to enroll it ED backup job
                {

                        UpdateCSVJobs -TypeAMRED "ED" #corre funcion actualizar csvs

                } #option 2 switch MenuAMRED

                'q' #this option is to quit/exit
                {#option q switch MenuAMRED
                        cls                                        
                        EXIT
                }#end option Q ENROLL

            } #end switch CreateMenuAMRED

        } # end do menau CreateMenuAMRED
      until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
    
} #end funcion AddServer

function LoadUserCredentials()
{
        $Credential = Get-Credential $global:UsuarioGlobal    #capture credentials    
        $global:CredentialGlobal = $Credential #assign it to global variable
        $Username = $Credential.UserName #Assign it to Global Variables
        $global:UsernameGlobal = $Username #Assign it to Global Variables
        $Password = $Credential.GetNetworkCredential().Password #perfecto #Assign it Global Variables
        $global:PasswordGlobal = $Password #Assign it to Global Variables
        $global:CanContinue = '' #Assign it to Global Variables
        $global:AMRCredential=$Credential
        
        if ($UsernameGlobal -ne '' -and $PasswordGlobal.trim() -ne '') #is not empty
        {
            $CanContinue = "Yes";
            #Write-Host $CanContinue
            #pause
        }
        elseif ($UsernameGlobal -eq '' -or $PasswordGlobal.trim() -eq '') #empty
        {
            cls
            $CanContinue = "No"
            WRITE-HOST "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "The password field is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                                    
            [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = "" ; Protection_Group = "" ; Status = 'Error: The password field is empty'; Date = $DT ; Code = $LASTEXITCODE } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
            LogsSecondaryCopy #copies a secondary version of the logs to a different location
            Start-Sleep -S 10
            EXIT
        }
}

#############################################################################################################################################################################################################################################################################################################
#######Linux Functions####################################################################################################################################################################

function AddLinuxPhysicalAMR ($VBRName)
{

    If ( ((Get-ChildItem -Force 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List') -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt'.Trim().ToLower()))) ) #checks the folder is not empty and that the file is not empty
    {
            cls
            WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
            PAUSE    
    } #fin if

     else # "The File is NOT empty"
    {

    
                    # parameters and variables#
                    ########################################################################################################################################################################################################################################   
                    $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                    $ServersList = $ServersList.Trim().ToLower() | Sort-Object -Unique #trim leading and trailing spaces, lowers, sorts and removes duplicates
                    $ServersFile = "servers.txt"
                    $SourceFolderServersFile = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List"
                    $SourcePathServersFile = $SourceFolderServersFile + "\" + $ServersFile # Source Path    	
            
                    $SourceFileLocationVBR = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    
                    $VBRDestination = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    

       
                    $DestinationLocalPC = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # sets the varible for the file location
    
                    $SourceFolder = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # Source Folder
    
                    $MergedFile = "MergedFile.txt" # Source File  
                    $SourcePathMergedFile = $SourceFolder + "\" + $MergedFile # Source folder Path for Merged File  
    
                    $LinuxPRGP01 = "Linux-PRGP01.csv" # Source File
                    $SourcePathLinuxPRGP01 = $SourceFolder + "\" + $LinuxPRGP01 # Source Path

                    $LinuxPRGP01TXT = "Linux-PRGP01.txt" # Source File
                    $SourcePathLinuxPRGP01TXT = $SourceFolder + "\" + $LinuxPRGP01TXT # Source Path

                    $SortedUniqueFile = "SortedUniqueFile.txt" # Source File  
                    $SourcePathSortedUnique = $SourceFolder + "\" + $SortedUniqueFile # Source folder Path for sorted and unique text
                    ########################################################################################################################################################################################################################################
                    NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal
                    $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
                    cls                           
                    # Let's Check exit code
                    If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    {#if			
                                #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$LinuxPRGP01" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                $ServerCount1 = (@(Get-Content $DestinationLocalPC\$LinuxPRGP01).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv).Length)

                                if ($ServerCount1 -le 500) #PRGP01 es menor y si entra
                                {
                                    
                                            Rename-Item $SourcePathLinuxPRGP01 $SourcePathLinuxPRGP01TXT #converts csv to txt file to remove format                                  
                                            $ServersTxtFile = Get-Content $SourcePathServersFile #get contents of new servers to add                                    
                                            $ConvertedCsvToTxtFile = Get-Content $SourcePathLinuxPRGP01TXT #get contents of servers currently being backed up that was converted from csv to txt    
                                            New-Item -ItemType file $SourcePathMergedFile -force > $LogNull #creates a new file to combine merged info from $ServersTxtFile and  $ConvertedCsvToTxtFile
                                            cls
                                            ####Combine Merge Files########################################################################################################################################################################################################################################################
                                            Add-Content $SourcePathMergedFile $ConvertedCsvToTxtFile #txt list of being backed up servers
                                            Add-Content $SourcePathMergedFile $ServersTxtFile #txt list of new servers to add
                                            ################################################################################################################################################################################################################################################################################
                                    
                                            ############## $trim() is a method Remove spaces from the beginning and end of the string#######################################################################################################################################################################################
                                    
                                            ForEach ($Name in gc $SourcePathMergedFile)
                                            {#for
                                                        $Name.trim() >> 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt'
                                            } #fin Foreach ($Name in gc $SourcePathMergedFile)
                                            ################################################################################################################################################################################################################################################################################################

                                            ############Change text contents to Lower Case###################################################################################################################################################################################################################################################
                                            (Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Raw).ToLower() | Out-File e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Force                                        
                                            ################################################################################################################################################################################################################################################################################################

                                            #############Find lines with text while ignoring blank lines. Remove the blank lines from the text################################################
                                            #gc e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt | where {$_ -ne ""} > e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\new.txt
                                            Select-String -Pattern "\w" -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt  | ForEach-Object { $_.line } | Set-Content -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt                                    
                                            ###############################################################################################################################################################################################################################################################################################

                                            #############Strip Empty Lines End of File#######################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            ####################################################################################################################################################################################################################################
                                                                        
                                            ##############Sort and Remove Duplicates ###########################################################################################################################################################################################
                                            $SortedFile = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' | Sort-Object -Unique #sorts the new txt file and remove duplicates combined txts
                                            New-Item -ItemType file $SourcePathSortedUnique -force > $LogNull #creates new file to add the sorted data
                                            Add-Content $SourcePathSortedUnique $SortedFile #agrega la info ordenada y sin duplicates al archivo que fue recreado para esto
                                            ###################################################################################################################################################################################################################################
                                                                         
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT
                                            $CSVCleanFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $ConvertSortedUniqueFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt'
                                            Rename-Item $ConvertSortedUniqueFile $CSVCleanFile #converts from txt to csv file

                                            ################# Removes Lines and Empty##########################################################################################################################################################################################
                                            $sourceFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $destPath = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'

                                            foreach($line in [System.IO.File]::ReadLines($sourceFile))
                                            {
                                                        if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                                        {
                                                                    $line >> $destPath
                                                        } #fin if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                            }#end foreach ($line in [System.IO.File]::ReadLines($sourceFile))
                                            ########################################################################################################################################################################################################################################################################################################
                                    
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT                                    
                                            $RenameCSVCleanNoLinesFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'
                                            $RenameLinuxPRGP01TxTtoCSV = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv'
                                            Rename-Item $RenameCSVCleanNoLinesFile $RenameLinuxPRGP01TxTtoCSV #assigns the final name to csv file to get it ready to copy back to vbr

                                            #########################Strip Empty Lines End of File##########################################################################################################################################################################################################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            #################################################################################################################################################################################################
                                            $PathVBRFileCSV = 'v$\Inventory\Physical-Clients-CSV\Linux-PRGP01.csv'
                                            $PathVBRFileCSVOld = 'v$\Inventory\Physical-Clients-CSV\Linux-PRGP01.csv.old'
                                            Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV \\$VBRNameGlobal\$PathVBRFileCSVOld  #renames csv file on vbr to old before copying the new one                                    
                                            robocopy.exe $SourceFolder \\$VBRNameGlobal\$VBRDestination\ $LinuxPRGP01 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr
                                            cls
                                            ################rescans protection group#####################################################################################################################################################################################################################################################################################################################
                                                            
                                            $PathVBRRToCopFilePS1 = 'V$\Inventory\Physical-Clients-CSV'
                                            $FileRescanLinuxPRGP01PS1 = 'ReScanLinuxPRGP01.ps1'
                                            $FullPathRescanFilePS1 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ReScanProtectionGroups\'
                                            $FullPathRescanFilePS1VBR = 'V:\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP01.ps1'  
                                                                        
                                            robocopy.exe $FullPathRescanFilePS1 \\$VBRNameGlobal\$PathVBRRToCopFilePS1\ $FileRescanLinuxPRGP01PS1 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr                                                                                                           
                                            cls
                                            $filelocationname = 'powershell.exe /c V:\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP01.ps1'
                                            $global:WMIResult = ([WMICLASS]"\\$VBRNameGlobal\ROOT\CIMV2:win32_process").Create($filelocationname) #ejecuta el ReScanWindowsPRGP01 para actualizar los grupos con el rescan
                                            #e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\.\PsExec64.exe \\$VBRNameGlobal -u UsernameGlobal -p $PasswordGlobal /accepteula -h /s cmd /c powershell.exe -ExecutionPolicy Bypass -file 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1' 2> $LogNull este lo pongo en comentarions porque vy a usar wmiclass
                                            cls
                                            ################END rescans protection group###########################################################################################################################################################################################################################################################################################################################################################################################################################################################################

                                            if ($WMIResult.ReturnValue -eq 0) #revisar el resultado de $WMIResult.ReturnValue si es cero todo perfecto
                                            {                                                                                
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " The server(s) Enrolled - listed below." -ForegroundColor White;                                                                                                                                                                                                                        
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $ServersList.Trim().ToLower() | Format-List -Property *                                                                        
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Linux-PRGP01.csv.old -Recurse #removes it form the VBR server                                                                                                
                                                                                                
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $VBRShortname = $VBRNameGlobal.split('.')[0]                                                                                                
                                                        foreach ($Servername in $ServersList)
                                                        {                                                                                
                                                                    [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Linux-PRGP01' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                        } #fin foreach to update logs                                                                                                 
                                                                                                
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                                        
                                                        RemoveLocalFilesLinuxAMR #removes all the local files temporarily used
                                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                                        PAUSE
                                                        EXIT                                        
                                            } #fin if ($WMIResult.ReturnValue -eq 0) osea si corrieo el rescan bien
                                            else
                                            {
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Linux-PRGP01.csv.old -Recurse #removes it form the VBR server
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP01.ps1 -Recurse #removes it form the VBR server                                                                                                                                        
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                        
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "There is an issue." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                                                        
                                                        Start-Sleep -S 10
                                                        RemoveLocalFilesLinuxAMR #removes all the local files temporarily used
                                                        EXIT
                                            } #fin else $WMIResult.ReturnValue no fue igual a 0 hubo algun error

                                            ########################################################################################################################################################################################################################################################

                                } #fin if ($ServerCount1 -le 500) #PRGP01
                                else #csv tiene el maximo de servers
                                {
                                        cls
                                        WRITE-HOST "Backup Job Full! " -ForegroundColor Red -NoNewline; WRITE-HOST "It has reached the maximum number of servers inside a group" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                            
                                        $VBRShortname = $VBRNameGlobal.split('.')[0]
                                        [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Linux-PRGP01' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                            
                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                        Start-Sleep -S 10
                                        EXIT
                                } #fin else csv tiene maximo de servers                       
                                                                                    
                    } # fin if (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    else
                    {                       
                            cls
                            WRITE-HOST "Application didn't run. This session will close in 10 seconds" -ForegroundColor Red
                            Start-Sleep -S 10
                            EXIT                        
                    } #fin else el net connect dio un error (($LASTEXITCODEGlobal -eq 0)) resultado NO es Cero

    } #fin else # "The File is NOT empty"
} #fin function AddLinuxPhysicalAMR




function AddLinuxPhysicalED ($VBRName)
{

    If ( ((Get-ChildItem -Force 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List') -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt'.Trim().ToLower()))) ) #checks the folder is not empty and that the file is not empty
    {
            cls
            WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
            PAUSE    
    } #fin if

     else # "The File is NOT empty"
    {

    
                    # parameters and variables#
                    ########################################################################################################################################################################################################################################   
                    $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                    $ServersList = $ServersList.Trim().ToLower() | Sort-Object -Unique #trim leading and trailing spaces, lowers, sorts and removes duplicates
                    $ServersFile = "servers.txt"
                    $SourceFolderServersFile = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List"
                    $SourcePathServersFile = $SourceFolderServersFile + "\" + $ServersFile # Source Path    	
            
                    $SourceFileLocationVBR = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    
                    $VBRDestination = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    

       
                    $DestinationLocalPC = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # sets the varible for the file location
    
                    $SourceFolder = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # Source Folder
    
                    $MergedFile = "MergedFile.txt" # Source File  
                    $SourcePathMergedFile = $SourceFolder + "\" + $MergedFile # Source folder Path for Merged File  
    
                    $LinuxPRGP01 = "Linux-PRGP02-ED.csv" # Source File
                    $SourcePathLinuxPRGP01 = $SourceFolder + "\" + $LinuxPRGP01 # Source Path

                    $LinuxPRGP01TXT = "Linux-PRGP02-ED.txt" # Source File
                    $SourcePathLinuxPRGP01TXT = $SourceFolder + "\" + $LinuxPRGP01TXT # Source Path

                    $SortedUniqueFile = "SortedUniqueFile.txt" # Source File  
                    $SourcePathSortedUnique = $SourceFolder + "\" + $SortedUniqueFile # Source folder Path for sorted and unique text
                    ########################################################################################################################################################################################################################################
                    NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal
                    $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
                    cls                           
                    # Let's Check exit code
                    If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    {#if			
                                #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$LinuxPRGP01" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                $ServerCount1 = (@(Get-Content $DestinationLocalPC\$LinuxPRGP01).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv).Length)

                                if ($ServerCount1 -le 500) #PRGP01 es menor y si entra
                                {
                                    
                                            Rename-Item $SourcePathLinuxPRGP01 $SourcePathLinuxPRGP01TXT #converts csv to txt file to remove format                                  
                                            $ServersTxtFile = Get-Content $SourcePathServersFile #get contents of new servers to add                                    
                                            $ConvertedCsvToTxtFile = Get-Content $SourcePathLinuxPRGP01TXT #get contents of servers currently being backed up that was converted from csv to txt    
                                            New-Item -ItemType file $SourcePathMergedFile -force > $LogNull #creates a new file to combine merged info from $ServersTxtFile and  $ConvertedCsvToTxtFile
                                            cls
                                            ####Combine Merge Files########################################################################################################################################################################################################################################################
                                            Add-Content $SourcePathMergedFile $ConvertedCsvToTxtFile #txt list of being backed up servers
                                            Add-Content $SourcePathMergedFile $ServersTxtFile #txt list of new servers to add
                                            ################################################################################################################################################################################################################################################################################
                                    
                                            ############## $trim() is a method Remove spaces from the beginning and end of the string#######################################################################################################################################################################################
                                    
                                            ForEach ($Name in gc $SourcePathMergedFile)
                                            {#for
                                                        $Name.trim() >> 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt'
                                            } #fin Foreach ($Name in gc $SourcePathMergedFile)
                                            ################################################################################################################################################################################################################################################################################################

                                            ############Change text contents to Lower Case###################################################################################################################################################################################################################################################
                                            (Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Raw).ToLower() | Out-File e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Force                                        
                                            ################################################################################################################################################################################################################################################################################################

                                            #############Find lines with text while ignoring blank lines. Remove the blank lines from the text################################################
                                            #gc e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt | where {$_ -ne ""} > e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\new.txt
                                            Select-String -Pattern "\w" -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt  | ForEach-Object { $_.line } | Set-Content -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt                                    
                                            ###############################################################################################################################################################################################################################################################################################

                                            #############Strip Empty Lines End of File#######################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            ####################################################################################################################################################################################################################################
                                                                        
                                            ##############Sort and Remove Duplicates ###########################################################################################################################################################################################
                                            $SortedFile = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' | Sort-Object -Unique #sorts the new txt file and remove duplicates combined txts
                                            New-Item -ItemType file $SourcePathSortedUnique -force > $LogNull #creates new file to add the sorted data
                                            Add-Content $SourcePathSortedUnique $SortedFile #agrega la info ordenada y sin duplicates al archivo que fue recreado para esto
                                            ###################################################################################################################################################################################################################################
                                                                         
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT
                                            $CSVCleanFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $ConvertSortedUniqueFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt'
                                            Rename-Item $ConvertSortedUniqueFile $CSVCleanFile #converts from txt to csv file

                                            ################# Removes Lines and Empty##########################################################################################################################################################################################
                                            $sourceFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $destPath = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'

                                            foreach($line in [System.IO.File]::ReadLines($sourceFile))
                                            {
                                                        if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                                        {
                                                                    $line >> $destPath
                                                        } #fin if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                            }#end foreach ($line in [System.IO.File]::ReadLines($sourceFile))
                                            ########################################################################################################################################################################################################################################################################################################
                                    
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT                                    
                                            $RenameCSVCleanNoLinesFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'
                                            $RenameLinuxPRGP01TxTtoCSV = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP02-ED.csv'
                                            Rename-Item $RenameCSVCleanNoLinesFile $RenameLinuxPRGP01TxTtoCSV #assigns the final name to csv file to get it ready to copy back to vbr

                                            #########################Strip Empty Lines End of File##########################################################################################################################################################################################################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP02-ED.csv' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            #################################################################################################################################################################################################
                                            $PathVBRFileCSV = 'v$\Inventory\Physical-Clients-CSV\Linux-PRGP02-ED.csv'
                                            $PathVBRFileCSVOld = 'v$\Inventory\Physical-Clients-CSV\Linux-PRGP02-ED.csv.old'
                                            Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV \\$VBRNameGlobal\$PathVBRFileCSVOld  #renames csv file on vbr to old before copying the new one                                    
                                            robocopy.exe $SourceFolder \\$VBRNameGlobal\$VBRDestination\ $LinuxPRGP01 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr
                                            cls
                                            ################rescans protection group#####################################################################################################################################################################################################################################################################################################################
                                                            
                                            $PathVBRRToCopFilePS1 = 'V$\Inventory\Physical-Clients-CSV'
                                            $FileRescanLinuxPRGP01PS1 = 'ReScanLinuxPRGP02ED.ps1'
                                            $FullPathRescanFilePS1 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ReScanProtectionGroups\'
                                            $FullPathRescanFilePS1VBR = 'V:\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP02ED.ps1'  
                                                                        
                                            robocopy.exe $FullPathRescanFilePS1 \\$VBRNameGlobal\$PathVBRRToCopFilePS1\ $FileRescanLinuxPRGP01PS1 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr                                                                                                           
                                            cls
                                            $filelocationname = 'powershell.exe /c V:\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP02ED.ps1'
                                            $global:WMIResult = ([WMICLASS]"\\$VBRNameGlobal\ROOT\CIMV2:win32_process").Create($filelocationname) #ejecuta el ReScanWindowsPRGP01 para actualizar los grupos con el rescan
                                            #e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\.\PsExec64.exe \\$VBRNameGlobal -u UsernameGlobal -p $PasswordGlobal /accepteula -h /s cmd /c powershell.exe -ExecutionPolicy Bypass -file 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1' 2> $LogNull este lo pongo en comentarions porque vy a usar wmiclass
                                            cls
                                            ################END rescans protection group###########################################################################################################################################################################################################################################################################################################################################################################################################################################################################

                                            if ($WMIResult.ReturnValue -eq 0) #revisar el resultado de $WMIResult.ReturnValue si es cero todo perfecto
                                            {                                                                                
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " The server(s) Enrolled - listed below." -ForegroundColor White;                                                                                                                                                                                                                        
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $ServersList.Trim().ToLower() | Format-List -Property *                                                                        
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Linux-PRGP02-ED.csv.old -Recurse #removes it form the VBR server                                                                                                
                                                                                                
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $VBRShortname = $VBRNameGlobal.split('.')[0]                                                                                                
                                                        foreach ($Servername in $ServersList)
                                                        {                                                                                
                                                                    [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Linux-PRGP02-ED' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                        } #fin foreach to update logs                                                                                                 
                                                                                                
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                                        
                                                        RemoveLocalFilesLinuxED #removes all the local files temporarily used
                                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                                        PAUSE
                                                        EXIT                                        
                                            } #fin if ($WMIResult.ReturnValue -eq 0) osea si corrieo el rescan bien
                                            else
                                            {
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Linux-PRGP02-ED.csv.old -Recurse #removes it form the VBR server
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP02ED.ps1 -Recurse #removes it form the VBR server                                                                                                                                        
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                        
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "There is an issue." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                                                        
                                                        Start-Sleep -S 10
                                                        RemoveLocalFilesLinuxED #removes all the local files temporarily used
                                                        EXIT
                                            } #fin else $WMIResult.ReturnValue no fue igual a 0 hubo algun error

                                            ########################################################################################################################################################################################################################################################

                                } #fin if ($ServerCount1 -le 500) #PRGP01
                                else #csv tiene el maximo de servers
                                {
                                        cls
                                        WRITE-HOST "Backup Job Full! " -ForegroundColor Red -NoNewline; WRITE-HOST "It has reached the maximum number of servers inside a group" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                            
                                        $VBRShortname = $VBRNameGlobal.split('.')[0]
                                        [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Linux-PRGP02-ED' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                            
                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                        Start-Sleep -S 10
                                        EXIT
                                } #fin else csv tiene maximo de servers                       
                                                                                    
                    } # fin if (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    else
                    {                       
                            cls
                            WRITE-HOST "Application didn't run. This session will close in 10 seconds" -ForegroundColor Red
                            Start-Sleep -S 10
                            EXIT                        
                    } #fin else el net connect dio un error (($LASTEXITCODEGlobal -eq 0)) resultado NO es Cero

    } #fin else # "The File is NOT empty"
} #fin function AddLinuxPhysicalED




function AddLinuxPhysicalAMRNonprod ($VBRName)
{

    If ( ((Get-ChildItem -Force 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List') -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt'.Trim().ToLower()))) ) #checks the folder is not empty and that the file is not empty
    {
            cls
            WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
            PAUSE    
    } #fin if

     else # "The File is NOT empty"
    {

    
                    # parameters and variables#
                    ########################################################################################################################################################################################################################################   
                    $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                    $ServersList = $ServersList.Trim().ToLower() | Sort-Object -Unique #trim leading and trailing spaces, lowers, sorts and removes duplicates
                    $ServersFile = "servers.txt"
                    $SourceFolderServersFile = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List"
                    $SourcePathServersFile = $SourceFolderServersFile + "\" + $ServersFile # Source Path    	
            
                    $SourceFileLocationVBR = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    
                    $VBRDestination = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    

       
                    $DestinationLocalPC = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # sets the varible for the file location
    
                    $SourceFolder = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # Source Folder
    
                    $MergedFile = "MergedFile.txt" # Source File  
                    $SourcePathMergedFile = $SourceFolder + "\" + $MergedFile # Source folder Path for Merged File  
    
                    $LinuxPRGP01 = "Linux-PRGP03-NonProd.csv" # Source File
                    $SourcePathLinuxPRGP01 = $SourceFolder + "\" + $LinuxPRGP01 # Source Path

                    $LinuxPRGP01TXT = "Linux-PRGP03-NonProd.txt" # Source File
                    $SourcePathLinuxPRGP01TXT = $SourceFolder + "\" + $LinuxPRGP01TXT # Source Path

                    $SortedUniqueFile = "SortedUniqueFile.txt" # Source File  
                    $SourcePathSortedUnique = $SourceFolder + "\" + $SortedUniqueFile # Source folder Path for sorted and unique text
                    ########################################################################################################################################################################################################################################
                    NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal
                    $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
                    cls                           
                    # Let's Check exit code
                    If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    {#if			
                                #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$LinuxPRGP01" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                $ServerCount1 = (@(Get-Content $DestinationLocalPC\$LinuxPRGP01).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv).Length)

                                if ($ServerCount1 -le 500) #PRGP01 es menor y si entra
                                {
                                    
                                            Rename-Item $SourcePathLinuxPRGP01 $SourcePathLinuxPRGP01TXT #converts csv to txt file to remove format                                  
                                            $ServersTxtFile = Get-Content $SourcePathServersFile #get contents of new servers to add                                    
                                            $ConvertedCsvToTxtFile = Get-Content $SourcePathLinuxPRGP01TXT #get contents of servers currently being backed up that was converted from csv to txt    
                                            New-Item -ItemType file $SourcePathMergedFile -force > $LogNull #creates a new file to combine merged info from $ServersTxtFile and  $ConvertedCsvToTxtFile
                                            cls
                                            ####Combine Merge Files########################################################################################################################################################################################################################################################
                                            Add-Content $SourcePathMergedFile $ConvertedCsvToTxtFile #txt list of being backed up servers
                                            Add-Content $SourcePathMergedFile $ServersTxtFile #txt list of new servers to add
                                            ################################################################################################################################################################################################################################################################################
                                    
                                            ############## $trim() is a method Remove spaces from the beginning and end of the string#######################################################################################################################################################################################
                                    
                                            ForEach ($Name in gc $SourcePathMergedFile)
                                            {#for
                                                        $Name.trim() >> 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt'
                                            } #fin Foreach ($Name in gc $SourcePathMergedFile)
                                            ################################################################################################################################################################################################################################################################################################

                                            ############Change text contents to Lower Case###################################################################################################################################################################################################################################################
                                            (Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Raw).ToLower() | Out-File e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Force                                        
                                            ################################################################################################################################################################################################################################################################################################

                                            #############Find lines with text while ignoring blank lines. Remove the blank lines from the text################################################
                                            #gc e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt | where {$_ -ne ""} > e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\new.txt
                                            Select-String -Pattern "\w" -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt  | ForEach-Object { $_.line } | Set-Content -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt                                    
                                            ###############################################################################################################################################################################################################################################################################################

                                            #############Strip Empty Lines End of File#######################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            ####################################################################################################################################################################################################################################
                                                                        
                                            ##############Sort and Remove Duplicates ###########################################################################################################################################################################################
                                            $SortedFile = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' | Sort-Object -Unique #sorts the new txt file and remove duplicates combined txts
                                            New-Item -ItemType file $SourcePathSortedUnique -force > $LogNull #creates new file to add the sorted data
                                            Add-Content $SourcePathSortedUnique $SortedFile #agrega la info ordenada y sin duplicates al archivo que fue recreado para esto
                                            ###################################################################################################################################################################################################################################
                                                                         
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT
                                            $CSVCleanFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $ConvertSortedUniqueFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt'
                                            Rename-Item $ConvertSortedUniqueFile $CSVCleanFile #converts from txt to csv file

                                            ################# Removes Lines and Empty##########################################################################################################################################################################################
                                            $sourceFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $destPath = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'

                                            foreach($line in [System.IO.File]::ReadLines($sourceFile))
                                            {
                                                        if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                                        {
                                                                    $line >> $destPath
                                                        } #fin if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                            }#end foreach ($line in [System.IO.File]::ReadLines($sourceFile))
                                            ########################################################################################################################################################################################################################################################################################################
                                    
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT                                    
                                            $RenameCSVCleanNoLinesFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'
                                            $RenameLinuxPRGP01TxTtoCSV = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP03-NonProd.csv'
                                            Rename-Item $RenameCSVCleanNoLinesFile $RenameLinuxPRGP01TxTtoCSV #assigns the final name to csv file to get it ready to copy back to vbr

                                            #########################Strip Empty Lines End of File##########################################################################################################################################################################################################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP03-NonProd.csv' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            #################################################################################################################################################################################################
                                            $PathVBRFileCSV = 'v$\Inventory\Physical-Clients-CSV\Linux-PRGP03-NonProd.csv'
                                            $PathVBRFileCSVOld = 'v$\Inventory\Physical-Clients-CSV\Linux-PRGP03-NonProd.csv.old'
                                            Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV \\$VBRNameGlobal\$PathVBRFileCSVOld  #renames csv file on vbr to old before copying the new one                                    
                                            robocopy.exe $SourceFolder \\$VBRNameGlobal\$VBRDestination\ $LinuxPRGP01 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr
                                            cls
                                            ################rescans protection group#####################################################################################################################################################################################################################################################################################################################
                                                            
                                            $PathVBRRToCopFilePS1 = 'V$\Inventory\Physical-Clients-CSV'
                                            $FileRescanLinuxPRGP01PS1 = 'ReScanLinuxPRGP03NonProd.ps1'
                                            $FullPathRescanFilePS1 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ReScanProtectionGroups\'
                                            $FullPathRescanFilePS1VBR = 'V:\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP03NonProd.ps1'  
                                                                        
                                            robocopy.exe $FullPathRescanFilePS1 \\$VBRNameGlobal\$PathVBRRToCopFilePS1\ $FileRescanLinuxPRGP01PS1 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr                                                                                                           
                                            cls
                                            $filelocationname = 'powershell.exe /c V:\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP03NonProd.ps1'
                                            $global:WMIResult = ([WMICLASS]"\\$VBRNameGlobal\ROOT\CIMV2:win32_process").Create($filelocationname) #ejecuta el ReScanWindowsPRGP01 para actualizar los grupos con el rescan
                                            #e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\.\PsExec64.exe \\$VBRNameGlobal -u UsernameGlobal -p $PasswordGlobal /accepteula -h /s cmd /c powershell.exe -ExecutionPolicy Bypass -file 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1' 2> $LogNull este lo pongo en comentarions porque vy a usar wmiclass
                                            cls
                                            ################END rescans protection group###########################################################################################################################################################################################################################################################################################################################################################################################################################################################################

                                            if ($WMIResult.ReturnValue -eq 0) #revisar el resultado de $WMIResult.ReturnValue si es cero todo perfecto
                                            {                                                                                
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " The server(s) Enrolled - listed below." -ForegroundColor White;                                                                                                                                                                                                                        
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $ServersList.Trim().ToLower() | Format-List -Property *                                                                        
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Linux-PRGP03-NonProd.csv.old -Recurse #removes it form the VBR server                                                                                                
                                                                                                
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $VBRShortname = $VBRNameGlobal.split('.')[0]                                                                                                
                                                        foreach ($Servername in $ServersList)
                                                        {                                                                                
                                                                    [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Linux-PRGP03-NonProd' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                        } #fin foreach to update logs                                                                                                 
                                                                                                
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                                        
                                                        RemoveLocalFilesLinuxAMRNonProd #removes all the local files temporarily used
                                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                                        PAUSE
                                                        EXIT                                        
                                            } #fin if ($WMIResult.ReturnValue -eq 0) osea si corrieo el rescan bien
                                            else
                                            {
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Linux-PRGP03-NonProd.csv.old -Recurse #removes it form the VBR server
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP03NonProd.ps1 -Recurse #removes it form the VBR server                                                                                                                                        
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                        
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "There is an issue." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                                                        
                                                        Start-Sleep -S 10
                                                        RemoveLocalFilesLinuxAMRNonProd #removes all the local files temporarily used
                                                        EXIT
                                            } #fin else $WMIResult.ReturnValue no fue igual a 0 hubo algun error

                                            ########################################################################################################################################################################################################################################################

                                } #fin if ($ServerCount1 -le 500) #PRGP01
                                else #csv tiene el maximo de servers
                                {
                                        cls
                                        WRITE-HOST "Backup Job Full! " -ForegroundColor Red -NoNewline; WRITE-HOST "It has reached the maximum number of servers inside a group" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                            
                                        $VBRShortname = $VBRNameGlobal.split('.')[0]
                                        [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Linux-PRGP03-NonProd' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                            
                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                        Start-Sleep -S 10
                                        EXIT
                                } #fin else csv tiene maximo de servers                       
                                                                                    
                    } # fin if (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    else
                    {                       
                            cls
                            WRITE-HOST "Application didn't run. This session will close in 10 seconds" -ForegroundColor Red
                            Start-Sleep -S 10
                            EXIT                        
                    } #fin else el net connect dio un error (($LASTEXITCODEGlobal -eq 0)) resultado NO es Cero

    } #fin else # "The File is NOT empty"
} #fin function AddLinuxPhysicalAMRNonprod


function AddLinuxPhysicalEDNonprod ($VBRName)
{

    If ( ((Get-ChildItem -Force 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List') -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt'.Trim().ToLower()))) ) #checks the folder is not empty and that the file is not empty
    {
            cls
            WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
            PAUSE    
    } #fin if

     else # "The File is NOT empty"
    {

    
                    # parameters and variables#
                    ########################################################################################################################################################################################################################################   
                    $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                    $ServersList = $ServersList.Trim().ToLower() | Sort-Object -Unique #trim leading and trailing spaces, lowers, sorts and removes duplicates
                    $ServersFile = "servers.txt"
                    $SourceFolderServersFile = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List"
                    $SourcePathServersFile = $SourceFolderServersFile + "\" + $ServersFile # Source Path    	
            
                    $SourceFileLocationVBR = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    
                    $VBRDestination = 'V$\Inventory\Physical-Clients-CSV' # sets the varible for the file destination    

       
                    $DestinationLocalPC = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # sets the varible for the file location
    
                    $SourceFolder = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup" # Source Folder
    
                    $MergedFile = "MergedFile.txt" # Source File  
                    $SourcePathMergedFile = $SourceFolder + "\" + $MergedFile # Source folder Path for Merged File  
    
                    $LinuxPRGP01 = "Linux-PRGP04-NonProd-ED.csv" # Source File
                    $SourcePathLinuxPRGP01 = $SourceFolder + "\" + $LinuxPRGP01 # Source Path

                    $LinuxPRGP01TXT = "Linux-PRGP04-NonProd-ED.txt" # Source File
                    $SourcePathLinuxPRGP01TXT = $SourceFolder + "\" + $LinuxPRGP01TXT # Source Path

                    $SortedUniqueFile = "SortedUniqueFile.txt" # Source File  
                    $SourcePathSortedUnique = $SourceFolder + "\" + $SortedUniqueFile # Source folder Path for sorted and unique text
                    ########################################################################################################################################################################################################################################
                    NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal
                    $global:LASTEXITCODEGlobal = $LASTEXITCODE #Assign it to control the results of the NET Use
                    cls                           
                    # Let's Check exit code
                    If (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    {#if			
                                #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
                                Copy-Item "\\$VBRNameGlobal\$SourceFileLocationVBR\$LinuxPRGP01" -Destination $DestinationLocalPC -Recurse #copy the .csv from the vbr to the local pc
                                $ServerCount1 = (@(Get-Content $DestinationLocalPC\$LinuxPRGP01).Length) #$ServerCount = (@(Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP01.csv).Length)

                                if ($ServerCount1 -le 500) #PRGP01 es menor y si entra
                                {
                                    
                                            Rename-Item $SourcePathLinuxPRGP01 $SourcePathLinuxPRGP01TXT #converts csv to txt file to remove format                                  
                                            $ServersTxtFile = Get-Content $SourcePathServersFile #get contents of new servers to add                                    
                                            $ConvertedCsvToTxtFile = Get-Content $SourcePathLinuxPRGP01TXT #get contents of servers currently being backed up that was converted from csv to txt    
                                            New-Item -ItemType file $SourcePathMergedFile -force > $LogNull #creates a new file to combine merged info from $ServersTxtFile and  $ConvertedCsvToTxtFile
                                            cls
                                            ####Combine Merge Files########################################################################################################################################################################################################################################################
                                            Add-Content $SourcePathMergedFile $ConvertedCsvToTxtFile #txt list of being backed up servers
                                            Add-Content $SourcePathMergedFile $ServersTxtFile #txt list of new servers to add
                                            ################################################################################################################################################################################################################################################################################
                                    
                                            ############## $trim() is a method Remove spaces from the beginning and end of the string#######################################################################################################################################################################################
                                    
                                            ForEach ($Name in gc $SourcePathMergedFile)
                                            {#for
                                                        $Name.trim() >> 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt'
                                            } #fin Foreach ($Name in gc $SourcePathMergedFile)
                                            ################################################################################################################################################################################################################################################################################################

                                            ############Change text contents to Lower Case###################################################################################################################################################################################################################################################
                                            (Get-Content e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\TrimmedFile.txt -Raw).ToLower() | Out-File e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt -Force                                        
                                            ################################################################################################################################################################################################################################################################################################

                                            #############Find lines with text while ignoring blank lines. Remove the blank lines from the text################################################
                                            #gc e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt | where {$_ -ne ""} > e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\new.txt
                                            Select-String -Pattern "\w" -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\LowerCaseFile.txt  | ForEach-Object { $_.line } | Set-Content -Path e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt                                    
                                            ###############################################################################################################################################################################################################################################################################################

                                            #############Strip Empty Lines End of File#######################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            ####################################################################################################################################################################################################################################
                                                                        
                                            ##############Sort and Remove Duplicates ###########################################################################################################################################################################################
                                            $SortedFile = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\NoLinesFile.txt' | Sort-Object -Unique #sorts the new txt file and remove duplicates combined txts
                                            New-Item -ItemType file $SourcePathSortedUnique -force > $LogNull #creates new file to add the sorted data
                                            Add-Content $SourcePathSortedUnique $SortedFile #agrega la info ordenada y sin duplicates al archivo que fue recreado para esto
                                            ###################################################################################################################################################################################################################################
                                                                         
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT
                                            $CSVCleanFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $ConvertSortedUniqueFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\SortedUniqueFile.txt'
                                            Rename-Item $ConvertSortedUniqueFile $CSVCleanFile #converts from txt to csv file

                                            ################# Removes Lines and Empty##########################################################################################################################################################################################
                                            $sourceFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanFile.csv'
                                            $destPath = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'

                                            foreach($line in [System.IO.File]::ReadLines($sourceFile))
                                            {
                                                        if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                                        {
                                                                    $line >> $destPath
                                                        } #fin if ((-not ($line.Contains("---") -or $line.Contains("affected"))) -and $line.Length -gt 0)
                                            }#end foreach ($line in [System.IO.File]::ReadLines($sourceFile))
                                            ########################################################################################################################################################################################################################################################################################################
                                    
                                            New-Item -ItemType file $SourcePathLinuxPRGP01TXT -force > $LogNull #re-creates an empty clean SourcePathWindowsPRGP01TXT                                    
                                            $RenameCSVCleanNoLinesFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\CSVCleanNoLinesFile.csv'
                                            $RenameLinuxPRGP01TxTtoCSV = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP04-NonProd-ED.csv'
                                            Rename-Item $RenameCSVCleanNoLinesFile $RenameLinuxPRGP01TxTtoCSV #assigns the final name to csv file to get it ready to copy back to vbr

                                            #########################Strip Empty Lines End of File##########################################################################################################################################################################################################################################################################################################
                                            $StripFile = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Linux-PRGP04-NonProd-ED.csv' #This will only strip the empty lines from the end of the file
                                            $Newtext = (Get-Content -Path $StripFile -Raw) -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                            [system.io.file]::WriteAllText($StripFile,$Newtext) #This will only strip the empty lines from the end of the file
                                            #################################################################################################################################################################################################
                                            $PathVBRFileCSV = 'v$\Inventory\Physical-Clients-CSV\Linux-PRGP04-NonProd-ED.csv'
                                            $PathVBRFileCSVOld = 'v$\Inventory\Physical-Clients-CSV\Linux-PRGP04-NonProd-ED.csv.old'
                                            Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV \\$VBRNameGlobal\$PathVBRFileCSVOld  #renames csv file on vbr to old before copying the new one                                    
                                            robocopy.exe $SourceFolder \\$VBRNameGlobal\$VBRDestination\ $LinuxPRGP01 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr
                                            cls
                                            ################rescans protection group#####################################################################################################################################################################################################################################################################################################################
                                                            
                                            $PathVBRRToCopFilePS1 = 'V$\Inventory\Physical-Clients-CSV'
                                            $FileRescanLinuxPRGP01PS1 = 'ReScanLinuxPRGP04NonProdED.ps1'
                                            $FullPathRescanFilePS1 = 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\ReScanProtectionGroups\'
                                            $FullPathRescanFilePS1VBR = 'V:\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP04NonProdED.ps1'  
                                                                        
                                            robocopy.exe $FullPathRescanFilePS1 \\$VBRNameGlobal\$PathVBRRToCopFilePS1\ $FileRescanLinuxPRGP01PS1 /NP /W:0 /R:0 /LOG+:$LogResultsRobocopy #copies the final file with the new names to the vbr                                                                                                           
                                            cls
                                            $filelocationname = 'powershell.exe /c V:\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP04NonProdED.ps1'
                                            $global:WMIResult = ([WMICLASS]"\\$VBRNameGlobal\ROOT\CIMV2:win32_process").Create($filelocationname) #ejecuta el ReScanWindowsPRGP01 para actualizar los grupos con el rescan
                                            #e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\.\PsExec64.exe \\$VBRNameGlobal -u UsernameGlobal -p $PasswordGlobal /accepteula -h /s cmd /c powershell.exe -ExecutionPolicy Bypass -file 'V:\Inventory\Physical-Clients-CSV\ReScanWindowsPRGP01.ps1' 2> $LogNull este lo pongo en comentarions porque vy a usar wmiclass
                                            cls
                                            ################END rescans protection group###########################################################################################################################################################################################################################################################################################################################################################################################################################################################################

                                            if ($WMIResult.ReturnValue -eq 0) #revisar el resultado de $WMIResult.ReturnValue si es cero todo perfecto
                                            {                                                                                
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " The server(s) Enrolled - listed below." -ForegroundColor White;                                                                                                                                                                                                                        
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $ServersList.Trim().ToLower() | Format-List -Property *                                                                        
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Linux-PRGP04-NonProd-ED.csv.old -Recurse #removes it form the VBR server                                                                                                
                                                                                                
                                                        $ServersList = $ServersList.Trim().ToLower() | sort -unique
                                                        $VBRShortname = $VBRNameGlobal.split('.')[0]                                                                                                
                                                        foreach ($Servername in $ServersList)
                                                        {                                                                                
                                                                    [pscustomobject]@{ Username = $UsernameGlobal ; Server = $Servername ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Linux-PRGP04-NonProd-ED' ; Status = 'Enroll - Succeeded' ; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                        } #fin foreach to update logs                                                                                                 
                                                                                                
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                                        
                                                        RemoveLocalFilesLinuxEDNonProd #removes all the local files temporarily used
                                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                                        PAUSE
                                                        EXIT                                        
                                            } #fin if ($WMIResult.ReturnValue -eq 0) osea si corrieo el rescan bien
                                            else
                                            {
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\Linux-PRGP04-NonProd-ED.csv.old -Recurse #removes it form the VBR server
                                                        Remove-Item \\$VBRNameGlobal\V$\Inventory\Physical-Clients-CSV\ReScanLinuxPRGP04NonProdED.ps1 -Recurse #removes it form the VBR server                                                                                                                                        
                                                        #Disconnects
                                                        Start-Sleep -s 1                                        
                                                        NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                                        
                                                        cls
                                                        WRITE-HOST $WMIResult.ReturnValue "Error! " -ForegroundColor Red -NoNewline; WRITE-HOST "There is an issue." -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                                                        
                                                        Start-Sleep -S 10
                                                        RemoveLocalFilesLinuxEDNonProd #removes all the local files temporarily used
                                                        EXIT
                                            } #fin else $WMIResult.ReturnValue no fue igual a 0 hubo algun error

                                            ########################################################################################################################################################################################################################################################

                                } #fin if ($ServerCount1 -le 500) #PRGP01
                                else #csv tiene el maximo de servers
                                {
                                        cls
                                        WRITE-HOST "Backup Job Full! " -ForegroundColor Red -NoNewline; WRITE-HOST "It has reached the maximum number of servers inside a group" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " This session will close in 10 seconds." -ForegroundColor Red;                            
                                        $VBRShortname = $VBRNameGlobal.split('.')[0]
                                        [pscustomobject]@{ Username = $UsernameGlobal ; Server = "" ; Veeam_Environment = $VBRShortname ; Protection_Group = 'Linux-PRGP04-NonProd-ED' ; Status = 'Failed: Backup Job Full!'; Date = $DT ; Code = $WMIResult.ReturnValue } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation                            
                                        LogsSecondaryCopy #copies a secondary version of the logs to a different location
                                        Start-Sleep -S 10
                                        EXIT
                                } #fin else csv tiene maximo de servers                       
                                                                                    
                    } # fin if (($LASTEXITCODEGlobal -eq 0)) #si entró y copió porque si tiene acceso
                    else
                    {                       
                            cls
                            WRITE-HOST "Application didn't run. This session will close in 10 seconds" -ForegroundColor Red
                            Start-Sleep -S 10
                            EXIT                        
                    } #fin else el net connect dio un error (($LASTEXITCODEGlobal -eq 0)) resultado NO es Cero

    } #fin else # "The File is NOT empty"
} #fin function AddLinuxPhysicalEDNonprod


#####################################################################################################################################################
#####################################################################################################################################################


################Un Enroll Section############################################################
#####################################################################################################################################################
#####################################################################################################################################################

Function DeleteServerFromProtectionGroup ($VBRName)
{

        If ( ((Get-ChildItem -Force 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List') -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt'.Trim().ToLower()))) ) #checks the folder is not empty and that the servers file is not empty
        {
                cls
                WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
                PAUSE    
        } #fin if DE SI SE ENCUENTRA VACIO CARPETA Y FILES

        else # "The SERVERS File is NOT empty"
        {
                $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                $ServersList = $ServersList.Trim().ToLower() | Sort-Object -Unique #trim leading and trailing spaces, lowers, sorts and removes duplicates
                $PathVBRFileCSV = 'V$\Inventory\Physical-Clients-CSV'    
                $File_Extension = "*.csv"
                $Newfile_name = "NewFile.csv"                    
                $Newfile_nameMatches = "NewFileMatches.txt"
                $VBRFolderLocation = "\\" + $VBRNameGlobal + "\" + $PathVBRFileCSV                
                $NewFileCompletePathCSVFile = "\\" + $VBRNameGlobal + "\" + $PathVBRFileCSV + "\" + $Newfile_name # Source Path for the new file name
                $NewFileCompletePathTXTFileMatches = "e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\$Newfile_nameMatches" # Source Path for the new file name to group the servers that were added/removed matched names
                $FolderLocationofCSVs = "\\" + $VBRNameGlobal + "\" + $PathVBRFileCSV + "\" + $File_Extension # folder location of the files with extension .csv
                $Serverfound = @()

                NET USE \\$VBRNameGlobal\V$ /USER:$UsernameGlobal $PasswordGlobal #connects to validate user and password
                if ($LASTEXITCODEGlobal -eq 0) #si el resultado de net use es cero significa que SI entró 
                {

                            #########################################################SECCION PARA BUSCAR Y capturar en cuales csvs se encuentran los servidores y actualizar el log#############################################################################################
							#####################################################################################################################################################################################################################################################

                            foreach ($ServernameMatch in $ServersList) # ciclo para lo que tenga la lista de servers buscarlos y capturar los csv en los que se encuentra
                            {    
                                        New-Item -ItemType file $LogMatchedFiles -force > $LogNull
                                        New-Item -ItemType file $MatchedNamesNoLines -force > $LogNull                                        
                                        Get-ChildItem -Path $FolderLocationofCSVs | Select-String -Pattern ^$ServernameMatch$ -list | Format-Table Filename >> $LogMatchedFiles #exact match ^$ para solo devolver el filename agregar -list | Format-Table Filename osino devuelve todo el path    
                                        Get-Content $LogMatchedFiles | Select-Object -Skip 3 | ft -hidetableheaders | Where {$_ -ne $null} >> $MatchedNamesNoLines  #se salta las primeras 3 filas para no incluir la primera fila en blanco, filename y -----
                                        $Matches = Get-Content $MatchedNamesNoLines | Where {$_ -ne $null}   # no captura lineas en blanco              

                                        if ($Matches -ne $null) #NO está vacío
                                        {
                                                        foreach ($file_nameMatch in $Matches) #ciclo para asigna lo que capturo en matches y pasarlos a filname
                                                        {
                                                                    $file_nameNoExTMatch = $file_nameMatch -replace "\.[^\.]+$"   #This is another way to remove extension .csv from filename
                                                                    if ( $file_nameMatch.trim() -ne "Filename" -or $file_nameMatch.Trim() -ne "--------" ) # no es ni Filename.Trim() ni --------.trim()
                                                                    {     
                                                                            if ([string]::IsNullOrWhiteSpace($file_nameNoExTMatch) ) #se encuentra vacio
                                                                            {        
                                                                                    cls
                                                                                    #echo "se encuentra vacio"
                                                                            } #fin if ([string]::IsNullOrWhiteSpace($file_nameNoExT) ) #se encuentra vacio
                                                                            
                                                                            else #si tiene nombre de filenameNoExt y actualiza logs
                                                                            {
                                                                                        $VBRShortname = $VBRNameGlobal.split('.')[0]
                                                                                        [pscustomobject]@{ Username = $UsernameGlobal ; Server = $ServernameMatch ; Veeam_Environment = $VBRShortname ; Protection_Group = $file_nameNoExTMatch ; Status = 'Un-Enroll - Succeeded'; Date = $DT ; Code = $LASTEXITCODE } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                                                                        #echo $file_nameNoExT $ServernameMatch
                                                                                        $Serverfound+= $ServernameMatch #accumulates servers found to display them at the end of the process                                                      
                                                                            } # fin else #si tiene nombre de filenameNoExt
                                                                    }  #fin if ( $file_name.trim() -ne "Filename" -or $file_name.Trim() -ne "--------" )
                                                                    
                                                                    else
                                                                    {}    
                                                        } #foreach ends ($file_name in $Matches) #ciclo para asigna lo que capturo en matches y pasarlos a filname
                                        }  #fin if ($Matches -ne $null) #NO está vacío
                                        
                                        else #SI está vacio
                                        {
                                                cls
                                                #Write-Host "no hay matches"        
                                        }  #fin else #SI está vacio
                          } #fin foreach # ciclo para lo que tenga la lista de servers buscarlos y capturar los csv en los que se encuentra


                            #####################################################################################################################################################################################################################################################
                            #####################################################################################################################################################################################################################################################
                            
                            
                            ###################################This cycle loops and checks all the csv files protection groups#########################################################
							#########################################################SECCION PARA BUSCAR Y BORRAR#############################################################################################################################################################
							#####################################################################################################################################################################################################################################################
		
                            $CSVFilesinFolder = (Get-ChildItem $FolderLocationofCSVs).Name    #brings a list of all the files with extensions .csv

                            foreach($item in $CSVFilesinFolder)
                            {                                       
                                            $file_name = $item                                            
                                            $file_nameNoExT = [System.IO.Path]::GetFileNameWithoutExtension($file_name)      #$file_nameNoExT = $file_name -replace "\.[^\.]+$" #This is another way to remove extension from files
                                            $global:CompletePathCSVFile = "\\" + $VBRNameGlobal + "\" + $PathVBRFileCSV + "\" + $file_name # Source Path
                                            If ( ((Get-ChildItem -Force $VBRFolderLocation) -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content $CompletePathCSVFile.Trim().ToLower()))) ) #checks that the csv file is empty and the folder where the vbr csv files are is empty
                                            {
                                                    cls
                                                   # WRITE-HOST "Error! $file_name " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
                                                   # PAUSE        
                                            } #cierra if de If ( ((Get-ChildItem -Force $VBRFolderLocation) -eq $Null) -Or ([string]::IsNullOrWhiteSpace((Get-Content $CompletePathCSVFile.Trim().ToLower()))) )entonces pasa al siguiente

                                             else # "The File is NOT empty"
                                            {
                                                        
																$file_name = $item                                                                
                                                                New-Item -ItemType file $NewFileCompletePathCSVFile -force > $LogNull #re-creates an empty clean $NewFileCompletePathCSVFile                                    
                                                                                                
                                                                $global:ServersList = Get-Content 'e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt' | Where-Object { $_.Trim() -ne '' } #removes any empty lines or tabs
                                                                $ServersList = $ServersList.Trim().ToLower() | SORT | Get-Unique
                                                                $CSVProtectionGRP = Get-Content ("\\" + $VBRNameGlobal + "\" + $PathVBRFileCSV + "\" + $file_name) | Where-Object { $_.Trim() -ne '' }  #removes any empty lines or tabs
                                                                $CSVProtectionGRP = $CSVProtectionGRP.Trim().ToLower() | SORT | Get-Unique
                                                                                                                                
                                                                $CSVProtectionGRP| where { $ServersList -notcontains $_ }| Set-Content $NewFileCompletePathCSVFile #compara que en la lista de servers no haya alguno que exista en el csv y el resultado final lo agrega a nuevo file
                                                                                                               
                                                                Remove-Item \\$VBRNameGlobal\$PathVBRFileCSV\$file_name -Recurse #removes the previous csv before it renames it to the original name it form the VBR server
                                                                Rename-Item \\$VBRNameGlobal\$PathVBRFileCSV\$Newfile_name \\$VBRNameGlobal\$PathVBRFileCSV\$file_name  #renames csv file on vbr FROM nEW TO THE ORIGINAL CSV NAME
    
                                                                #########################Strip Empty Lines End of File##############################################################################################################################################################################################################################################
                                                                $global:StripFileIn = (Get-Content -Path \\$VBRNameGlobal\$PathVBRFileCSV\$file_name -Raw) #This will only strip the empty lines from the end of the file           
                                                                $global:Newtext = $StripFileIn -replace "(?s)`r`n\s*$" #This will only strip the empty lines from the end of the file                                    
                                                                [System.IO.File]::WriteAllText("\\" + $VBRNameGlobal + "\" + $PathVBRFileCSV + "\" + $file_name, $Newtext)   #este metodo evita que al final del archivo quede una linea en blanco         
                                                                ####################################################################################################################################################################################################                                                                                                                                                                           
                                           } #cierra else "The File is NOT empty"
                            } #cierra foreach($item in $CSVFilesinFolder)
                            if ([string]::IsNullOrWhiteSpace($Serverfound) ) #se encuentra vacio
                            { #se encuentra vacio no hace nada
                                    cls
                                    WRITE-HOST "Warning: " -ForegroundColor White -NoNewline; WRITE-HOST "NO server(s) found." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " Below list of the server(s) - NOT being backed up." -ForegroundColor White;                                            
                                    echo $ServersList | sort -unique  #despliega la lista de servers que no fueron found o sea no se encuentra en Bar                                      
                                    $VBRShortname = $VBRNameGlobal.split('.')[0]
                                    foreach ($ServerNotFound in $ServersList)
                                    {
                                            [pscustomobject]@{ Username = $UsernameGlobal ; Server = $ServerNotFound ; Veeam_Environment = $VBRShortname ; Protection_Group = "" ; Status = 'Warning: NOT being backed up'; Date = $DT ; Code = $LASTEXITCODE } | Export-Csv -Path  $CompleteLogAuditCSVPathFile -Append -NoTypeInformation
                                    } #fin foreach($ServerNotFound in $ServersList)
                            } #cierra if se encuentra vacio no hace nada                            
                            else # $Serverfound está lleno y los despliega
                            {                                    
                                    cls
                                    WRITE-HOST "Completed " -ForegroundColor White -NoNewline; WRITE-HOST "The Un-Enroll process has been successfully completed." -ForegroundColor Green -BackgroundColor Black -NoNewline; WRITE-HOST " Below list of the server(s) Un-enrolled." -ForegroundColor White;                                            
                                    echo $Serverfound | Sort-Object -Unique                                    
                                    Remove-Item $global:LogMatchedFiles -Recurse         #removes it locally        
                                    Remove-Item $global:MatchedNamesNoLines -Recurse     #removes it locally                                    
                                    $Serverfound = $Null  #cleans the arrays
                            } #cierra else Serverfound está lleno y los despliega

                } # cierra if net use es cero y si entro bien                
                else # no es 0 LASTEXITCODEGlobal resultado de Net use y fue error
                { #Tuvo error no hace nada
                    Start-Sleep -S 10

                }# cierra else no es 0 LASTEXITCODEGlobal resultado de Net use y fue error

            New-Item -ItemType file e:\Script-Add-Remove-Agents-To-VeeamProtectionGroup\Enroll_Unenroll-Servers-List\servers.txt -force > $LogNull   #creates a new file to clear the contents form servers list locally                                                        
            NET USE /DELETE \\$VBRNameGlobal\v$ > $LogNull #disconnects                                            
            Remove-Item $global:LogNull -Recurse                 #removes it locally            
            Remove-Item $global:Log2 -Recurse
            LogsSecondaryCopy #copies a secondary version of the logs to a different location
            PAUSE
            EXIT                                                        
        }# fin del else del SERVERS file not empty
                            
} #fin funcion delete



#####################################################################################################################################################
#####################################################################################################################################################






#####################################################################################################################################################
#####################################################################################################################################################


#####################################################################################################################################################
#####################################################################################################################################################
#Reports Sections
#####################################################################################################################################################
#####################################################################################################################################################

function PopulateVBRList #generates a list to read from file
{
      
    
    [System.Collections.ArrayList]$ArrayVBRServerPopulateList = 
    @("ch2svbr100.amr.corp.intel.com",
    "hf2svbr100.amr.corp.intel.com",
    "ra2svbr100.amr.corp.intel.com",
    "fm1svbr100.amr.corp.intel.com",    
    "fm7svbr100.amr.corp.intel.com",    
    "bgssvbr100.gar.corp.intel.com",        
    "shz1svbr100.ccr.corp.intel.com",
    "hf2svbr200.amr.corp.intel.com")
    #"SC8SVBR100.amr.corp.intel.com",    

    $ArrayVBRServerPopulateList | Out-File -FilePath ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:VBRListFilename)
    #################Remove Empty LInes############################################################################
    $file = ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:VBRListFilename)
    (gc $file) | ? {$_.trim() -ne "" } | set-content $file
    $content = [System.IO.File]::ReadAllText($file)
    $content = $content.Trim()
    [System.IO.File]::WriteAllText($file, $content)
###############################################################################################################
}

function PrepareViewBackupStatus
{       
        
        Param
        (                
                [ValidateNotNullOrEmpty()] #it will fail if empty
                [string[]] #array type instead of string
                $VeeamStringListFQDN #array name
        )
        Begin
        {       
             #variables
             $global:CurrentDateTime = $global:CurrentDateTime = (Get-Date -Format MMddyyyy_HHmmss)
             
        }
        Process
        {
        
                #Write-Host "`$arg1 value HAS BEEN ASSIGNED: $VeeamFQDN"        
                if (Test-Path ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -PathType leaf) #si existe el file
                {
                        #################Trim section################################################################################
                        $LoadfileSvrs1 = GC ("\\"+ $ServerExecuteProgram + "\" + $global:ServersTXTFull) #variable para validar que tiene info
                        if (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                        {
                                $LoadfileSvrs1 = $LoadfileSvrs1.Trim().ToLower()
                        } # fin (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                        $LoadfileSvrs1 > ("\\"+ $ServerExecuteProgram + "\" + $global:ServersTXTFull) #variable para validar que tiene info
                        ###############################################################################################################

                        #################Remove Empty LInes############################################################################
                        $fileSvrs1 = ("\\"+ $ServerExecuteProgram + "\" + $global:ServersTXTFull) #variable para validar que tiene info
                        (gc $fileSvrs1) | ? {$_.trim() -ne "" } | set-content $fileSvrs1
                        $contentSvrs1 = [System.IO.File]::ReadAllText($fileSvrs1)
                        $contentSvrs1 = $contentSvrs1.Trim()                                                                          
                        [System.IO.File]::WriteAllText($fileSvrs1, $contentSvrs1)
                        ###############################################################################################################                                                                            
                        $CheckifContainData = Get-Content ("\\"+ $ServerExecuteProgram + "\" + $global:ServersTXTFull) #variable para validar que tiene info                        
                                         
                        if (![string]::IsNullOrWhiteSpace($CheckifContainData)) #revisa que no se encuentre !NO vacio serverstxt
                        {
                            #$CheckifContainData = $CheckifContainData.Trim().ToLower()
                            $CheckifContainData > ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime
                            New-Item -ItemType file ("\\" + $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -force > $LogNull   #creates a new file to clear the contents from servers list locally

                            foreach ($VeeamServer in $VeeamStringListFQDN) #needs to use .Clone as the original arraya won't allow readings in foreach       
                            {
                                
                                if (![string]::IsNullOrWhiteSpace($VeeamServer)) #revisa que no se encuentre !NO vacio serverstxt
                                {
                                            ###Section to capture shortname and fqdn and suffix########################
                                            $FQDNVeeamServer = $VeeamServer #the parameter is sent as long name FQDN
                                            $VeeamServer = $FQDNVeeamServer.Split('.')[0] #captures just the shortname / hostname
                                            $DomainSuffix = $FQDNVeeamServer -replace "$VeeamServer.","" # captures just the suffix
                                            ############################################################################
                                        
                                            md ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime) -Force > $LogNull # creates BackupStatus folder in the remote server
                                            md ("\\" + $global:ServerExecuteProgram + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime) -Force > $LogNull #creates ReportCSV/Currentdatetime folder localmente
                                            
                                            $CheckifContainDataNewServersTXTFull = Get-Content ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime

                                            if (![string]::IsNullOrWhiteSpace($CheckifContainDataNewServersTXTFull)) #revisa que no se encuentre !NO vacio serverstxt
                                            {

                                                    Copy-Item ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt") -Destination ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime + "\") #copy the computer list to search on the remote server-Destination VeeamServer
                                    
                                                    ########Connection PS Seesion#############################################################################################################################
                                                    $Session = New-PSSession -ComputerName $FQDNVeeamServer -Credential $global:AMRCredential -ConfigurationName microsoft.powershell #login with secured json credentials for amr\sys
                                                    #$Session = New-PSSession -ComputerName $FQDNVeeamServer #without creds
                    
                                                    if ($Session.State -eq "Closed") #"Remote Script Errored out"
                                                    {
                                                            #"New-Pssession Errored out and didn't connect"
                                                    } #ifn if session closed
                                                    else
                                                    {
                                                        try
                                                        {       
                                                                Invoke-Command -ComputerName $FQDNVeeamServer -ScriptBlock ${function:RemoteViewBackupStatus} -ArgumentList $global:CurrentDateTime #esta solucion es para llamar directamente una funcion que se encuentre dentro de este mismo ps1 y lo ejecuta en la pc remota
                                                                #$scriptContent = Get-Content (c:\viewbackupstatus.ps1) -Raw                                                                            
                                                                #invoke-command -ComputerName $VeeamServer -ScriptBlock ([scriptblock]::Create($scriptContent)) -ArgumentList $global:CurrentDateTime
                                                                #Invoke-Command -FilePath ($SourceLocationBackupStatus + "\" + $PS1name) -ComputerName $VeeamServer #excecutes the file stored on barjat on the VeeamServer #esta solucion ejecuta en la PC remota el ps1 directamente pero tiene que estar guardado local                                    

                                                                if (Test-Path ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime) -PathType Container) #Container is for directory and -Leaf for files
                                                                {
                                                                        if (Test-Path ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime + "\" + $VeeamServer + "_" + $global:CSVFileName + $global:CurrentDateTime + ".csv") -PathType Leaf) #Container is for directory and -Leaf for files
                                                                        {
                                                                                #existe remote csv y txt server files
                                                                                Copy-Item ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime + "\" + $VeeamServer + "_" + $global:CSVFileName + $global:CurrentDateTime + ".csv") -Destination ("\\" + $global:ServerLogName + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime + "\") #copia el csv desde veeam server a local
                                                                                Copy-Item ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt") -Destination ("\\" + $global:ServerLogName + "\" + $global:PathTXTFolder + "\") #copia el csv desde veeam server a local
                                                                        } # fin if (Test-Path ($BackupStatusRemoteFolder) -PathType leaf)                                                           
                                                                        Remove-Item ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime) -Force  -Recurse -ErrorAction SilentlyContinue #removes folder from remote server vbr
                                                                } # fin if Test-Path ("\\" + $VeeamServer + "\" + $global:RemoteBackupStatusPath) -PathType Container
                                                    
                                                        } #fin try
                                                        catch #if there is an error return 1 with invoke-command
                                                        {
                                                                return 1 > $LogNull;      
                                                        } # fin catch                                
                                                        return 2 > $LogNull; #si devuele dos el invoke command corrio bien todo salio bien
                                                        Remove-PSSession -Session $Session #remueve session
                                                    } #fin else ($session.State no fue "Closed") osea se State encuentra Opened
                                            } # fin if (![string]::IsNullOrWhiteSpace($CheckifContainData)) #se encuentra lleno
                                            else
                                            {
                                                    break #use to immediately exit Foreach, For, While, Do, or Switch statements.
                                            } # fin else se encuentra vacio IsNullOrWhiteSpace($CheckifContainDataNewServersTXTFull)
                                } # fin if de veeamserver sring vacio
                            } # fin foreach ($VeeamServer in $VeeamArrayListFQDN.Clone())                    
        } # fin if se encuenta lleno !NO Vacio ([string]::IsNullOrWhiteSpace($CheckifContainData)
        else
        {
                cls
                WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;        
        } #fin else servers.txt se encuentra vacio

}# fin if Test-Path ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull)

else
{
        cls
        WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;        
} # servers.txt no existe        
                        
    } #fin process
    End
    {
                CombineCSVs
	            GenerateCSVtoHTML
    } # fin end
        
} # fin function


function PrepareViewBackupStatusMultiple
{       
        
        Param
        (                
                [ValidateNotNullOrEmpty()] #it will fail if empty
                [string[]] #array type instead of string
                $VeeamStringListFQDN #array name
        )
        Begin
        {       
                #global time needs to be refreshed outside this loop
        }
        Process
        {

                            foreach ($VeeamServer in $VeeamStringListFQDN) #needs to use .Clone as the original arraya won't allow readings in foreach       
                            {
                                
                                if (![string]::IsNullOrWhiteSpace($VeeamServer)) #revisa que no se encuentre !NO vacio serverstxt
                                {
                                            ###Section to capture shortname and fqdn and suffix########################
                                            $FQDNVeeamServer = $VeeamServer #the parameter is sent as long name FQDN
                                            $VeeamServer = $FQDNVeeamServer.Split('.')[0] #captures just the shortname / hostname
                                            $DomainSuffix = $FQDNVeeamServer -replace "$VeeamServer.","" # captures just the suffix
                                            ############################################################################
                                        
                                            md ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime) -Force > $LogNull # creates BackupStatus folder in the remote server
                                            md ("\\" + $global:ServerExecuteProgram + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime) -Force > $LogNull #creates ReportCSV/Currentdatetime folder localmente

                                            #################Trim section################################################################################
                                            $Loadfile = GC ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime
                                            if (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                                            {
                                                    $Loadfile = $Loadfile.Trim().ToLower()
                                            } # FIN if (![string]::IsNullOrWhiteSpace($Loadfile))
                                            $Loadfile > ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime
                                            ###############################################################################################################

                                            #################Remove Empty LInes############################################################################
                                            $file = ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime
                                            (gc $file) | ? {$_.trim() -ne "" } | set-content $file
                                            $content = [System.IO.File]::ReadAllText($file)
                                            $content = $content.Trim()
                                            [System.IO.File]::WriteAllText($file, $content)
                                            ###############################################################################################################
                                            $CheckifContainDataNewServersTXTFull = Get-Content ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime

                                            if (![string]::IsNullOrWhiteSpace($CheckifContainDataNewServersTXTFull)) #revisa que no se encuentre !NO vacio serverstxt
                                            {

                                                    Copy-Item ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt") -Destination ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime + "\") #copy the computer list to search on the remote server-Destination VeeamServer
                                    
                                                    ########Connection PS Seesion#############################################################################################################################
                                                    $Session = New-PSSession -ComputerName $FQDNVeeamServer -Credential $global:AMRCredential -ConfigurationName microsoft.powershell #login with secured json credentials for amr\sys
                                                    #$Session = New-PSSession -ComputerName $FQDNVeeamServer #without creds
                    
                                                    if ($Session.State -eq "Closed") #"Remote Script Errored out"
                                                    {
                                                            #"New-Pssession Errored out and didn't connect"
                                                    } #ifn if session closed
                                                    else
                                                    {
                                                        try
                                                        {       
                                                                Invoke-Command -ComputerName $FQDNVeeamServer -ScriptBlock ${function:RemoteViewBackupStatus} -ArgumentList $global:CurrentDateTime #esta solucion es para llamar directamente una funcion que se encuentre dentro de este mismo ps1 y lo ejecuta en la pc remota
                                                                #$scriptContent = Get-Content (c:\viewbackupstatus.ps1) -Raw                                                                            
                                                                #invoke-command -ComputerName $VeeamServer -ScriptBlock ([scriptblock]::Create($scriptContent)) -ArgumentList $global:CurrentDateTime
                                                                #Invoke-Command -FilePath ($SourceLocationBackupStatus + "\" + $PS1name) -ComputerName $VeeamServer #excecutes the file stored on barjat on the VeeamServer #esta solucion ejecuta en la PC remota el ps1 directamente pero tiene que estar guardado local                                    

                                                                if (Test-Path ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime) -PathType Container) #Container is for directory and -Leaf for files
                                                                {
                                                                        if (Test-Path ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime + "\" + $VeeamServer + "_" + $global:CSVFileName + $global:CurrentDateTime + ".csv") -PathType Leaf) #Container is for directory and -Leaf for files
                                                                        {
                                                                                #existe remote csv y txt server files
                                                                                Copy-Item ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime + "\" + $VeeamServer + "_" + $global:CSVFileName + $global:CurrentDateTime + ".csv") -Destination ("\\" + $global:ServerLogName + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime + "\") #copia el csv desde veeam server a local
                                                                                Copy-Item ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt") -Destination ("\\" + $global:ServerLogName + "\" + $global:PathTXTFolder + "\") #copia el TXT con los nombres de los servers desde veeam server a local
                                                                        } # fin if (Test-Path ($BackupStatusRemoteFolder) -PathType leaf)                                                           
                                                                        Remove-Item ("\\" + $FQDNVeeamServer + "\" + $global:RemoteBackupStatusPath + $global:CurrentDateTime) -Force  -Recurse -ErrorAction SilentlyContinue #removes folder from remote server vbr
                                                                } # fin if Test-Path ("\\" + $VeeamServer + "\" + $global:RemoteBackupStatusPath) -PathType Container
                                                    
                                                        } #fin try
                                                        catch #if there is an error return 1 with invoke-command
                                                        {
                                                                return 1 > $LogNull;      
                                                        } # fin catch                                
                                                        return 2 > $LogNull; #si devuele dos el invoke command corrio bien todo salio bien
                                                        Remove-PSSession -Session $Session #remueve session
                                                    } #fin else ($session.State no fue "Closed") osea se State encuentra Opened
                                            } # fin if (![string]::IsNullOrWhiteSpace($CheckifContainData)) #se encuentra lleno
                                           else
                                           {
                                                    BREAK #use to immediately exit Foreach, For, While, Do, or Switch statements.
                                           } # fin else se encuentra vacio IsNullOrWhiteSpace($CheckifContainDataNewServersTXTFull)
                                } # fin if de veeamserver sring vacio
                            } # fin foreach ($VeeamServer in $VeeamArrayListFQDN.Clone())

        } #fin process
        End
        {
               
        } # fin end
        
} # fin function PrepareViewBackupStatusMultiple



######################################################################################################################################################
####This Function RemoteViewBackupStatus is called from the Pre function and will run on the remote server
######################################################################################################################################################

function RemoteViewBackupStatus
{
       
        Param
        (                
                [ValidateNotNullOrEmpty()] #it will fail if empty
                [string[]] #string type instead of string
                $RemoteCurrentDateTime #string name
               
        )

                ### Local Variables###
                $today = (Get-Date -Format g) #8/16/2019 5:48 PM
                $global:ServerToCopyLogs = "vmbar01.amr.corp.intel.com"
                $RemoteCurrentDateTime > "c:\Temp\BackupStatus_$RemoteCurrentDateTime\CurrentTimeDate.txt"
                $RemoteCurrentDateTime = GC "c:\Temp\BackupStatus_$RemoteCurrentDateTime\CurrentTimeDate.txt"
                $vbrServer = $env:COMPUTERNAME #captures the hostname/shortname
                $vbrServerFQDN = [System.Net.Dns]::GetHostByName($vbrServer).HostName #gets the FQDN from the shortname
                $global:RemoteBackupStatusPath = "c$\temp"
                $global:RemoteBackupStatusFolderName = ("BackupStatus_")
                $global:NewServerList = "servers"
                $global:PathTXTFolder = "e$\Script-Add-Remove-Agents-To-VeeamProtectionGroup\BackupStatus\TXT" #folder path location of the vbr list and any other txt file also the one gets created from servers.txt                


                ###region Connect###
                #=========================================================================================================================================================                 
                # Load Veeam Snapin###
                If (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) 
                {
                        If (!(Add-PSSnapin -PassThru VeeamPSSnapIn)) 
                        {
                                Write-Error "Unable to load Veeam snapin" -ForegroundColor Red
                                Exit
                        } #fin If (!(Add-PSSnapin -PassThru VeeamPSSnapIn)) 
                } #If (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) 

                ###Connect to VBR server###
                $OpenConnection = (Get-VBRServerSession).Server
                If ($OpenConnection -ne $vbrServer)
                {
                        Disconnect-VBRServer
                        Try 
                        {
                                Connect-VBRServer -server $vbrServer -ErrorAction Stop
                        } # fin Try
                        Catch 
                        {
                                Write-Host "Unable to connect to VBR server - $vbrServer" -ForegroundColor Red
                                exit
                        } # fin catch
                } # fin if ($OpenConnection -ne $vbrServerFQDN)
                #endregion connect

#=========================================================================================================================================================
#Section for Agent Level Backup Status
#=========================================================================================================================================================

                if (Test-Path ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime +  "\" + $global:NewServerList + "_" + $RemoteCurrentDateTime + ".txt") -PathType leaf) # Leaf if for files and Containers for folders check if the serverTXT exists on the remote servers
                {
                        $RemoteServerList = Get-Content ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime +  "\" + $global:NewServerList + "_" + $RemoteCurrentDateTime + ".txt")
                        [string[]]$ArrayRemoteServerList = @($RemoteServerList)                      

                        foreach ($ComputerName in $ArrayRemoteServerList) ###foreach ($ComputerName in [array]$ArrayList# You cannot remove objects of an array while iterating it with the foreach statement.
                        {                                
                                $vbrrestore = get-vbrbackup | where JobType -eq 'EpAgentManagement' | Get-VBRRestorePoint | where name -eq $ComputerName |  sort name,CreationTime | select name,creationtime, @{n='Days since last success'; e={(New-TimeSpan -Start $_.creationtime -End $today).days}} | group name
                                $RestorePoints = $vbrrestore.count
                                $vbrrestore | foreach {$_.group | select -last 1} | ft -AutoSize > ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + "\" + $vbrServer + "_" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + ".txt")
                                $CheckBackupStatusTXT = GC ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + "\" + $vbrServer + "_" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + ".txt")

                                if (![string]::IsNullOrWhiteSpace($CheckBackupStatusTXT)) #checks the vrbRestore results TXT file is NOT empty y hay que aplicar parsing
                                {

                                        $ImportSkip3Lines = Get-Content ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + "\" + $vbrServer + "_" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + ".txt") | Select -Skip 3 #se salta 3 lineas porque el contenido tiene header y ----------
                                        $JustOneWhiteSpace = $ImportSkip3Lines.Trim() -replace '\s+',' ' -split '\s'  #remueve los espacios en cada palabra en una misma fila del texto
                                        $Computer = $JustOneWhiteSpace[0]
                                        $datecreated = $JustOneWhiteSpace[1]
                                        $timecreated = $JustOneWhiteSpace[2]
                                        $AMPMcreated = $JustOneWhiteSpace[3]
                                        $DaysSinceLastBackup = $JustOneWhiteSpace[4]
                                        $FullDateTimeMostRecentBackup = -join ($datecreated, " ", $timecreated, " ", $AMPMcreated)
                                        
                                        $CSVBackupStatus = New-Object PSObject #crea objeto para darle formato al export en csv
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name “Server Name” -Value $Computer
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Date: Most Recent Backup" -Value $FullDateTimeMostRecentBackup
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Days since the last successful backup" -Value $DaysSinceLastBackup
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Total Restore Points" -Value $RestorePoints
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Backup Method" -Value "Agent Level"
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Veeam_Environment" -Value $env:COMPUTERNAME

                                        if ([string]::IsNullOrWhiteSpace($CSVBackupStatus)) #checks the object $CSVBackupStatus vrbRestore results is empty y se encuentra vacio no hace nada
                                        {                                 
                                        } #fin if vacio no hace nada
                                        else # lleno
                                        {            
                                                $CSVBackupStatus | export-csv -path ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + "\" + $vbrServer + "_" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + ".csv") -NoTypeInformation -Force -Append #exports the contents from object $CSVBackupStatus no type information removes #TYPE System.Management.Automation.PSCustomObject                                                
                                                $ArrayRemoteServerList = $ArrayRemoteServerList -notmatch $ComputerName # busca la palabra y borra (Get-Content $file) -notmatch $VirtualName | Out-File $file # busca la palabra y borra
                                        } #fin else se encuentra lleno
                                } #fin if ![string]::IsNullOrWhiteSpace($CheckBackupStatusTXT)) # vrbRestore has data
                                else
                                {
                                } # fin else el remote vbrrestore results $TxtFile se encuentra vacio
                        }# fin foreach ($ComputerName in $ArrayList.Clone()) Agents
                } #fin if ![string]::IsNullOrWhiteSpace($CheckBackupStatusTXT)) # vrbRestore has data

#=========================================================================================================================================================
#=========================================================================================================================================================


#=========================================================================================================================================================
#Section for Image Level Backup Status
#=========================================================================================================================================================


                if ($ArrayRemoteServerList.Count -ne 0) # array is empty procede actualizar el server txt
                {
                       
                        foreach ($VirtualName in $ArrayRemoteServerList) ###foreach ($ComputerName in [array]$ArrayList# You cannot remove objects of an array while iterating it with the foreach statement.
                        {                                
                                $vbrrestore = get-vbrbackup | Get-VBRRestorePoint | where name -eq $VirtualName | sort vmname,CreationTime | select vmname, creationtime , @{n='Days since last success'; e={(New-TimeSpan -Start $_.creationtime -End $today).days}} | group vmname    
                                $RestorePoints = $vbrrestore.count
                                $vbrrestore | foreach {$_.group | select -last 1} | ft -AutoSize > ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + "\" + $vbrServer + "_" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + ".txt")
                                $CheckBackupStatusTXT = GC ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + "\" + $vbrServer + "_" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + ".txt")

                                if (![string]::IsNullOrWhiteSpace($CheckBackupStatusTXT)) #checks the vrbRestore results TXT file is NOT empty y hay que aplicar parsing
                                {

                                        $ImportSkip3Lines = Get-Content ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + "\" + $vbrServer + "_" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + ".txt") | Select -Skip 3 #se salta 3 lineas porque el contenido tiene header y ----------
                                        $JustOneWhiteSpace = $ImportSkip3Lines.Trim() -replace '\s+',' ' -split '\s'  #remueve los espacios en cada palabra en una misma fila del texto
                                        $Computer = $JustOneWhiteSpace[0]
                                        $datecreated = $JustOneWhiteSpace[1]
                                        $timecreated = $JustOneWhiteSpace[2]
                                        $AMPMcreated = $JustOneWhiteSpace[3]
                                        $DaysSinceLastBackup = $JustOneWhiteSpace[4]
                                        $FullDateTimeMostRecentBackup = -join ($datecreated, " ", $timecreated, " ", $AMPMcreated)
                                        
                                        $CSVBackupStatus = New-Object PSObject #crea objeto para darle formato al export en csv
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name “Server Name” -Value $Computer
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Date: Most Recent Backup" -Value $FullDateTimeMostRecentBackup
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Days since the last successful backup" -Value $DaysSinceLastBackup
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Total Restore Points" -Value $RestorePoints
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Backup Method" -Value "Image Level"
                                        $CSVBackupStatus | Add-Member -MemberType NoteProperty -Name "Veeam_Environment" -Value $env:COMPUTERNAME

                                        if ([string]::IsNullOrWhiteSpace($CSVBackupStatus)) #checks the object $CSVBackupStatus vrbRestore results is empty y se encuentra vacio no hace nada
                                        {                                 
                                        } #fin if vacio no hace nada
                                        else # lleno
                                        {            
                                                $CSVBackupStatus | export-csv -path ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + "\" + $vbrServer + "_" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime + ".csv") -NoTypeInformation -Force -Append #exports the contents from object $CSVBackupStatus no type information removes #TYPE System.Management.Automation.PSCustomObject
                                                # $ArrayRemoteServerList = $ArrayRemoteServerList.Replace($VirtualName,$null);
                                                # Set-Content -Path ($file) -Value (get-content -Path ($file) | Select-String -Pattern "hola" -NotMatch) #busca la palabra y borra                                                
                                                $ArrayRemoteServerList = $ArrayRemoteServerList -notmatch $VirtualName # busca la palabra y borra (Get-Content $file) -notmatch $VirtualName | Out-File $file # busca la palabra y borra
                                        } #fin else se encuentra lleno
                                } #fin if ![string]::IsNullOrWhiteSpace($CheckBackupStatusTXT)) # vrbRestore has data
                                else
                                {
                                } # fin else el remote vbrrestore results $TxtFile se encuentra vacio
                        }# fin foreach ($ComputerName in $ArrayList.Clone()) Agents
                        $ArrayRemoteServerList > ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime +  "\" + $global:NewServerList + "_" + $RemoteCurrentDateTime + ".txt") #actualiza el txt servers con los datos del array                        
                        #################Remove Empty LInes############################################################################
                        $fileremov = ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime +  "\" + $global:NewServerList + "_" + $RemoteCurrentDateTime + ".txt")
                        (gc $fileremov) | ? {$_.trim() -ne "" } | set-content $fileremov
                        $contentremov = [System.IO.File]::ReadAllText($fileremov)
                        $contentremov = $contentremov.Trim()
                        [System.IO.File]::WriteAllText($fileremov, $contentremov)
                        ###############################################################################################################
                } # fin IF si array NO está vacio 
                else
                {
                        $ArrayRemoteServerList > ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime +  "\" + $global:NewServerList + "_" + $RemoteCurrentDateTime + ".txt") #actualiza el txt servers con los datos del array
                        #################Remove Empty LInes############################################################################
                        $fileremov = ("\\" + $vbrServerFQDN  + "\" + $global:RemoteBackupStatusPath + "\" + $global:RemoteBackupStatusFolderName + $RemoteCurrentDateTime +  "\" + $global:NewServerList + "_" + $RemoteCurrentDateTime + ".txt")
                        (gc $fileremov) | ? {$_.trim() -ne "" } | set-content $fileremov
                        $contentremov = [System.IO.File]::ReadAllText($fileremov)
                        $contentremov = $contentremov.Trim()
                        [System.IO.File]::WriteAllText($fileremov, $contentremov)
                        ###############################################################################################################
                } # fin else array si está Vacio
}  #fin de la funcion view backup status remote


function CombineCSVs
{    
    #variables    
    $Title = "Final_Report_"
    $pathin = ("\\" + $global:ServerLogName + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime)
    $pathout = ("\\" + $global:ServerLogName + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime + "\" + $Title + $global:CSVFileName + $global:CurrentDateTime + ".csv")
            
            if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime + "\" + "*.csv") -PathType leaf) #check it contains csv files
            {            
                    $listToEmptylines = Get-ChildItem -Path $pathin | where-object {$_.BaseName -match $global:CurrentDateTime} | select FullName
                    foreach($filename in $listToEmptylines.FullName)
                    {
                            #################Remove Empty Lines###########################################################################################################################################                
                            (gc $filename) | ? {$_.trim() -ne "" } | set-content $filename
                            $content = [System.IO.File]::ReadAllText($filename)
                            $content = $content.Trim()
                            [System.IO.File]::WriteAllText($filename, $content)
                            ###############################################################################################################################################################################
                    } #fin foreach ($filename in $listToEmptylines.FullName)

                    ###############Now Merge all csv and create a new one FullReport####################################################################################
                    $list = Get-ChildItem -Path $pathin | where-object {$_.BaseName -match $global:CurrentDateTime} | select FullName
                    foreach($file in $list)
                    {
                            Import-Csv -Path $file.FullName | Export-Csv -Path $pathout -NoTypeInformation -Append
                    } #FIN FOREACH $FILE IN $LIST)
                    ###############################################################################################################################################################################
                    #################Remove Empty Lines from Final_Report_###########################################################################################################################################                
                    $listToEmptylinesFullReport = Get-ChildItem -Path $pathin | where-object {$_.BaseName -match $Title} | select FullName
                    foreach($filenameFullReport in $listToEmptylinesFullReport.FullName)
                    {
                            (gc $filenameFullReport) | ? {$_.trim() -ne "" } | set-content $filenameFullReport
                            $contentFinalReport = [System.IO.File]::ReadAllText($filenameFullReport)
                            $contentFinalReport = $contentFinalReport.Trim()
                            [System.IO.File]::WriteAllText($filenameFullReport, $contentFinalReport)
                    } # FIN FOREACH
                    ############################################################################################################################################################################################            
            }  # fin if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime + "\" + "*.csv") -PathType leaf) #check it contains csv files                
} # fin function Combine CSV


function GenerateCSVtoHTML
{

#=========================================================================================================================================================
#Convert Merged .csv Final Report to html css
#=========================================================================================================================================================

$css = @"
<style>
h1, h5, th { text-align: center; font-family: Segoe UI; }
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 11px; padding: 5px 20px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
"@

#variables    
$Title = "Final_Report_"

if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime + "\" + $Title + $global:CSVFileName + $global:CurrentDateTime + ".csv") -PathType leaf) # Leaf for file Container for folders
{       

        $SortUniqueCSV = Import-CSV ("\\" + $global:ServerLogName + "\" + $global:CSVReportsFolderPath + "\" + $global:CSVFileName + $global:CurrentDateTime + "\" + $Title + $global:CSVFileName + $global:CurrentDateTime + ".csv") | sort "Server Name" -Unique #importa el csv que se forma con final merged y los ordena por nombre        
        $SortUniqueCSV | ConvertTo-Html -Head $css -Body "<h1>Backup Status Report</h1>`n<h5>Generated on $(Get-Date)</h5>" | Out-File ("\\" + $global:ServerLogName + "\" + $global:HTMLReportsFolderPath + "\" + $Title + $global:HTMLFileName + $global:CurrentDateTime + ".html") # convierte el csv a css html

        if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:HTMLReportsFolderPath + "\" + $Title + $global:HTMLFileName + $global:CurrentDateTime + ".html") -PathType leaf)
        {
                start ("\\" + $global:ServerLogName + "\" + $global:HTMLReportsFolderPath + "\" + $Title + $global:HTMLFileName + $global:CurrentDateTime + ".html")
        }
} #fin if
} #fin function


########################################################################################################################################################################################################################################

#Capacity Repository and Proxy Information + Licenses
########################################################################################################################################################################################################################################


function GenerateRepoProxyReport
{       
        
        Param
        (                
                [ValidateNotNullOrEmpty()] #it will fail if empty
                [string[]] #array type instead of string
                $VeeamStringListFQDN #array name
        )
        Begin
        {       
          $global:CurrentDateTime = $global:CurrentDateTime = (Get-Date -Format MMddyyyy_HHmmss) #refreshes current date time minutes and seconds      
        }
        Process
        {

                foreach ($VeeamServer in $VeeamStringListFQDN) #string de VBRs
                {
                    if (![string]::IsNullOrWhiteSpace($VeeamServer)) #revisa que no se encuentre !NO vacio serverstxt
                    {
                                            ###Section to capture shortname and fqdn and suffix########################
                                            $FQDNVeeamServer = $VeeamServer #the parameter is sent as long name FQDN
                                            $VeeamServer = $FQDNVeeamServer.Split('.')[0] #captures just the shortname / hostname
                                            $DomainSuffix = $FQDNVeeamServer -replace "$VeeamServer.","" # captures just the suffix
                                            ############################################################################
                                            ########Connection PS Seesion#############################################################################################################################
                                            $Session = New-PSSession -ComputerName $FQDNVeeamServer -Credential $global:AMRCredential <# -ConfigurationName microsoft.powershell #> #login with secured json credentials for amr\sys
                                            #$Session = New-PSSession -ComputerName $FQDNVeeamServer #without creds
                                            if ($Session.State -eq "Closed") #"Remote Script Errored out"
                                            {
                                                    #"New-Pssession Errored out and didn't connect"
                                            } #ifn if session closed
                                            else
                                            {
                                                    try
                                                    {       
                                                            Invoke-Command -ComputerName $FQDNVeeamServer -ScriptBlock ${function:RemoteCapacityStatus} -ArgumentList $global:CurrentDateTime, $global:AMRCredential #esta solucion es para llamar directamente una funcion que se encuentre dentro de este mismo ps1 y lo ejecuta en la pc remota
                                                            #$scriptContent = Get-Content (c:\viewbackupstatus.ps1) -Raw                                                                            
                                                            #invoke-command -ComputerName $VeeamServer -ScriptBlock ([scriptblock]::Create($scriptContent)) -ArgumentList $global:CurrentDateTime
                                                            #Invoke-Command -FilePath ($SourceLocationBackupStatus + "\" + $PS1name) -ComputerName $VeeamServer #excecutes the file stored on barjat on the VeeamServer #esta solucion ejecuta en la PC remota el ps1 directamente pero tiene que estar guardado local                                                                                                                                                                                                                                    
                                                    } #fin try
                                                    catch #if there is an error return 1 with invoke-command
                                                    {
                                                            return 1 > $LogNull;      
                                                    } # fin catch                                
                                                            return 2 > $LogNull; #si devuele dos el invoke command corrio bien todo salio bien
                                                            Remove-PSSession -Session $Session #remueve session
                                          } #fin else ($session.State no fue "Closed") osea se State encuentra Opened
                    } #fin if (![string]::IsNullOrWhiteSpace($VeeamServer))
                } # fin foreach ($VeeamServer in $VeeamArrayListFQDN.Clone())                    

        } #fin process
        End
        {               
               StartHTMLCapacityReporProxy
               # CombineCSVs
	           # GenerateCSVtoHTML
        } # fin end
        
} # fin function end GenerateRepoProxyReport

function RemoteCapacityStatus
{
       
Param
(                
        [ValidateNotNullOrEmpty()] #it will fail if empty
        [string[]] #string type instead of string
        $RemoteCurrentDateTime, #string name
        $Credential = [System.Management.Automation.PSCredential]::Empty
               
)       

#region User-Variables

$RemoteCurrentDateTime > "c:\Temp\CurrentTimeDate.txt"
$RemoteCurrentDateTime = GC "c:\Temp\CurrentTimeDate.txt"

$vbrServer = $env:COMPUTERNAME #captures the hostname/shortname
$vbrServerFQDN = [System.Net.Dns]::GetHostByName($vbrServer).HostName #gets the FQDN from the shortname
$global:RemoteBackupStatusPath = "c$\temp"

#Today's local date
$TodayDate = $RemoteCurrentDateTime
$DateTime = $(Get-Date -format g)
# VBR Server (Server Name, FQDN or IP)
$vbrServer = $env:Computername
# Report Title
$BaRTitle = "IT Backup and Restore"
# Report Title
$rptTitle = "Capacity Report: Veeam Backup & Replication"
# Show VBR Server name in report header
$showVBR = $true
# HTML Report Width (Percent)
$rptWidth = 97
######################################################################################################################################################
# Location of Veeam executable (Veeam.Backup.Shell.exe)
#$veeamExePath = "c:\Program Files\Veeam\Backup and Replication\Backup\Veeam.Backup.Shell.exe"
#$veeamExePath = "V:\Veeam\Backup\Veeam.Backup.Shell.exe"
# Busca en toda el filesystem y discos: gdr -PSProvider 'FileSystem' | %{ ls -r $_.root} 2>$null | where { $_.name -eq "Veeam.Backup.Shell.exe" } | Select-Object Directory

$fileToCheckVeeamBackupShell="c:\Program Files\Veeam\Backup and Replication\Backup\Veeam.Backup.Shell.exe"
$fileToCheck2VeeamBackupShell="V:\Veeam\Backup\Veeam.Backup.Shell.exe"
if (Test-Path $fileToCheckVeeamBackupShell -PathType leaf) # LEAF IS FOR FILES
{
        $veeamExePath=$fileToCheckVeeamBackupShell
} # FIN IF
elseif ((Test-Path $fileToCheck2VeeamBackupShell -PathType leaf)) # LEAF IS FOR FILES
{
        $veeamExePath=$fileToCheck2VeeamBackupShell

} # FIN elseif
else
{
        $veeamExePathFound=gdr -PSProvider 'FileSystem' | %{ ls -r $_.root} 2>$null | where { $_.name -eq "Veeam.Backup.Shell.exe" } | Select-Object Directory
        $PathVeeamBackup="Veeam\Backup"
        foreach ($rowveeamExePath in $veeamExePathFound)
        {
                If ($rowveeamExePath -like "*$PathVeeamBackup*")
                {
                        $veeamExePath=$rowveeamExePath.Directory.FullName+"\Veeam.Backup.Shell.exe"
                        $veeamExePath=$veeamExePath.Trim()
                        break
                } # end if
        } # end foreach
} # FIN ELSE

######################################################################################################################################################
# Save HTML output to a file
$saveHTML = $true
# HTML File output path and filename
$ServerToStoreHTML = $vbrServer
$FolderToStoreHTML = $global:RemoteBackupStatusPath
$pathHTML = "\\" + $ServerToStoreHTML + "\" + $FolderToStoreHTML + "\" + $vbrServer + '_Capacity_Report_' + $RemoteCurrentDateTime + '.html'


# Launch HTML file after creation
$launchHTML = $false


# Email Subject 
$emailSubject = $rptTitle
# Append VBR Server name to Email Subject
$vbrSubject = $true
# Append Date and Time to Email Subject
$dtSubject = $true


# Show Proxy Info
$showProxy = $true
# Show Repository Info
$showRepo = $true
# Show Replica Target Info
$showReplicaTarget = $true
# Show License expiry info
$showLicExp = $true

# Highlighting Thresholds
# Repository Free Space Remaining %
$repoCritical = 10
$repoWarn = 20
# Replica Target Free Space Remaining %
$replicaCritical = 10
$replicaWarn = 20
# License Days Remaining
$licenseCritical = 30
$licenseWarn = 90
#endregion

#region Connect
# Load Veeam Snapin
If (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
  If (!(Add-PSSnapin -PassThru VeeamPSSnapIn)) {
    Write-Error "Unable to load Veeam snapin" -ForegroundColor Red
    Exit
  }
}
<#
# Connect to VBR server
$OpenConnection = (Get-VBRServerSession).Server
If ($OpenConnection -ne $vbrServer){
  Disconnect-VBRServer
  Try {
    Connect-VBRServer -server $vbrServer -ErrorAction Stop
  } Catch {
    Write-Host "Unable to connect to VBR server - $vbrServer" -ForegroundColor Red
    exit
  }
}
#endregion

#>

# Get Configuration Backup Info
$configBackup = Get-VBRConfigurationBackupJob
# Get VBR Server object
$vbrServerObj = Get-VBRLocalhost
# Get all Proxies
$proxyList = Get-VBRViProxy
# Get all Repositories
$repoList = Get-VBRBackupRepository
$repoListSo = Get-VBRBackupRepository -ScaleOut

# Toggle VBR Server name in report header
If ($showVBR) {
  $vbrName = "Veeam Environment: $vbrServer"
} Else {
  $vbrName = $null
}


# Append VBR Server to Email subject
If ($vbrSubject) {
  $emailSubject = "$vbrServer $emailSubject"
}

# Append Date and Time to Email subject
If ($dtSubject) {
  $emailSubject = "$emailSubject - $(Get-Date -format g)"
}
#endregion

#region Functions
 
Function Get-VBRProxyInfo {
  [CmdletBinding()]
  param (
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [PSObject[]]$Proxy
  )
  Begin {
    $outputAry = @()
    Function Build-Object {param ([PsObject]$inputObj)
      $ping = New-Object System.Net.NetworkInformation.Ping;
      $isIP = '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
      If ($inputObj.Host.Name -match $isIP) {
        $IPv4 = $inputObj.Host.Name
      } Else {
        $DNS = [Net.DNS]::GetHostEntry("$($inputObj.Host.Name)")
        $IPv4 = ($DNS.get_AddressList() | Where {$_.AddressFamily -eq "InterNetwork"} | Select -First 1).IPAddressToString
      }
      
      #$pinginfo = $ping.Send($IPv4)
      #$ping.SendPingAsync($IPv4)
      $pinginfo = $ping.send("$($IPv4)")       
      
      If ($pinginfo.Status -eq "Success") {
        $hostOnline = "Online"
        $response = $pinginfo.RoundtripTime
      } Else {
        $hostOnline = "Offline"
        $response = $null
      }
      If ($inputObj.IsDisabled) {
        $enabled = "False"
      } Else {
        $enabled = "True"
      }   
      $tMode = switch ($inputObj.Options.TransportMode) {
        "Auto" {"Automatic"}
        "San" {"Direct SAN"}
        "HotAdd" {"Hot Add"}
        "Nbd" {"Network"}
        default {"Unknown"}   
      }
      $vPCFuncObject = New-Object PSObject -Property @{
        ProxyName = $inputObj.Name
        RealName = $inputObj.Host.Name.ToLower()
        Disabled = $inputObj.IsDisabled
        pType = $inputObj.ChassisType
        Status  = $hostOnline
        IP = $IPv4
        Response = $response
        Enabled = $enabled
        maxtasks = $inputObj.Options.MaxTasksCount
        tMode = $tMode
      }
      Return $vPCFuncObject
    }
  }
  Process {
    Foreach ($p in $Proxy) {
      $outputObj = Build-Object $p
    }
    $outputAry += $outputObj
  }
  End {
    $outputAry
  }   
}

#Default Backup Repository
<# Function Get-VBRRepoInfo {
  [CmdletBinding()]
  param (
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [PSObject[]]$Repository
  )
  Begin {
    $outputAry = @()
    Function Build-Object {param($name, $repohost, $path, $free, $total, $maxtasks, $rtype)
      $repoObj = New-Object -TypeName PSObject -Property @{
        Target = $name
        RepoHost = $repohost
        Storepath = $path        
        StorageFree = [Math]::Round([Decimal]$free/1TB,2)
        StorageTotal = [Math]::Round([Decimal]$total/1TB,2)
        #StorageUsed = StorageTotal - StorageFree
        FreePercentage = [Math]::Round(($free/$total)*100)
        MaxTasks = $maxtasks
        rType = $rtype
      }
      Return $repoObj
    }
  }
  Process {
    Foreach ($r in $Repository) {
      # Refresh Repository Size Info
      [Veeam.Backup.Core.CBackupRepositoryEx]::SyncSpaceInfoToDb($r, $true)
      $rType = switch ($r.Type) {
        "WinLocal" {"Windows Local"}
        "LinuxLocal" {"Linux Local"}
        "CifsShare" {"CIFS Share"}
        "DataDomain" {"Data Domain"}
        "ExaGrid" {"ExaGrid"}
        "HPStoreOnce" {"HP StoreOnce"}
        default {"Unknown"}   
      }
      $outputObj = Build-Object $r.Name $($r.GetHost()).Name.ToLower() $r.Path $r.info.CachedFreeSpace $r.Info.CachedTotalSpace $r.Options.MaxTaskCount $rType
    }
    $outputAry += $outputObj
  }
  End {
    $outputAry
  }
} #>

Function Get-VBRSORepoInfo {
  [CmdletBinding()]
  param (
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [PSObject[]]$Repository
  )
  Begin {
    $outputAry = @()
    Function Build-Object {param($name, $rname, $repohost, $path, $free, $total, $maxtasks, $rtype)
      $repoObj = New-Object -TypeName PSObject -Property @{
        SoTarget = $name
        Target = $rname
        RepoHost = $repohost
        Storepath = $path
        StorageFree = [math]::Round([Math]::Round([Decimal]$free/1TB,1)) # round it to 1 decimal but the final answer round it to no decimals [math]::Round($Usado)
        StorageTotal = [math]::Round([Math]::Round([Decimal]$total/1TB,1)) # round it to 1 decimal but the final answer round it to no decimals [math]::Round($Usado)        
        StorageUsed = [math]::Round(([Math]::Round([Decimal]$total/1TB,1)) - ([Math]::Round([Decimal]$free/1TB,1))) # round it to 1 decimal but the final answer round it to no decimals [math]::Round($Usado)
        #StorageUsed = ([Math]::Round([Decimal]$total/1TB,1)) - ([Math]::Round([Decimal]$free/1TB,1)) # round it to 1 decimals and keeps answer with 1 decimal
        FreePercentage = [Math]::Round(($free/$total)*100)
        MaxTasks = $maxtasks
        rType = $rtype
      }
      Return $repoObj
    }
  }
  Process {
    Foreach ($rs in $Repository) {
      ForEach ($rp in $rs.Extent) {
        $r = $rp.Repository 
        # Refresh Repository Size Info
        [Veeam.Backup.Core.CBackupRepositoryEx]::SyncSpaceInfoToDb($r, $true)           
        $rType = switch ($r.Type) {
          "WinLocal" {"Windows Local"}
          "LinuxLocal" {"Linux Local"}
          "CifsShare" {"CIFS Share"}
          "DataDomain" {"Data Domain"}
          "ExaGrid" {"ExaGrid"}
          "HPStoreOnce" {"HP StoreOnce"}
          default {"Unknown"}     
        }
        $outputObj = Build-Object $rs.Name $r.Name $($r.GetHost()).Name.ToLower() $r.Path $r.info.CachedFreeSpace $r.Info.CachedTotalSpace $r.Options.MaxTaskCount $rType
        $outputAry += $outputObj
      }
    } 
  }
  End {
    $outputAry
  }
}

Function Get-VeeamVersion {
  Try {
    $veeamExe = Get-Item $veeamExePath
    $VeeamVersion = $veeamExe.VersionInfo.ProductVersion
    Return $VeeamVersion
  } Catch {
    Write-Host "Unable to Locate Veeam executable, check path - $veeamExePath" -ForegroundColor Red
    exit  
  }
} 
 
Function Get-VeeamSupportDate {
  param (
    [string]$vbrServer
  ) 
  # Query (remote) registry with WMI for license info
  Try{
    $wmi = get-wmiobject -list "StdRegProv" -namespace root\default -computername $vbrServer -ErrorAction Stop
    $hklm = 2147483650
    $bKey = "SOFTWARE\Veeam\Veeam Backup and Replication\license"
    $bValue = "Lic1"
    $regBinary = ($wmi.GetBinaryValue($hklm, $bKey, $bValue)).uValue
    $veeamLicInfo = [string]::Join($null, ($regBinary | % { [char][int]$_; }))
    # Convert Binary key
    $pattern = "expiration date\=\d{1,2}\/\d{1,2}\/\d{1,4}"
    $expirationDate = [regex]::matches($VeeamLicInfo, $pattern)[0].Value.Split("=")[1]
    $datearray = $expirationDate -split '/'
    $expirationDate = Get-Date -Day $datearray[0] -Month $datearray[1] -Year $datearray[2]
    $totalDaysLeft = ($expirationDate - (get-date)).Totaldays.toString().split(",")[0]
    $totalDaysLeft = [int]$totalDaysLeft
    $objoutput = New-Object -TypeName PSObject -Property @{
      ExpDate = $expirationDate.ToShortDateString()
      DaysRemain = $totalDaysLeft
    }
  } Catch{
    $objoutput = New-Object -TypeName PSObject -Property @{
      ExpDate = "WMI Connection Failed"
      DaysRemain = "WMI Connection Failed"
    }
  }
  $objoutput
} 

Function Get-VeeamWinServers {
  $vservers=@{}
  $outputAry = @()
  $vservers.add($($script:vbrServerObj.Name),"VBRServer")
  Foreach ($srv in $script:proxyList) {
    If (!$vservers.ContainsKey($srv.Host.Name)) {
      $vservers.Add($srv.Host.Name,"ProxyServer")
    }
  }
  Foreach ($srv in $script:repoList) {
    If ($srv.Type -ne "LinuxLocal" -and !$vservers.ContainsKey($srv.gethost().Name)) {
      $vservers.Add($srv.gethost().Name,"RepoServer")
    }
  }
  Foreach ($rs in $script:repoListSo) {
    ForEach ($rp in $rs.Extent) {
      $r = $rp.Repository 
      $rName = $($r.GetHost()).Name
      If ($r.Type -ne "LinuxLocal" -and !$vservers.ContainsKey($rName)) {
        $vservers.Add($rName,"RepoSoServer")
      }
    }
  }  
  Foreach ($srv in $script:tapesrvList) {
    If (!$vservers.ContainsKey($srv.Name)) {
      $vservers.Add($srv.Name,"TapeServer")
    }
  }  
  $vservers = $vservers.GetEnumerator() | Sort-Object Name
  Foreach ($vserver in $vservers) {
    $outputAry += $vserver.Name
  }
  return $outputAry
}

#region Report
# Get Veeam Version
$VeeamVersion = Get-VeeamVersion

If ($VeeamVersion -lt 9.5) {
  Write-Host "Script requires VBR v9.5" -ForegroundColor Red
  Write-Host "Version detected - $VeeamVersion" -ForegroundColor Red
  exit
}

# HTML Stuff
$headerObj = @"
<html>
    <head>
        <title>$rptTitle</title>
            <style>  
              body {font-family: Tahoma; background-color:#ffffff;}
              table {font-family: Tahoma;width: $($rptWidth)%;font-size: 12px;border-collapse:collapse;}
              <!-- table tr:nth-child(odd) td {background: #e2e2e2;} -->
              th {background-color: #e2e2e2;border: 1px solid #a7a9ac;border-bottom: none;}
              td {background-color: #ffffff;border: 1px solid #a7a9ac;padding: 2px 3px 2px 3px;}
            </style>
    </head>
"@
 
$bodyTop = @"
    <body>
        <center>
            <table>
                <tr>
                    <td style="width: 50%;height: 14px;border: none;background-color: ZZhdbgZZ;color: White;font-size: 10px;vertical-align: bottom;text-align: left;padding: 2px 0px 0px 5px;"></td>
                    <td style="width: 50%;height: 14px;border: none;background-color: ZZhdbgZZ;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 2px 5px 0px 0px;">Date: $(Get-Date -format g)</td>
                </tr>
                <tr>
                    <td style="width: 50%;height: 24px;border: none;background-color: ZZhdbgZZ;color: White;font-size: 24px;vertical-align: bottom;text-align: left;padding: 0px 0px 0px 15px;">$rptTitle</td>
                    <td style="width: 50%;height: 24px;border: none;background-color: ZZhdbgZZ;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 0px 5px 2px 0px;">$vbrName</td>
                </tr>
                <tr>
                    <td style="width: 50%;height: 12px;border: none;background-color: ZZhdbgZZ;color: White;font-size: 12px;vertical-align: bottom;text-align: left;padding: 0px 0px 0px 5px;"></td>
                    <td style="width: 50%;height: 12px;border: none;background-color: ZZhdbgZZ;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 0px 5px 0px 0px;">Version $VeeamVersion</td>
                </tr>
                <tr>
                    <td style="width: 50%;height: 12px;border: none;background-color: ZZhdbgZZ;color: White;font-size: 12px;vertical-align: bottom;text-align: left;padding: 0px 0px 0px 5px;"></td>
                    <td style="width: 50%;height: 12px;border: none;background-color: ZZhdbgZZ;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 0px 5px 0px 0px;">$BaRTitle</td>
                </tr>
            </table>
"@
 
$subHead01 = @"
<table>
                <tr>
                    <td style="height: 35px;background-color: #f3f4f4;color: #626365;font-size: 16px;padding: 5px 0 0 15px;border-top: 5px solid white;border-bottom: none;">
"@

$subHead01suc = @"
<table>
                 <tr>
                    <td style="height: 35px;background-color: #00b050;color: #ffffff;font-size: 16px;padding: 5px 0 0 15px;border-top: 5px solid white;border-bottom: none;">
"@

$subHead01war = @"
<table>
                 <tr>
                    <td style="height: 35px;background-color: #ffd96c;color: #ffffff;font-size: 16px;padding: 5px 0 0 15px;border-top: 5px solid white;border-bottom: none;">
"@

$subHead01err = @"
<table>
                <tr>
                    <td style="height: 35px;background-color: #FB9895;color: #ffffff;font-size: 16px;padding: 5px 0 0 15px;border-top: 5px solid white;border-bottom: none;">
"@

$subHead02 = @"
</td>
                </tr>
             </table>
"@

$HTMLbreak = @"
<table>
                <tr>
                    <td style="height: 10px;background-color: #626365;padding: 5px 0 0 15px;border-top: 5px solid white;border-bottom: none;"></td>
						    </tr>
            </table>
"@

$footerObj = @"
<table>
                <tr>
                    <td style="height: 15px;background-color: #ffffff;border: none;color: #626365;font-size: 10px;text-align:center;"> Report Generated on: $DateTime [jose.andres.torres@intel.com] </a></td>
                </tr>
            </table>
        </center>
    </body>
</html>
"@



# Get Proxy Info
$bodyProxy = $null
If ($showProxy) {
  If ($proxyList -ne $null) {
    $arrProxy = $proxyList | Get-VBRProxyInfo | Select @{Name="Proxy Name"; Expression = {$_.ProxyName}},
      @{Name="Transport Mode"; Expression = {$_.tMode}}, @{Name="Max Tasks"; Expression = {$_.MaxTasks}},
      @{Name="Proxy Host"; Expression = {$_.RealName}}, @{Name="Host Type"; Expression = {$_.pType}},
      Enabled, @{Name="IP Address"; Expression = {$_.IP}},
      @{Name="RT (ms)"; Expression = {$_.Response}}, Status
    $bodyProxy = $arrProxy | Sort "Proxy Host" |  ConvertTo-HTML -Fragment
    If ($arrProxy.Status -match "Offline") {
      $proxyHead = $subHead01err
    } ElseIf ($arrProxy -match "Online") {
      $proxyHead = $subHead01suc
    } Else {
      $proxyHead = $subHead01
    }    
    $bodyProxy = $proxyHead + "Proxy Details" + $subHead02 + $bodyProxy
  }
}

<# Temporarily removed

# Get Repository Info
$bodyRepo = $null
If ($showRepo) {
  If ($repoList -ne $null) {
    $arrRepo = $repoList | Get-VBRRepoInfo | Select @{Name="Repository Name"; Expression = {$_.Target}},
      @{Name="Type"; Expression = {$_.rType}}, @{Name="Max Tasks"; Expression = {$_.MaxTasks}},
      @{Name="Host"; Expression = {$_.RepoHost}}, @{Name="Path"; Expression = {$_.Storepath}},
      @{Name="Free (TB)"; Expression = {$_.StorageFree}}, @{Name="Total (TB)"; Expression = {$_.StorageTotal}},
      @{Name="Free (%)"; Expression = {$_.FreePercentage}},
      @{Name="Status"; Expression = {
        If ($_.FreePercentage -lt $repoCritical) {"Critical"}
        ElseIf ($_.StorageTotal -eq 0)  {"Warning"} 
        ElseIf ($_.FreePercentage -lt $repoWarn) {"Warning"}
        ElseIf ($_.FreePercentage -eq "Unknown") {"Unknown"}
        Else {"OK"}}
      }
    $bodyRepo = $arrRepo | Sort "Repository Name" | ConvertTo-HTML -Fragment       
    If ($arrRepo.status -match "Critical") {
      $repoHead = $subHead01err
    } ElseIf ($arrRepo.status -match "Warning|Unknown") {
      $repoHead = $subHead01war
    } ElseIf ($arrRepo.status -match "OK") {
      $repoHead = $subHead01suc
    } Else {
      $repoHead = $subHead01
    }    
    $bodyRepo = $repoHead + "Repository Details" + $subHead02 + $bodyRepo
  }
} #>

# Get Scale Out Repository Info
$bodySORepo = $null
If ($showRepo) {
  If ($repoListSo -ne $null) {
    $arrSORepo = $repoListSo | Get-VBRSORepoInfo | Select @{Name="Scale Out Repository Name"; Expression = {$_.SOTarget}},
      @{Name="Member Repository Name"; Expression = {$_.Target}}, @{Name="Type"; Expression = {$_.rType}},
      @{Name="Max Tasks"; Expression = {$_.MaxTasks}}, @{Name="Host"; Expression = {$_.RepoHost}},
      @{Name="Path"; Expression = {$_.Storepath}},
      @{Name="Total (TB)"; Expression = {$_.StorageTotal}}, @{Name="Used (TB)"; Expression = {$_.StorageUsed}},
      @{Name="Free (TB)"; Expression = {$_.StorageFree}}, @{Name="Free (%)"; Expression = {$_.FreePercentage}},      
      @{Name="Status"; Expression = {
        If ($_.FreePercentage -lt $repoCritical) {"Critical"}
        ElseIf ($_.StorageTotal -eq 0)  {"Warning"}
        ElseIf ($_.FreePercentage -lt $repoWarn) {"Warning"}
        ElseIf ($_.FreePercentage -eq "Unknown") {"Unknown"}
        Else {"OK"}}
      }
    $bodySORepo = $arrSORepo | Sort "Scale Out Repository Name", "Member Repository Name" | ConvertTo-HTML -Fragment
    If ($arrSORepo.status -match "Critical") {
      $sorepoHead = $subHead01err
    } ElseIf ($arrSORepo.status -match "Warning|Unknown") {
      $sorepoHead = $subHead01war
    } ElseIf ($arrSORepo.status -match "OK") {
      $sorepoHead = $subHead01suc
    } Else {
      $sorepoHead = $subHead01
    }
    $bodySORepo = $sorepoHead + "Scale Out Repository Details" + $subHead02 + $bodySORepo
  }
}


# Get Replica Target Info
$bodyReplica = $null
If ($showReplicaTarget) {
  If ($allJobsRp -ne $null) {
    $repTargets = $allJobsRp | Get-VBRReplicaTarget | Select @{Name="Replica Target"; Expression = {$_.Target}}, Datastore,
      @{Name="Free (GB)"; Expression = {$_.StorageFree}}, @{Name="Total (GB)"; Expression = {$_.StorageTotal}},
      @{Name="Free (%)"; Expression = {$_.FreePercentage}},
      @{Name="Status"; Expression = {
        If ($_.FreePercentage -lt $replicaCritical) {"Critical"}
        ElseIf ($_.StorageTotal -eq 0)  {"Warning"}
        ElseIf ($_.FreePercentage -lt $replicaWarn) {"Warning"}
        ElseIf ($_.FreePercentage -eq "Unknown") {"Unknown"}
        Else {"OK"}
        }
      } | Sort "Replica Target"
    $bodyReplica = $repTargets | ConvertTo-HTML -Fragment
    If ($repTargets.status -match "Critical") {
      $reptarHead = $subHead01err
    } ElseIf ($repTargets.status -match "Warning|Unknown") {
      $reptarHead = $subHead01war
    } ElseIf ($repTargets.status -match "OK") {
      $reptarHead = $subHead01suc
    } Else {
      $reptarHead = $subHead01
    }    
    $bodyReplica = $reptarHead + "Replica Target Details" + $subHead02 + $bodyReplica
  }
}


# Get License Info
$bodyLicense = $null
If ($showLicExp) {
  $arrLicense = Get-VeeamSupportDate $vbrServer | Select @{Name="Expiry Date"; Expression = {$_.ExpDate}},
    @{Name="Days Remaining"; Expression = {$_.DaysRemain}}, `
    @{Name="Status"; Expression = {
      If ($_.DaysRemain -lt $licenseCritical) {"Critical"}
      ElseIf ($_.DaysRemain -lt $licenseWarn) {"Warning"}
      ElseIf ($_.DaysRemain -eq "Failed") {"Failed"}
      Else {"OK"}}
    }  
  $bodyLicense = $arrLicense | ConvertTo-HTML -Fragment
  If ($arrLicense.Status -eq "OK") {
    $licHead = $subHead01suc
  } ElseIf ($arrLicense.Status -eq "Warning") {
    $licHead = $subHead01war
  } Else {
    $licHead = $subHead01err
  }
  $bodyLicense = $licHead + "License/Support Renewal Date" + $subHead02 + $bodyLicense
}

# Combine HTML Output
$htmlOutput = $headerObj + $bodyTop + $bodySummaryProtect + $bodySummaryBK + $bodySummaryRp + $bodySummaryBc + $bodySummaryTp + $bodySummaryEp + $bodySummarySb
  
If ($bodySummaryProtect + $bodySummaryBK + $bodySummaryRp + $bodySummaryBc + $bodySummaryTp + $bodySummaryEp + $bodySummarySb) {
  $htmlOutput += $HTMLbreak
}
  
$htmlOutput += $bodyMissing + $bodyWarning + $bodySuccess

If ($bodyMissing + $bodySuccess + $bodyWarning) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodyMultiJobs

If ($bodyMultiJobs) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodyJobsBk + $bodyJobSizeBk + $bodyAllSessBk + $bodyAllTasksBk + $bodyRunningBk + $bodyTasksRunningBk + $bodySessWFBk + $bodyTaskWFBk + $bodySessSuccBk + $bodyTaskSuccBk

If ($bodyJobsBk + $bodyJobSizeBk + $bodyAllSessBk + $bodyAllTasksBk + $bodyRunningBk + $bodyTasksRunningBk + $bodySessWFBk + $bodyTaskWFBk + $bodySessSuccBk + $bodyTaskSuccBk) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodyRestoRunVM + $bodyRestoreVM

If ($bodyRestoRunVM + $bodyRestoreVM) {
  $htmlOutput += $HTMLbreak
  }

$htmlOutput += $bodyJobsRp + $bodyAllSessRp + $bodyAllTasksRp + $bodyRunningRp + $bodyTasksRunningRp + $bodySessWFRp + $bodyTaskWFRp + $bodySessSuccRp + $bodyTaskSuccRp

If ($bodyJobsRp + $bodyAllSessRp + $bodyAllTasksRp + $bodyRunningRp + $bodyTasksRunningRp + $bodySessWFRp + $bodyTaskWFRp + $bodySessSuccRp + $bodyTaskSuccRp) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodyJobsBc + $bodyJobSizeBc + $bodyAllSessBc + $bodyAllTasksBc + $bodySessIdleBc + $bodyTasksPendingBc + $bodyRunningBc + $bodyTasksRunningBc + $bodySessWFBc + $bodyTaskWFBc + $bodySessSuccBc + $bodyTaskSuccBc

If ($bodyJobsBc + $bodyJobSizeBc + $bodyAllSessBc + $bodyAllTasksBc + $bodySessIdleBc + $bodyTasksPendingBc + $bodyRunningBc + $bodyTasksRunningBc + $bodySessWFBc + $bodyTaskWFBc + $bodySessSuccBc + $bodyTaskSuccBc) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodyJobsTp + $bodyAllSessTp + $bodyAllTasksTp + $bodyWaitingTp + $bodySessIdleTp + $bodyTasksPendingTp + $bodyRunningTp + $bodyTasksRunningTp + $bodySessWFTp + $bodyTaskWFTp + $bodySessSuccTp + $bodyTaskSuccTp

If ($bodyJobsTp + $bodyAllSessTp + $bodyAllTasksTp + $bodyWaitingTp + $bodySessIdleTp + $bodyTasksPendingTp + $bodyRunningTp + $bodyTasksRunningTp + $bodySessWFTp + $bodyTaskWFTp + $bodySessSuccTp + $bodyTaskSuccTp) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodyTapes + $bodyTpPool + $bodyTpVlt + $bodyExpTp + $bodyTpExpPool + $bodyTpExpVlt + $bodyTpWrt

If ($bodyTapes + $bodyTpPool + $bodyTpVlt + $bodyExpTp + $bodyTpExpPool + $bodyTpExpVlt + $bodyTpWrt) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodyJobsEp + $bodyJobSizeEp + $bodyAllSessEp + $bodyRunningEp + $bodySessWFEp + $bodySessSuccEp

If ($bodyJobsEp + $bodyJobSizeEp + $bodyAllSessEp + $bodyRunningEp + $bodySessWFEp + $bodySessSuccEp) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodyJobsSb + $bodyAllSessSb + $bodyAllTasksSb + $bodyRunningSb + $bodyTasksRunningSb + $bodySessWFSb + $bodyTaskWFSb + $bodySessSuccSb + $bodyTaskSuccSb

If ($bodyJobsSb + $bodyAllSessSb + $bodyAllTasksSb + $bodyRunningSb + $bodyTasksRunningSb + $bodySessWFSb + $bodyTaskWFSb + $bodySessSuccSb + $bodyTaskSuccSb) {
  $htmlOutput += $HTMLbreak
}

$htmlOutput += $bodySummaryConfig + $bodyProxy + $bodyRepo + $bodySORepo + $bodyRepoPerms + $bodyReplica + $bodyServices + $bodyLicense + $footerObj

# Fix Details
$htmlOutput = $htmlOutput.Replace("ZZbrZZ","<br />")
# Remove trailing HTMLbreak
$htmlOutput = $htmlOutput.Replace("$($HTMLbreak + $footerObj)","$($footerObj)")
# Add color to output depending on results
#Green
$htmlOutput = $htmlOutput.Replace("<td>Running<","<td style=""color: #00b051;"">Running<")
$htmlOutput = $htmlOutput.Replace("<td>OK<","<td style=""color: #00b051;"">OK<")
$htmlOutput = $htmlOutput.Replace("<td>Online<","<td style=""color: #00b051;"">Online<")
$htmlOutput = $htmlOutput.Replace("<td>Success<","<td style=""color: #00b051;"">Success<")
#Yellow
$htmlOutput = $htmlOutput.Replace("<td>Warning<","<td style=""color: #ffc000;"">Warning<")
#Red
$htmlOutput = $htmlOutput.Replace("<td>Not Running<","<td style=""color: #ff0000;"">Not Running<")
$htmlOutput = $htmlOutput.Replace("<td>Failed<","<td style=""color: #ff0000;"">Failed<")
$htmlOutput = $htmlOutput.Replace("<td>Critical<","<td style=""color: #ff0000;"">Critical<")
$htmlOutput = $htmlOutput.Replace("<td>Offline<","<td style=""color: #ff0000;"">Offline<")
# Color Report Header and Tag Email Subject
If ($htmlOutput -match "#FB9895") {
  # If any errors paint report header red
  $htmlOutput = $htmlOutput.Replace("ZZhdbgZZ","#FB9895")
  $emailSubject = "$emailSubject [Failed]"
} ElseIf ($htmlOutput -match "#ffd96c") {
  # If any warnings paint report header yellow
  $htmlOutput = $htmlOutput.Replace("ZZhdbgZZ","#00b050") # por ahora lo voy a poner en verde
  #$htmlOutput = $htmlOutput.Replace("ZZhdbgZZ","#ffd96c") este lo pone amarillo por ahora vamos a usar verde
  $emailSubject = "$emailSubject [Warning]"
} ElseIf ($htmlOutput -match "#00b050") {
  # If any success paint report header green
  $htmlOutput = $htmlOutput.Replace("ZZhdbgZZ","#00b050")
  $emailSubject = "$emailSubject [Success]"
} Else {
  # Else paint gray
  $htmlOutput = $htmlOutput.Replace("ZZhdbgZZ","#626365")
}
#endregion


# Save HTML Report to File
If ($saveHTML) {       
  $htmlOutput | Out-File $pathHTML
  If ($launchHTML) {
    Invoke-Item $pathHTML
  }
}
#endregion

Remove-Item "c:\Temp\CurrentTimeDate.txt"

}  #fin de la funcion RemoteCapacityStatus


function StartHTMLCapacityReporProxy
{
    
    #Region copy html to local server
               $global:FolderToStoreHTML = "c$\temp"
               $global:pathHTML = "\\" + $FQDNVeeamServer + "\" + $FolderToStoreHTML + "\" + $VeeamServer + '_Capacity_Report_' + $global:CurrentDateTime + '.html'
               if (Test-Path ($pathHTML) -PathType leaf) #si existe el file
                {
                        Copy-Item ($pathHTML) -Destination ("\\" + $global:ServerLogName + "\" + $global:PathHTMLCapacityFolder + "\") #copia el html desde veeam server a local
                        Remove-Item ($pathHTML) -Force  -Recurse -ErrorAction SilentlyContinue # removes the capacity report from the veeam server
                } # end if to if output html exists    
                #endregion

    # region if html exists launch it
    if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:PathHTMLCapacityFolder + "\" + $VeeamServer + '_Capacity_Report_' + $global:CurrentDateTime + '.html') -PathType leaf)
    {
            start ("\\" + $global:ServerLogName + "\" + $global:PathHTMLCapacityFolder + "\" + $VeeamServer + '_Capacity_Report_' + $global:CurrentDateTime + '.html')
    }
    #endregion

} #fin function StartHTMLCapacityReporProxy


########################################################################################################################################################################################################################################
#Section Disk Usage Report FETB
########################################################################################################################################################################################################################################

function GenerateDiskUsageReport
{
        
        Param
        (                
                #[ValidateNotNullOrEmpty()] #it will fail if empty
                [string[]]
                $VeeamStringListFQDN, #array name                                
                [System.Management.Automation.PSCredential]
                [System.Management.Automation.Credential()]
                $CredentialUserAlternate = [System.Management.Automation.PSCredential]::Empty 
                #[System.Management.Automation.PSCredential]$CredentialUserAlternate
        )

        Begin
        {       
                $global:CurrentDateTime = $global:CurrentDateTime = (Get-Date -Format MMddyyyy_HHmmss) #refreshes current date time minutes and seconds           
        }
        
        Process
        {
                if (Test-Path ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -PathType leaf) #si existe el file
                {
                        #################Trim section#######################################################################################################################################                        
                        $Loadfile = GC ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull)
                        New-Item ("\\" + $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -ItemType File  -force > $LogNull   #creates a new file to clear the contents from servers list locally
                        if (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                        {
                                $Loadfile = $Loadfile.Trim()
                        } # fin (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                                $Loadfile > ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime
                        #################Trim section#######################################################################################################################################

                        #################Remove Empty Lines#################################################################################################################################
                        $file = ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime
                        (gc $file) | ? {$_.trim() -ne "" } | set-content $file
                        $content = [System.IO.File]::ReadAllText($file)
                        $content = $content.Trim()
                        [System.IO.File]::WriteAllText($file, $content)
                        #################Trim section#######################################################################################################################################
                        $CheckifContainData = Get-Content ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime
                        if (![string]::IsNullOrWhiteSpace($CheckifContainData)) #revisa que no se encuentre !NO vacio serverstxt
                        {
                                $global:Hostnames = $CheckifContainData.Trim().ToLower()
                                
                                #Set-Content ("\\" + $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -Value "" > $LogNull   #creates a new file to clear the contents from servers list locally                        
                                foreach ($VeeamServer in $VeeamStringListFQDN) #string de VBRs
                                {
                                        if (![string]::IsNullOrWhiteSpace($VeeamServer)) #revisa que no se encuentre !NO vacio VeeamServer
                                        {
                                                ###Section to capture shortname and fqdn and suffix########################
                                                $FQDNVeeamServer = $VeeamServer #the parameter is sent as long name FQDN
                                                $VeeamServer = $FQDNVeeamServer.Split('.')[0] #captures just the shortname / hostname
                                                $DomainSuffix = $FQDNVeeamServer -replace "$VeeamServer.","" # captures just the suffix
                                                ############################################################################
                                                ########Connection PS Seesion#############################################################################################################################
                                                $Session = New-PSSession -ComputerName $FQDNVeeamServer -Credential $CredentialUserAlternate
                                                #$Session = New-PSSession -ComputerName $FQDNVeeamServer #without creds
                    
                                                if ($Session.State -eq "Closed") #"Remote Script Errored out"
                                                {
                                                           #"New-Pssession Errored out and didn't connect"
                                                } # fin if session closed
                                                else
                                                {
                                                        try
                                                        {                                                                       
                                                                Invoke-Command -ComputerName $FQDNVeeamServer -ScriptBlock ${function:RemoteDiskUsage} -ArgumentList $global:CurrentDateTime, $global:Hostnames, $CredentialUserAlternate #-UseSSL #esta solucion es para llamar directamente una funcion que se encuentre dentro de este mismo ps1 y lo ejecuta en la pc remota
                                                                #$scriptContent = Get-Content (c:\viewbackupstatus.ps1) -Raw                                                                            
                                                                #invoke-command -ComputerName $VeeamServer -ScriptBlock ([scriptblock]::Create($scriptContent)) -ArgumentList $global:CurrentDateTime
                                                                #Invoke-Command -FilePath ($SourceLocationBackupStatus + "\" + $PS1name) -ComputerName $VeeamServer #excecutes the file stored on barjat on the VeeamServer #esta solucion ejecuta en la PC remota el ps1 directamente pero tiene que estar guardado local                                                                                                                                                                                                                                        
                                                        } #fin try
                                                        catch #if there is an error return 1 with invoke-command
                                                        {
                                                                return 1 > $LogNull;      
                                                        } # fin catch                                
                                                                return 2 > $LogNull; #si devuele dos el invoke command corrio bien todo salio bien
                                                                Remove-PSSession -Session $Session #remueve session
                                                        } #fin else ($session.State no fue "Closed") osea se State encuentra Opened
                                        } # fin if (![string]::IsNullOrWhiteSpace($VeeamServer))
                                } #fin foreach ($VeeamServer in $VeeamStringListFQDN) #string de VBRs                                
                        } #fin if (![string]::IsNullOrWhiteSpace($CheckifContainData))
                        else
                        {
                            cls
                            WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;
                            pause
                        } #fin else serversTXT se encuentra vacio                
                } # fin if (Test-Path ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -PathType leaf) #si existe el file                                
        } #fin process
        End
        {      
	            GenerateDiskUsageCSVtoHTML $global:VBRList
                StartHTMLDiskUsage    
        } # fin end
} # fin function end GenerateDiskUsageReport


function RemoteDiskUsage
{       
    Param
    (                
        [ValidateNotNullOrEmpty()] #it will fail if empty
        [string[]] #string type instead of array
        $RemoteCurrentDateTime,      #string name
        [string[]]                   #string type instead of array
        $RemoteHostnames, #string for computer names,
        [System.Management.Automation.PSCredential] # type used to pass use the PS credentials
        [System.Management.Automation.Credential()] # type used to declare the credentials variable below
        $CredentialUserAlternate = [System.Management.Automation.PSCredential]::Empty               
    )   

#region User-Variables

$RemoteCurrentDateTime > "c:\Temp\DiskUsage_CurrentTimeDate.txt" #variable to keep the current time provided from the parameter
$RemoteCurrentDateTime = GC "c:\Temp\DiskUsage_CurrentTimeDate.txt"

$vbrServer = $env:COMPUTERNAME #captures the hostname/shortname
$vbrServerFQDN = [System.Net.Dns]::GetHostByName($vbrServer).HostName #gets the FQDN from the shortname

$path = "c:\Temp"
$CSVFile = "_DiskUsage_Report_"
$pathServerTXT = $path + "\" + 'DiskUsage_Servers_' + $RemoteCurrentDateTime + '.txt' #local path on the remote
$pathServerCSV = $path + "\" + $vbrServer + $CSVFile + $RemoteCurrentDateTime + '.csv' #local path on the remote

$RemoteHostnames > $pathServerTXT
$RemoteHostnames = GC $pathServerTXT
 
#$cred= get-credential
#$domain = "amr"
#$LAdmin = $domain + "\ad_jatorres"
#$LPassword = ConvertTo-SecureString "PWD HERE" -AsPlainText -Force
#$CredentialsTemp = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $LAdmin, $LPassword

New-Item $pathServerCSV -ItemType File -Force -ErrorAction SilentlyContinue > $path\logtemp.txt
#Set-Content $pathServerCSV -Value "" > $path\logtemp.txt   #creates a new file to clear the contents from servers list locally                        

#end region

#region foreach computer

foreach ($Computer in $RemoteHostnames)  
{   
        if (![string]::IsNullOrWhiteSpace($Computer)) #revisa computadora si tenga nombre
        {
                #Get-WmiObject win32_logicaldisk | ft DeviceID,VolumeName,@{Name=”Free Space (GB)”;Expression={[math]::round($_.FreeSpace / 1GB,0)}},@{Name=”Size in GB”;Expression={[math]::round($_.Size /1GB,0)}} –AutoSize                                                       
                #$Session = New-PSSession -ComputerName $Computer #without creds                
                #$Session = New-PSSession -ComputerName $Computer -Credential $CredentialUserAlternate -ConfigurationName microsoft.powershell #login with secured json credentials for amr\sys
                
                if (test-Connection -ComputerName $Computer -BufferSize 16 -Count 1 -ea 0 -Quiet) # computer is online
                {
                        #Write-Host $Computer is online -ForegroundColor Green
                        try
                        {                                       
                                $Disks=Get-WmiObject -Class Win32_LogicalDisk -ComputerName $Computer -credential $CredentialUserAlternate -ErrorVariable Err -ErrorAction Stop                                
                                $Servername=Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer -Credential $CredentialUserAlternate -ErrorAction Stop                                        
                                $Servername=$Servername.Name
                                foreach ($objdisk in $Disks)  
                                {  
                                        $out=New-Object PSObject
                                        $total = [Math]::Round([Math]::Round([Decimal]$objDisk.Size/1GB,1)) # round it to 1 decimal but the final answer round it to no decimals [math]::Round($Usado)        
                                        $free = [Math]::Round([Math]::Round([Decimal]$objDisk.FreeSpace/1GB,1)) # round it to 1 decimal but the final answer round it to no decimals [math]::Round($Usado)        
                                        #$total=“{0:N0}” -f ($objDisk.Size/1GB)  #no decimals “{0:N0}”
                                        #$total = [math]::Round($total,0) # 2 decimals
                                        #$free=($objDisk.FreeSpace/1GB) # 2 decimals
                                        #$free = [math]::Round($free,0)
                                        $usedspace= ($total - $free)
                                        $usedspace = [Math]::Round($usedspace) # ,0 decimals [math]::Round($Usado)
                                        $freePercent=“{0:P0}” -f ([double]$objDisk.FreeSpace/[double]$objDisk.Size) 
                                        $out | Add-Member -MemberType NoteProperty -Name "Primary Name" -Value $Servername
                                        $out | Add-Member -MemberType NoteProperty -Name "Backup Name" -Value $Computer
                                        $out | Add-Member -MemberType NoteProperty -Name "Drive" -Value $objDisk.DeviceID
                                        $out | Add-Member -MemberType NoteProperty -Name "Used (GB)" -Value $usedspace        
                                        $out | Add-Member -MemberType NoteProperty -Name "Provisioned (GB)" -Value $total 
                                        $out | Add-Member -MemberType NoteProperty -Name “Free (GB)” -Value $free 
                                        $out | Add-Member -MemberType NoteProperty -Name “Free Space (%)” -Value $freePercent 
                                        $out | Add-Member -MemberType NoteProperty -Name "Drive Label" -Value $objdisk.volumename 
                                        $out | Add-Member -MemberType NoteProperty -Name "Drive Type" -Value $objdisk.DriveType 
                                        $out | export-csv $pathServerCSV -NoTypeInformation -Append                        
                                        cls
                                } # fin foreach ($objdisk in $Disks)
                                # Remove-PSSession -Session $Session #remueve session
                        } #fin try
                        catch #if there is an error return 1 with get-wmiobject
                        {
                                #Write-Warning  "$Computer Get-WMIObject : Access is denied. (Exception from HRESULT: 0x80070005 (E_ACCESSDENIED))"     
                                #return 1 > $LogNull;
                                $MSGAccess = "Access-Denied"
                                $out=New-Object PSObject
                                $out | Add-Member -MemberType NoteProperty -Name "Primary Name" -Value $MSGAccess
                                $out | Add-Member -MemberType NoteProperty -Name "Backup Name" -Value $Computer
                                $out | Add-Member -MemberType NoteProperty -Name "Drive" -Value $MSGAccess
                                $out | Add-Member -MemberType NoteProperty -Name "Used (GB)" -Value "0"        
                                $out | Add-Member -MemberType NoteProperty -Name "Provisioned (GB)" -Value "0"
                                $out | Add-Member -MemberType NoteProperty -Name “Free (GB)” -Value "0"
                                $out | Add-Member -MemberType NoteProperty -Name “Free Space (%)” -Value "0%"
                                $out | Add-Member -MemberType NoteProperty -Name "Drive Label" -Value $MSGAccess 
                                $out | Add-Member -MemberType NoteProperty -Name "Drive Type" -Value $MSGAccess 
                                $out | export-csv $pathServerCSV -NoTypeInformation -Append                        
                        } # fin catch
                } # fin if si hay connection
                else 
                {
                        #Write-Host $Computer is offline -ForegroundColor Red
                        $MSGStatus = "Offline"
                        $out=New-Object PSObject
                        $out | Add-Member -MemberType NoteProperty -Name "Primary Name" -Value $MSGStatus
                        $out | Add-Member -MemberType NoteProperty -Name "Backup Name" -Value $Computer
                        $out | Add-Member -MemberType NoteProperty -Name "Drive" -Value $MSGStatus
                        $out | Add-Member -MemberType NoteProperty -Name "Used (GB)" -Value "0"        
                        $out | Add-Member -MemberType NoteProperty -Name "Provisioned (GB)" -Value "0"
                        $out | Add-Member -MemberType NoteProperty -Name “Free (GB)” -Value "0"
                        $out | Add-Member -MemberType NoteProperty -Name “Free Space (%)” -Value "0%"
                        $out | Add-Member -MemberType NoteProperty -Name "Drive Label" -Value $MSGStatus 
                        $out | Add-Member -MemberType NoteProperty -Name "Drive Type" -Value $MSGStatus 
                        $out | export-csv $pathServerCSV -NoTypeInformation -Append                        
                } #fin else test fallido #computer offline                    
        } # fin if (![string]::IsNullOrWhiteSpace($CheckifContainData)) #se encuentra lleno                   
}  # fin foreach ($Computer in $Computers) 

#endregion

#region removes temp files

Remove-Item ($pathServerTXT) -Force  -Recurse -ErrorAction SilentlyContinue # removes the txt with the computer names
Remove-Item "c:\Temp\DiskUsage_CurrentTimeDate.txt" -Force  -Recurse -ErrorAction SilentlyContinue # removes the txt with the computer names
Remove-Item ($path + "\" + 'logtemp.txt') -Force  -Recurse -ErrorAction SilentlyContinue # removes the txt log

#endregion

} #fin function RemoteDiskUsage



function GenerateDiskUsageCSVtoHTML
{

Param
(                
        [ValidateNotNullOrEmpty()] #it will fail if empty
        [string[]] #string type instead of array
        $VeeamStringListFQDN
               
)   

#=========================================================================================================================================================
#Convert Merged .csv Final Report to html css
#=========================================================================================================================================================

$css = @"
<style>
h1, h5, th { text-align: center; font-family: Segoe UI; }
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 11px; padding: 5px 20px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
"@

###Section to capture shortname and fqdn and suffix########################
$FQDNVeeamServer = $VeeamStringListFQDN #the parameter is sent as long name FQDN
$VeeamServer = $FQDNVeeamServer.Split('.')[0] #captures just the shortname / hostname
$DomainSuffix = $FQDNVeeamServer -replace "$VeeamServer.","" # captures just the suffix
############################################################################

#Region copy html to local server
$global:RemoteFolderToStoreCSV = "c$\temp"
$global:RemotepathCSV = "\\" + $FQDNVeeamServer + "\" + $RemoteFolderToStoreCSV + "\" + $VeeamServer + $global:HTMLDiskUsageFileName + $global:CurrentDateTime + '.csv'


if (Test-Path ($global:RemotepathCSV) -PathType leaf) #si existe el file
{
        Copy-Item ($RemotepathCSV) -Destination ("\\" + $global:ServerLogName + "\" + $global:CSVDiskUsageReportsFolderPath + "\") > $LogNull #copia el csv desde veeam server a local
        Remove-Item ($RemotepathCSV) -Force  -Recurse -ErrorAction SilentlyContinue # removes the capacity report from the veeam server
} # end if to if output html exists    
#endregion

if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:CSVDiskUsageReportsFolderPath + "\" + $VeeamServer + $global:CSVDiskUsageFileName + $global:CurrentDateTime + '.csv') -PathType leaf) # Leaf for file Container for folders
{       
        #################Trim section################################################################################
        $Loadfile = GC ("\\" + $global:ServerLogName + "\" + $global:CSVDiskUsageReportsFolderPath + "\" + $VeeamServer + $global:CSVDiskUsageFileName + $global:CurrentDateTime + '.csv')
        if (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
        {
                $Loadfile = $Loadfile.Trim()
        } # fin (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
        $Loadfile > ("\\" + $global:ServerLogName + "\" + $global:CSVDiskUsageReportsFolderPath + "\" + $VeeamServer + $global:CSVDiskUsageFileName + $global:CurrentDateTime + '.csv')
        ###############################################################################################################

        #################Remove Empty LInes############################################################################
        $file = ("\\" + $global:ServerLogName + "\" + $global:CSVDiskUsageReportsFolderPath + "\" + $VeeamServer + $global:CSVDiskUsageFileName + $global:CurrentDateTime + '.csv')
        (gc $file) | ? {$_.trim() -ne "" } | set-content $file
        $content = [System.IO.File]::ReadAllText($file)
        $content = $content.Trim()
        [System.IO.File]::WriteAllText($file, $content)
        ###############################################################################################################
        $SortUniqueDiskCSV = Import-CSV ("\\" + $global:ServerLogName + "\" + $global:CSVDiskUsageReportsFolderPath + "\" + $VeeamServer + $global:CSVDiskUsageFileName + $global:CurrentDateTime + '.csv') <# | sort "Name" #> # quitar el -Unique #importa el csv que se forma con final merged y los ordena por nombre 
        $SortUniqueDiskCSV | ConvertTo-Html -Head $css -Body "<h1>Disk Usage Report</h1>`n<h5>Generated on $(Get-Date)</h5>" | Out-File ("\\" + $global:ServerLogName + "\" + $global:HTMLDiskUsageReportsFolderPath + "\" + $VeeamServer + $global:HTMLDiskUsageFileName + $global:CurrentDateTime + '.html') # convierte el csv a css html
} #fin if Test-Path
} #fin function GenerateDiskUsageCSVtoHTML


function StartHTMLDiskUsage
{    
    

    # region if html exists launch it
    if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:HTMLDiskUsageReportsFolderPath + "\" + $VeeamServer + $global:HTMLDiskUsageFileName + $global:CurrentDateTime + '.html') -PathType leaf)
    {
            start ("\\" + $global:ServerLogName + "\" + $global:HTMLDiskUsageReportsFolderPath + "\" + $VeeamServer + $global:HTMLDiskUsageFileName + $global:CurrentDateTime + '.html')
    }
    #endregion

} #fin function StartHTMLDiskUsage


########################################################################################################################################################################################################################################
#Functions Section for One For All
#######################################################################################################################################################################################################################################

function DiskUsageRepos
{       
        Param
        (                
                [ValidateNotNullOrEmpty()] #it will fail if empty        
                [System.Management.Automation.PSCredential]$CredentialUserAlternate = [System.Management.Automation.PSCredential]::Empty
        )
        $global:CurrentDateTime = $global:CurrentDateTime = (Get-Date -Format MMddyyyy_HHmmss) #refreshes current date time minutes and seconds  
        #region User-Variables                
        $ImportRepoServers = Import-Csv -Path ("\\" + $global:ServerLogName + "\" + $global:pathTemplateRepos + "\" + "Template-RepoServers.csv")        
        New-Item ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv') -ItemType File -Force -ErrorAction SilentlyContinue > $global:LogNull
        Remove-Item $global:LogNull
        #end region

        #region foreach computer
        
        ForEach ($rowRepos in $ImportRepoServers)
        {                
                if (![string]::IsNullOrWhiteSpace($rowRepos)) #revisa computadora si tenga nombre
                {                
                        #$Session = New-PSSession -ComputerName $Computer -Credential $CredentialUserAlternate -ConfigurationName microsoft.powershell #login with secured json credentials for amr\sys                
                
                        ###Section to capture shortname and fqdn and suffix################################
                                               
                        $Purpose = $rowRepos.("Purpose")
                        $RepoName = $rowRepos.("Repository")                        
                        $SOR = $rowRepos.("Scale Out Repository")
                        $Environment = $rowRepos.("Environment")
                        $Region = $rowRepos.("Region")
                        $Building = $rowRepos.("Building")                        
                        $RepoFQDN = $RepoName #the parameter is sent as long name FQDN
                        $RepoShort = $RepoFQDN.Split('.')[0] #captures just the shortname / hostname
                        #$DomainSuffix = $RepoFQDN -replace "$RepoShort.","" # captures just the suffix
                        ###################################################################################
                       # $ImportRepoServers.IndexOf($Computer)
                        
                
                        if (test-Connection -ComputerName $RepoName -BufferSize 16 -Count 1 -ea 0 -Quiet) # computer is online
                        {
                                #Write-Host $Computer is online -ForegroundColor Green
                                try
                                {                         
                                        #$Servername=[System.Net.Dns]::GetHostByName($RepoName)   
                                        $Disks=Get-WmiObject -Class Win32_LogicalDisk -ComputerName $RepoName -Filter "DeviceID = 'o:' " –credential $CredentialUserAlternate -ErrorVariable Err -ErrorAction Stop                                        
                                        $Servername=Get-WmiObject -Class Win32_ComputerSystem -ComputerName $RepoName -Credential $CredentialUserAlternate -ErrorAction Stop                                        
                                        $Servername=$Servername.Name                                     
                                        foreach ($objdisk in $Disks)  
                                        {  
                                                $out=New-Object PSObject
                                                $total = [Math]::Round([Math]::Round([Decimal]$objDisk.Size/1TB,1)) # round it to 1 decimal but the final answer round it to no decimals [math]::Round($Usado)        
                                                $free = [Math]::Round([Math]::Round([Decimal]$objDisk.FreeSpace/1TB,1)) # round it to 1 decimal but the final answer round it to no decimals [math]::Round($Usado)                                                
                                                $usedspace= ($total - $free)
                                                $usedspace = [Math]::Round($usedspace) # ,0 decimals [math]::Round($Usado)
                                                $freePercent=“{0:P0}” -f ([double]$objDisk.FreeSpace/[double]$objDisk.Size) 
                                                $out | Add-Member -MemberType NoteProperty -Name "Purpose" -Value $Purpose
                                                $out | Add-Member -MemberType NoteProperty -Name "Repository" -Value $Servername
                                                $out | Add-Member -MemberType NoteProperty -Name "Drive" -Value $objDisk.DeviceID
                                                $out | Add-Member -MemberType NoteProperty -Name "Used (TB)" -Value $usedspace        
                                                $out | Add-Member -MemberType NoteProperty -Name "Provisioned (TB)" -Value $total 
                                                $out | Add-Member -MemberType NoteProperty -Name “Free (TB)” -Value $free 
                                                $out | Add-Member -MemberType NoteProperty -Name “Free Space (%)” -Value $freePercent
                                                $out | Add-Member -MemberType NoteProperty -Name "Scale Out Repository" -Value $SOR
                                                $out | Add-Member -MemberType NoteProperty -Name "Environment" -Value $Environment
                                                $out | Add-Member -MemberType NoteProperty -Name "Region" -Value $Region
                                                $out | Add-Member -MemberType NoteProperty -Name "Building" -Value $Building
                                                $out | Add-Member -MemberType NoteProperty -Name "Status" -Value "Online"
                                                $out | Add-Member -MemberType NoteProperty -Name "Date" -Value $global:DateReportColumn                                                                           
                                                $out | export-csv ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv') -NoTypeInformation -Append
                                                cls
                                        } # fin foreach ($objdisk in $Disks)
                                        # Remove-PSSession -Session $Session #remueve session
                                } #fin try
                                catch #if there is an error return 1 with get-wmiobject
                                {
                                        #return 1 > $LogNull;
                                        $MSGAccess = "Access-Denied"
                                        $out=New-Object PSObject                                        
                                        $out | Add-Member -MemberType NoteProperty -Name "Purpose" -Value $Purpose
                                        $out | Add-Member -MemberType NoteProperty -Name "Repository" -Value $RepoShort                                        
                                        $out | Add-Member -MemberType NoteProperty -Name "Drive" -Value $MSGAccess
                                        $out | Add-Member -MemberType NoteProperty -Name "Used (TB)" -Value "0"        
                                        $out | Add-Member -MemberType NoteProperty -Name "Provisioned (TB)" -Value "0"
                                        $out | Add-Member -MemberType NoteProperty -Name “Free (TB)” -Value "0"
                                        $out | Add-Member -MemberType NoteProperty -Name “Free Space (%)” -Value "0%"
                                        $out | Add-Member -MemberType NoteProperty -Name "Scale Out Repository" -Value $SOR
                                        $out | Add-Member -MemberType NoteProperty -Name "Environment" -Value $Environment
                                        $out | Add-Member -MemberType NoteProperty -Name "Region" -Value $Region
                                        $out | Add-Member -MemberType NoteProperty -Name "Building" -Value $Building
                                        $out | Add-Member -MemberType NoteProperty -Name "Status" -Value "Online"
                                        $out | Add-Member -MemberType NoteProperty -Name "Date" -Value $global:DateReportColumn                                                                             
                                        $out | export-csv ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv') -NoTypeInformation -Append
                                } # fin catch
                        } # fin if si hay connection
                        else 
                        {
                                #Write-Host $Computer is offline -ForegroundColor Red
                                $MSGStatus = "Offline"
                                $out=New-Object PSObject
                                $out | Add-Member -MemberType NoteProperty -Name "Purpose" -Value $Purpose
                                $out | Add-Member -MemberType NoteProperty -Name "Repository" -Value $RepoShort                                
                                $out | Add-Member -MemberType NoteProperty -Name "Drive" -Value $MSGStatus
                                $out | Add-Member -MemberType NoteProperty -Name "Used (TB)" -Value "0"        
                                $out | Add-Member -MemberType NoteProperty -Name "Provisioned (TB)" -Value "0"
                                $out | Add-Member -MemberType NoteProperty -Name “Free (TB)” -Value "0"
                                $out | Add-Member -MemberType NoteProperty -Name “Free Space (%)” -Value "0%"
                                $out | Add-Member -MemberType NoteProperty -Name "Scale Out Repository" -Value $SOR
                                $out | Add-Member -MemberType NoteProperty -Name "Environment" -Value $Environment
                                $out | Add-Member -MemberType NoteProperty -Name "Region" -Value $Region
                                $out | Add-Member -MemberType NoteProperty -Name "Building" -Value $Building
                                $out | Add-Member -MemberType NoteProperty -Name "Status" -Value "Offline"                                   
                                $out | Add-Member -MemberType NoteProperty -Name "Date" -Value $global:DateReportColumn
                                $out | export-csv ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv') -NoTypeInformation -Append                                
                        } #fin else test fallido #computer offline                        
                } # fin if (![string]::IsNullOrWhiteSpace($CheckifContainData)) #se encuentra lleno                         
        }  # fin foreach ($Computer in $Computers) 

#endregion

#region call other functions
    GenerateDiskUsageReposCSVtoHTML
    StartHTMLDiskUsageRepos
    EmailRepos $global:NeedEmail $global:ToSendEmail   
#endregion
} #fin function RemoteDiskUsageRepos

function GenerateDiskUsageReposCSVtoHTML
{

###################variables#############################################################################################################################
        #$global:pathServerCSV = $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv' #local path on the remote
        #$global:pathServerHTML = $global:pathServerOneForAllHTML + "\" + $global:CSVFile + $global:CurrentDateTime + '.html' #local path        
################################################################################################################################################################  

#=========================================================================================================================================================
#Convert Merged .csv Final Report to html css
#=========================================================================================================================================================

$css = @"
<style>
h1, h5, th { text-align: center; font-family: Segoe UI; }
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 11px; padding: 5px 20px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
"@


        #region User-Variables
        
        #end region

        if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv') -PathType leaf) # Leaf for file Container for folders
        {       
                #################Trim section################################################################################
                $Loadfile = GC ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv')
                if (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                {
                        $Loadfile = $Loadfile.Trim()
                } # fin (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                $Loadfile > ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv')
                ###############################################################################################################

                #################Remove Empty LInes############################################################################
                $file = ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv')
                (gc $file) | ? {$_.trim() -ne "" } | set-content $file
                $content = [System.IO.File]::ReadAllText($file)
                $content = $content.Trim()
                [System.IO.File]::WriteAllText($file, $content)
                ###############################################################################################################
                $ImporCSVRepos = Import-CSV ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv') <# | sort "Name" #> # quitar el -Unique #importa el csv que se forma con final merged y los ordena por nombre 
                $ImporCSVRepos | ConvertTo-Html -Head $css -Body "<h1>Capacity Report - Veeam Repos</h1>`n<h5>Generated on $(Get-Date)</h5>" | Out-File ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllHTML + "\" + $global:CSVFile + $global:CurrentDateTime + '.html') # convierte el csv a css html
        } #fin if Test-Path        
} #fin function GenerateDiskUsageCSVtoHTML


function StartHTMLDiskUsageRepos
{    
    

    # region if html exists launch it
    if (Test-Path ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllHTML + "\" + $global:CSVFile + $global:CurrentDateTime + '.html') -PathType leaf)
    {
            start ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllHTML + "\" + $global:CSVFile + $global:CurrentDateTime + '.html')
    }
    #endregion

} #fin function StartHTMLDiskUsage


function EmailRepos
{

        Param
        (                
         
                [string]
                $SendEmailParam,
                [array]
                $ToEmailParam
        )


        # Report Title
        $BaRTitle = "IT Backup and Restore"
        # Report Title
        $rptTitle = "Capacity Report - Veeam Repos"
        # Email configuration
        $sendEmail = $SendEmailParam        
        $emailHost = "smtp.intel.com"
        $emailPort = 25
        $emailEnableSSL = $false
        $emailUser = ""
        $emailPass = ""
        $emailFrom = "jose.andres.torres@intel.com"
        $EmailToAddresses = @($ToEmailParam)
        #email1@intel.com, email2@intel.com, jose.andres.torres@intel.com
        # Send HTML report as attachment (else HTML report is body)
        # $emailAttach = $false
        # Email Subject 
        $emailSubject = $rptTitle
        
        # Append Date and Time to Email Subject
        $dtSubject = $true

        # Append Date and Time to Email subject
        If ($dtSubject) 
        {
                $emailSubject = "$emailSubject - $(Get-Date -format g)"
        }

        #region Output
        # Send Report via Email
        If ($sendEmail -eq $true) 
        {
                # $emailAttach = $true
                $smtp = New-Object System.Net.Mail.SmtpClient($emailHost, $emailPort)
                $smtp.Credentials = New-Object System.Net.NetworkCredential($emailUser, $emailPass)
                $smtp.EnableSsl = $emailEnableSSL                
                $pathCSVEmail = ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllCSV + "\" + $global:CSVFile + $global:CurrentDateTime + '.csv')
                $pathHTMLEmail = ("\\" + $global:ServerLogName + "\" + $global:pathServerOneForAllHTML + "\" + $global:CSVFile + $global:CurrentDateTime + '.html')
                $attachment = new-object System.Net.Mail.Attachment $pathCSVEmail                
                $HTML = Get-Content $pathHTMLEmail -Raw
                $htmlOutput = $HTML
                $body = $htmlOutput                
                foreach ($EmailTo in $EmailToAddresses)
                {
                        $msg = New-Object System.Net.Mail.MailMessage($emailFrom, $EmailTo)                
                        $msg.Subject = $emailSubject
                        $msg.Attachments.Add($attachment)                        
                        $msg.Body = $body
                        $msg.isBodyhtml = $true
                        $smtp.send($msg)
                } #fin foreach ($EmailToAddressesAddresses in $EmailToAddresses)                 
                $attachment.dispose()                
        } #fin if $send email $true
        else
        {
            break
        } # fin else not send email
#endregion
} #fin EmailRepos



########################################################################################################################################################################################################################################
#MAIN FUNCTION TO RELAUNCH MENU START BEGIN PROGRAM
########################################################################################################################################################################################################################################

function RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU
{
        
        $global:DateReportColumn = $(Get-Date -format "MM/dd/yyyy") # date to include in the all for one report
        $Today = $(Get-Date) # get current day date and time        
        $DT = $(Get-Date -format "MM/dd/yyyy HH:mm:ss") # get current date and time / get-date -format g Retrieve the current date and time, display as a General short date/time: 8/31/2019 4:13 PM used for logs           
        $global:CurrentDateTime = $global:CurrentDateTime = (Get-Date -Format MMddyyyy_HHmmss)
        Clear-Host
        $OptionMenuPrincipal = ""
        do
        { #do PRINCIPAL antes del switch   
	        CreateMenuPrincipal -Title "Veeam Backup & Replication - IT BaR Team" -MenuItems "Enroll into Backups","Un-enroll from Backups","Reports","About","Exit" -TitleColor White -LineColor Cyan -MenuItemColor Yellow	 
            $OptionMenuPrincipal = ""
            $OptionMenuPrincipal = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case   
            switch ($OptionMenuPrincipal)
            { #switch 1
                    '1' 
                    {#option 1 PRINCIPAL
                        do
                        {#do opt1 CreateMenuPhysicalVirtual antes del switch  OptionMenuPhysicalVirtual                                                 
                            CreateMenuPhysicalVirtual
                            $OptionMenuPhysicalVirtual = ""
                            $OptionMenuPhysicalVirtual = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case                            
                            
                            
                            switch ($OptionMenuPhysicalVirtual)
                            { #switch CreateMenuPhysicalVirtual

                                '1' 
                                {#option 1 Physical Sever - Agent Level - Software based menu physical virtual
                                                                     
                                        do
                                        {#do opt CreateMenuWindowsLinux antes del switch

                                            CreateMenuWindowsLinux
                                            $SelectionMenuWindowsLinux = ""
                                            $SelectionMenuWindowsLinux = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 

                                            switch($SelectionMenuWindowsLinux)
                                            { #begin switch CreateMenuWindowsLinux                                                        

                                                    '1' #Windows
                                                    {

                                                        
                                                          do
                                                          {#do opt1 CreateMenuEnroll antes del switch CreateMenuEnroll

                                                                CreateMenuEnroll
                                                                $global:OptionMenuEnroll = ""
                                                                $global:OptionMenuEnroll = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                $global:ProdorNon = '' #Assign it to Global Variables to control if Non prod backup jobs csvs
        
                                                                switch ($global:OptionMenuEnroll)
                                                                { #switch CreateMenuEnroll

                                                                '0' #FM7 LAB FM7SVBRLAB200
                                                                {

                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "FM7SVBRLAB200.amr.corp.intel.com"
                                                                            ValidateRemoteAccess -VBRName "FM7SVBRLAB200.amr.corp.intel.com"
								                                            AddServer -VBRName "FM7SVBRLAB200.amr.corp.intel.com"
                                                                }

                                                                '1' #BGSSVBR100
                                                                {

                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "BGSSVBR100.gar.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "BGSSVBR100.gar.corp.intel.com"
								                                        AddServer -VBRName "BGSSVBR100.gar.corp.intel.com"

                                                                }

                                                                '2' #CH2SVBR100.amr.corp.intel.com
                                                                {

                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "CH2SVBR100.amr.corp.intel.com"                                                                        
                                                                        ValidateRemoteAccess -VBRName "CH2SVBR100.amr.corp.intel.com"
								                                        AddServer -VBRName "CH2SVBR100.amr.corp.intel.com"
                                                                }

                                                                
                                                                '3' #DL1SVBR100.ccr.corp.intel.com
                                                                {

                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "DL1SVBR100.ccr.corp.intel.com"                                                                        
                                                                        ValidateRemoteAccess -VBRName "DL1SVBR100.ccr.corp.intel.com"
								                                        AddServer -VBRName "DL1SVBR100.ccr.corp.intel.com"
                                                                }

                                                                '4' #FM1SVBR100
                                                                {
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "FM1SVBR100.amr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "FM1SVBR100.amr.corp.intel.com"
								                                        AddServer -VBRName "FM1SVBR100.amr.corp.intel.com"                                                            
                                                                }

                                                                '5' #FM7SVBR100
                                                                {                                                            
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "FM7SVBR100.amr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "FM7SVBR100.amr.corp.intel.com"
								                                        AddServer -VBRName "FM7SVBR100.amr.corp.intel.com"
                                                                }

                                                                '6' #HF2SVBR100
                                                                {
                                                            
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "HF2SVBR100.amr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "HF2SVBR100.amr.corp.intel.com"
								                                        AddServer -VBRName "HF2SVBR100.amr.corp.intel.com"
                                                                }

                                                                '7' #Non Prod HF2SVBR100 $OptionMenuEnroll = 6
                                                                {
                                                                        $ProdorNon = "HFNonProd"
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "HF2SVBR100.amr.corp.intel.com"                                                                        
                                                                        ValidateRemoteAccess -VBRName "HF2SVBR100.amr.corp.intel.com"
								                                        do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddWindowsPhysicalAMRNonprod -VBRName "HF2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux csvs                                                                                                                
                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddWindowsPhysicalEDNonprod -VBRName "HF2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux ED csvs
                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU $global:MMddyyyyHHmmss = (Get-Date -Format MMddyyyy_HHmmss) #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                }

                                                                  '8' #HF2SVBR200 Legal
                                                                {
                                                            
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "HF2SVBR200.amr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "HF2SVBR200.amr.corp.intel.com"
								                                        AddServer -VBRName "HF2SVBR200.amr.corp.intel.com"
                                                                }

                                                                '9' #PG12SVBR100.gar.corp.intel.com
                                                                {

                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "PG12SVBR100.gar.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "PG12SVBR100.gar.corp.intel.com"
								                                        AddServer -VBRName "PG12SVBR100.gar.corp.intel.com"
                                                                }

                                                                '10' #RA2SVBR100
                                                                {

                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "RA2SVBR100.amr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "RA2SVBR100.amr.corp.intel.com"
								                                        AddServer -VBRName "RA2SVBR100.amr.corp.intel.com"
                                                                }

                                                                '11' #RR7SVBR100
                                                                {

                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "RR7SVBR100.amr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "RR7SVBR100.amr.corp.intel.com"
								                                        AddServer -VBRName "RR7SVBR100.amr.corp.intel.com"
                                                                }


                                                               '12' #SC8SVBR100
                                                                {
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "SC8SVBR100.amr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "SC8SVBR100.amr.corp.intel.com"
								                                        AddServer -VBRName "SC8SVBR100.amr.corp.intel.com"
                                                                }


                                                                '13' #SHZ1SVBR100
                                                                {
                                                                
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "SHZ1SVBR100.ccr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "SHZ1SVBR100.ccr.corp.intel.com"
								                                        AddServer -VBRName "SHZ1SVBR100.ccr.corp.intel.com"
                                                                }                                                              

                                                                'm'
                                                                {
                                                                        RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU $global:MMddyyyyHHmmss = (Get-Date -Format MMddyyyy_HHmmss) #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                } #end m

                                                                'q' #option quit Menu ENROLL
                                                                {
                                                                        cls                                                                
                                                                        EXIT
                                                                }#end option Q Menu ENROLL

                                                             } #end switch CreateMenuEnroll 
                                                          }#end do option CreateMenuEnroll
                                                          until ($global:OptionMenuEnroll -eq 'q' -or $global:OptionMenuEnroll -eq 'Q') #end until CreateMenuEnroll                                                                                       
                                                    } #end Windows

                                                    '2' #Linux
                                                    {
                                                            
                                                            do
                                                            {#do opt1 CreateMenuEnroll antes del switch CreateMenuEnroll

                                                                CreateMenuEnroll
                                                                $global:OptionMenuEnroll = ""
                                                                $global:OptionMenuEnroll = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                        
                                                                switch ($global:OptionMenuEnroll)
                                                                { #switch CreateMenuEnroll

                                                                '0' #FM7 LAB FM7SVBRLAB200
                                                                {

                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "FM7SVBRLAB200.amr.corp.intel.com"
                                                                            ValidateRemoteAccess -VBRName "FM7SVBRLAB200.amr.corp.intel.com"
								                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "FM7SVBRLAB200.amr.corp.intel.com" #corre funcion actualizar linux csvs

                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "FM7SVBRLAB200.amr.corp.intel.com" #corre funcion actualizar linux ED csvs

                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU $global:MMddyyyyHHmmss = (Get-Date -Format MMddyyyy_HHmmss) #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin #FM7 LAB FM7SVBRLAB200

                                                                '1' #BGSSVBR100
                                                                {

                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "BGSSVBR100.gar.corp.intel.com"
                                                                            ValidateRemoteAccess -VBRName "BGSSVBR100.gar.corp.intel.com"
								                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "BGSSVBR100.gar.corp.intel.com" #corre funcion actualizar linux csvs

                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "BGSSVBR100.gar.corp.intel.com" #corre funcion actualizar linux ED csvs

                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU $global:MMddyyyyHHmmss = (Get-Date -Format MMddyyyy_HHmmss) #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED

                                                                } # #BGSSVBR100

                                                                '2' #CH2SVBR100.amr.corp.intel.com
                                                                {

                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "CH2SVBR100.amr.corp.intel.com"
                                                                            ValidateRemoteAccess -VBRName "CH2SVBR100.amr.corp.intel.com"
                                                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "CH2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux csvs

                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "CH2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux ED csvs

                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin CH2SVBR100

                                                                '3' #FM1SVBR100
                                                                {
                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "FM1SVBR100.amr.corp.intel.com"
                                                                            ValidateRemoteAccess -VBRName "FM1SVBR100.amr.corp.intel.com"
								                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "FM1SVBR100.amr.corp.intel.com" #corre funcion actualizar linux csvs

                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "FM1SVBR100.amr.corp.intel.com" #corre funcion actualizar linux ED csvs

                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin FM1SVBR100

                                                                '4' #FM7SVBR100
                                                                {                                                            
                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "FM7SVBR100.amr.corp.intel.com"
                                                                            ValidateRemoteAccess -VBRName "FM7SVBR100.amr.corp.intel.com"
								                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "FM7SVBR100.amr.corp.intel.com" #corre funcion actualizar linux csvs

                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "FM7SVBR100.amr.corp.intel.com" #corre funcion actualizar linux ED csvs

                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin FM7SVBR100

                                                                '5' #HF2SVBR100
                                                                {
                                                            
                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "HF2SVBR100.amr.corp.intel.com"                                                                            
                                                                            ValidateRemoteAccess -VBRName "HF2SVBR100.amr.corp.intel.com"
								                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "HF2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux csvs                                                                                                                
                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "HF2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux ED csvs                                                                                                               
                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin HF2SVBR100

                                                                '6' #Non Prod HF2SVBR100 $OptionMenuEnroll = 6
                                                                {
                                                                            $global:ProdorNon = '' #Assign it to Global Variables to control if Non prod backup jobs csvs
                                                                            $ProdorNon = "HFNonProd"
                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "HF2SVBR100.amr.corp.intel.com"                                                                            
                                                                            ValidateRemoteAccess -VBRName "HF2SVBR100.amr.corp.intel.com"
                                                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMRNonprod -VBRName "HF2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux csvs                                                                                                                
                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalEDNonprod -VBRName "HF2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux ED csvs
                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin Non Prod HF2SVBR100

                                                                '7' #HF2SVBR200 Legal
                                                                {
                                                            
                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "HF2SVBR200.amr.corp.intel.com"                                                                            
                                                                            ValidateRemoteAccess -VBRName "HF2SVBR200.amr.corp.intel.com"
								                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "HF2SVBR200.amr.corp.intel.com" #corre funcion actualizar linux csvs                                                                                                                
                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "HF2SVBR200.amr.corp.intel.com" #corre funcion actualizar linux ED csvs                                                                                                               
                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin HF2SVBR200 Legal

                                                                '8' #RA2SVBR100
                                                                {

                                                                            <# LoadUserCredentials #>
                                                                            $VBRNameGlobal = "RA2SVBR100.amr.corp.intel.com"
                                                                            ValidateRemoteAccess -VBRName "RA2SVBR100.amr.corp.intel.com"
								                                            do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "RA2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux csvs

                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "RA2SVBR100.amr.corp.intel.com" #corre funcion actualizar linux ED csvs

                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin RA2SVBR100


                                                               '9' #RR7SVBR100
                                                                {
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "RR7SVBR100.amr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "RR7SVBR100.amr.corp.intel.com"
								                                        do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "RR7SVBR100.amr.corp.intel.com" #corre funcion actualizar linux csvs

                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "RR7SVBR100.amr.corp.intel.com" #corre funcion actualizar linux ED csvs

                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin SC8SVBR100


                                                                '10' #SHZ1SVBR100
                                                                {
                                                                
                                                                        <# LoadUserCredentials #>
                                                                        $VBRNameGlobal = "SHZ1SVBR100.ccr.corp.intel.com"
                                                                        ValidateRemoteAccess -VBRName "SHZ1SVBR100.ccr.corp.intel.com"
								                                        do
                                                                            { #do This menau CreateMenuAMRED
                                                                                        CreateMenuAMRED
                                                                                        $OptionMenuAMRED = ""
                                                                                        $OptionMenuAMRED = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case 
                                                                                        switch ($OptionMenuAMRED)
                                                                                        { #switch CreateMenuAMRED
                                                                                                    '1' #this option 1 is to enroll it AMR backup job
                                                                                                    {                    
                                                                                                                AddLinuxPhysicalAMR -VBRName "SHZ1SVBR100.ccr.corp.intel.com" #corre funcion actualizar linux csvs

                                                                                                    } #option 1 switch MenuAMRED

                                                                                                    '2' #this option 2 is to enroll it ED backup job
                                                                                                    {    
                                                                                                                AddLinuxPhysicalED -VBRName "SHZ1SVBR100.ccr.corp.intel.com" #corre funcion actualizar linux ED csvs

                                                                                                    } #option 2 switch MenuAMRED

                                                                                                    'm'
                                                                                                    {
                                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                                    } #end m

                                                                                                   'q' #this option is to quit/exit
                                                                                                    {#option q switch MenuAMRED
                                                                                                                cls                                        
                                                                                                                EXIT
                                                                                                    }#end option Q ENROLL
    
                                                                                        } #end switch CreateMenuAMRED
                                                                            } # end do menu CreateMenuAMRED
                                                                            until ($OptionMenuAMRED -eq 'q') # end del until MenuAMRED
                                                                } # fin 10

                                                                '11' #
                                                                {
                                                                } # fin 11

                                                                '12' #
                                                                {
                                                                } # fin 12

                                                                '13' #
                                                                {
                                                                } # fin 13

                                                                'm'
                                                                {
                                                                        RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                } #end m                                                                

                                                                'q' #option quit Menu ENROLL
                                                                {
                                                                        cls                                                                
                                                                        EXIT
                                                                }#end option Q Menu ENROLL

                                                                } #end switch CreateMenuEnroll 
                                                          }#end do option CreateMenuEnroll
                                                          until ($global:OptionMenuEnroll -eq 'q' -or $global:OptionMenuEnroll -eq 'Q') #end until CreateMenuEnroll
                                                    
                                                    } #end Linux

                                                    'm'
                                                    {
                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                    } #end m

                                                    'q' #quit
                                                    {                                                            
                                                            cls
                                                            EXIT
                                                    }# end quit                                                    
                                                  
                                            } #end switch

                                       } # end do opt create menu windowslinux
                                       until ($SelectionMenuWindowsLinux -eq 'q' -or $SelectionMenuWindowsLinux -eq 'Q') #end until CreateMenuWindowsLinux
                                    }#end option 1 physical                                   

                            '2' 
                                {#option 2 virtual image level menu physical virtual
                                    
                                    <# LoadUserCredentials #>

                                }#end option 2 virtual image level

                            'm'
                            {
                                    RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                            } #end m
                                                    
                            'q' 
                                {#option q ENROLL
                                    cls                                    
                                    EXIT
                                }#end option Q ENROLL

                            } #end switch CreateMenuPhysicalVirtual

                        }#end do option 1 ENROLL
                        until ($OptionMenuPhysicalVirtual -eq 'q' -or $OptionMenuPhysicalVirtual -eq 'Q') #end until CreateMenuPhysicalVirtual
                                                
                    }#end option 1 PRINCIPAL
                
                '2' #option 2 PRINCIPAL UN-ENROLL removes server(s) from policy
                {
                        cls
                        do
                        { #do CreateMenuPhysicalVirtual antes del switch  OptionMenuPhysicalVirtual
                                CreateMenuPhysicalVirtual
                                $OptionMenuPhysicalVirtual = ""
                                $OptionMenuPhysicalVirtual = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case
                                switch ($OptionMenuPhysicalVirtual)
                                {
                                        '1'  #option 1 Physical Sever - UN-ENROLL
                                        {
                                                do
                                                {
                                                        CreateMenuUnenroll
                                                        $global:OptionMenuUnenroll = ""
                                                        $global:OptionMenuUnenroll = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case                                                                            
                                                        switch ($global:OptionMenuUnenroll) #UN-ENROLL
                                                        {
                                                                                    '0' #FM7 LAB FM7SVBRLAB200
                                                                                    {

                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "FM7SVBRLAB200.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "FM7SVBRLAB200.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "FM7SVBRLAB200.amr.corp.intel.com"
                                                                                    }

                                                                                    '1' #BGSSVBR100
                                                                                    {

                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "BGSSVBR100.gar.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "BGSSVBR100.gar.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "BGSSVBR100.gar.corp.intel.com"
                                                                                    }

                                                                                    '2' #CH2SVBR100.amr.corp.intel.com
                                                                                    {

                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "CH2SVBR100.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "CH2SVBR100.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "CH2SVBR100.amr.corp.intel.com"
                                                                                    }

                                                                                    '3' #DL1SVBR100
                                                                                    {
                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "DL1SVBR100.ccr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "DL1SVBR100.ccr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "DL1SVBR100.ccr.corp.intel.com"                                                            
                                                                                    }

                                                                                    '4' #FM1SVBR100
                                                                                    {
                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "FM1SVBR100.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "FM1SVBR100.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "FM1SVBR100.amr.corp.intel.com"                                                            
                                                                                    }

                                                                                    '5' #FM7SVBR100
                                                                                    {                                                            
                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "FM7SVBR100.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "FM7SVBR100.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "FM7SVBR100.amr.corp.intel.com"
                                                                                    }
        
                                                                                    '6' #HF2SVBR100
                                                                                    {
                                                                
                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "HF2SVBR100.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "HF2SVBR100.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "HF2SVBR100.amr.corp.intel.com"
                                                                                    }    
                                                                                    
                                                                                    '7' #HF2SVBR200 Legal
                                                                                    {
                                                                
                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "HF2SVBR200.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "HF2SVBR200.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "HF2SVBR200.amr.corp.intel.com"
                                                                                    }
                                                                                    
                                                                                     '8' #PG12SVBR100
                                                                                    {

                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "PG12SVBR100.gar.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "PG12SVBR100.gar.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "PG12SVBR100.gar.corp.intel.com"
                                                                                    }      
                                                                                 

                                                                                    '9' #RA2SVBR100
                                                                                    {

                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "RA2SVBR100.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "RA2SVBR100.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "RA2SVBR100.amr.corp.intel.com"
                                                                                    }


                                                                                    '10' #RR7SVBR100
                                                                                    {
                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "RR7SVBR100.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "RR7SVBR100.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "RR7SVBR100.amr.corp.intel.com"
                                                                                    }

                                                                                    '11' #SC8SVBR100
                                                                                    {
                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "SC8SVBR100.amr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "SC8SVBR100.amr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "SC8SVBR100.amr.corp.intel.com"
                                                                                    }


                                                                                    '12' #SHZ1SVBR100.ccr.corp.intel.com
                                                                                    {
                                                                
                                                                                                <# LoadUserCredentials #>
                                                                                                $VBRNameGlobal = "SHZ1SVBR100.ccr.corp.intel.com"
                                                                                                ValidateRemoteAccess -VBRName "SHZ1SVBR100.ccr.corp.intel.com"
								                                                                DeleteServerFromProtectionGroup -VBRName "SHZ1SVBR100.ccr.corp.intel.com"
                                                                                    }
                                               

                                                                                    'm'
                                                                                    {
                                                                                            RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                    } #end m

                                                                                    'q' #option quit Menu ENROLL
                                                                                    {
                                                                                        cls                                                                
                                                                                        EXIT
                                                                                    }#end option Q Menu ENROLL
                                                        } #fin switch ($global:OptionMenuUnenroll) #UN-ENROLL
                                                } # fin do Physical Sever - UN-ENROLL
                                                until ($global:OptionMenuUnenroll -eq 'q' -or $global:OptionMenuUnenroll -eq 'Q') #end until CreateMenuEnroll UN-ENROLL
                                        } # fin switch option 1 Physical Sever - UN-ENROLL

                                        '2' #option 2 Virtual Sever - UN-ENROL
                                        {
                                        } # fin switch option 2 Virtual Sever - UN-ENROL

                                        'm'
                                        {
                                                RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                        } #end m

                                        'q' #option quit Menu ENROLL
                                        {
                                                cls                                                                
                                                EXIT
                                        }#end option Q Menu ENROLL                             
                                } #fin #switch CreateMenuPhysicalVirtual UN-ENROLL                                 
                        } # fin #do CreateMenuPhysicalVirtual antes del switch  OptionMenuPhysicalVirtual
                        until ($OptionMenuPhysicalVirtual -eq 'q' -or $OptionMenuPhysicalVirtual -eq 'Q') #end until CreateMenuPhysicalVirtual UN-ENROLL
                } #Fin option 2 PRINCIPAL UN-ENROLL removes server(s) from policy
                
                '3' #Opcion Report
                    {
                        cls                        
                        do
                        {#do opt3 MenuReports antes del switch  OptionMenuReports
                                MenuReports
                                $OptionMenuReports = ""
                                $OptionMenuReports = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case                            
                                
                                switch ($OptionMenuReports)
                                { #switch OptionMenuReports 

                                                '1'  #option 1 View Backup Status
                                                {                                                                                                        
                                                     do
                                                     {#do opt1 Menu Backup Status antes del switch  OptionMenuReports
                                                        MenuSingleMultipeVBR
                                                        $OptionMenuSingleMultipeVBR = ""
                                                        $OptionMenuSingleMultipeVBR = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case                            
                                
                                                        switch ($OptionMenuSingleMultipeVBR)
                                                        { #switch OptionMenuSingleMultipeVBR

                                                            '1' #Choose One Single VBR
                                                            {                         
                                                                    do #do 2 CreateMenuEnroll View Backups antes del switch CreateMenuEnroll
                                                                {
                                                                        MenuViewBackupStatusEnv
                                                                        $global:OptionMenuEnrollViewBackups = ""
                                                                        $global:OptionMenuEnrollViewBackups = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case                                                                 

                                                                        switch ($global:OptionMenuEnrollViewBackups)
                                                                        { #switch CreateMenuEnroll
                                                                            
                                                                            '0' #FM7 LAB FM7SVBRLAB200
                                                                                {

                                                                                        $global:VBRList = @("FM7SVBRLAB200.amr.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList
                                                                                }

                                                                                '1' #BGSSVBR100
                                                                                {       
                                                                                        $global:VBRList = @("BGSSVBR100.gar.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList
                                                                                }

                                                                                '2' #CH2SVBR100.amr.corp.intel.com
                                                                                {       
                                                                                        $global:VBRList = @("CH2SVBR100.amr.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList
                                                                                }

                                                                                '3' #FM1SVBR100
                                                                                {       
                                                                                        $global:VBRList = @("FM1SVBR100.amr.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList
                                                                                }

                                                                                '4' #FM7SVBR100
                                                                                {       
                                                                                        $global:VBRList = @("FM7SVBR100.amr.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList
                                                                                }

                                                                                '5' #HF2SVBR100
                                                                                {     
                                                                                        #$VBRNameGlobal = "HF2SVBR100.amr.corp.intel.com"                                                                                        
                                                                                        $global:VBRList = @("HF2SVBR100.amr.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList                                                                                       
                                                                                } # fin opc 5

                                                                                '6' #HF2SVBR200 Legal
                                                                                {     
                                                                                        #$VBRNameGlobal = "HF2SVBR200.amr.corp.intel.com"                                                                                        
                                                                                        $global:VBRList = @("HF2SVBR200.amr.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList                                                                                       
                                                                                } # fin opc 6
                                                                               
                                                                                '7' #RA2SVBR100
                                                                                {
                                                                                        $global:VBRList = @("RA2SVBR100.amr.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList
                                                                                }

                                                                                '8' #SC8SVBR100
                                                                                {
                                                                                        <# $global:CurrentDateTime = (Get-Date -Format MMddyyyy_HHmmss)
                                                                                        $VBRNameGlobal = "SC8SVBR100.amr.corp.intel.com" > ("\\$global:ServerLogName\$global:PathTXTFolder\$global:VBRListFilename")
                                                                                        $global:VBRList = gc ("\\$global:ServerLogName\$global:PathTXTFolder\$global:VBRListFilename")
                                                                                        $global:VBRList = @($global:VBRList)
                                                                                        PrepareViewBackupStatus $global:VBRList    #>
                                                                                }

                                                                                '9' #SHZ1SVBR100
                                                                                {       
                                                                                        $global:VBRList = @("SHZ1SVBR100.ccr.corp.intel.com")
                                                                                        PrepareViewBackupStatus $global:VBRList
                                                                                        
                                                                                        
                                                                                }

                                                                                '10' #
                                                                                {
                                                                                }

                                                                                '11' #
                                                                                {
                                                                                }

                                                                                '12' #
                                                                                {
                                                                                }

                                                                                'm'
                                                                                {
                                                                                   RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                } #end m
                                                                            
                                                                                'q' #option quit Menu ENROLL
                                                                                {
                                                                                    cls                                                                
                                                                                    EXIT
                                                                                }#end option Q Menu ENROLL

                                                                        } #end switch OptionMenuEnrollViewBackups 
                                                                }#end do option OptionMenuEnrollViewBackups
                                                                until ($OptionMenuEnrollViewBackups -eq 'q' -or $OptionMenuEnrollViewBackups -eq 'Q') #end until CreateMenuEnroll                                                                                                       
                                                            } # fin op1 OptionMenuSingleMultipeVBR Single

                                                            '2' #Runs against all VBRs
                                                            {
                                                                    if (Test-Path ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -PathType leaf) #si existe el file
                                                                    {
                                                                            $global:CurrentDateTime = $global:CurrentDateTime = (Get-Date -Format MMddyyyy_HHmmss) #refreshes current date and time - minutes and seconds
                                                                            #################Trim section################################################################################
                                                                            $LoadfileSvrs = GC ("\\"+ $ServerExecuteProgram + "\" + $global:ServersTXTFull) #variable para validar que tiene info
                                                                            if (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                                                                            {
                                                                                    $LoadfileSvrs = $LoadfileSvrs.Trim().ToLower()
                                                                            } # fin (![string]::IsNullOrWhiteSpace($Loadfile)) #revisa que no se encuentre !NO vacio serverstxt
                                                                            $LoadfileSvrs > ("\\"+ $ServerExecuteProgram + "\" + $global:ServersTXTFull) #variable para validar que tiene info
                                                                            ###############################################################################################################

                                                                            #################Remove Empty LInes############################################################################
                                                                            $fileSvrs = ("\\"+ $ServerExecuteProgram + "\" + $global:ServersTXTFull) #variable para validar que tiene info
                                                                            (gc $fileSvrs) | ? {$_.trim() -ne "" } | set-content $fileSvrs
                                                                            $contentSvrs = [System.IO.File]::ReadAllText($fileSvrs)
                                                                            $contentSvrs = $contentSvrs.Trim()                                                                           
                                                                            [System.IO.File]::WriteAllText($fileSvrs, $contentSvrs)
                                                                            ###############################################################################################################                                                                            
                                                                            $CheckifContainData = Get-Content ("\\"+ $ServerExecuteProgram + "\" + $global:ServersTXTFull) #variable para validar que tiene info
                                                                            if (![string]::IsNullOrWhiteSpace($CheckifContainData)) #revisa que no se encuentre !NO vacio serverstxt
                                                                            {
                                                                                    $CheckifContainData > ("\\" + $global:ServerExecuteProgram + "\" + $global:PathTXTFolder + "\" + $global:NewServerList + "_" + $global:CurrentDateTime + ".txt")  #crea una copia del la lista de computadoras y le crea un nombre consecutivo con currentdatetime
                                                                                    New-Item ("\\" + $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -type file -force > $LogNull   #creates a new file to clear the contents from servers list locally in case someone else runs the application

                                                                                    PopulateVBRList                                                                                    
                                                                                    $global:AllVBRList = gc ("\\$global:ServerLogName\$global:PathTXTFolder\$global:VBRListFilename")
                                                                                    $global:AllVBRList = @($global:AllVBRList)
                                                                                    
                                                                                    foreach ($VBR in $global:AllVBRList)
                                                                                    {
                                                                                            if (![string]::IsNullOrWhiteSpace($VBR)) #revisa VBR que no se encuentre !NO vacio serverstxt
                                                                                            {                                                                                                    
                                                                                                    PrepareViewBackupStatusMultiple $VBR                                                                                                    
                                                                                            } 
                                                                                            else
                                                                                            {
                                                                                                    break
                                                                                            }  
                                                                                    } #fin foreach ($VBR in $global:AllVBRList)
                                                                                    CombineCSVs
	                                                                                GenerateCSVtoHTML                                                                                                                                                
                                                                            } # fin IF para validar que el ServerTXTFull tiene info
                                                                            else
                                                                            {
                                                                                    cls
                                                                                    WRITE-HOST "Error! $LASTEXITCODE " -ForegroundColor Red -NoNewline; WRITE-HOST "The file is empty" -ForegroundColor Yellow -BackgroundColor Red -NoNewline; WRITE-HOST " There is not even one server name to proceed" -ForegroundColor Red;        
                                                                                    pause
                                                                            } #fin else servers.txt se encuentra vacio                                                                    
                                                                    } # fin if si existe el ServersTXTFull (Test-Path ("\\"+ $global:ServerExecuteProgram + "\" + $global:ServersTXTFull) -PathType leaf) #si existe el file                                                                                                                                        
                                                            } # fin op2 OptionMenuSingleMultipeVBR Multiple

                                                            'm'
                                                            {
                                                                   RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU $global:MMddyyyyHHmmss = (Get-Date -Format MMddyyyy_HHmmss) #FUNCTION TO LAUNCH MAIN MENU
                                                            } #end m
                                                            'q'
                                                            {
                                                                cls
                                                                EXIT
                                                            } # fin q OptionMenuSingleMultipeVBR

                                                         } #fin switch OptionMenuSingleMultipeVBR  
                                                }#end do option 1 View Backup Status
                                                until ($OptionMenuSingleMultipeVBR -eq 'q' -or $OptionMenuSingleMultipeVBR -eq 'Q') #end until MenuReports                                                                    
                                                } # fin op 1

                                                '2'  #option 2 Capacity Local Repository
                                                {

                                                                    do #do 2 CreateMenuLocalCapacity Capacity Report antes del switch CreateMenuEnroll
                                                                    {
                                                                        CreateMenuLocalCapacity
                                                                        $global:OptionCreateMenuLocalCapacity = ""
                                                                        $global:OptionCreateMenuLocalCapacity = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case                                                                 

                                                                        switch ($global:OptionCreateMenuLocalCapacity)
                                                                        { #switch CreateMenuEnroll
                                                                            
                                                                            '0' #FM7 LAB FM7SVBRLAB200 / Alternate Capacity for Veeam Servers
                                                                                {
                                                                                        
                                                                                        $AlternatelocationCapacity = Read-Host -Prompt 'Enter Server FQDN' #or can change it to the name of the user or different file name                                                                                        
                                                                                        $global:VBRList = @($AlternatelocationCapacity.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '1' #BGSSVBR100
                                                                                {                                                                                        
                                                                                        $VBRNameGlobal = "BGSSVBR100.gar.corp.intel.com"                                                                                        
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList   
                                                                                }

                                                                                '2' #CH2SVBR100.amr.corp.intel.com
                                                                                {       
                                                                                        $VBRNameGlobal = "CH2SVBR100.amr.corp.intel.com"                                                                                        
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '3' #DL1SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "DL1SVBR100.ccr.corp.intel.com"                                                                                        
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '4' #FM1SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "FM1SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                 '5' #FM1SVBR500 SAP
                                                                                {       
                                                                                        $VBRNameGlobal = "FM1SVBR500.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '6' #FM7SVBR100 Non-Prod
                                                                                {       
                                                                                        $VBRNameGlobal = "FM7SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '7' #FM7SVBR500 SAP
                                                                                {       
                                                                                        $VBRNameGlobal = "FM7SVBR500.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '8' #HF2SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "HF2SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '9' #HF2SVBR200
                                                                                {       
                                                                                        $VBRNameGlobal = "HF2SVBR200.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '10' #OC8SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "OC8SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                 '11' #PG12SVBR100
                                                                                {                                                                                        
                                                                                        $VBRNameGlobal = "PG12SVBR100.gar.corp.intel.com"                                                                                        
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList   
                                                                                }

                                                                                '12' #RR7SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "RR7SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }
                                                                                
                                                                                '13' #RA2SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "RA2SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }  
                                                                                
                                                                                 '14' #SC8SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "SC8SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }                                                                             


                                                                                '15' #SHZ1SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "SHZ1SVBR100.ccr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }
                                                                            
                                                                                'm'
                                                                                {
                                                                                    RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                } #end m

                                                                                'q' #option quit Menu ENROLL
                                                                                {
                                                                                    cls                                                                
                                                                                    EXIT
                                                                                }#end option Q Menu ENROLL

                                                                        } #end switch OptionMenuEnrollViewBackups 
                                                                }#end do option OptionMenuEnrollViewBackups
                                                                until ($global:OptionCreateMenuLocalCapacity -eq 'q' -or $global:OptionCreateMenuLocalCapacity -eq 'Q') #end until CreateMenuEnroll
                                                } # fin op 2

                                                '3'  #option 3 Capacity VCCE Repository
                                                {

                                                                    do #do 3 antes del switch CreateMenuVCCE
                                                                    {
                                                                        CreateMenuVCCE
                                                                        $global:OptionMenuVCCE = ""
                                                                        $global:OptionMenuVCCE = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case                                                                 

                                                                        switch ($global:OptionMenuVCCE)
                                                                        { #switch OptionMenuVCCE

                                                                                '1' #CH2SVCCE100.amr.corp.intel.com
                                                                                {
                                                                                        $VBRNameGlobal = "CH2SVCCE100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '2' #FM1SVCCE100.amr.corp.intel.com
                                                                                {       
                                                                                        $VBRNameGlobal = "FM1SVCCE100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '3' #HF2SVCCE100.amr.corp.intel.com
                                                                                {       
                                                                                        $VBRNameGlobal = "HF2SVCCE100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                '4' #PG12SVCCE100.gar.corp.intel.com
                                                                                {       
                                                                                        $VBRNameGlobal = "PG12SVCCE100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateRepoProxyReport $global:VBRList
                                                                                }

                                                                                'm'
                                                                                {
                                                                                        RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                } #end m
                                                                            
                                                                                'q' #option quit Menu ENROLL
                                                                                {
                                                                                    cls                                                                
                                                                                    EXIT
                                                                                }#end option Q Menu ENROLL

                                                                        } #end switch OptionMenuVCCE 
                                                                }#end do option OptionMenuVCCE
                                                                until ($global:OptionMenuVCCE -eq 'q' -or $global:OptionMenuVCCE -eq 'Q') #end until CreateMenuVCCE                                        
                                                } # fin opc 3

                                                '4'
                                                {                                                        
                                                        do
                                                        { 
                                                                MenuOneForAll                                                     
                                                                $global:OptionMenuAllForOne = ""
                                                                $global:OptionMenuAllForOne = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case   
                                                                switch ($global:OptionMenuAllForOne)
                                                                {
                                                                        '1'
                                                                        {
                                                                                cls
                                                                                $global:NeedEmail = $false
                                                                                $global:ToSendEmail = ""
                                                                                DiskUsageRepos $global:AMRCredential
                                                                        } # fin option 1

                                                                        '2'
                                                                        {                                                                                
                                                                                cls
                                                                                $global:NeedEmail = $true
                                                                                $global:ToSendEmail = ""
                                                                                $global:ToSendEmail = (Read-Host "Please enter email address").ToLower().Trim(); #Set characters to lower case                           
                                                                                DiskUsageRepos $global:AMRCredential                                                                                                                                                                
                                                                        } # fin option 2 with email attachment

                                                                        'm'
                                                                        {
                                                                                RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                        } #end m
                                                                        
                                                                        'q' #option quit Menu ENROLL
                                                                        {
                                                                                cls                                                                
                                                                                EXIT
                                                                        }#end option Q Menu ENROLL

                                                                } # end switch ($global:OptionMenuAllForOne)
                                                        } # end do menu MenuOneForAll
                                                        until ($global:OptionMenuAllForOne -eq 'q') # end del until MenuOneForAll                                                
                                                } #fin opcion 4 One For all
                                                
                                                '5'
                                                {
                                                                    do #do 4 CreateMenuEnroll GenerateDiskUsageReport antes del switch CreateMenuEnroll FETB for Windows Servers Only
                                                                    {
                                                                        CreateMenuFETB
                                                                        $global:OptionMenuEnrollDiskUsage = ""
                                                                        $global:OptionMenuEnrollDiskUsage = (Read-Host "Please choose an option").ToLower(); #Set characters to lower case                                                                 

                                                                        switch ($global:OptionMenuEnrollDiskUsage)
                                                                        { #switch CreateMenuEnroll
                                                                            
                                                                            '0' #Alternate Location
                                                                                {       
                                                                                        $AlternatelocationCapacity = Read-Host -Prompt 'Enter Server FQDN' #or can change it to the name of the user or different file name                                                                                        
                                                                                        $global:VBRList = @($AlternatelocationCapacity.Trim().ToLower())                                                                                        
                                                                                        LoadUserCredentials
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:CredentialGlobal
                                                                                        #GenerateDiskUsageReportAlternate $global:VBRList, -Credential (Get-Credential) This is just a direct way to pass -Credential as parameters
                                                                                }

                                                                                '1' #BGSSVBR100
                                                                                {
                                                                                        $VBRNameGlobal = "BGSSVBR100.gar.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                }

                                                                                '2' #CH2SVBR100.amr.corp.intel.com
                                                                                {       
                                                                                        $VBRNameGlobal = "CH2SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                }

                                                                                '3' #FM1SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "FM1SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                }

                                                                                '4' #FM7SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "FM7SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                }

                                                                                '5' #HF2SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "HF2SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                }

                                                                                '6' #HF2SVBR200 Legal
                                                                                {       
                                                                                        $VBRNameGlobal = "HF2SVBR200.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                }

                                                                                '7' #RA2SVBR100
                                                                                {
                                                                                        $VBRNameGlobal = "RA2SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                }


                                                                                '8' #SC8SVBR100
                                                                                {
                                                                                 <#       $VBRNameGlobal = "SC8SVBR100.amr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                  #>
                                                                                }

                                                                                '9' #SHZ1SVBR100
                                                                                {       
                                                                                        $VBRNameGlobal = "SHZ1SVBR100.ccr.corp.intel.com"
                                                                                        $global:VBRList = @($VBRNameGlobal.Trim().ToLower())
                                                                                        GenerateDiskUsageReport $global:VBRList, -Credential $global:AMRCredential
                                                                                }

                                                                                '10' #
                                                                                {
                                                                                }

                                                                                '11' #
                                                                                {
                                                                                }

                                                                                '12' #
                                                                                {
                                                                                }

                                                                                'm'
                                                                                {
                                                                                        RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                                                } #end m
                                                                            
                                                                                'q' #option quit Menu ENROLL
                                                                                {
                                                                                    cls                                                                
                                                                                    EXIT
                                                                                }#end option Q Menu ENROLL

                                                                        } #end switch OptionMenuEnrollViewBackups 
                                                                }#end do option OptionMenuEnrollViewBackups
                                                                until ($global:OptionMenuEnrollDiskUsage -eq 'q' -or $global:OptionMenuEnrollDiskUsage -eq 'Q') #end until CreateMenuEnroll                                                                                        
                                                } # fin op 4 disk usage report

                                                'm'
                                                {
                                                        RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU #FUNCTION TO LAUNCH MAIN MENU                                                                                                    
                                                } #end m

                                                'q'  #option q Quits/Exit
                                                {
                                                    cls
                                                    EXIT
                                                } # fin quits

                                } #fin switch OptionMenuReports  
                        }#end do option 3 OptionMenuReports
                        until ($OptionMenuReports -eq 'q' -or $OptionMenuReports -eq 'Q') #end until MenuReports  
                    }#end option 3 PRINCIPAL

                '4' #Opcion ABOUT
                    {
                        cls                     
                        AboutJAT
                        pause                        
                    }#end option 4 PRINCIPAL
                
                '5' #opcion 5 Quits Exits
                    {
                        cls                        
                        EXIT
                    }#end option 5 PRINCIPAL

     } #end switch 1
} # end do 1 PRINCIPAL
until ($OptionMenuPrincipal -eq '5') # end until 1 Principal

} #fin RelaunchMainMenu #FUNCTION TO LAUNCH MAIN MENU


########################################################################################################################################################################################################################################
########################################################################################################################################################################################################################################
#BEGIN Application Start
########################################################################################################################################################################################################################################
#[console]::ForegroundColor = "Green" #Changes text color
#[console]::BackgroundColor = "Blue" #Changes the background color
#net stop workstation /y #restarting service resolves this issue. Multiple connections to a server or shared resource by the same user Error
#net start workstation #restarting service resolves this issue. Multiple connections to a server or shared resource by the same user Error

ValidateAllowedUser


########################################################################################################################################################################################################################################
########################################################################################################################################################################################################################################
#END FINAL
######################################################################################################################################################################################################################################## 