/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySite, %syINET, %sySystem)

/// The $System.Config class provides methods to activate configuration settings without restarting InterSystems IRIS. For the most part, these do not need to be called directly by customer code because configuration classes will call them when modifying configuration settings. 
Class %SYSTEM.Config Extends Help [ Abstract, Final, System = 4 ]
{

/// $SYSTEM.Config.Modifybbsiz(NewSetting) sets the default maximum bbsize.  This setting will apply to all new InterSystems IRIS processes.
/// It returns the previous value of the Config.config.bbsiz setting.<br>
/// $SYSTEM.Config.Modifybbsiz() with no argument returns the active value of the Config.config.bbsiz setting.<br>
/// The input value will be modified to insure that it is at least as large as the minimum permitted value, no larger than the the largest permitted value, and rounded up to an appropriate chunk size.
/// See the configuration settings section for permitted values.
ClassMethod Modifybbsiz() As %Integer
{
}

/// $SYSTEM.Config.ModifyConsoleFile(NewSetting) changes the console file. 
/// It returns the previous value of the Config.config.ConsoleFile setting.<br>
/// $SYSTEM.Config.ModifyConsoleFile() with no argument returns the current value.<br>
/// The input value will be modified to its canonic form.
ClassMethod ModifyConsoleFile() As %String
{
}

/// $SYSTEM.Config.ModifyDumpStyle(NewSetting) changes the dumpstyle setting specified by the [Debug] section of cache.cpf for new processes.
/// It returns the previous value of the dumpstyle setting.<br>
/// $SYSTEM.Config.ModifyDumpStyle() with no argument returns the current value.<br>
/// Consult "dumpstyle" in the Configuration Parameter File Reference for valid values.
ClassMethod ModifyDumpStyle() As %Integer
{
}

/// $SYSTEM.Config.ModifyLineRecallBuffer(NewSetting) sets the default LineRecallBuffer size.  This setting will apply to all new InterSystems IRIS processes which do not specify -h on the command line.
/// It returns the previous value of the Config.config.LineRecallBuffer setting.<br>
/// $SYSTEM.Config.ModifyLineRecallBuffer() with no argument returns the active value of the Config.config.LineRecallBuffer setting.<br>
/// The value of LineRecallBuffer is 1024 out of the box.
/// The input value will be modified to insure that it is within the range of permitted values and will be rounded up to a power of 2.
/// See the configuration settings section for permitted values.
ClassMethod ModifyLineRecallBuffer() As %Integer
{
}

/// $SYSTEM.Config.ModifyListFormat(NewSetting) sets the default ListFormat value.
/// This setting will apply to all new InterSystems IRIS processes.
/// It returns the previous value of the ListFormat setting.<br>
/// $SYSTEM.Config.ModifyListFormat() with no argument returns the current value.<br>
/// Consult "ListFormat" in the Configuration Parameter File Reference for valid values.
ClassMethod ModifyListFormat() As %Integer
{
}

/// $SYSTEM.Config.ModifyLineRecallEntries(NewSetting) sets the default LineRecallEntries size.  This setting will apply to all new InterSystems IRIS processes which do not specify -h on the command line.
/// It returns the previous value of the Config.config.LineRecallEntries setting.<br>
/// $SYSTEM.Config.ModifyLineRecallEntries() with no argument returns the active value of the Config.config.LineRecallEntries setting.<br>
/// The value of LineRecallEntries is 32 out of the box.
/// The input value will be modified to insure that it is within the range of permitted values.
/// See the configuration settings section for permitted values.
ClassMethod ModifyLineRecallEntries() As %Integer
{
}

/// $SYSTEM.Config.ModifyMaxServers(NewSetting) will change the active Config.config.MaxServers setting. 
/// It returns the new active value of the Config.config.MaxServers setting.<br>
/// $SYSTEM.Config.ModifyMaxServers() with no argument returns the current value.<br>
/// This API works in conjunction with the Config.config class to determine how many ECP servers the InterSystems IRIS instance can access.
/// Sufficient client network buffer and control structures are allocated during instance startup to support connection to Config.config.MaxServers
/// ECP database servers.  If the MaxServers setting is increased, the Config.config class will call $SYSTEM.Config.ModifyMaxServers() to activate the new maximum ECP database server setting.
/// Additional client network buffer or control structures are allocated from the shared memory heap (SMheap) at this time if available and the new active number of ECP server structures is returned.
/// An attempt to reduce MaxServers below the number allocated at startup or below the number actually in use will be ignored.
/// If the InterSystems IRIS instance is restarted, buffers and control structures will be statically allocated to accomodate the Config.config.MaxServers setting.
/// The $SYSTEM.Config.ModifyMaxServers() method is intended for use by InterSystems utilities and should not be called by customer code.
ClassMethod ModifyMaxServers() As %Integer
{
}

/// $SYSTEM.Config.Modifynetjob(NewSetting) sets the activate value of the Config.config.netjob setting to NewSetting.  Valid values of NewSetting are 0 (disable) and 1 (enable).
/// This method is intended for use by InterSystems IRIS utilities.  It should not be called directly by customer code.  It will be executed
/// when the Config.config object is saved if the netjob setting has been modified.<br>
/// $SYSTEM.Config.Modifynetjob() with no argument returns the active value of the Config.config.netjob setting.
ClassMethod Modifynetjob() As %Integer
{
}

/// $SYSTEM.Config.ModifyVMSConsoleTerminal(NewSetting) changes the console file. 
/// It returns the previous value of the Config.config.VMSConsoleTerminal setting.<br>
/// $SYSTEM.Config.ModifyVMSConsoleTerminal() with no argument returns the current value.<br>
/// If input value is "" no output will be made to a console terminal.
ClassMethod ModifyVMSConsoleTerminal() As %String
{
}

/// $SYSTEM.Config.ModifyWIJdir(NewDirectory) modifies the active Config.config.wijdir setting and causes the Write Daemon to create and initializes the new .WIJ image journal file.
/// This Method does not modify the configuration file or the configuration object.  It is not intended to be called from customer code.  
/// It will be called as a result of the wijdir being changed when the CONFIG.config object is saved.  
/// It returns the previous active value of the Config.config.wijdir.<br>
/// It returns "" and does not change the active wij directory if a .WIJ image journal file already exists in the target directory.<br>
/// $SYSTEM.Config.ModifyWIJdir() with no argument returns the active value of the Config.config.wijdir setting.<br>
ClassMethod ModifyWIJdir() As %String
{
}

/// $SYSTEM.Config.ModifyZFSize(NewSetting) sets the default zfheap allocation for InterSystems IRIS processes.  This setting will apply to all new InterSystems IRIS processes.
/// It returns the previous value of the Config.config.ZFSize setting.<br>
/// $SYSTEM.Config.ModifyZFSize() with no argument returns the current value of the Config.config.ZFSize setting.<br>
/// $SYSTEM.Config.ModifyZFSize(0) sets ZFSize to the default value.<br>
/// The input value will be modified to insure that it is at least as large as the minimum permitted value, no larger than the the largest permitted value, and rounded up to an appropriate chunk size.
/// See the configuration settings section for permitted values.
ClassMethod ModifyZFSize() As %Integer
{
}

/// $SYSTEM.Config.ModifyZFString(NewSetting) sets the amount of space allocated for values returned by callouts to external functions using $zf() 
/// It returns the previous value of the  Config.config.ZFString setting.<br>
/// $SYSTEM.Config.ModifyZFString() with no argument returns the current value.<br>
/// $SYSTEM.Config.ModifyZFString(0) sets ZFString to the default value.<br>
/// The input value will be modified to insure that it is at least as large as the minimum permitted value, no larger than the the largest permitted value, and rounded up to an appropriate chunk size.
/// See the configuration settings section for permitted values.
ClassMethod ModifyZFString() As %Integer
{
}

}
