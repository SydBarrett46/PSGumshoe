function Get-EventPsIPC {
    <#
    .Synopsis
    Get Windows PowerShell IPC events.
    .DESCRIPTION
    Get Windows PowerShell IPC events.
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .NOTES
    This function needs to be executed with administrator priviages on the host.
    #>
    [CmdletBinding()]
    [Alias()]
    [OutputType([PSObject])]
    Param (

        # Log name of where to look for the PowerShell events.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $LogName = 'Microsoft-Windows-PowerShell/Operational',

        # Specifies the maximum number of events that Get-WinEvent returns. Enter an integer. The default is to return all the events in the logs or files.
        [Parameter(Mandatory=$false,
                  ValueFromPipelineByPropertyName=$true,
                  Position=1)]
        [int]
        $MaxEvents,

        # Start Date to get all event going forward.
        [Parameter(Mandatory=$false)]
        [datetime]
        $StartTime,

        # End data for searching events.
        [Parameter(Mandatory=$false)]
        [datetime]
        $EndTime,

        <#
        Specifies the name of the computer that this cmdlet gets events from the event logs. Type the NetBIOS name, an Internet Protocol (IP)
        address, or the fully qualified domain name of the computer. The default value is the local computer.

        This parameter accepts only one computer name at a time. To find event logs or events on multiple computers, use a ForEach-Object
        statement. For more information about this parameter, see the examples.

        To get events and event logs from remote computers, the firewall port for the event log service must be configured to allow remote access.

        This cmdlet does not rely on Windows PowerShell remoting. You can use the ComputerName parameter even if your computer is not configured
        to run remote commands.
        #>
        [Parameter(Mandatory=$false)]
        [string]
        $ComputerName,

        <#
        Specifies a user account that has permission to perform this action. The default value is the current user.

        Type a user name, such as User01 or Domain01\User01. Or, enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
        If you type a user name, you will be prompted for a password. If you type only the parameter name, you will be prompted for both a user
        name and a password.
        #>
        [Parameter(Mandatory=$false)]
        [pscredential]
        [Management.Automation.CredentialAttribute()]
        $Credential = [Management.Automation.PSCredential]::Empty
    )

    Begin {}
    Process {

       # Hash for filtering
        $HashFilter = @{LogName=$LogName; Id=53504; ProviderName='Microsoft-Windows-PowerShell'}

        # Hash for command paramteters
        $ParamHash = @{}

        if ($MaxEvents -gt 0)
        {
            $ParamHash.Add('MaxEvents', $MaxEvents)
        }

        if ($StartTime) {
            $HashFilter.Add('StartTime', $StartTime)
        }

        if ($EndTime) {
            $HashFilter.Add('EndTime', $EndTime)
        }

        if ($ComputerName){
            $HashFilter.Add('ComputerName', $ComputerName)
        }

        if ($Credential.UserName -ne $null){
            $HashFilter.Add('Credential', $Credential)
        }

        $ParamHash.Add('FilterHashTable',$HashFilter)
        Get-WinEvent @ParamHash | ForEach-Object -Process {
            [xml]$evtXml = $_.toxml()
            $evtInfo = [ordered]@{}
            $evtInfo['EventId'] = $evtXml.Event.System.EventID
            $evtInfo['EventRecordID'] = $evtXml.Event.System.EventRecordID
            $evtInfo['TimeCreated'] = [datetime]$evtXml.Event.System.TimeCreated.SystemTime
            $evtInfo['Computer'] = $evtXml.Event.System.Computer
            $evtInfo['Provider'] = $evtXml.Event.System.Provider.Name
            $evtInfo['ProcessID'] = $evtxml.Event.System.Execution.ProcessID
            $evtInfo['ThreadID'] = $evtxml.Event.System.Execution.ThreadID
            $evtInfo['ActivityID'] = $evtxml.Event.System.Correlation.ActivityID
            $evtInfo['UserID'] = $evtxml.Event.System.Security.UserID
            New-Object psobject -Property $evtInfo
        }
    }
    End {}
}