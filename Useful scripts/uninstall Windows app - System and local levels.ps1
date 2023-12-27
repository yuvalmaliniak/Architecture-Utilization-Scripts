# This script is designed to force delete a Windows application
# The script uninstalls the app both by the system and local levels
# Designed to match Azure AD devices, but does not related to MDM
# All data installed on both levels, include shortcuts and reg files, will be removed
# Change the app name and settings to be matching your app

$UninstallLogfile_system = "PATH\uninstall_system.log"
$UninstallLogfile_user = "PATH\uninstallWS_user.log"
$Logfile = "PATH\script.log"
function WriteLog
{
	Param ([string]$LogString)
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$LogMessage = "$Stamp $LogString"
	Add-content $LogFile -value $LogMessage
}

$Desire_version= "1.0" # change to whatever you need
$app_name="ENTER APP NAME"
$check_app_exists = Get-WmiObject -Class Win32_Product | Where-Object{($_.Name -eq $app_name) -and $_.Version -gt $Desire_version}
$pcname = $env:computername

#get logged in user, its sid and its user profile dir
$loggedInUser = Get-WMIObject Win32_ComputerSystem
$User = New-Object System.Security.Principal.NTAccount($loggedInUser.UserName)
WriteLog("The logged in user is $User")
$sid = $User.Translate([System.Security.Principal.SecurityIdentifier]).value
WriteLog("The logged in user's SID is $sid")
# Define drive HKU:
New-PSDrive HKU Registry HKEY_USERS
$userProfileFolder = $(Get-ItemProperty "HKU:\${sid}\*").USERPROFILE.Where{$_ -ne $null}
WriteLog("The logged in user's profile dir is $userProfileFolder")


#checking if the app is installed
if($check_app_exists -eq $null)
{
	WriteLog("Desired version is not installed yet on $pcname, Exiting")
    Exit
}
WriteLog("Desired version is installed")


#maintain a flag indicating whether we failed in one of the removal procedures
#this flag will be a part of an analytics message at the end of the script
$success = $true

    WriteLog("Removing manual installation")
    #uninstall the version by impersonation to logged on user
    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    ​
    namespace murrayju.ProcessExtensions
    {
        public static class ProcessExtensions
		{
			#region Win32 Constants
	​
			private const int CREATE_UNICODE_ENVIRONMENT = 0x00000400;
			private const int CREATE_NO_WINDOW = 0x08000000;
	​
			private const int CREATE_NEW_CONSOLE = 0x00000010;
	​
			private const uint INFINITE = 0xFFFFFFFF;
			private const uint INVALID_SESSION_ID = 0xFFFFFFFF;
			private static readonly IntPtr WTS_CURRENT_SERVER_HANDLE = IntPtr.Zero;
	​
	​
			#endregion
	​
			#region DllImports
	​
			[DllImport("advapi32.dll", EntryPoint = "CreateProcessAsUser", SetLastError = true, CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
			private static extern bool CreateProcessAsUser(
				IntPtr hToken,
				String lpApplicationName,
				String lpCommandLine,
				IntPtr lpProcessAttributes,
				IntPtr lpThreadAttributes,
				bool bInheritHandle,
				uint dwCreationFlags,
				IntPtr lpEnvironment,
				String lpCurrentDirectory,
				ref STARTUPINFO lpStartupInfo,
				out PROCESS_INFORMATION lpProcessInformation);
	​
			[DllImport("advapi32.dll", EntryPoint = "DuplicateTokenEx")]
			private static extern bool DuplicateTokenEx(
				IntPtr ExistingTokenHandle,
				uint dwDesiredAccess,
				IntPtr lpThreadAttributes,
				int TokenType,
				int ImpersonationLevel,
				ref IntPtr DuplicateTokenHandle);
	​
			[DllImport("userenv.dll", SetLastError = true)]
			private static extern bool CreateEnvironmentBlock(ref IntPtr lpEnvironment, IntPtr hToken, bool bInherit);
	​
			[DllImport("userenv.dll", SetLastError = true)]
			[return: MarshalAs(UnmanagedType.Bool)]
			private static extern bool DestroyEnvironmentBlock(IntPtr lpEnvironment);
	​
			[DllImport("kernel32.dll", SetLastError = true)]
			private static extern bool CloseHandle(IntPtr hSnapshot);
	​
			[DllImport("kernel32.dll", SetLastError = true)]
			private static extern UInt32 WaitForSingleObject(IntPtr hHandle, UInt32 dwMilliseconds);
	​
			[DllImport("kernel32.dll", SetLastError = true)]
			public static extern bool GetExitCodeProcess(IntPtr hProcess, out uint exitCode);​

			[DllImport("kernel32.dll")]
			private static extern uint WTSGetActiveConsoleSessionId();
	​
			[DllImport("Wtsapi32.dll")]
			private static extern uint WTSQueryUserToken(uint SessionId, ref IntPtr phToken);
	​
			[DllImport("wtsapi32.dll", SetLastError = true)]
			private static extern int WTSEnumerateSessions(
				IntPtr hServer,
				int Reserved,
				int Version,
				ref IntPtr ppSessionInfo,
				ref int pCount);
	​
			#endregion
	​
			#region Win32 Structs
	​
			private enum SW
			{
				SW_HIDE = 0,
				SW_SHOWNORMAL = 1,
				SW_NORMAL = 1,
				SW_SHOWMINIMIZED = 2,
				SW_SHOWMAXIMIZED = 3,
				SW_MAXIMIZE = 3,
				SW_SHOWNOACTIVATE = 4,
				SW_SHOW = 5,
				SW_MINIMIZE = 6,
				SW_SHOWMINNOACTIVE = 7,
				SW_SHOWNA = 8,
				SW_RESTORE = 9,
				SW_SHOWDEFAULT = 10,
				SW_MAX = 10
			}
	​
			private enum WTS_CONNECTSTATE_CLASS
			{
				WTSActive,
				WTSConnected,
				WTSConnectQuery,
				WTSShadow,
				WTSDisconnected,
				WTSIdle,
				WTSListen,
				WTSReset,
				WTSDown,
				WTSInit
			}
	​
			[StructLayout(LayoutKind.Sequential)]
			private struct PROCESS_INFORMATION
			{
				public IntPtr hProcess;
				public IntPtr hThread;
				public uint dwProcessId;
				public uint dwThreadId;
			}
	​
			private enum SECURITY_IMPERSONATION_LEVEL
			{
				SecurityAnonymous = 0,
				SecurityIdentification = 1,
				SecurityImpersonation = 2,
				SecurityDelegation = 3,
			}
	​
			[StructLayout(LayoutKind.Sequential)]
			private struct STARTUPINFO
			{
				public int cb;
				public String lpReserved;
				public String lpDesktop;
				public String lpTitle;
				public uint dwX;
				public uint dwY;
				public uint dwXSize;
				public uint dwYSize;
				public uint dwXCountChars;
				public uint dwYCountChars;
				public uint dwFillAttribute;
				public uint dwFlags;
				public short wShowWindow;
				public short cbReserved2;
				public IntPtr lpReserved2;
				public IntPtr hStdInput;
				public IntPtr hStdOutput;
				public IntPtr hStdError;
			}
	​
			private enum TOKEN_TYPE
			{
				TokenPrimary = 1,
				TokenImpersonation = 2
			}
	​
			[StructLayout(LayoutKind.Sequential)]
			private struct WTS_SESSION_INFO
			{
				public readonly UInt32 SessionID;
	​
				[MarshalAs(UnmanagedType.LPStr)]
				public readonly String pWinStationName;
	​
				public readonly WTS_CONNECTSTATE_CLASS State;
			}
	​
			#endregion
	​
			// Gets the user token from the currently active session
			private static bool GetSessionUserToken(ref IntPtr phUserToken)
			{
				var bResult = false;
				var hImpersonationToken = IntPtr.Zero;
				var activeSessionId = INVALID_SESSION_ID;
				var pSessionInfo = IntPtr.Zero;
				var sessionCount = 0;
	​
				// Get a handle to the user access token for the current active session.
				if (WTSEnumerateSessions(WTS_CURRENT_SERVER_HANDLE, 0, 1, ref pSessionInfo, ref sessionCount) != 0)
				{
					var arrayElementSize = Marshal.SizeOf(typeof(WTS_SESSION_INFO));
					var current = pSessionInfo;
	​
					for (var i = 0; i < sessionCount; i++)
					{
						var si = (WTS_SESSION_INFO)Marshal.PtrToStructure((IntPtr)current, typeof(WTS_SESSION_INFO));
						current += arrayElementSize;
	​
						if (si.State == WTS_CONNECTSTATE_CLASS.WTSActive)
						{
							activeSessionId = si.SessionID;
						}
					}
				}
	​
				// If enumerating did not work, fall back to the old method
				if (activeSessionId == INVALID_SESSION_ID)
				{
					activeSessionId = WTSGetActiveConsoleSessionId();
				}
	​
				if (WTSQueryUserToken(activeSessionId, ref hImpersonationToken) != 0)
				{
					// Convert the impersonation token to a primary token
					bResult = DuplicateTokenEx(hImpersonationToken, 0, IntPtr.Zero,
						(int)SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation, (int)TOKEN_TYPE.TokenPrimary,
						ref phUserToken);
	​
					CloseHandle(hImpersonationToken);
				}
	​
				return bResult;
			}
	​
			public static uint StartProcessAsCurrentUser(string appPath, string cmdLine = null, string workDir = null, bool visible = true)
			{
				var hUserToken = IntPtr.Zero;
				var startInfo = new STARTUPINFO();
				var procInfo = new PROCESS_INFORMATION();
				var pEnv = IntPtr.Zero;
	​
				startInfo.cb = Marshal.SizeOf(typeof(STARTUPINFO));
	​
				try
				{
					if (!GetSessionUserToken(ref hUserToken))
					{
						throw new Exception("StartProcessAsCurrentUser: GetSessionUserToken failed.");
					}
	​
					uint dwCreationFlags = CREATE_UNICODE_ENVIRONMENT | (uint)(visible ? CREATE_NEW_CONSOLE : CREATE_NO_WINDOW);
					startInfo.wShowWindow = (short)(visible ? SW.SW_SHOW : SW.SW_HIDE);
					startInfo.lpDesktop = "winsta0\\default";
	​
					if (!CreateEnvironmentBlock(ref pEnv, hUserToken, false))
					{
						throw new Exception("StartProcessAsCurrentUser: CreateEnvironmentBlock failed.");
					}
				
					//https://stackoverflow.com/a/14001282/2561181
					if (!string.IsNullOrEmpty(cmdLine))
					{
						cmdLine = appPath + " " + cmdLine;
					}
	​
					if (!CreateProcessAsUser(hUserToken,
						appPath, // Application Name
						cmdLine, // Command Line
						IntPtr.Zero,
						IntPtr.Zero,
						false,
						dwCreationFlags,
						pEnv,
						workDir, // Working directory
						ref startInfo,
						out procInfo))
					{
						throw new Exception("StartProcessAsCurrentUser: CreateProcessAsUser failed.\n");
					}
	​
					WaitForSingleObject(procInfo.hProcess, INFINITE);
				    uint exitCode;
					GetExitCodeProcess(procInfo.hProcess, out exitCode);
					return exitCode;
				}
				catch
				{
					return 1;
				}				
				finally
				{
					CloseHandle(hUserToken);
					if (pEnv != IntPtr.Zero)
					{
						DestroyEnvironmentBlock(pEnv);
					}
					CloseHandle(procInfo.hThread);
					CloseHandle(procInfo.hProcess);
				}				
			}
		}
    }    ​
"@
    Add-Type -ReferencedAssemblies 'System','System.Runtime.InteropServices' -TypeDefinition $Source -Language CSharp     
    $arguments = "/X {B8C8B3E1-DD4F-4BB7-ABCC-F79BAC283D6A} /L*V $UninstallLogfile_user /q"
    $exitCode = [murrayju.ProcessExtensions.ProcessExtensions]::StartProcessAsCurrentUser('C:\Windows\System32\msiexec.exe',$arguments)
	WriteLog("Desired version is uninstalled, removal exit code is $exitCode")
	if ($exitCode -ne 0)
	{
		$success = $false
	}	

# uninstalling on system level
  
	WriteLog("Version is installed by system level on $pcname")
	WriteLog("removing shortcuts")
	$app_lnk = $app_name + ".lnk"
	#remove v8.0.2 shortcuts - search for shortcuts created by v8.0.2 installation and exclude possible v8.1.0 shortcuts
	$shortcuts_found = Get-Childitem -include $app_lnk -Path "$userProfileFolder" -Recurse -ErrorAction SilentlyContinue -force |	
		Select -ExpandProperty FullName |
		sort length -Descending
	if ($shortcuts_found -ne $null)
	{ 
		foreach ($shortcut in $shortcuts_found)
		{  
			WriteLog("Removing the shortcut $shortcut")
			Remove-Item $shortcut -Force
		}
	}
	else
	{
		WriteLog("No shortcuts to remove")
	}
	
    #uninstall the version by system user
	WriteLog("Uninstalling version 8.0")
	$msiCode = $check_app_exists.IdentifyingNumber
	$arguments = "/X $msiCode /L*V $UninstallLogfile_system /q"
	$uninstallResult = (Start-Process -FilePath C:\Windows\System32\msiexec.exe -ArgumentList $arguments -Wait -PassThru).ExitCode
	if ($uninstallResult -ne 0)
	{ 
		WriteLog("Uninstalled version has failed with error code $uninstallResult")
		$success = $false
		Exit
	}
	WriteLog("Uninstalled version 8.0 successfully")
   

	#Remove logged in user's registry keys/values of the version
	WriteLog("Removing registry uninstall entry for logged in user")	
	$registryPathToRemove = "HKU:\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Appname"		
	$test_path = Test-Path $registryPathToRemove
	if ($test_path -eq $true)
	{
		Remove-Item -Path $registryPathToRemove -Force -Recurse
		$test_path = Test-Path $registryPathToRemove
		if ($test_path -eq $true)
		{			
			WriteLog("Registry $registryPathToRemove NOT removed!!")		
			$success = $false
		}
		else
		{
			WriteLog("Registry $registryPathToRemove removed successfully")				
		}
	}
	else
	{
		WriteLog("Registry $registryPathToRemove wasn't found so nothing to remove")				
	}		
	
	
}

# Check the status
if ($success -eq $true)
{
	WriteLog("Successfully removed version 8, if existed")
}

WriteLog("FINISHED")
