Function Test-RPCConnection {
<#
.SYNOPSIS
This cmdlet is used to test RPC connections to a remote device


.DESCRIPTION
Test open RPC connections between the local machine executing this cmdlet and a remotely specified device


.PARAMETER ComputerName
Specify the FQDN, IP address, or hostname of a remote device to check your RPC connectivity with


.EXAMPLE
Test-RpcConnection -ComputerName dhcp.domain.com
# This example checks to see if any RPC communications can be opened betwnee localhost and dhcp.domain.com


.LINK
https://devblogs.microsoft.com/scripting/testing-rpc-ports-with-powershell-and-yes-its-as-much-fun-as-it-sounds/
http://bit.ly/scriptingguystwitter
http://bit.ly/scriptingguysfacebook
https://social.msdn.microsoft.com/profile/Joel%20Vickery,%20PFE


.NOTES
I stole this from the below author and made a few inconsequential changes
Author: Ryan Ries [MSFT]
Origianl date: 15 Feb. 2014
Requires: -Version 3
Contact: scripter@microsoft.com
Modifications Made by Robert Osborne
Contact: rosborne@osbornepro.com


INPUTS
System.String


OUTPUTS
PSCustomObject
#>
    [CmdletBinding(SupportsShouldProcess=$True)]
        param(
            [Parameter(
                Position=0,
                Mandatory=$True,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$False,
                HelpMessage="Define the hostname, FQDN, or IP address of the remote host to test RPC connectivity on")]  # End Parameter
            [String[]]$ComputerName = 'localhost')

BEGIN {

    $Output = @()
    $Source = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;



public class Rpc
{
    [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
    public static extern int RpcBindingFromStringBinding(string StringBinding, out IntPtr Binding);

    [DllImport("Rpcrt4.dll")]
    public static extern int RpcBindingFree(ref IntPtr Binding);

    [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
    public static extern int RpcMgmtEpEltInqBegin(IntPtr EpBinding,
                                            int InquiryType, // 0x00000000 = RPC_C_EP_ALL_ELTS
                                            int IfId,
                                            int VersOption,
                                            string ObjectUuid,
                                            out IntPtr InquiryContext);

    [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
    public static extern int RpcMgmtEpEltInqNext(IntPtr InquiryContext,
                                            out RPC_IF_ID IfId,
                                            out IntPtr Binding,
                                            out Guid ObjectUuid,
                                            out IntPtr Annotation);

    [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
    public static extern int RpcBindingToStringBinding(IntPtr Binding, out IntPtr StringBinding);

    public struct RPC_IF_ID
    {
        public Guid Uuid;
        public ushort VersMajor;
        public ushort VersMinor;
    }


    // Returns a dictionary of <Uuid, port>
    public static Dictionary<int, string> QueryEPM(string host)
    {
        Dictionary<int, string> ports_and_uuids = new Dictionary<int, string>();
        int retCode = 0; // RPC_S_OK 

        IntPtr bindingHandle = IntPtr.Zero;
        IntPtr inquiryContext = IntPtr.Zero;                
        IntPtr elementBindingHandle = IntPtr.Zero;
        RPC_IF_ID elementIfId;
        Guid elementUuid;
        IntPtr elementAnnotation;

        try
        {                    
            retCode = RpcBindingFromStringBinding("ncacn_ip_tcp:" + host, out bindingHandle);
            if (retCode != 0)
                throw new Exception("RpcBindingFromStringBinding: " + retCode);

            retCode = RpcMgmtEpEltInqBegin(bindingHandle, 0, 0, 0, string.Empty, out inquiryContext);
            if (retCode != 0)
                throw new Exception("RpcMgmtEpEltInqBegin: " + retCode);

            do
            {
                IntPtr bindString = IntPtr.Zero;
                retCode = RpcMgmtEpEltInqNext (inquiryContext, out elementIfId, out elementBindingHandle, out elementUuid, out elementAnnotation);
                if (retCode != 0)
                    if (retCode == 1772)
                        break;

                retCode = RpcBindingToStringBinding(elementBindingHandle, out bindString);
                if (retCode != 0)
                    throw new Exception("RpcBindingToStringBinding: " + retCode);
                            
                string s = Marshal.PtrToStringAuto(bindString).Trim().ToLower();
                if(s.StartsWith("ncacn_ip_tcp:"))
                    if (ports_and_uuids.ContainsKey(int.Parse(s.Split('[')[1].Split(']')[0])) == false) ports_and_uuids.Add(int.Parse(s.Split('[')[1].Split(']')[0]), elementIfId.Uuid.ToString());
                           
                RpcBindingFree(ref elementBindingHandle);
                        
            }
            while (retCode != 1772); // RPC_X_NO_MORE_ENTRIES
        }
        catch(Exception ex)
        {
            Console.WriteLine(ex);
            return ports_and_uuids;
        }
        finally
        {
            RpcBindingFree(ref bindingHandle);
        }
        return ports_and_uuids;
    }
}
'@

} PROCESS {
 
    ForEach ($C in $ComputerName) {
        $EPMOpen = $False
        $Socket = New-Object -TypeName System.Net.Sockets.TcpClient
                
        Try {
                            
            $Socket.Connect($C, 135)
            If ($Socket.Connected) {

                $EPMOpen = $True

            }  # End If

            $Socket.Close()
                         
        } Catch {

            $Output += New-Object -TypeName PSCustomObject -Property @{
                ComputerName=$C;
                Port=135;
                Status="Unreachable"
            }  # End New-Object -Property

            $Socket.Dispose()

        }  # End Try Catch
                
        If ($EPMOpen) {

            Add-Type -TypeDefinition $Source

            $RpcPortsUuids = [Rpc]::QueryEPM($C)
            $PortDeDup = ($RpcPortsUuids.Keys) | Sort-Object -Unique

            Foreach ($Port In $PortDeDup) {

                $Socket = New-Object -TypeName System.Net.Sockets.TcpClient
                Try {

                    $Socket.Connect($C, $Port)
                    If ($Socket.Connected) {

                        $Output += New-Object -TypeName PSCustomObject -Property @{
                            ComputerName=$C;
                            Port=135;
                            Status="Open"
                        }  # End New-Object -Property

                    }  # End If

                    $Socket.Close()

                } Catch {

                    $Output += New-Object -TypeName PSCustomObject -Property @{
                        ComputerName=$C;
                        Port=135;
                        Status="Unreachable"
                    }  # End New-Object -Property

                    $Socket.Dispose()

                }  # End Try Catch

            }  # End ForEach

        }  # End If

    }  # End ForEach

} END {

    Write-Verbose -Message "Completed RPC connection testing"
    Return $Output

}  # End BPE

}  # End Function Test-RPCConnection
