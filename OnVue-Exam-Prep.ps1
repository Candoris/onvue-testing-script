
#--!!--# 
#--!!--# 
#TODO:
    #Cleanup input box
    #Add output box with confirmation
    #Add additional error handling


#--!!--# 
#--!!--# 


param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
Function StopService {

    Get-Service -Name "ScreenConnect *" | Stop-Service -Force -Verbose 
    Get-Service -Name "ScreenConnect *" | Set-Service -StartupType Disabled -Verbose

    Get-Service -Name "SAAZ*" | Stop-Service -Force -Verbose 
    Get-Service -Name "SAAZ*" | Set-Service -StartupType Disabled -Verbose

    Get-Service -Name "Hyper-V*" | Stop-Service -Force -Verbose 
    Get-Service -Name "Hyper-V*" | Set-Service -StartupType Disabled -Verbose

    Get-Service -Name "LogMeIn*" | Stop-Service -Force -Verbose 
    Get-Service -Name "LogMeIn*" | Set-Service -StartupType Disabled -Verbose

    Get-Service -Name "LMIGuardian*" | Stop-Service -Force -Verbose 
    Get-Service -Name "LMIGuardian*" | Set-Service -StartupType Disabled -Verbose

    Get-Service -Name "zEvt*" | Stop-Service -Force -Verbose 
    Get-Service -Name "zEvt*" | Set-Service -StartupType Disabled -Verbose

    Stop-Process -Name ramaint
}
Function RestartService {

    Get-Service -Name "ScreenConnect *" | Set-Service -StartupType Automatic -Verbose
    Get-Service -Name "ScreenConnect *" | Start-Service -Verbose 
    
    Get-Service -Name "SAAZ*" | Set-Service -StartupType Automatic -Verbose
    Get-Service -Name "SAAZ*" | Start-Service -Verbose 
    
    Get-Service -Name "Hyper-V*" | Set-Service -StartupType Manual -Verbose
    Get-Service -Name "Hyper-V*" | Start-Service -Verbose 

    Get-Service -Name "LogMeIn*" | Set-Service -StartupType Automatic -Verbose
    Get-Service -Name "LogMeIn*" | Start-Service -Verbose 

    Get-Service -Name "LMIGuardian*" | Set-Service -StartupType Automatic -Verbose
    Get-Service -Name "LMIGuardian*" | Start-Service -Verbose 

    Get-Service -Name "zEvt*" | Set-Service -StartupType Automatic -Verbose
 #--!!--Don't start zEvt service automatically, it doesn't appear that it is supposed to be always running
  # Get-Service -Name "zEvt*" | Start-Service -Verbose 


}
Function Invoke-InputBox {

    [cmdletbinding(DefaultParameterSetName="plain")]
    [OutputType([system.string],ParameterSetName='plain')]
   

    Param(
     
            [Parameter(HelpMessage = "Please enter a timeframe",
            ParameterSetName="plain")]        

            [ValidateNotNullorEmpty()]
            [ValidateScript({$_.length -le 25})]
            [string]$Title = "GOOD LUCK ON YOUR EXAM!!!",

            [Parameter(ParameterSetName="secure")]        
            [Parameter(HelpMessage = "Enter a time",ParameterSetName="plain")]
            [ValidateNotNullorEmpty()]
            [ValidateScript({$_.length -le 50})]
            [string]$Prompt = "Please enter a timeframe (in Minutes):"
            
          )

    if ($PSEdition -eq 'Core') {
        Write-Warning "Sorry. This script will not run on PowerShell Core."
        #bail out
        Return
    }

    Add-Type -AssemblyName PresentationFramework
    Add-Type –assemblyName PresentationCore
    Add-Type –assemblyName WindowsBase

    #remove the variable because it might get cached in the ISE or VS Code
    Remove-Variable -Name TimeInput -Scope script -ErrorAction SilentlyContinue

    $form = New-Object System.Windows.Window
    $stack = New-object System.Windows.Controls.StackPanel

    #define input box size
    $form.Title = $title
    $form.Height = 150
    $form.Width = 350

    $label = New-Object System.Windows.Controls.Label
    $label.Content = "    $Prompt"
    $label.HorizontalAlignment = "left"
    $stack.AddChild($label)


    $inputbox = New-Object System.Windows.Controls.TextBox
 

    $inputbox.Width = 300
    $inputbox.HorizontalAlignment = "center"

    $stack.AddChild($inputbox)

    $space = new-object System.Windows.Controls.Label
    $space.Height = 10
    $stack.AddChild($space)

    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "_OK"

    $btn.Width = 65
    $btn.HorizontalAlignment = "center"
    $btn.VerticalAlignment = "bottom"

    #add an event handler
    $btn.Add_click( {

            $script:TimeInput = $inputbox.text
            $form.Close()

         })

    $stack.AddChild($btn)
    $space2 = new-object System.Windows.Controls.Label
    $space2.Height = 10
    $stack.AddChild($space2)

    $btn2 = New-Object System.Windows.Controls.Button
    $btn2.Content = "_Cancel"

    $btn2.Width = 65
    $btn2.HorizontalAlignment = "center"
    $btn2.VerticalAlignment = "bottom"

    #add an event handler
    $btn2.Add_click( {
            
            $form.Close()
            exit
            
        })

    $stack.AddChild($btn2)

    #add the stack to the form
    $form.AddChild($stack)

    #show the form
    $inputbox.Focus() | Out-Null
    $form.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen

    $form.ShowDialog() | out-null

    #write the result from the input box back to the pipeline
    $script:TimeInput

}


if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
        Write-Warning "Sorry. We were not able to automatically elevate.  Check file ownership/permissions"
    } else {
   
    #--!!--# show elevated window and verbose service-control commands for debugging purposes?
       # Start-Process  powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
   
    #--!!--# Do NOT show elevated window and verbose service-control commands for production purposes?
        Start-Process  powershell.exe -Verb RunAs -ArgumentList ('-windowstyle hidden -noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'running with full privileges'






#DoWork:

Invoke-InputBox

$timespan = New-TimeSpan -minutes $TimeInput
[int]$timespanSec = [convert]::ToInt32($TimeInput, 10) * 60

    #Stop Services
StopService
    
    #Sleep for time specified by user (Output for debugging)
    #Write-Output "Sleeping for: " $timespanSec " Seconds"
Start-Sleep -seconds $timespanSec

    #Start Services after sleeping for specified time
RestartService




