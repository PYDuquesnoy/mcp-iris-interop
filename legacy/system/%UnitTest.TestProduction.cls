/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Unit test base class specialized for testing productions.<br>
/// Unit tests created based on this class are associated with one production. 
/// When the unit test is run, it automatically starts the production, allows it to run for a parameterized time, 
/// puts new event log entries in an array and passes control to a method for custom verifications, then
/// stops the production and checks for errors.<br>
/// The programmer can adjust some parameters, add code to verify results, and use callback methods to handle events 
/// before/after start/stop production.<br>
/// </p>
/// <p>How to use this class:
/// <ul>
/// <li>Create a subclass of this base class, one per production.   Typically there will be one directory
///   per production, and one unit test class per directory/production, called for example Test.xml.  In case
///   one wants to run the same production with various settings there may be additional unit test classes such as
///   Test2.xml, Test3.xml, etc.</li>
/// <li> Override parameter <parameter>PRODUCTION</parameter> to contain the production class name.</li>
/// <li> Override parameters <parameter>MAXWAIT</parameter>, <parameter>MINRUN</parameter> and 
///   <parameter>IGNOREPRODUCTIONERRORS</parameter> if the defaults are not adequate to the production case.</li>
/// <li> Override method <method>CheckResults</method> to include your code with custom verification of the 
///   intended production results.</li>
/// <li> Override method <method>CheckErrors</method> if you set <parameter>IGNOREPRODUCTIONERRORS</parameter> = 1 and 
///   want to check the errors yourself.</li>
/// <li> Override methods <method>OnBeforeProductionStart</method> and <method>OnAfterProductionStart</method> with 
///   code to run before or after the production is started, for example to put files in place (before start), 
///   or to call a method that fires the test by instantiating a business service and sending a message (after start).</li>
/// <li> Override methods <method>OnBeforeProductionStop</method> and <method>OnAfterProductionStop</method> with 
///   code to run right before or after the production is stopped, if needed.<br>
///   Note: Initialization and cleanup code may go as usual into <b>OnBeforeOneTest()</b>, <b>OnAfterOneTest()</b>, etc., inherited from <class>%UnitTest.TestCase</class>.</li>
/// </ul></p>
/// <p>There are methods to facilitate usage, such as change settings, retrieve additional records from the
/// Interoperability event log, compare files, etc.  More details are given below and in the description for each method.<br>
/// <p> General utility/helper methods available to be used in the test code:
/// <ul>
/// <li> <method>GetSetting</method>: Get the current value of a setting for a production item.</li>
/// <li> <method>ChangeSetting</method>: Change the value of settings for production items.</li>
/// <li> <method>CreateCredentials</method>: Define credentials. </li>
/// <li> <method>SendRequest</method>: Call Interoperability testing service to send a request.</li>
/// <li> <method>CopyFile</method>: Copy a file from a directory to another directory.</li>
/// <li> <method>CompareFiles</method>: Compare the contents of two files.</li>
/// <li> <method>Error</method>: Compose a general error message as %Status with the text message provided.</li>
/// <li> <method>LogErrors</method>: Generate log messages with all errors contained in a status variable.</li>
/// <li> <method>GetEventLog</method>: Retrieve records from the Interoperability event log.</li>
/// <li> <method>SelectToString</method>: Return a string containing select information from the Event Log.</li>
/// </ul></p>
/// <p> File management utility/helper methods available to be used in the test code (all with normalized names):
/// <ul>
/// <li> <method>CreateMainDirTree</method>: Initialize test directories, with subdirectories for HL7 use.</li>
/// <li> <method>CopyFile</method>: Copy a file from a directory to another directory.</li>
/// <li> <method>CompareFiles</method>: Compare the contents of two files.</li>
/// <li> <method>CleanUpDirectory</method>: Remove all files from a directory or tree.</li>
/// 
/// </ul></p>
/// <p> The following properties are available:
/// <ul>
/// <li> <property>MainDir</property></li>
/// <li> <property>HL7InputDir</property></li>
/// <li> <property>HL7OutputDir</property></li>
/// <li> <property>HL7ArchiveDir</property></li>
/// <li> <property>HL7WorkDir</property></li>
/// <li> <property>MachineName</property></li>
/// <li> <property>InstanceName</property></li>
/// <li> <property>DSNToSamples</property></li>
/// <li> <property>DSNToUser</property></li>
/// </ul></p>
/// <p> Utility/helper methods to be used during test development or debugging:
/// <ul>
/// <li> <method>Run</method>: Run without loading/deleting any classes. </li>
/// <li> <method>Debug</method>: Run in debug mode, without loading/deleting any classes.</li>
/// <li> <method>Export</method>: Export all classes in a package to a directory.</li>
/// <li> <method>ListSettings</method>: List to the terminal all current settings for a given production and config item.</li>
/// </ul></p>
Class %UnitTest.TestProduction Extends %UnitTest.TestCase [ System = 3 ]
{

/// Class name of the production.  It must contain the production class name.
Parameter PRODUCTION;

/// Maximum time in seconds to wait for the production to completely start or stop.  The default is 10 seconds, 
/// override if necessary.
Parameter MAXWAIT = 10;

/// Minimum time to let production run before collecting event log entries of type "infouser" and check for results. 
/// The default is 10 seconds, override if necessary.  This varies with the production; some productions only
/// need to run for a little time, and some require more time.
Parameter MINRUN = 10;

/// If any errors appear in the Event Log during execution of the production, the test will fail.
/// In many cases, errors are expected to happen.  In this case, override this parameter.  You may also want to check them manually 
/// by overriding the method <method>CheckErrors</method>.
Parameter IGNOREPRODUCTIONERRORS = 0;

/// Normalized root test directory name, which by default is directory <b>TestAutoNNN</b>
/// on the same level as the InterSystems IRIS or HealthShare instance, and where <b>NNN</b> is the build number.
/// To initialize the directory tree see method <method>CreateMainDirTree</method>.
Property MainDir As %String;

/// Normalized directory name for HL7 input
Property HL7InputDir As %String;

/// Normalized directory name for HL7 output
Property HL7OutputDir As %String;

/// Normalized directory name for HL7 work
Property HL7WorkDir As %String;

/// Normalized directory name for HL7 archive
Property HL7ArchiveDir As %String;

/// Machine name
Property MachineName As %String;

/// Instance name
Property InstanceName As %String;

/// DSN name pointing to namespace SAMPLES
Property DSNToSamples As %String;

/// DSN name pointing to namespace USER
Property DSNToUser As %String;

/// Production's first event log ID
Property BaseLogId As %Integer;

/// Last event log ID retrieved for this production execution
Property LastLogId As %Integer;

/// Initialize properties.  <br>
/// Note: Do not edit this method.  If you want to change the property values, set them directly in your code.
Method %OnNew(initvalue) As %Status [ Internal ]
{
	Set s = ##super(initvalue) If 's Quit s
	Set InstallDir = $SYSTEM.Util.DataDirectory()
	Set InstallDirParent = ##class(%File).ParentDirectoryName(InstallDir)
	Set i%MainDir = ##class(%File).SubDirectoryName(InstallDirParent, "TestAuto"_(+$system.Version.GetBuildNumber()))
	Set i%HL7InputDir = ..SubMainDir("HL7/In")
	Set i%HL7OutputDir = ..SubMainDir("HL7/Out")
	Set i%HL7WorkDir = ..SubMainDir("HL7/Work")
	Set i%HL7ArchiveDir = ..SubMainDir("HL7/Archive")
	Set i%MachineName = $P($system,":",1)
	Set i%InstanceName = $P($system,":",2)
	Set i%DSNToSamples = $S($$$isUNIX:"Samples",$$$isWINDOWS:i%InstanceName_" Samples",1:"")
	Set i%DSNToUser = $S($$$isUNIX:"User",$$$isWINDOWS:i%InstanceName_" User",1:"")
	Quit $$$OK
}

/// Code to run right before the production is started.  This is useful to:<br>
/// <ul><li>Adjust settings - see method <method>ChangeSetting</method>.</li>
/// <li>Create directories - see method <method>CreateMainDirTree</method>.</li>
/// <li>Copy files - see method <method>CopyFile</method>.</li>
/// <li>Create credentials required by the production - see method <method>CreateCredentials</method>.</li>
/// <li>etc.</li></ul>
/// If an error status is returned, the test will be aborted and failed.
/// So if a non fatal error occurs, you may invoke ..LogErrors(status,"OnBeforeProductionStart()") and return $$$OK.
Method OnBeforeProductionStart() As %Status
{
	Quit $$$OK
}

/// Code to run right after the production is started. Used, for example, to call a method that initiates the test.
/// If an error status is returned, the test will be aborted and failed and the production will be stopped.
/// So if a non fatal error occurs, you may invoke ..LogErrors(status,"OnAfterProductionStart()") and return $$$OK.
Method OnAfterProductionStart() As %Status
{
	Quit $$$OK
}

/// Code to run right before the production is stopped.
/// If an error status is returned, the test will be failed and aborted, the production will be stopped.
/// If a non fatal error occurs, you may invoke ..LogErrors(status,"OnBeforeProductionStop()") and return $$$OK.
Method OnBeforeProductionStop() As %Status
{
	Quit $$$OK
}

/// Code to run right after the production is stopped.
/// If an error status is returned, the test is failed.
/// If a non fatal error occurs, you may invoke ..LogErrors(status,"OnAfterProductionStop()") and return $$$OK.
Method OnAfterProductionStop() As %Status
{
	Quit $$$OK
}

/// Fill in with code to check the results for the production execution.<br>
/// This method is initialized with a local array containing user created entries of type "Info" from the Event Log, 
/// not including the start production/components entries, with the following contents:<br>
///   <b>Log</b> = last existing seq for array <b>Log()</b> <br>
///   <b>Log(seq, fieldname)</b> = fieldvalue<br>
/// To get other entries from the Event Log, or for more information about the array contents,
/// see method <method>GetEventLog</method>. <br>
/// Return $$$OK in most cases, or an error status if you want to indicate that there was a failure.  Remember 
/// that failures are automatic when unit test macros are used.<br>
Method CheckResults(ByRef Log As %String, New As %String) As %Status
{
	Quit $$$OK
}

/// Override this method if you are going to check errors with custom code.
/// It's automatically invoked when parameter <parameter>IGNOREPRODUCTIONERRORS</parameter> = 1.
Method CheckErrors() As %Status
{
	Set s = ..GetEventLog("error", "", ..BaseLogId, .Err, .n) // Retrieve all records of type "Error"
	// Insert custom code here
	Quit $$$OK
}

/// Get the current value of a setting for a production item. <b>Value</b> must be passed by reference. Examples: <br>
///     Set s = ..GetSetting([Production], ConfigName, Setting, .Value)<br>
///     Set s = ##class(%UnitTest.TestProduction).GetSetting(Production, ConfigName, Setting, .Value)<br>
ClassMethod GetSetting(production As %String = "", configName As %String = "", setting As %String = "", Output value As %String) As %Status
{
	Kill value
	Quit ..ChangeOrGetSetting("Get", production, configName, setting, .value)
}

/// Change the value of a setting for a production item, optionally updating the production class too. Examples: <br>
///     Set s = ..ChangeSetting([Production], ConfigName, Setting, Value)<br>
///     Set s = ##class(%UnitTest.TestProduction).ChangeSetting(Production, ConfigName, Setting, Value, 1)<br>
/// The values are validated.  Check the return for errors.
ClassMethod ChangeSetting(production As %String = "", configName As %String = "", setting As %String = "", value As %String = "", saveToProduction As %Boolean = 0) As %Status
{
	Set s = ..ChangeOrGetSetting("Change", production, configName, setting, value)
	If 'saveToProduction || 's Quit s
	Set oProduction = ##class(Ens.Config.Production).%OpenId(production, , .s)
	If '$IsObject(oProduction) || $$$ISERR(s) Quit ..Error("Can't open production '"_production_"' to save change - Error: "_$system.Status.GetErrorText(s))
	Quit oProduction.SaveToClass()
}

/// Internal method called by GetSetting and ChangeSetting.
ClassMethod ChangeOrGetSetting(operation As %String = "Get", production As %String = "", configName As %String = "", setting As %String = "", ByRef value As %String = "") As %Status [ Internal, Private ]
{
	Set op = (operation="Change") // 0 = Get, 1 = Change
	If $c(0)[production Set production = ..#PRODUCTION If production="" Quit ..Error("Missing production name")
	If $c(0)[configName Quit ..Error("Missing config name")
	If $c(0)[setting Quit ..Error("Missing setting name")
	If $c(0)[value Set value = "" If op Quit ..Error("Missing value")
	Set oItem = ""
	Set rsql = ##class(%ResultSet.SQL).%Prepare("select %id as mid from Ens_Config.Item where Production='"_production_"' and Name='"_configName_"' order by Enabled desc")
	If rsql.%SQLCODE=100 Quit ..Error("Can't find item: Production '"_production_"' ConfigName '"_configName_"'")
	If '(rsql.%SQLCODE) If rsql.%Next() Set oItem = rsql.mid
	If '$IsObject(oItem) Quit ..Error("Can't open item: Production '"_production_"' ConfigName '"_configName_"' Error: "_rsql.%SQLCODE_" ("_rsql.%Message_")")
	// Look for existing setting
	Set f = 0, new = 0, ok = 1
	For i = 1:1:oItem.Settings.Count() {
		Set o = oItem.Settings.GetAt(i)
		If o.Name=setting Set f = 1, v = o.Value Quit
	}
	If f, 'op Set value = v Quit $$$OK // Get
	If 'f Set new = 1, oS = ##class(Ens.Config.Setting).%New() // It's a new setting
	// Look up all host settings
	Set f = 0
	Set rs = ##class(%ResultSet).%New()
	Set rs.ClassName = oItem.ClassName
	Set rs.QueryName = "EnumerateSettings"
	If (rs.QueryIsValid()) {
		Set tSC = rs.Execute()
		While rs.Next() && 'f {
			Set name = $G(rs.Data("Name"))
			If name=setting {
				If 'f Set f = 1 Set:new oS.Target = "Host"
				If 'op Set v = oS.Value
				Else  Set ok = $classmethod(oItem.ClassName, setting_"IsValid", value)
				Quit
			}
		}
	}
	Do rs.Close()
	Set rs = ""
	If f, 'op Set value = v Quit $$$OK // Get
	If 'f {
		// Look up all adapter settings
		Set rs = ##class(%ResultSet).%New()
		Set rs.ClassName = oItem.AdapterClassName()
		Set rs.QueryName = "EnumerateSettings"
		If (rs.QueryIsValid()) {
			Set tSC = rs.Execute()
			While (rs.Next()) && 'f {
				Set name = $G(rs.Data("Name"))
				If name=setting {
					If 'f Set f = 1 Set:new oS.Target = "Adapter"
					If 'op Set v = oS.Value
					Else  Set ok = $classmethod(oItem.AdapterClassName(), setting_"IsValid", value)
					Quit
				}
			}
		}
		Do rs.Close()
		Set rs = ""
	}
	If f, 'op Set value = v Quit $$$OK // Get
	If 'f || 'op Quit ..Error("Can't find setting name '"_setting_"' for Production '"_production_"' ConfigName '"_configName_"'") Quit
	If 'ok Quit ..Error("Invalid value '"_value_"' for setting name '"_setting_"' for Production '"_production_"' ConfigName '"_configName_"'") Quit
	If new {
		Set oS.Name = setting
		Set oS.Value = value
		Do oItem.Settings.Insert(oS)
		}
	Else  {
		Set o.Value = value
	}
	Set s = oItem.%Save()
	Quit s
}

/// Define credentials.  If one already exists with the same Id, it's overwritten.  Examples: <br>
///     Set s = ..CreateCredentials(Id, UserName, Password)<br>
///     Set s = ##class(%UnitTest.TestProduction).CreateCredentials(Id, UserName, Password)
ClassMethod CreateCredentials(CredId As %String = "", User As %String = "", Pw As %String = "") As %Status
{
	If (CredId="") || (User="") Quit ..Error("Credentials' Id and Username are required to create credentials")
	Set oCred = ""
	Set rsql = ##class(%ResultSet.SQL).%Prepare( "select %id as mid from Ens_Config.Credentials where SystemName = '"_CredId_"'" )
	If '(rsql.%SQLCODE) If rsql.%Next() Set oCred = rsql.mid
	If oCred="" Set oCred = ##class(Ens.Config.Credentials).%New()
	Set oCred.SystemName = CredId
	Set oCred.Username = User
	Set oCred.Password = Pw
	Quit oCred.%Save()
}

/// Call Interoperability testing service to send a request to a business process or business operation.  This is 
/// a way to invoke them directly without creating a dummy business service.  The production needs to be
/// enabled for testing.<br>
/// If no request object type is passed, then type Ens.Request is assumed.<br>
/// Example:<br>
/// Set s = ..SendRequest("MyBPName", MyRequestObject, .Response, [GetReply], [Time]) <br>
///    <b>GetReply=1</b> indicates a response is expected (default is 0).<br>
///    <b>Time</b> indicates how long to wait for a response in case GetReply=1.  Default is 30 secs.
ClassMethod SendRequest(Name As %String = "", Req As %RegisteredObject, ByRef Resp As %RegisteredObject, GetReply As %Boolean = 0, Time As %Integer = 30) As %Status
{
	If Name="" Quit ..Error("Missing destination config name to send request to")
	If $G(Req)="" Set Req = ##class(Ens.Request).%New()
	If '$IsObject(Req) Quit ..Error("Invalid request object")
	Do ..GetMacros(.Macro)
	Set Resp = "", Session = "", MsgType = Macro("eMessageTypeResponse"), mid = ""
	Set tSC = ##Class(EnsLib.Testing.Service).SendTestRequest(Name, Req, .Resp, .Session, GetReply)
	If 'tSC Quit tSC
	If $G(Session)="" Quit ..Error("No session returned")
	If GetReply, '$IsObject(Resp), Time>0 {
		Set timer = Time, waiting = 1
		While timer && waiting {
			Hang 1
			Set rs = ##class(%ResultSet.SQL).%Prepare("select top 1 id from ens.messageheader where sessionid=:Session and type=:MsgType and sourceconfigname=:Name order by timecreated desc")
        	If (rs.%SQLCODE) Set timer = timer-1
        	Else  Set waiting = 0
		}
		If waiting Quit ..Error("No response received")
		Set s = rs.%Next()
		If 's Quit ..Error("Error while fetching response")
		Set mid = rs.Get("ID")
		Set hr = ##class(Ens.MessageHeader).%OpenId(mid)
		If '$IsObject(hr) Quit ..Error("Can't determine the response object")
		Set Resp = $classmethod(hr.MessageBodyClassName, "%OpenId", hr.MessageBodyId)
	}
	If GetReply, '$IsObject(Resp) Quit ..Error("No response returned")
	Quit $$$OK
}

/// Compose a general error message as %Status with the text message provided.
/// If message is the null string, this method returns $$$OK instead.<br>
/// To append text to an existing error text, pass the status as a second argument.<br>
/// Examples:<br>
///     Set status=..Error(message, [oldstatus])<br>
///     Set status=##class(%UnitTest.TestProduction).Error(message, [oldstatus])
ClassMethod Error(msg As %String = "", s As %Status = "") As %Status
{
	If s="" Set s = $$$OK
	If msg="" Quit s
	Set tx = msg
	If $$$ISERR(s) Do $system.Status.DecomposeStatus(s, .e) If +$G(e) Set tx = msg_"; "_e(e)
	Quit $$$ERROR($$$GeneralError, tx)
}

/// Generate log messages with all errors contained in status variable <b>s</b>.
Method LogErrors(s As %Status = 1, where As %String = "")
{
	Quit:+$G(s)
	If $G(where)'="" Set where = "Error occurred in "_where_" - "
	Do $system.Status.DecomposeStatus(s, .Err)
	For i = $G(Err):-1:1 Do $$$LogMessage(where_$S($G(Err)>1:"Error #"_i_": ", 1:"")_Err(i))
	Quit
}

/// Retrieve records from the Interoperability event log, returning them in an array.<br>
/// <b>type</b> = "info" or "error" or "trace" or "warning" or "alert" or "assert" or
///        "infouser" or "startstop" or "other"
/// <b>name</b> = config name to filter entries (only fetch entries associated with this config name)<br>
/// Examples: <br>
/// To get new user entries of type "Info":<br>
/// Set s = ..GetEventLog("infouser", "", "", .Log, .New)<br>
/// To get new entries of type "Trace":<br>
/// Set s = ..GetEventLog("trace", "MyBP", "", .Log, .New)<br>
/// where <b>New</b> indicates how many new entries were found.<br>
/// Sample format for the returned array: <br>
/// 	Log(1,"ConfigName")="Ens.ScheduleHandler" <br>
/// 	Log(1,"ID")="114" <br>
/// 	Log(1,"Job")="4768" <br>
/// 	Log(1,"SessionId")="8" <br>
/// 	Log(1,"SourceClass")="Ens.Director" <br>
/// 	Log(1,"SourceMethod")="UpdateProduction" <br>
/// 	Log(1,"Stack")="" <br>
/// 	Log(1,"Text")="Production 'QDENS.HL7.HL7Routing.Production' is up-to-date." <br>
/// 	Log(1,"TimeLogged")="2006-12-05 17:41:06.421" <br>
/// 	Log(1,"Type")="Info"
Method GetEventLog(type As %String = "all", name As %String = "", baseId As %Integer, ByRef v As %String, Output New As %Integer) As %Status
{
	// First, build cross table for record types: strings to Ensemble constants
	Do ..GetMacros(.Macro)
	Kill Trans
	Set Trans("info") = Macro("eLogTypeInfo")
	Set Trans("error") = Macro("eLogTypeError")
	Set Trans("trace") = Macro("eLogTypeTrace")
	Set Trans("warning") = Macro("eLogTypeWarning")
	Set Trans("alert") = Macro("eLogTypeAlert")
	Set Trans("assert") = Macro("eLogTypeAssert")
	
	Set New = 0
	Set type = $Zcvt(type,"l"), fx = 0
	If type="all" {
		Set tx = ""
		}
	ElseIf type="info" {
		Set tx = Trans("info")
	}
	ElseIf type="infouser" {
		Set tx = Trans("info"), fx = 1
	}
	ElseIf type="startstop" {
		Set tx = Trans("info"), fx = 2
	}
	ElseIf type="error" {
		Set tx = Trans("error")
	}
	ElseIf type="trace" {
		Set tx = Trans("trace")
	}
	ElseIf type="warning" {
		Set tx = Trans("warning")
	}
	ElseIf type="alert" {
		Set tx = Trans("alert")
	}
	ElseIf type="assert" {
		Set tx = Trans("assert")
	}
	ElseIf type="other" {
		Set tx = "other"
	}
	Else  {
		Quit ..Error("Unrecognized event log type '"_type_"'")
	}
	Set tx = $Zcvt(tx,"l")
	
	If $G(baseId)="" {
		Set baseId = +..LastLogId
	}
	If baseId<..BaseLogId {
		Set baseId = +..BaseLogId
	}
	Set baseId = +baseId
	Set query = "SELECT ID,TimeLogged,Type,Job,SessionId,ConfigName,SourceClass,SourceMethod,Text,Stack"
	Set query = query_" FROM Ens_Util.Log WHERE ID>="_baseId_" ORDER BY ID"
	Set rs = ##class(%ResultSet).%New()
	Set rs.RuntimeMode = 2 // external
	Set s = rs.Prepare(query)
	Set s = rs.Execute()
	While rs.Next() {
		If tx'="", tx'="other" {
			Set t = $Zcvt(rs.Get("Type"),"l")
			If Trans(t)'=tx Continue
			If fx {
				// Check whether it's start / stop / update
				Set fss = 0, sc = rs.Get("SourceClass"), sm = rs.Get("SourceMethod")
				If sc="Ens.Director", (sm="StartProduction") || (sm="StopProduction") || (sm="UpdateProduction") {
					Set fss=1
				}
				If sc="Ens.Job", sm="Start" {
					Set fss=1
				}
				If fx=1, fss Continue
				If fx=2, 'fss Continue
			}
		}
		If tx="other" {
			If $D(Trans(t)) Continue
		}
		If name'="", rs.Get("ConfigName")'=name Continue
		Set v=$I(v), New = New+1
		For c = "ID","TimeLogged","Type","Job","SessionId","ConfigName","SourceClass","SourceMethod","Text","Stack" {
			Set v(v,c) = rs.Get(c)
		}
	}
	Do rs.Close()
	Set rs = ""
	If $G(v)>0 {
		Set ..LastLogId = v(v,"ID")+1
	}
	Quit $$$OK
}

/// Extract select text information from the event log returned results, and return a delimited string containing
/// the count followed by selected values, filtering by property/index <b>Prop</b> equals to <b>Value</b>.
ClassMethod SelectToString(ByRef Log As %String, Prop As %String = "", Value As %String = "", Del As %String = "^") As %String
{
	Set S = ""
	Set n = 0
	If $D(Log)=11 {
		For i = 1:1:Log {
			If Prop'="", $G(Log(i,Prop))'=Value Continue
			Set n = n + 1, S = S_Del_Log(i,"Text")
		}
	}
	Quit n_S
}

/// Run itself without loading/deleting any classes.  Example: <br>
///   Do ##class(MyTestClass).Run() <br>
/// See also method <method>Debug</method>.
ClassMethod Run() As %Status
{
	Set class=$classname()
	If class="%UnitTest.TestProduction" Quit $$$OK
	Quit ##class(%UnitTest.Manager).DebugRunTestCase("", class, "/debug=0/recursive=0")
}

/// Run itself in debug mode, without loading/deleting any classes.
/// If an assertion fails or if an error is encountered, execution will pause.  Example: <br>
///   Do ##class(MyTestClass).Debug() <br>
/// See also method <method>Run</method>.
ClassMethod Debug() As %Status
{
	Set class=$classname()
	If class="%UnitTest.TestProduction" Quit $$$OK
	Quit ##class(%UnitTest.Manager).DebugRunTestCase("", class, "/debug=1/recursive=0")
}

/// Export all classes in the same package to a directory as a set of individual files.<br>
/// If the directory is not specified, then ^UnitTestRoot will be used as a base and the last piece of
/// the package name will be used as the subdirectory name.<br>
/// If the suite name is not specified, then the last piece of the package name of the current class will be used.<br>
/// Note that parameter suite is ignored when a directory is specified.<br>
/// Examples:<br>
/// Do ##class(MyTestClass).Export()<br>
/// Do ##class(MyTestClass).Export("D:\Test\MyProductionTests\TempDir")<br>
/// Do ##class(MyTestClass).Export(,"MySuite")<br>
/// To do: In production-enabled namespaces, all rules and VDoc schemas whose names start with the package should also be exported.<br>
/// To do: Think about other kinds of files such as CSP pages.
ClassMethod Export(dir As %String = "", suite As %String = "")
{
	Set p = $classname()
	If p="%UnitTest.TestProduction" Write !,"This method must be called from a subclass",! Quit
	Set package = $P(p,".",1,$L(p,".")-1)
	If (suite="") || (dir'="") Set suite = $P(package,".",$L(package,"."))
	Set u = $G(^UnitTestRoot)
	If dir="", u="" Write !,"Please set ^UnitTestRoot or provide a full directory name",! Quit
	If dir="" Set dir = ##class(%File).SubDirectoryName(u, suite)
	Set dir = ##class(%File).NormalizeDirectory(dir)
	Write !!,"Exporting classes in package '", package, "' into directory '", dir, "'"
	Set s = ##class(%File).CreateDirectoryChain(dir)
	If 's Write !!,"Can't create directory '", dir, "'" Quit
	Set s = $system.OBJ.GetPackageList(.c, package, "as-r")
	If 's Write !!,"Error: " Do $system.OBJ.DisplayError(s) Quit
	If $O(c(""))="" Write !!,"No classes found in package '", package, "'" Quit
	Set class = ""  For  {
		Set class = $O(c(class)) Quit:class=""
		Set justname = $P(class,".",$L(class,"."))
		Set file = dir_justname_".xml"
		Write !,"Exporting class '", class, "' to file ", file
		Set s = $system.OBJ.Export(class_".CLS", file, , .err, )
		If 's Write !,"Error: " ZW err
	}
}

/// List all existing settings and their values for a given production and config item name.  If a config name is
/// provided, all settings for this config name are listed.  Otherwise all config names are listed.  Examples:<br>
///    Do ##class(MyTestClass).ListSettings(, [configname]) <br>
///    Do ##class(%UnitTest.TestProduction).ListSettings(production, [configname])
ClassMethod ListSettings(production As %String = "", configName As %String = "")
{
	Set s = ..CheckNamespace() If 's Do $system.OBJ.DisplayError(s) Quit
	If production="" Set production = ..#PRODUCTION If production="" Write !,"Missing production name" Quit
	If configName="" {
		// List all config items
		Write !,"Config items in production '",production,"':"
		Write !!,"Name ClassName Enabled(1/0)",!!
		Set rsql = ##class(%ResultSet.SQL).%Prepare("select Name,ClassName,Enabled from Ens_Config.Item where Production='"_production_"'")
		Set n = 0
		If (rsql.%SQLCODE) {
			If rsql.%SQLCODE'=100 Write !,"Error ",rsql.%SQLCODE," (",rsql.%Message,")"
		}
		Else  {
			While (rsql.%Next()) {
				Do rsql.%Print()
				Set n = n+1
			}
		}
		If 'n Write !,"Can't find any items"
	}
	Else  {
		// List all settings for a given config item
		Write !!,"Settings for production '",production,",' config. item '",configName,"':"
		Set rsql = ##class(%ResultSet.SQL).%Prepare( "select %id as mid from Ens_Config.Item where Production='"_production_"' and Name='"_configName_"'" )
		If (rsql.%SQLCODE) Write !!,"Can't find item: Production '"_production_"' ConfigName '"_configName_"'" Quit
		Set oItem = ""
		If rsql.%Next() Set oItem = rsql.mid
		If '$IsObject(oItem) Write !!,"Can't open item" Quit
		Kill aos
		// Get all default host settings
		Set rs = ##class(%ResultSet).%New()
		Set rs.ClassName = oItem.ClassName
		Set rs.QueryName = "EnumerateSettings"
		If (rs.QueryIsValid()) {
			Set tSC = rs.Execute()
			While (rs.Next()) {
				Set name = $G(rs.Data("Name"))
				Set default = $G(rs.Data("Default"))
				If name'="" Set aos("Host",name) = default
			}
		}
		Do rs.Close()
		Set rs = ""
		// Get all default adapter settings
		Set rs = ##class(%ResultSet).%New()
		Set rs.ClassName = oItem.AdapterClassName()
		Set rs.QueryName = "EnumerateSettings"
		If (rs.QueryIsValid()) {
			Set tSC = rs.Execute()
			While (rs.Next()) {
				Set name = $G(rs.Data("Name"))
				Set default = $G(rs.Data("Default"))
				If name'="" Set aos("Adapter",name) = default_" (default)"
			}
		}
		Do rs.Close()
		Set rs = ""
		// Replace with actual settings found in Ens.Config.Item
		For i = 1:1:oItem.Settings.Count() {
			Set o = oItem.Settings.GetAt(i)
			Set name = o.Name
			If name'="" {
				Set value = o.Value
				Set target = o.Target If target'="Adapter" Set target = "Host"
				Set aos(target,name)=value
			}
		}
		// Display all host and adapter settings
		Set n = 0
		For t = "Host", "Adapter" {
			Set name = ""
			For {
				Set name = $O(aos(t,name)) Quit:name=""
				Write !,t," Setting Name '",name,"'  Value '",aos(t,name),"'"
				Set n = n+1
			}
		}
		If 'n Write !,"No settings were found."	
	}
	Quit
}

/// Helper method to return the normalized directory name for the full directory path composed of
/// the default test directory plus the additional directories, eg. <b>sub1/sub2</b>.
/// The argument containing the additional directories must use slashes ( <b>/</b> ) as the directory delimiter, on all platforms.
Method SubMainDir(AddDirs = "") As %String
{
	Set Dir = ..MainDir
	For i = 1:1:$L(AddDirs,"/") {
		Set Dir = ##class(%File).SubDirectoryName(Dir, $P(AddDirs,"/",i))
	}
	Quit Dir
}

/// Create a test directory tree that is suitable for generic testing and for HL7 testing.
/// The default root test directory is defined by property <property>MainDir</property>. <br>
/// This method does not erase any files or directories if they are already present.  To do a cleanup,
/// see method <method>CleanUpDirectory</method>. <br>
/// This method may be invoked in OnBeforeAllTests() or OnBeforeProductionStart() to initialize the test directory tree.
Method CreateMainDirTree() As %Status
{
	Do $$$LogMessage("Creating directory tree under "_..MainDir)
	Set s = $$$OK
	For d = ..MainDir, ..HL7InputDir, ..HL7OutputDir, ..HL7WorkDir, ..HL7ArchiveDir {
		Set s = ##class(%File).CreateDirectoryChain(d)
		Quit:'s
	}
	If 's Quit ..Error("Error creating directory "_d)
	Quit $$$OK
}

/// <b>Delete</b> all files in a directory.  If <b>Recurse</b> is true, also delete all subdirectories recursively,
/// and delete the original directory selected, that is, the entire directory vanishes.
Method CleanUpDirectory(Dir As %String = "", Recurse As %Boolean = 0) As %Status [ Internal ]
{
	If Dir="" Quit ..Error("Missing directory name")
	Set Dir = ##class(%File).NormalizeDirectory(Dir)
	If '##class(%File).DirectoryExists(Dir) Quit $$$OK // Directory doesn't exist, nothing to delete
	Do $$$LogMessage("Cleaning up directory "_Dir)
	Set rs = ##class(%ResultSet).%New("%File:FileSet")
	If '$IsObject(rs) Quit ..Error("Error in %File:FileSet")
	Set s = rs.Execute(Dir)
	If 's Quit ..Error("Error in Execute for %File:FileSet")
	Set s = $$$OK
	While (rs.Next()) {
		Set Type = rs.Data("Type"), Name=rs.Data("Name"), Item=rs.Data("ItemName")
		//Write !,"Type ",Type," Name ",Name," Item ",Item
		If Type="D" {
			If Recurse Set s = ..CleanUpDirectory(Name, 1) // Call itself recursively
		}
		Else  {
			//Write "  *** Delete file ",Name
			Set f = ##class(%File).Delete(Name)
			If 'f Set s = ..Error("Error deleting file "_Name)
		}
		If 's Quit
	}
	If 's Quit s
	// Write !,"*** Delete directory ",Dir
	If Recurse Set s = ##class(%File).RemoveDirectory(Dir)
	If 's Quit ..Error("Error removing directory "_Dir)
	Quit $$$OK
}

/// Copy a file from a directory to another directory.  This allows for example to place files in
/// input directories.  The default origin directory <b>SourceDir</b> is the unit test directory.  The default 
/// destination directory <b>TargetDir</b> is the directory name specified by <property>HL7InputDir</property>.
Method CopyFile(FileName As %String = "", SourceDir As %String = "", TargetDir As %String = "") As %Status
{
	If FileName="" Quit ..Error("Missing file name")
	If SourceDir="" Set SourceDir = ..Manager.CurrentDir If SourceDir="" Quit ..Error("Property CurrentDir not set, can't copy from this default location")
	If TargetDir="" Set TargetDir = ..HL7InputDir
	Set FullName1 = ..GetFullName(SourceDir, FileName)
	Set FullName2 = ..GetFullName(TargetDir, FileName)
	Do $$$LogMessage("Copying file "_FullName1_" to "_FullName2)
	Set f = ##class(%File).CopyFile(FullName1, FullName2)
	If f Quit $$$OK
	Quit ..Error("Failed to copy file "_FileName_" from "_SourceDir_" to "_TargetDir)
}

/// Compare the contents of two files and return $$$OK if they are equal, or a status code otherwise. <br>
/// The default for <b>FileName2</b> is the same name as <b>FileName1</b> concatenated with <b>_reference</b>
/// before the last file extension. <br>Examples: <br>
/// <b>FileName1</b> = MyFile.txt, default <b>FileName2</b> = MyFile_Reference.txt <br>
/// <b>FileName1</b> = HL7Message_ADTA01, default <b>FileName2</b> = HL7Message_ADTA01_Reference <br>
/// The default for <b>Dir1</b> is the directory name specified by <property>HL7OutputDir</property>. <br>
/// The default for <b>Dir2</b> is the unit test directory. 
Method CompareFiles(FileName1 As %String = "", FileName2 As %String = "", Dir1 As %String = "", Dir2 As %String = "") As %Status
{
	If FileName1="" Quit ..Error("Missing first file name")
	If FileName2="" {
		If FileName1'["." Set FileName2 = FileName1_"_reference"
		Else  Set l = $L(FileName1,"."), x = $P(FileName1,".",l), FileName2 = $P(FileName1,".",1,l-1)_"_reference."_x
	}
	If Dir1="" Set Dir1 = ..HL7OutputDir
	If Dir2="" Set Dir2 = ..Manager.CurrentDir If Dir1="" Quit ..Error("Property CurrentDir not set, can't compare a file in this default location")
	Set FullName1 = ..GetFullName(Dir1, FileName1)
	Set FullName2 = ..GetFullName(Dir2, FileName2)
	If '##class(%File).Exists(FullName1) Quit ..Error("File "_FullName1_" doesn't exist")
	If '##class(%File).Exists(FullName2) Quit ..Error("File "_FullName2_" doesn't exist")
	Do $$$LogMessage("Comparing files "_FullName1_" and "_FullName2)
	If ##class(%File).Compare(FullName1, FullName2) Quit $$$OK
	Quit ..Error("Files are different")
}

/// Given a directory and a file name, return a normalized full file name.
ClassMethod GetFullName(Dir As %String = "", FileName As %String = "") As %String
{
	If (Dir="") || (FileName="") Quit ..Error("Must provide both directory and file name")
	Set d = Dir
	If $$$isWINDOWS Set:"\/"'[$E(d,$L(d)) d = d_"\"
	If $$$isUNIX Set:"/"'=$E(d,$L(d)) d = d_"/"
	Quit ##class(%File).NormalizeFilename(d_FileName)
}

Method CheckEnvironment() As %Status [ CodeMode = objectgenerator, Internal, Private ]
{
	If %class.Name="%UnitTest.TestProduction" Quit $$$OK
	If '##class(%UnitTest.TestProduction).CheckNamespace() Quit $$$ERROR($$$GeneralError, "This class is only for use in Ensemble and HealthShare systems")
	Do %code.WriteLine(" Quit $$$OK")
	Quit $$$OK
}

/// Enforce mandatory parameter PRODUCTION to be filled in.
Method CheckParameterPRODUCTION() As %Status [ CodeMode = objectgenerator, Internal, Private ]
{
	If %class.Name="%UnitTest.TestProduction" Quit $$$OK
	If %parameter("PRODUCTION")="" Quit $$$ERROR($$$GeneralError, "Parameter PRODUCTION must be specified")
	Do %code.WriteLine(" Quit $$$OK")
	Quit $$$OK
}

/// Define an array with the macros used in this class from the definitions in the production when available.
ClassMethod GetMacros(Output MacroVars As %String) [ CodeMode = objectgenerator, Internal, Private ]
{
	If '$D(^%SYS("Ensemble","InstalledNamespace",$namespace)) Quit $$$OK
	If '$D(^rINC("EnsConstants")) Quit $$$OK // sanity check
	Do %code.WriteLine(" #Include EnsConstants")
	Do %code.WriteLine(" Set MacroVars(""eProductionStateStopped"") = $$$eProductionStateStopped")
	Do %code.WriteLine(" Set MacroVars(""eProductionStateRunning"") = $$$eProductionStateRunning")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeInfo"") = $$$eLogTypeInfo")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeError"") = $$$eLogTypeError")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeTrace"") = $$$eLogTypeTrace")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeWarning"") = $$$eLogTypeWarning")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeAlert"") = $$$eLogTypeAlert")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeAssert"") = $$$eLogTypeAssert")
	Do %code.WriteLine(" Set MacroVars(""eMessageTypeResponse"") = $$$eMessageTypeResponse")
	Do %code.WriteLine(" Quit")
	Quit $$$OK
}

/// Check if namespace is Interoperability or HealthShare enabled.
ClassMethod CheckNamespace() As %Status
{
	If $D(^%SYS("Ensemble","InstalledNamespace",$namespace)), $$$comClassDefined("Ens.StudioManager") Quit $$$OK
	Quit ..Error("Not a Ensemble or HealthShare namespace")
}

Method StartProduction() As %Boolean [ Internal, Private ]
{
	Do ..GetMacros(.Macro)
	Set r = $$$AssertTrue(##class(%Dictionary.CompiledClass).%ExistsId(..#PRODUCTION),"Verifying production class '"_..#PRODUCTION_"' exists")
	If 'r Quit 0
	Set r = $$$AssertTrue($classmethod(..#PRODUCTION,"%IsA","Ens.Production"),"Verifying class is a production class")
	If 'r Quit 0
	Set ..BaseLogId = 1
	Set ..LastLogId = 1
	Set s = ##class(Ens.Director).GetProductionStatus(.tProductionName,.tState)
	If $G(tState)'=Macro("eProductionStateStopped") {
		Do $$$LogMessage("Ensemble is not stopped")
		Do $$$LogMessage("Trying to stop production '"_$G(tProductionName)_"'")
		Do ##class(Ens.Director).StopProduction()
		Set s = ..WaitForState(Macro("eProductionStateStopped"))
		If 's {
			Do $$$LogMessage("Forcing production to stop")
			Set t0 = $ZH
			Do ##class(Ens.Director).StopProduction(,1)
			Hang ..#MAXWAIT-(($ZH-t0-.5)\1) // Wait remining number of seconds until ..#MAXWAIT minus 1
			Do ##class(Ens.Director).CleanProduction(1)
			Set s = ..WaitForState(Macro("eProductionStateStopped"))
		}
		Set r = $$$AssertStatusOK(s, "Verifying Ensemble is now stopped'")
		If 'r Quit 0 
	}
	// Get base log event ID
	Set query = "SELECT TOP 1 ID FROM Ens_Util.Log ORDER BY ID DESC"
	Set rs = ##class(%ResultSet).%New()
	Set s = rs.Prepare(query)
	If s Set s = rs.Execute() If s, rs.Next() Set ..BaseLogId = rs.GetData(1)+1
	Do rs.Close()
	Set rs = ""
	Set ..LastLogId = ..BaseLogId
	// Start the production now
	Do $$$LogMessage("Starting production '"_..#PRODUCTION_"'")
	Set t0 = $ZH
	Set r = $$$AssertStatusOK(##class(Ens.Director).StartProduction(..#PRODUCTION), "Invoking Ens.Director::StartProduction")
	If 'r Do ..LogErrors(r) Quit 0
	Hang ..#MAXWAIT-(($ZH-t0-.5)\1) // Wait remining number of seconds until ..#MAXWAIT minus 1
	Set r = $$$AssertStatusOK(..WaitForState(Macro("eProductionStateRunning")), "Verifying production state is 'Running'")
	If 'r Do ..LogErrors(r) Quit 0
	Set b = $$$AssertNotTrue(##class(Ens.Director).ProductionNeedsUpdate(.tReason), "Verifying if production needs update due to problems after start")
	If 'b {
		// There were issues!
		Set del = $C(13,10)
		Set n = $L($G(tReason),del)
		// Wait until number of issues stabilize
		For  {
			Hang 2
			Do ##class(Ens.Director).ProductionNeedsUpdate(.tReason)
			If $L($G(tReason),del)=n Quit // Stabilized
			Set n = $L($G(tReason),del)
		}
		// Log issues
		For i = 1:1:n {
			If $P(tReason,del,i)'="" Do $$$LogMessage("Reason "_i_": "_$P(tReason,del,i))
		}
		Quit 0
	}
	Quit 1
}

Method StopProduction() As %Boolean [ Internal, Private ]
{
	Do ..GetMacros(.Macro)
	Do $$$LogMessage("Stopping production '"_..#PRODUCTION_"'")
	Set r = $$$AssertStatusOK(##class(Ens.Director).StopProduction(..#MAXWAIT), "Invoking Ens.Director::StopProduction")
	If 'r Quit 0
	Set r = $$$AssertStatusOK(..WaitForState(Macro("eProductionStateStopped")), "Verifying Ensemble state is 'Stopped'")
	If 'r Quit 0
	Quit 1
}

Method WaitForState(pState As %String) As %Status [ Internal, Private ]
{
	Set time  =..#MAXWAIT, s = $$$OK
	Hang 1
	Do {
		Set s = ##class(Ens.Director).GetProductionStatus(.tProductionName, .tState)
		If 's Quit
		If tState=pState Quit
		Set time = time-1
		If 'time Set s = ..Error("State did not change to '"_pState_"' (remained '"_tState_"')")
		Hang 1
	} While time
	Quit s
}

/// Main execution flow control.
Method TestControl() As %Status [ Internal ]
{
	Do $$$LogMessage($system_":"_$namespace_":$ZV="_$ZV)
	If '$$$AssertStatusOK(..OnBeforeProductionStart(), "OnBeforeProductionStart()") Quit
	If '$$$AssertTrue(..StartProduction(), "StartProduction()") GoTo Stop
	If '$$$AssertStatusOK(..OnAfterProductionStart(), "OnAfterProductionStart()") GoTo Stop
	Do $$$LogMessage("Waiting minimum run time of "_..#MINRUN_" secs")
	Set Enough = 0, sec = 1
	While ('Enough) {
		// This is currently done in a loop because I intend to add another mechanism to stop the loop
		Hang 1
		Set sec = sec+1
		If sec>..#MINRUN Set Enough = 1
	}
	// Retrieve event log entries array of type "Info" user-generated to pass to method CheckResults
	Set s = ..GetEventLog("infouser", "", ..BaseLogId, .Log, .New)
	Do $$$LogMessage("Invoking CheckResults()")
	Do $$$AssertStatusOK(..CheckResults(.Log, $G(New)), "User code to verify production results: CheckResults()")
	Do $$$AssertStatusOK(..OnBeforeProductionStop(), "OnBeforeProductionStop()")
Stop
	Do $$$AssertTrue(..StopProduction(), "StopProduction()")
	Do $$$AssertStatusOK(..OnAfterProductionStop(), "OnAfterProductionStop()")
	If ..#IGNOREPRODUCTIONERRORS {
		Do $$$LogMessage("Intentionally skipping automatic verification of production errors")
		Do $$$LogMessage("Invoking CheckErrors()")
		Do ..CheckErrors() // The programmer may add code in this method to verify the errors
	}
	Else  {
		// Automatically check errors
		Kill Err Set s = ..GetEventLog("error", "", ..BaseLogId, .Err, .n) // Retrieve all records of type "Error"
		Do $$$AssertEquals($D(Err), 0, "Verifying no production errors occurred")
		For i = 1:1:n {
			Do $$$LogMessage("Error in Event Log: "_Err(i,"SourceClass")_":"_Err(i,"SourceMethod")_", Item "_Err(i,"ConfigName")_", Text: "_Err(i,"Text"))
		}
	}
	Quit
}

}
