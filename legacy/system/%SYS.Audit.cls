/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syJrninc, %syEMS)

/// The auditing system allows the user to capture events
/// which occur on the system, and log them to an audit file.
/// <br><br>
/// When running SQL queries on the audit log, it is helpful to use the UTCTimestamp
/// in the WHERE clause to speed up the query, and minimize the amount of data
/// which is returned. For example: <br><br>
/// 
/// 	SELECT SystemID,AuditIndex,UTCTimeStamp,EventSource,EventType,Event,Pid,CSPSessionID,Username,Description<br>
/// 	FROM %SYS.Audit<br>
/// 	WHERE UTCTimeStamp BETWEEN :UTCBeginDateTime AND :UTCEndDateTime<br>
/// 	ORDER BY UTCTimeStamp DESC, SystemID DESC, AuditIndex DESC<br>
/// 	<br>
/// 	The UTCTimeStamp is the UTC time in ODBC format. To convert a local $H time to this format use
/// 	the following:<br><br>
/// 	s x=##Class(%SYS.Audit).ConvertLocalHToUTC($H)
/// 	<br>
/// 	The UTCTimeStamp which is returned as part of the record, can be converted to local time
/// 	with the following:<br><br>
/// 	s x=##Class(%SYS.Audit).ConvertUTCToLocal(UTCTimeStamp)<br><br>
/// 
/// Access to all the audit class methods require the %Admin_Secure:"Use" privilege.<br><br>
/// If you wish to modify an audit record, use the Modify() class method. If you wish to modify it using direct object
/// you must first use the OpenAuditRecord() class method and then the %Save() method. Note that saving the object in
/// this way also requires that the user have write access to the Audit database resource.<br>
/// 	
Class %SYS.Audit Extends (%Persistent, %SYSTEM.Help, %XML.Adaptor) [ Inheritance = right, StorageStrategy = Audit, System = 4 ]
{

Parameter SOURCECONTROL [ Internal ] = {"Revision path: $Id: //iris/latest/databases/sys/cls/Security/Users.xml#66 $"_$c(13,10)_"Last Change:   $DateTime: 2022/06/08 09:18:09 $"_$c(13,10)_"Changelist #:  $Change: 5432096 $"};

Index IDKEY On (UTCTimeStamp, SystemID, AuditIndex) [ IdKey, Internal, Unique ];

Property AuditIndex As %BigInt;

/// Authentication method process used.
Property Authentication As Security.Datatype.Authentication;

/// Executable name on the client machine.
Property ClientExecutableName As %String(MAXLEN = 128);

/// IP address of the client, as passed from client. This corresponds to the ClientIPAddress in %SYS.ProcessQuery.
Property ClientIPAddress As %String(MAXLEN = 128);

/// Session ID of the process if a CSP process.
Property CSPSessionID As %String(MAXLEN = 16);

/// Description of the audit event.<br>
/// Control characters less than $c(32) are not allowed in this data except
/// for CR,LF, and tab.
Property Description As %SYS.AuditString(MAXLEN = 128);

ClassMethod DescriptionLogicalToDisplay(Description As %String) As %String [ Internal ]
{
 i $e(Description,1,2)="@@" {
	 q "^^"_$e(Description,3,*)
 } else {
	q Description
 }
}

/// Name of the audit event.
Property Event As %String(MAXLEN = 64);

/// EventData -- arbitrary data associated with this event.<br>
/// Control characters less than $c(32) are not allowed in this data except
/// for CR,LF, and tab.
Property EventData As %SYS.AuditString(MAXLEN = 16384);

ClassMethod EventDataLogicalToDisplay(EventData As %String) As %String [ Internal ]
{
 i $e(EventData,1,2)="@@" {
	 q "^^"_$e(EventData,3,*)
 } else {
	q EventData
 }
}

/// Event Source (system events all have "%System" here).
Property EventSource As %String(MAXLEN = 64);

/// EventType.
Property EventType As %String(MAXLEN = 64);

/// Group of the audit event.
Property GroupName As %String(MAXLEN = 64);

/// Job ID
Property JobId As %String(MAXLEN = 16);

/// Job Number
Property JobNumber As %Integer [ Calculated, SqlComputeCode = { set {*}=$zb({JobId},65535,1)}, SqlComputed, SqlFieldName = JobNumber ];

/// Namespace process was executing in.
Property Namespace As %String(MAXLEN = 128);

ClassMethod NamespaceLogicalToDisplay(Namespace As %String) As %String [ Internal ]
{
 q $tr(Namespace,"@","^")
}

/// Operating system username of process.<br>
/// Username given to the process by the operating system when the process
/// is created. When displayed, it is truncated to 16 characters. Note that the real O/S
/// username is only returned when connecting to UNIX or VMS systems; For Windows, it 
/// will return the O/S username for a console process, but for telnet it will return
/// the $USERNAME of the process. For client connections, it contains the O/S username
/// of the client.
Property OSUsername As %String(MAXLEN = 16);

/// Process ID.<br>
/// Note that on VMS system, the Hex pid is stored internally as a decimal value, i.e. $zh(pid).
Property Pid As %String(MAXLEN = 16);

/// $ROLES value that was active when the audit event occurred.
Property Roles As %String(MAXLEN = 2048);

/// Routine running including DB and System.
Property RoutineSpec As %String(MAXLEN = 512);

/// IP address of the client, as detected on the TCP channel by the server process. 
/// This corresponds to the StartupClientIPAddress in %SYS.ProcessQuery.
Property StartupClientIPAddress As %String(MAXLEN = 128);

/// Any %Status variable passed into the call.
Property Status As %Status [ InitialExpression = 1 ];

/// SystemName:ConfigurationName of where the event was generated.<br>
/// This is useful when merging separate audit streams from different systems.
Property SystemID As %String(MAXLEN = 128);

/// User info field
Property UserInfo As %String(MAXLEN = 64);

/// Username from $Username that was active when audit event occurred.
Property Username As %SYS.AuditString(MAXLEN = 160);

/// UTC $ZTIMESTAMP value when the audit event occurred.
Property UTCTimeStamp As %String(MAXLEN = 64);

/// Apply the audit header to the audit file.<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod ApplyAuditHeader() As %Status [ Internal ]
{
#; This function reads any audit records which got written to the header, and applies them
#; to the audit file. This requires the %All role.
 s $zt="ReadAuditHeaderE"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary ; verified 9/26/16 STC
#;Get the header
 l +$$$AuditHeader
 s Header=$g($$$AuditHeader)
#;If the header does not exist, create it
 i Header="" s ($$$AuditHeader,Header)=$lb($j("",$$$AuditHeaderSize))
#;Nothing to do, but try to increase the size if necessary
 i $ll(Header)=1 {
	i $l(Header)<$$$AuditHeaderSize {
		Try {
			s ($$$AuditHeader,Header)=$lb($j("",$$$AuditHeaderSize))
		} catch {}
	}
	g ReadAuditHeaderEnd
 }
#;Peel the padding
 s Header=$li(Header,1,$ll(Header)-1)
#;For each audit record (15 fields) set it into the audit database.
#;Note that if we get an error (e.g. filefull) its ok, they'll just
#;get written later, the next time this is called
 s count = $ll(Header)
 For j=1:1:count {
	s rec=$li(Header,1)
#;Get the indexes
 	s UTCTimeStamp=$li(rec,15)
 	s System=$li(rec,13)
 	s Index=$li(rec,1)
#;Set the record into the audit file
 	s $$$AuditGbl(UTCTimeStamp,System,Index)=$li(rec,1,$ll(rec))
	$$$IncAuditWrittenCount($li(rec,7)_"/"_$li(rec,8)_"/"_$li(rec,5))
#;Remove record from the header, re-pad, and set it back in
 	s Header=$li(Header,2,$ll(Header))
 	f i=($$$AuditHeaderSize-$l(Header)):-1:1 q:$l(Header_$lb($j("",i)))<=$$$AuditHeaderSize
 	s $$$AuditHeader=Header_$lb($j("",i))
 	d $$$JRNFLUSHBUF
 }
ReadAuditHeaderEnd
 l -$$$AuditHeader#"I"
 q $$$OK
ReadAuditHeaderE s $zt=""
 l -$$$AuditHeader#"I"
 q $$$OK
}

/// Determine if any records in the audit header are prior to EndDateTime.
ClassMethod CheckHeader(EndDateTime As %String) As %Integer [ Internal, Private ]
{
 #;Get the current header
  s Header=$g($$$AuditHeader,$lb(""))
 #;Peel off the padding
  s Header=$li(Header,1,$ll(Header)-1)
 #;No records, return 0
  i $ll(Header)=0 q 0
  i '$l(EndDateTime) q 1
  i $p(EndDateTime,",",2)=0 s EndDateTime=(+UTCEndDateTime-1)_","_86399.999
  s UTCEndDateTime=..ConvertLocalHToUTC(EndDateTime)
  s n=0
  f i=1:1:$ll(Header) s UTCTimeStamp=$li($li(Header,i),15) i UTCEndDateTime]UTCTimeStamp s n=1 q
  q n
}

/// Converts Audit records to the current IRIS format.<br>
/// This is called before any of the Audit methods runs and also during an upgrade to make sure that the audit global
/// is in the current format.<br>
/// It will also check if there are any audit records in Cache' format (stored in the ^CacheAuditD
/// global) and merge those globals into the current IRIS audit global.<br>
/// Note that journaling is turned off for the process during the conversion.<br>
/// <br>
/// Parameters:<br>
/// Count (byref) - Returned count of number of audit records converted.<br>
/// 0 - Version already matches.<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Convert(ByRef Count As %Integer) As %Status
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary ; verified 10/23/18 STC
 k Count
 s Count=0
#;Perform any conversion of the IRIS audit database first before we attempt to handle any
#;Cache conversion. The Cache conversion below must convert it to the current version.
 i $d(^IRIS.AuditD) {
	i ($g(^IRIS.AuditV)'=$$$AuditVersion) {
#;Perform any conversion of the audit global here. There currently is none,
#;So the ^IRIS.AuditV global must just be missing. If we need to convert in the future,
#;make sure we turn off journaling.		
		s ^IRIS.AuditV=$$$AuditVersion
	}
 }
#;If here, the ^IRIS.AuditD global (if it exists) is in the correct format.
#;CacheAuditD is no longer mapped so we need to explicitly reference the audit directory in
#;the %SYS namespace
 i $namespace="%SYS" {
	s AuditDir=..GetAuditDatabase()
	s AuditDir="^^"_AuditDir
 } else {
	s AuditDir=$namespace
 }
#;We must test both AuditDir and no AuditDir reference since the user could have imported CacheAuditD into the
#;%SYS namespace (remember its not mapped), and we want to find it and handle the conversion in this case also.
 i ($d(^|AuditDir|CacheAuditD)=0),($d(^CacheAuditD)=0) q $$$OK
#;If here we have to convert the ^CacheAuditD global to ^IRIS.AuditD.
#;The Audit version we are converting it to is 2018.1
#;If the version changes, we must change the code below to convert it to that version, as well as add code above
#;to convert ^IRIS.AuditD
#;Do not journal the audit conversion
 s Journal=$$CURRENT^%SYS.NOJRN
 i Journal d DISABLE^%SYS.NOJRN
GetUnmappedAudit
 i $d(^|AuditDir|CacheAuditD) {
	k ^|AuditDir|CacheAuditV
	k ^|AuditDir|CacheAuditHeader
	zkill ^|AuditDir|CacheAuditD
	$$$InfoMsg("Converting Cache audit records to IRIS format in namespace "_AuditDir)
 	s Count=0
 	s TimeStamp=""
	f  {
#;Convert most recent first. No need for transactions here.
		s TimeStamp=$o(^|AuditDir|CacheAuditD(TimeStamp),-1) q:TimeStamp=""
		s Node=""
		f  {
			s Node=$o(^|AuditDir|CacheAuditD(TimeStamp,Node)) q:Node=""
			s Counter=""
			f  {
				s Counter=$o(^|AuditDir|CacheAuditD(TimeStamp,Node,Counter),1,Data) q:Counter=""
	 			s ^IRIS.AuditD(TimeStamp,Node,Counter)=Data
				k ^|AuditDir|CacheAuditD(TimeStamp,Node,Counter)
				s Count=Count+1
			}
	 	}
	}
	$$$InfoMsg(Count_" Audit records successfully converted")
 }
#;If the CacheAuditD global still exists, then it is the old 2 subscript global 
#;^CacheAuditD(Node,Count) which is pre-2009.1
 i $d(^|AuditDir|CacheAuditD) {
	$$$InfoMsg("Converting pre-2009.1 Cache audit records to IRIS format in namespace "_AuditDir)
#;Start with most recent audit records
	s Count=0
	s Node=$q(^|AuditDir|CacheAuditD(""),-1,Record)
	while Node'="" {
		i $ql(Node)=2 {
			s ^IRIS.AuditD($li(Record,15),$qs(Node,1),$qs(Node,2))=Record
			k @Node
			s Count=Count+1
		}
		s Node=$q(@Node,-1,Record)
 	}
	$$$InfoMsg(Count_" Audit records successfully converted")
 }
 i $d(^|AuditDir|CacheAuditD) {
	 $$$SevereError("Error converting ^|"_AuditDir_"|CacheAuditD to ^IRIS.AuditD")
	 $$$SevereError("Renaming ^|"_AuditDir_"|CacheAuditD to ^|"_AuditDir_"|CacheAuditError")
	 Merge ^|"_AuditDir_"|CacheAuditError=^|"_AuditDir_"|CacheAuditD
	 Kill ^|"_AuditDir_"|CacheAuditD
 }
#;Now if we have imported the CacheAuditD global into the %SYS namespace (remember its not mapped), convert it here also
#;The Cache audit globals had the "keep" bit set, so we need to call this to get rid of the directory entry.
 i $e(AuditDir,1,2)="^^" {
	d ##Class(%Library.GlobalEdit).DeleteDirectoryEntry($e(AuditDir,3,*), "CacheAuditD")
	d ##Class(%Library.GlobalEdit).DeleteDirectoryEntry($e(AuditDir,3,*), "CacheAuditV")
	d ##Class(%Library.GlobalEdit).DeleteDirectoryEntry($e(AuditDir,3,*), "CacheAuditHeader")
	s AuditDir="%SYS"
	g GetUnmappedAudit
 }
 s ^IRIS.AuditV=$$$AuditVersion
 s Status=$$$OK
Exit
 i +$g(Journal) d ENABLE^%SYS.NOJRN
 q Status
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 g Exit
}

/// Convert the local $H time to an ODBC format string in UTC.<br>
/// When using SQL, use this function to convert a local time in $h to UTC time to
/// use in your SELECT statement.<br>
ClassMethod ConvertLocalHToUTC(LocalH As %String) As %String
{
 	q $zdatetime($ZU(193,LocalH,1),3,,3)
}

/// Convert a UTCTimeStamp in ODBC format to Local Time in ODBC format.<br>
ClassMethod ConvertUTCHToLocal(UTC As %String) As %String
{
 	q $zdatetime($zu(193,UTC,0),3,,3)
}

ClassMethod ConvertUTCToLocal(UTC As %String) As %String [ Internal ]
{
 	q $zdatetime($zu(193,$zdatetimeH(UTC,3),0),3,,3)
}

/// Copy matching audit records to a defined namespace.<br>
/// Parameters:<br>
/// BeginDateTime - $zdatetime($H,3) value of the first audit record to copy, "" = first record<br>
/// EndDateTime - $zdatetime($H,3) value of the Last audit record to copy, "" = Last record<br>
/// The following parameters may be specified as a comma separated list as follows:<br>
/// "*" - All records match<br>
/// "String,String1" - Any records matching one of these elements<br>
/// "String*" - Any record starting with "String"<br>
/// "String,String1*,String2" - Any record matching one of these elements, or starting with "String1"<br>
/// Note that these are all case insensitive matches<br>
/// EventSources - Comma separated list of valid event sources<br>
/// EventTypes - Comma separated list of valid event types<br>
/// Events - Comma separated list of event names<br>
/// Usernames - Comma separated list of user names<br>
/// SystemIDs - Comma separated list of System:Config names<br> 
/// Namespace - Valid namespace to copy audit records to<br>
/// Flags - Bit 0 - Delete audit record after copy<br>
/// Return values:<br>
/// NumCopied (byref) - Number of audit records copied<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Copy(ByRef NumCopied As %Integer, Namespace As %String, Flags As %Integer = 0, BeginDateTime As %String = "", EndDateTime As %String = "", EventSources As %String = "*", EventTypes As %String = "*", Events As %String = "*", Usernames As %String = "*", SystemIDs As %String = "*") As %Status
{
 s $zt="Error"
 s NumCopied=0
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
#;namespace is the same
 i $namespace=$zcvt(Namespace,"U") q $$$OK
#;Make sure the audit database is in the right format
 s Status=..Convert()
 i '$$$ISOK(Status) q Status
 s Status=$$ConvertDestination(Namespace)
 i '$$$ISOK(Status) q
#;Write 2 audit records in case the first one is deleted in the copy
 s CRLF=$c(13)_$c(10),String="",Pad=$j("",20)
 i Flags=0 {
 	s String=String_$$$GetMsg($$$AuditMsg,"CopyAuditData")_CRLF
 } else {
 	s String=String_$$$GetMsg($$$AuditMsg,"CopyAndDeleteAuditData")_CRLF
 }
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
 	s Node=$q(^$$$AuditDataName(""))
 	i Node="" {
		s BDateTime=$zdatetime($h,3)
	} else {
 		s BDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s Node=$q(^$$$AuditDataName(""),-1)
	i Node="" {
		s EDateTime=$h
	} else {
		s EDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"TargetNamespaceC")_Pad,1,$l(Pad))_Namespace_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$Case(Flags,0:$$$GetMsg($$$AuditMsg,"CopyAuditData"),1:$$$GetMsg($$$AuditMsg,"CopyAndDeleteAuditData")))
 $$$AddAllRoleTemporary  ; verified 9/26/16 STC
 l +$$$AuditGbl
 i ..CheckHeader(EndDateTime) s sc=$$$ERROR($$$AuditHeaderUnwritten) g Cleanup
 Set Rset = ##class(%ResultSet).%New("%SYS.Audit:List")
 i '$IsObject(Rset) q %objlasterror
 n %NoAuditList s %NoAuditList=1
 d Rset.Execute(BeginDateTime,EndDateTime,EventSources,EventTypes,Events,Usernames,SystemIDs)
 While Rset.Next() {
	s UTCTimeStamp=Rset.Data("UTCTimeStamp"),SystemID=Rset.Data("SystemID"),AuditIndex=Rset.Data("AuditIndex")
	s ^|Namespace|$$$AuditDataName(UTCTimeStamp,SystemID,AuditIndex)=^$$$AuditDataName(UTCTimeStamp,SystemID,AuditIndex)
 	i Flags=1 k ^$$$AuditDataName(UTCTimeStamp,SystemID,AuditIndex)
	s NumCopied=NumCopied+1
 }
 s ^|Namespace|IRIS.AuditV=^IRIS.AuditV
 s String=""
 i Flags=0 {
 	s String=String_$$$FormatMsg($$$AuditMsg,"CopyNumAuditRecordsC",NumCopied)_CRLF
 } else {
 	s String=String_$$$FormatMsg($$$AuditMsg,"CopyAndDeleteNumAuditRecordsC",NumCopied)_CRLF
 }
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"TargetNamespaceC")_Pad,1,$l(Pad))_Namespace_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$Case(Flags,0:$$$GetMsg($$$AuditMsg,"CopyAuditData"),1:$$$GetMsg($$$AuditMsg,"CopyAndDeleteAuditData")))
Cleanup
 l -$$$AuditGbl#"I"
 q $$$OK
Error s $zt=""
 l -$$$AuditGbl#"I"
 Quit $$$ERROR($$$ObjectScriptError,$ze)
 
ConvertDestination(Namespace)
 s $zt="Error1"
 n $namespace
 d $zu(5,Namespace)
 s Status=..Convert()
 q Status
Error1 s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Creates the audit globals with the correct collation.
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod CreateGlobals(Directory As %String) As %Status [ Internal ]
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary  ; verified 9/26/16 STC
#;Set the global attributes for each of the audit globals
 f i=$$$AuditDataNameStr,$$$AuditHeaderNameStr,$$$AuditVersionStr {
 	s Global=##Class(%GlobalEdit).Open(i,Directory,,,.Status)
 	i '$$$ISOK(Status) {
 		s Global=##Class(%GlobalEdit).%New(Directory)
 		s Global.Name=i
 	}
 	s Global.Collation=5
 	s Global.IsKeep=1
 	s Status=Global.%Save()
 	i '$$$ISOK(Status) q
 }
 s ^$$$AuditVersionName=$$$AuditVersion
 q Status
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Delete matching audit records.<br>
/// Parameters:<br>
/// BeginDateTime - $zdatetime($H,3) value of the first audit record to delete, 
/// use "" to begin with the first record<br>
/// EndDateTime - $zdatetime($H,3) value of the Last audit record to delete. 
/// Audit records will be deleted up through, but not including, this value. Use "" to delete through last record<br>
/// The following parameters may be specified as a comma separated list as follows:<br>
/// "*" - All records match<br>
/// "String,String1" - Any records matching one of these elements<br>
/// "String*" - Any record starting with "String"<br>
/// "String,String1*,String2" - Any record matching one of these elements, or starting with "String1"<br>
/// Note that these are all case insensitive matches<br>
/// EventSources - Comma separated list of valid event sources<br>
/// EventTypes - Comma separated list of valid event types<br>
/// Events - Comma separated list of event names<br>
/// Usernames - Comma separated list of user names<br>
/// SystemIDs - Comma separated list of System:Config names<br> 
/// JSONSearch - String to search for in the JSON Data field
/// Return values:<br>
/// NumDeleted (byref) - Number of audit records deleted<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Delete(ByRef NumDeleted As %Integer, BeginDateTime As %String = "", EndDateTime As %String = "", EventSources As %String = "*", EventTypes As %String = "*", Events As %String = "*", Usernames As %String = "*", SystemIDs As %String = "*", JSONSearch As %String = "") As %Status
{
 s $zt="Error"
 s NumDeleted=0
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
#;Make sure the audit database is in the right format
 s Status=..Convert()
 i '$$$ISOK(Status) q Status
#;Write 2 audit records in case the first one is deleted in the copy
 s CRLF=$c(13)_$c(10),String="",Pad=$j("",20)
 s String=String_$$$GetMsg($$$AuditMsg,"DeleteAuditRecordsC")_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
 	s Node=$q(^$$$AuditDataName(""))
 	i Node="" {
		s BDateTime=$zdatetime($h,3)
	} else {
 		s BDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s Node=$q(^$$$AuditDataName(""),-1)
	i (Node="")||(Node="^IRIS.AuditD") {
		s EDateTime=$zdatetime($H,3)
	} else {
		s EDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$$$GetMsg($$$AuditMsg,"DeleteAuditData"))
 $$$AddAllRoleTemporary  ; verified 9/26/16 STC
 l +$$$AuditGbl
 Set Rset = ##class(%ResultSet).%New("%SYS.Audit:List")
 i '$IsObject(Rset) q %objlasterror
 n %NoAuditList s %NoAuditList=1
 d Rset.Execute(BeginDateTime,EndDateTime,EventSources,EventTypes,Events,Usernames,SystemIDs,,,,,JSONSearch)
 While Rset.Next() {
	s UTCTimeStamp=Rset.Data("UTCTimeStamp"),SystemID=Rset.Data("SystemID"),AuditIndex=Rset.Data("AuditIndex")
 	k ^$$$AuditDataName(UTCTimeStamp,SystemID,AuditIndex)
	s NumDeleted=NumDeleted+1
 }
 s String=""
 s String=String_$$$FormatMsg($$$AuditMsg,"DeleteNumAuditRecordsC",NumDeleted)_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$$$GetMsg($$$AuditMsg,"DeleteAuditData"),1)
Cleanup
 l -$$$AuditGbl#"I"
 q $$$OK
Error s $zt=""
 l -$$$AuditGbl#"I"
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Erase the audit file.<br>
/// Flags:
///  0 - Erase all contents<br>
///  1 - Erase and create new audit file<br>
///  2 - Erase and create new audit file, treat as encryption state changed<br>
/// Note that bit 1 infers that ALL data in the audit database will be deleted, not just Audit data<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Erase(Flags As %Integer = 0) As %Status
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary  ; verified 9/26/16 STC
 i '##Class(Security.System).Exists($$$SystemSecurityName,.System,.Status) q Status
 l +$$$AuditGbl
 s Node=$q(^$$$AuditDataName(""))
 i Node="" {
	 s BeginTime=$zdatetime($h,3)
	 s EndTime=BeginTime
 } else {
 	s BeginTime=..ConvertUTCToLocal($li(@Node,15))
 	s EndTime=..ConvertUTCToLocal($li(@$q(^$$$AuditDataName(""),-1),15))
 }
 i Flags = 0 {
	k ^$$$AuditDataName
	k ^$$$AuditHeaderName
#;Force the audit record to file even if not auditing.
	d ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,$$$FormatMsg($$$AuditMsg,"ErasedAuditFromTo",BeginTime,EndTime),$$$GetMsg($$$AuditMsg,"EraseAuditData"),1)
 } else {
 	s AuditDatabase=..GetAuditDatabase()
#; Set switch 10 to prohibit writes to the audit db, wait 10 seconds for quiesce
 	i $$%swset^SWSET(10,1) s SWSET=1
	s Quiesce=$$TQUIGLO^SWSET(0)
 	i 'Quiesce s Status=$$$ERROR($$$AuditUnableToQuiesce) g Cleanup
#;Turn off all audit flags for my process to make sure we don't try to write to it if dismounted. The dismount
#;itself can cause a write to it.
	f i=$zu(179,$$$AUDITMINEVENTNUMBER):1:($zu(179,$$$AUDITMAXEVENTNUMBER)-1) s OldVal(i)=$zu(179,$$$AUDITEFFECTIVE,i,0)
#; Now try to dismount it for 20 seconds
 	f i=1:1:20 s Status=$zu(3,AuditDatabase) q:Status>0  h 1
#;Let write daemon close it
 	h 1
	i Status<=0 s Status=$$$ERROR($$$UnexpectedError,Status) g Cleanup
#;Now delete it
	S Status=##Class(%Library.File).Delete(AuditDatabase_$$$UCFILENAME_".DAT")
	i '$$$ISOK(Status) {
#;Remount it on failure
		d $zu(17,AuditDatabase)
		g Cleanup
	}
#;Now create a new database
	s EncKeyID=$System.Security.System.GetDBEncKeyID()
	i (EncKeyID'=""),System.AuditEncrypt {
		s Status=##class(SYS.Database).CreateDatabase(AuditDatabase,,,1,$$$DBIRISAUDITResourceName)
	} else {
		s Status=##class(SYS.Database).CreateDatabase(AuditDatabase,,,,$$$DBIRISAUDITResourceName)
	}
	i '$$$ISOK(Status) g Cleanup
#;Create the default globals with the correct collation
	s Status=..CreateGlobals(AuditDatabase)
#;And audit the event. Force the audit to be written to the audit file even if auditing
#;is off or we are not auditing this event.
	i Flags=1 {
		d ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,$$$FormatMsg($$$AuditMsg,"ErasedAuditFromTo",BeginTime,EndTime),$$$GetMsg($$$AuditMsg,"EraseAuditData"),1)
	} else {
		d ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,$$$FormatMsg($$$AuditMsg,"ErasedAuditFromToEncrypt",BeginTime,EndTime),$$$GetMsg($$$AuditMsg,"EraseAuditData"),1)
	}
 }
Cleanup
 i $d(SWSET),$$%swset^SWSET(10,0)
 l -$$$AuditGbl#"I"
#;Restore the audit flags to previous values
 i $d(OldVal) {
	 f i=$zu(179,$$$AUDITMINEVENTNUMBER):1:($zu(179,$$$AUDITMAXEVENTNUMBER)-1) d $zu(179,$$$AUDITEFFECTIVE,i,OldVal(i))
 }
 q Status
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 g Cleanup
}

/// Audit record exists.<br>
/// This method checks for the existence of an Audit record in the security database.<br>
/// Parameters:<br>
/// UTCTimeStamp - UTC timestamp of the audit record<br>
/// SystemID - System ID of the audit event, usually NODE:CFGNAME<br>
/// AuditIndex - Index number of the audit record<br>
/// Return values:<br>
/// If Value of the method = 0 (Audit record does not exist, or some error occured)<br>
/// Audit = Null<br>
/// Status = Audit "x" does not exist, or other error message<br><br>
/// If Value of the method = 1 (Audit record exists)<br>
/// Audit = Object handle to Audit record<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
/// If you wish to modify the returned object, use the Modify() method.<br>
ClassMethod Exists(UTCTimeStamp As %String = "", SystemID As %String = "", AuditIndex As %Integer = 0, ByRef Audit As %ObjectHandle, ByRef Status As %Status) As %Boolean
{
 s $zt="Error"
 s Audit=""
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
	 s Status=$$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	 q 0
 }
 $$$AddAllRoleTemporary  ; verified 10/31/18 STC
 s Audit=..%OpenId(UTCTimeStamp_"||"_SystemID_"||"_AuditIndex,,.Status)
 i $$$ISOK(Status) q 1
 i $p($SYSTEM.Status.GetErrorCodes(Status),",")=$$$ERRORCODE($$$LoadObjectNotFound) s Status=$$$ERROR($$$AuditDoesNotExist,UTCTimeStamp_"||"_SystemID_"||"_AuditIndex)
 q 0
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 q 0
}

/// Export matching records to an xml file.<br>
/// Parameters:<br>
/// FileName - Valid filename to copy audit records to<br>
/// Flags - Bit 0 - Delete audit record after export<br>
/// BeginDateTime - $zdatetime($H,3) value of the first audit record to copy, "" = first record<br>
/// EndDateTime - $zdatetime($H,3) value of the Last audit record to copy, "" = Last record<br>
/// The following parameters may be specified as a comma separated list as follows:<br>
/// "*" - All records match<br>
/// "String,String1" - Any records matching one of these elements<br>
/// "String*" - Any record starting with "String"<br>
/// "String,String1*,String2" - Any record matching one of these elements, or starting with "String1"<br>
/// Note that these are all case insensitive matches<br>
/// EventSources - Comma separated list of valid event sources<br>
/// EventTypes - Comma separated list of valid event types<br>
/// Events - Comma separated list of event names<br>
/// Usernames - Comma separated list of user names<br>
/// SystemIDs - Comma separated list of System:Config names<br> 
/// Username - Comma separated list of user names to copy, "*" = All<br>
/// Return values:<br>
/// NumCopied (byref) - Number of audit records exported.<br>
/// Note: Two audit record will get written out when this is called in case the first one
/// is deleted as part of the export operation.<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Export(FileName As %String, ByRef NumExported As %Integer, Flags As %Integer = 0, BeginDateTime As %String = "", EndDateTime As %String = "", EventSources As %String = "*", EventTypes As %String = "*", Events As %String = "*", Usernames As %String = "*", SystemIDs As %String = "*") As %Status
{
 s $zt="Error"
 s NumExported=0
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
#;Make sure the audit database is in the right format
 s Status=..Convert()
 i '$$$ISOK(Status) q Status
#;Write 2 audit records in case the first one is deleted in the copy
 s CRLF=$c(13,10),String="",Pad=$j("",20)
 i Flags=0 {
 	s String=String_$$$GetMsg($$$AuditMsg,"ExportAuditRecordsC")_CRLF
 } else {
 	s String=String_$$$GetMsg($$$AuditMsg,"ExportAndDeleteAuditRecordsC")_CRLF
 }
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
 	s Node=$q(^$$$AuditDataName(""))
 	i Node="" {
		s BDateTime=$zdatetime($h,3)
	} else {
 		s BDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s Node=$q(^$$$AuditDataName(""),-1)
	i Node="" {
		s EDateTime=$h
	} else {
		s EDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"FileNameC")_Pad,1,$l(Pad))_FileName_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$Case(Flags,0:$$$GetMsg($$$AuditMsg,"ExportAuditData"),1:$$$GetMsg($$$AuditMsg,"ExportAndDeleteAuditData")))
 $$$AddAllRoleTemporary  ; verified 9/26/16 STC
 l +$$$AuditGbl
 i ..CheckHeader(EndDateTime) s sc=$$$ERROR($$$AuditHeaderUnwritten) g Cleanup
 #; From now on must exit through Cleanup
 s Rset=##class(%ResultSet).%New("%SYS.Audit:List")
 #; Create and initialize an %XML.Writer object
 Set writer=##class(%XML.Writer).%New()
 s sc=writer.OutputToFile(FileName)
     If $$$ISERR(sc) goto Cleanup
 s writer.Charset="UTF-8"
 s writer.Indent=1
 s sc=writer.RootElement("AuditExport") ;won't work without this
 i $$$ISERR(sc) goto Cleanup
 n %NoAuditList s %NoAuditList=1
 d Rset.Execute(BeginDateTime,EndDateTime,EventSources,EventTypes,Events,Usernames,SystemIDs)
 While Rset.Next() {
	s UTCTimeStamp=Rset.Data("UTCTimeStamp"),SystemID=Rset.Data("SystemID"),AuditIndex=Rset.Data("AuditIndex")
	s oref=..%OpenId(UTCTimeStamp_"||"_SystemID_"||"_AuditIndex)
	#;Perform the export using the object Id.
    set sc=writer.Object(oref)
    If $$$ISERR(sc) goto Cleanup 
    i Flags=1 k ^$$$AuditDataName(UTCTimeStamp,SystemID,AuditIndex)
	s NumExported=NumExported+1
 }
 s sc=writer.EndRootElement()
 i $$$ISERR(sc) goto Cleanup
 s sc=writer.EndDocument()
 s String=""
 i Flags=0 {
 	s String=String_$$$FormatMsg($$$AuditMsg,"ExportNumAuditRecordsC",NumExported)_CRLF
 } else {
 	s String=String_$$$FormatMsg($$$AuditMsg,"ExportAndDeleteNumAuditRecordsC",NumExported)_CRLF
 }
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"FileNameC")_Pad,1,$l(Pad))_FileName_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$Case(Flags,0:$$$GetMsg($$$AuditMsg,"ExportAuditData"),1:$$$GetMsg($$$AuditMsg,"ExportAndDeleteAuditData")))
Cleanup
 l -$$$AuditGbl#"I"
 i $d(sc),'$$$ISOK(sc) q sc
 q $$$OK
Error s $zt=""
 l -$$$AuditGbl#"I"
 i $d(writer) d writer.EndDocument()
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Get the Audit properties.<br>
/// Parameters:<br>
/// SystemID - System ID of the audit event, usually NODE:CFGNAME<br>
/// AuditIndex - Index number of the audit record<br>
/// Return values:<br>
/// Properties - Array of properties<br>
/// Properties("AuditIndex")<br>
/// Properties("ClientExecutableName")<br>
/// Properties("ClientIPAddress")<br>
/// Properties("CSPSessionID")<br>
/// Properties("Description")<br>
/// Properties("Event")<br>
/// Properties("EventData")<br>
/// Properties("EventSource")<br>
/// Properties("EventType")<br>
/// Properties("JobId")<br>
/// Properties("Namespace")<br>
/// Properties("Pid")<br>
/// Properties("Roles")<br>
/// Properties("RoutineSpec")<br>
/// Properties("StartupClientIPAddress")<br>
/// Properties("SystemID")<br>
/// Properties("Username")<br>
/// Properties("UTCTimeStamp")<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Get(UTCTimeStamp As %String, SystemID As %String, AuditIndex As %Integer, ByRef Properties As %String) As %Status
{
 s $zt="Error"
 k Properties
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 i '..Exists(UTCTimeStamp,SystemID,AuditIndex,.Audit,.Status) q Status
 s Status=..GetProperties(Audit,.Properties)
 q Status
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Get audit database (directory) using $$$GetAuditDatabase or the name of the database
/// where we would audit to if it were turned on.  Code copied from ..Erase() for use by
/// shadowing.
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod GetAuditDatabase() As %String [ Internal ]
{
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 s AuditDatabase=$$$GetAuditDatabase
 #;If auditing is turned off, get the name of the database where we would audit to if it were on
 i AuditDatabase="" {
	s AuditDatabase=$p($g(^SYS("GREDIR","DSLOC","master",$p($zu(86),"*",2),"IRISAUDIT")),$c(1),1)
	i AuditDatabase="" s AuditDatabase=##Class(%File).SubDirectoryName($ZU(12),"irisaudit")
 }
 Quit AuditDatabase
}

/// Get the Audit properties.<br>
/// Parameters:<br>
/// Audit - Object handle to an audit record
/// Properties
/// Get the Audit properties.<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod GetProperties(Audit As %ObjectHandle, ByRef Properties As %String) As %Status [ Internal ]
{
 s $zt="Error"
 k Properties
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 s Properties("AuditIndex")=Audit.AuditIndex
 s Properties("Authentication")=Audit.Authentication
 s Properties("ClientExecutableName")=Audit.ClientExecutableName
 s Properties("ClientIPAddress")=Audit.ClientIPAddress
 s Properties("CSPSessionID")=Audit.CSPSessionID
 s Properties("Description")=Audit.Description
 s Properties("Event")=Audit.Event
 s Properties("EventData")=Audit.EventData
 s Properties("EventSource")=Audit.EventSource
 s Properties("EventType")=Audit.EventType
 s Properties("JobId")=Audit.JobId
 s Properties("Namespace")=Audit.Namespace
 s Properties("Pid")=Audit.Pid
 s Properties("Roles")=Audit.Roles
 s Properties("RoutineSpec")=Audit.RoutineSpec
 s Properties("StartupClientIPAddress")=Audit.StartupClientIPAddress
 s Properties("SystemID")=Audit.SystemID
 s Properties("Username")=Audit.Username
 s Properties("UTCTimeStamp")=Audit.UTCTimeStamp
 q $$$OK
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Import audit records from an xml file.<br>
/// Parameters:<br>
/// FileName - Valid filename to import audit records from<br>
/// NumImported (byref) - Returns number of records imported<br>
/// Flags - Control import<br>
/// Bit 0 - Do not import records, just return count<br>
/// Note: On failure, no records will be imported<br>
/// Audit records may not be imported into the %SYS namespace<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Import(FileName As %String, ByRef NumImported As %Integer, Flags As %Integer = 0) As %Status
{
 s $zt="Error"
 s NumImported=0
 s NumSkipped=0
 i $namespace="%SYS" q $$$ERROR($$$NoPctSysAuditImport,$namespace)
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary  ; verified 9/26/16 STC
 #; Create and initialize an %XML.Reader object
 i '$zb(Flags,1,1) {
 	TSTART
 	s TSTART=1
 }
 s reader=##class(%XML.Reader).%New()
#;If called from Security.System:ImportAll(), the filename will be in $list format
#;Piece 1 - Original file imported from, used in audit record
#;Piece 2 - Converted temp file imported from
#;$lb("c:\iris\mgr\export.xml","c:\iris\mgr\temp\udhiue")
 i $listvalid(FileName) {
	 s File=$li(FileName,2)
	 s FileName=$li(FileName,1)
 } else {
	 s File=FileName
 }
 s sc=reader.OpenFile(File)
 i $$$ISERR(sc) goto Rollback
 Do reader.Correlate("Audit","%SYS.Audit")
 While reader.Next(.audit,.sc) {
	i $$$ISERR(sc) q 
	i $zb(Flags,1,1) {
		s NumImported=NumImported+1
		Continue
	}
	#;The reader.Next() performed the import, obtaining the object Id into "audit".
    s tf=..Exists(audit.UTCTimeStamp,audit.SystemID,audit.AuditIndex,,.sc)
    i 'tf s sc=audit.%Save() i $$$ISERR(sc) q
    i tf {
	   #; set up properties and call Modify to update existing resource
	   s sc=..GetProperties(audit,.p)
	   i $$$ISERR(sc) q
	   s sc=..Modify(audit.UTCTimeStamp,audit.SystemID,audit.AuditIndex,.p)
	   k audit
       i $$$ISERR(sc) q
    }
    s NumImported=NumImported+1
 }
 i $$$ISERR(sc) goto Rollback 
 i $d(TSTART) {
	TCOMMIT
	k TSTART
 }
 i '$zb(Flags,1,1) {
 	s CRLF=$c(13)_$c(10),String="",Pad=$j("",20)
 	s String=String_$$$GetMsg($$$AuditMsg,"ImportAuditRecordsC")_CRLF
 	s String=String_$e($$$GetMsg($$$AuditMsg,"ImportFileC")_Pad,1,$l(Pad))_FileName_CRLF
 	s String=String_$e($$$GetMsg($$$AuditMsg,"TargetNamespaceC")_Pad,1,$l(Pad))_$namespace_CRLF
 	s String=String_$e($$$GetMsg($$$AuditMsg,"RecordsImportedC")_Pad,1,$l(Pad))_NumImported_CRLF
 	Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$$$GetMsg($$$AuditMsg,"ImportAuditData"))
 }
 s sc=$$$OK
Exit
 q sc
Rollback
 i $d(TSTART) {
	TROLLBACK 1
	k TSTART
 }
 s NumImported=0
 g Exit
Error s $zt=""
 s sc=$$$ERROR($$$ObjectScriptError,$ze)
 g Rollback
}

/// Modify an Audit record's properties.<br>
/// Modifies an Audit records properties from the security database.<br>
/// Parameters:<br>
/// UTCTimeStamp - UTC timestamp of the audit record<br>
/// SystemID - System ID of the audit event, usually NODE:CFGNAME<br>
/// AuditIndex - Index number of the audit record<br>
/// See the Get() method for a description of the Properties parameter.<br>
/// If a specific property is not passed in the properties array, 
/// the value is not modified.<br>
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Modify(UTCTimeStamp As %String, SystemID As %String, AuditIndex As %Integer, ByRef Properties As %String) As %Status
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 i '..Exists(UTCTimeStamp,SystemID,AuditIndex,.Audit,.Status) q Status
 i $d(Properties("AuditIndex")),(Properties("AuditIndex")'=Audit.AuditIndex) s Audit.AuditIndex=Properties("AuditIndex")
 i $d(Properties("Authentication")),(Properties("Authentication")'=Audit.Authentication) s Audit.Authentication=Properties("Authentication")
 i $d(Properties("ClientExecutableName")),(Properties("ClientExecutableName")'=Audit.ClientExecutableName) s Audit.ClientExecutableName=Properties("ClientExecutableName")
 i $d(Properties("ClientIPAddress")),(Properties("ClientIPAddress")'=Audit.ClientIPAddress) s Audit.ClientIPAddress=Properties("ClientIPAddress")
 i $d(Properties("CSPSessionID")),(Properties("CSPSessionID")'=Audit.CSPSessionID) s Audit.CSPSessionID=Properties("CSPSessionID")
 i $d(Properties("Description")),(Properties("Description")'=Audit.Description) s Audit.Description=Properties("Description")
 i $d(Properties("Event")),(Properties("Event")'=Audit.Event) s Audit.Event=Properties("Event")
 i $d(Properties("EventData")),(Properties("EventData")'=Audit.EventData) s Audit.EventData=Properties("EventData")
 i $d(Properties("EventSource")),(Properties("EventSource")'=Audit.EventSource) s Audit.EventSource=Properties("EventSource")
 i $d(Properties("EventType")),(Properties("EventType")'=Audit.EventType) s Audit.EventType=Properties("EventType")
 i $d(Properties("JobId")),(Properties("JobId")'=Audit.JobId) s Audit.JobId=Properties("JobId")
 i $d(Properties("Namespace")),(Properties("Namespace")'=Audit.Namespace) s Audit.Namespace=Properties("Namespace")
 i $d(Properties("Pid")),(Properties("Pid")'=Audit.Pid) s Audit.Pid=Properties("Pid")
 i $d(Properties("Roles")),(Properties("Roles")'=Audit.Roles) s Audit.Roles=Properties("Roles")
 i $d(Properties("RoutineSpec")),(Properties("RoutineSpec")'=Audit.RoutineSpec) s Audit.RoutineSpec=Properties("RoutineSpec")
 i $d(Properties("StartupClientIPAddress")),(Properties("StartupClientIPAddress")'=Audit.StartupClientIPAddress) s Audit.StartupClientIPAddress=Properties("StartupClientIPAddress")
 i $d(Properties("SystemID")),(Properties("SystemID")'=Audit.SystemID) s Audit.SystemID=Properties("SystemID")
 i $d(Properties("Username")),(Properties("Username")'=Audit.Username) s Audit.Username=Properties("Username")
 i $d(Properties("UTCTimeStamp")),(Properties("UTCTimeStamp")'=Audit.UTCTimeStamp) s Audit.UTCTimeStamp=Properties("UTCTimeStamp")
 $$$AddAllRoleTemporary  ; verified 10/31/18 STC
 s Status=Audit.%Save()
 q Status
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Stops auditing.<br>
/// Called when the system audit parameters change, and at shutdown.
/// Do not call directly to stop auditing.
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod Stop() As %Status [ Internal ]
{
 s $zt="Error"
#;When $SYSTEM.Security.Audit gets called to write an audit record, the first thing the method
#;does is check to see if auditing is enabled. If not, the method exits with a status 
#;of 0 (event not audited.)
#;
#;The method then checks if the audit write error count is 0. If it is 0, then it tries to
#;write the audit record to the audit database. If the write fails (e.g. FILEFULL), the
#;audit write error count is incremented by one, and the FILEFULL error is generated.
#;
#;If the audit write error count is not 0 (there were previous FILEFULL errors by other
#;processes) the process will first try to write an audit record with the following information
#;  $SYSTEM.Security.Audit($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,"","Audit error: 35 events not logged")
#;If the write is not successfull, the error count is incremented by one, and the FILEFULL
#;error is generated.
#;If the write is successfull (i.e. some action was taken to increase the size of the audit file),
#;the audit write error count is zeroed, and the real audit record is written out.
#;
#;In the case here, where auditing is being stopped, if we get a filefull, we write this
#;info into the audit header. When auditing is started back up again, the audit header is read,
#;the audit record is regenerated, then the audit header is cleared.
#;
#;#;We need %Admin Secure:U privilege to do anything with auditing
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 d ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,$$$FormatMsg($$$AuditMsg,"AuditingStoppedTo",..GetAuditDatabase()),$$$GetMsg($$$AuditMsg,"AuditingStopped"))
 s Status=$$$StopAuditing
 i 'Status q $$$ERROR($$$AuditNotStopped,..GetAuditDatabase())
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Start/Stop/Switch the Audit file based on the contents of the audit configuration.<br>
/// Called only when the audit parameters are changed in the Security.System class.
/// Requires %Admin_Secure:"Use" privilege.<br>
ClassMethod UpdateAuditFile() As %Status [ Internal ]
{
 s $zt="Error"
#;We need %Admin Secure:U privilege to do anything with auditing
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 s System=##Class(Security.System).%OpenId($$$SystemSecurityName,,.Status)
 i '$$$ISOK(Status) q Status
#;See if we are currently auditing. If the Audit database is "" we are not.
 s OldAuditDatabase=$$$GetAuditDatabase
 i 'System.AuditEnabled {
#;If we were auditing, the system flag turning off auditing got set. So stop it.
	i OldAuditDatabase'="" {
		s Status=..Stop()
		i '$$$ISOK(Status) q Status
 	} else {
		d ##Class(%SYS.System).WriteToConsoleLog("Auditing is disabled")
	}
	q $$$OK
 }
#;If here we are either starting auditing, or switching the audit database.
#;Get the system defined audit database. If for some reason it is "",
#;then put it in the mgr\irisaudit directory
 s AuditDatabase=$p($g(^SYS("GREDIR","DSLOC","master",$p($zu(86),"*",2),"IRISAUDIT")),$c(1),1)
 i AuditDatabase="" s AuditDatabase=##Class(%File).SubDirectoryName($ZU(12),"irisaudit")
#;We shouldn't be called if what we switch to is the same as what currently is
 i AuditDatabase=OldAuditDatabase q $$$OK
#;Make sure we set the max size of the audit database to 0. The only way to recover
#;from a cache audit db getting a filefull error is to delete it.
 s AuditDB=##Class(SYS.Database).%OpenId(AuditDatabase)
 i $isobject(AuditDB) {
	 if AuditDB.MaxSize'=0 {
	 	 s AuditDB.MaxSize=0
		 s Status=AuditDB.%Save()
	 }
	 k AuditDB
 }
 i OldAuditDatabase'="" {
#;If here, we are going to switch to a new audit database. Apply any
#;audit header, then audit the switch in the old database
	s String=$$$FormatMsg($$$AuditMsg,"AuditDatabaseSwitchedTo",AuditDatabase)
	s String=String_$c(13,10)_$$$FormatMsg($$$AuditMsg,"AuditDatabaseSwitchedFrom",OldAuditDatabase)
	d ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$$$GetMsg($$$AuditMsg,"AuditDatabaseSwitched"))
#;Switch it
 	s Status=$$$SwitchAuditDatabase(AuditDatabase)
	i 'Status {
 		d ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,"",$$$FormatMsg($$$AuditMsg,"AuditDatabaseNotSwitched"))
		q $$$ERROR($$$AuditDatabaseNotAvailable,AuditDatabase)
 	}
 } else {
#;If here we are going to start auditing
 	s Status=$$$StartAuditing(AuditDatabase)
 	i 'Status {
	 	d ##Class(%SYS.System).WriteToConsoleLog("Unable to start auditing to "_AuditDatabase)
 		q $$$ERROR($$$AuditUnableToStart,AuditDatabase)
 	}
	d $$$SetAuditFlags(System.AuditFlags)
 }
 s Status=..CreateGlobals(AuditDatabase)
#;Now that we switched or started, we need to see if there was a leftover 
#;header to write in the new audit database (which could have been previously used.) 
#;This will also create the header if one doesn't exist
 i OldAuditDatabase'="" {
	s String=$$$FormatMsg($$$AuditMsg,"AuditDatabaseSwitchedFrom",OldAuditDatabase)
	s String=String_$c(13,10)_$$$FormatMsg($$$AuditMsg,"AuditDatabaseSwitchedTo",AuditDatabase)
 	d ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,String,$$$GetMsg($$$AuditMsg,"AuditDatabaseSwitched"))
 } else {
	d $$$Initialize
	d ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditChange,$$$FormatMsg($$$AuditMsg,"AuditingStartedTo",AuditDatabase),$$$GetMsg($$$AuditMsg,"AuditingStarted"))
 }
#;Make sure the audit file is in the correct format.
 i $d(^SYS("FirstRestartSinceInstall")) j ##Class(%SYS.Audit).Convert()::4
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Write a record to the audit file.<br>
/// Used internally by the Config.* and Security.* methods.
ClassMethod WriteToAuditFile(Source As %String, Type As %String, Name As %String, EventData As %String, Description As %String, Force As %Integer = 0) As %Boolean [ Internal ]
{
#;This function is only used internally by the audit, Config, and security system.
#;This function will write an event to the audit file. It writes directly to the Audit log
#;instead of using $SYSTEM.Security.Audit to perform the write. The method works exactly like 
#; $SYSTEM.Security.Audit except that if an error occurs during the set,
#;(e.g. FILEFULL),then the event is written to the Audit header so it can be updated into the 
#;audit file at a later point in time. 
#;The audit header is a fixed size of $$$AuditHeaderSize (3641145-2000) bytes. It is created when the audit file
#;is initialized for the first time. It is primarily used to hold audit records which could
#;not be written to the file (e.g. filefull) while auditing was being stopped, 
#;started, or switched, or other security information was being changed. 
#;The header is a list of lists, each $list string is an audit record. The internal format is as follows:
#;
#;List 1 - Contents of audit record 1
#;List 2 - Contents of audit record 2
#;...
#;Last element - padding required to pad to $$$AuditHeaderSize (3641145-2000)
#;
#;Note that we could conceivably fail to write the audit record if the number of audit
#;records in the header grows beyond the capacity of the header.
#;The method either return 0 - Audit record not written, or 1 - Audit record written.
#;If Force=1, then the audit record will be written even if auditing is off or the audit
#;event is not enabled.
 s $zt="Error"
 s CurrentRoles=$roles
 $$$AddAllRoleTemporary  ; verified 9/26/16 STC
#;See if auditing is on for the system, and for the event itself. If not, just return 0 (not written).
#;Increment the total in any case.
 $$$IncAuditTotalCount(Source_"/"_Type_"/"_Name)
 i Force=0 {
 	q:'$$$AuditingIsOn 0
 	i '$$$EventAuditIsOn(Source,Type,Name) q 0
 }
#;Turn off transactions for this Audit record
 s InTransaction=$zu(139,2)
#;If we are forcing an audit, then write directly to the global.
 i '$$$AuditingIsOn {
 	s AuditDatabase=$p($g(^SYS("GREDIR","DSLOC","master",$p($zu(86),"*",2),"IRISAUDIT")),$c(1),1)
 	i AuditDatabase="" s AuditDatabase=##Class(%File).SubDirectoryName($ZU(12),"irisaudit")
	s AuditIndex=$increment(^|"^^"_AuditDatabase|IRIS.AuditD)
 } else {
 	s AuditIndex=$increment($$$AuditGbl)
 }	 
 s AuditRecord=""
 s TimeStamp=$zdatetime($ztimestamp,3,,3)
 s SystemID=$zu(110)_":"_$p($zu(86),"*",2)	;SystemID
#;Stuff which calls this entry point are system routines we provide. We really don't need (or even want)
#;to report the actual location of the audit. If in the future we want to report it, we can undef this.
#if 0
 s CallDB=$zu(96,27)
 s Routine=$p($stack($stack-1,"PLACE")," ")_" |"""_"^"_$li(CallDB,3)_"^"_$li(CallDB,2)_""""_"|"
#else
 s Routine=""
#endif
 s AuditRecord=$lb(
 		AuditIndex,		;AuditIndex
		$zu(67,13,$j),	;ClientExecutableName
		$zu(67,15,$j),	;Client IP Address
		Description,	;Description
		Name,			;Event
		EventData,		;EventData
		Source,			;EventSource
		Type,			;EventType
		$namespace,		;Namespace
		$p($j,":"),		;Pid (make sure we take off the nodename if 3652:NODE)
		CurrentRoles,	;$Roles
		Routine,		;RoutineSpec
		SystemID,		;SystemID
		$username,		;Username
		TimeStamp,		;UTCTimeStamp
		$zu(67,14,$j), 	;CSP Session ID
		$zu(67,20,$j), 	;User Info
		+$zu(61,30,$zu(61)), ;JobId
		"",				;Group (Not used)
		1,				;Status
		$zu(67,11,$j),	;O/S username
		$System.Security.Users.GetSecurityLevel(),  ; Authentication level
		$zu(67,24,$j)	;Startup Client IP Address
		)
 i '$$$AuditingIsOn {
	s ^|"^^"_AuditDatabase|IRIS.AuditD(TimeStamp,SystemID,AuditIndex)=AuditRecord
 } else {
	s $$$AuditGbl(TimeStamp,SystemID,AuditIndex)=AuditRecord
 }
 d $zu(139,InTransaction)
 k InTransaction
 $$$IncAuditWrittenCount(Source_"/"_Type_"/"_Name)
#;make sure the journal buffer is set to disk.
 d $$$JRNFLUSHBUF
#;Since we had a successfull write, see if we need to apply a header
 d ..ApplyAuditHeader()
 q 1
Error s $zt="Error1"
#;If here, we got some sort of error writing to the audit file above (e.g. FILEFULL)
 i $d(InTransaction) d $zu(139,InTransaction)
 k InTransaction
 l +$$$AuditHeader
#;Get the current header
 s Header=$g($$$AuditHeader,$lb(""))
#;Peel off the padding
 s Header=$li(Header,1,$ll(Header)-1)
#;Now add in the entire audit record. Note that if the format changes, we need to change
#;this also. Audit records are just concatenated with each other, 15 fields to a record
#;SAP240+
#;Turn off transactions for this audit record.
 s InTransaction=$zu(139,2)
 i $g(AuditRecord)="" {
 	s TimeStamp=$zdatetime($ztimestamp,3,,3)
 	s SystemID=$zu(110)_":"_$p($zu(86),"*",2)
 	s AuditIndex=$increment($$$AuditGbl)
 	s AuditRecord = $lb(
 	AuditIndex,		;AuditIndex
 	$zu(67,13,$j),	;ClientExecutableName
 	$zu(67,15,$j),	;Client IP Address
 	Description,	;Description
 	Name,			;Event
 	EventData,		;EventData
 	Source,			;EventSource
 	Type,			;EventType
 	$namespace,		;Namespace
 	$p($j,":"),		;Pid (make sure we take off the nodename if 3652:NODE)
 	CurrentRoles,	;$Roles
 	"",				;RoutineSpec - Can't get this now
 	SystemID,		;SystemID
 	$username,		;Username
 	TimeStamp,		;UTCTimeStamp
 	$zu(67,14,$j), 	;CSP Session ID
 	$zu(67,20,$j), 	;User Info
 	+$zu(61,30,$zu(61)), ;JobId
 	"",				;Group
 	1,				;Status
 	$zu(67,11,$j),	;O/S Username
	$System.Security.Users.GetSecurityLevel(),  ; Authentication level
 	$zu(67,24,$j)	;Startup IP Address
	)	
 }
#;Insert into the Header
 s $li(Header,$ll(Header)+1) = AuditRecord
#;SAP240-
#;Pad it back out
 f i=($$$AuditHeaderSize-$l(Header)):-1:1 q:$l(Header_$lb($j("",i)))<=$$$AuditHeaderSize
 s $$$AuditHeader=Header_$lb($j("",i))
#;Remove the lock immediately
 l -$$$AuditHeader#"I"
 d $zu(139,InTransaction)
 k InTransaction
#;make sure the journal buffer is set to disk.
 d $$$JRNFLUSHBUF
 q 1
Error1 s $zt="Error2"
 i $d(InTransaction) d $zu(139,InTransaction)
 $$$IncAuditFailuresCount(Source_"/"_Type_"/"_Name)
 Try {
	 $$$WarnMsg("Failed to Audit: "_$listToString(AuditRecord))
 } catch {}
 l -$$$AuditHeader#"I"
 Quit 0
Error2 s $zt=""
 Quit 0
}

/// List all audit records, brief display, reverse order. <br>
/// Parameters:
/// BeginDateTime - $zdatetime($H,3) value of the first audit record, "" = first record<br>
/// EndDateTime - $zdatetime($H,3) value of the last audit record, "" = Last record<br>
/// The following parameters may be specified as a comma separated list as follows:<br>
/// "*" - All records match<br>
/// "String,String1" - Any records matching one of these elements<br>
/// "String*" - Any record starting with "String"<br>
/// "String,String1*,String2" - Any record matching one of these elements, or starting with "String1"<br>
/// Note that these are all case insensitive matches<br>
/// EventSources - Comma separated list of valid event sources<br>
/// EventTypes - Comma separated list of valid event types<br>
/// Events - Comma separated list of event names<br>
/// Usernames - Comma separated list of user names<br>
/// SystemIDs - Comma separated list of System:Config names<br> 
/// Pids - Comma separated list of Pids,VMS systems passed in Hex<br>
/// Groups - Comma separated list of Groups (currently unused)<br>
/// Authentication - Comma separated list of authentication types<br>
/// Flags - 0=Descending (most recent first) 1=Ascending (earliest first)<br>
/// JSONSearch - String to search for in the JSON Data field
/// Requires %Admin_Secure:"Use" privilege.<br>
Query List(BeginDateTime As %String, EndDateTime As %String, EventSources As %String, EventTypes As %String, Events As %String, Usernames As %String, SystemIDs As %String, Pids As %String, Groups As %String, Authentications As Security.Datatype.Authentication, Flags As %Integer, JSONSearch As %String) As %Query(ROWSPEC = "SystemID:%String,AuditIndex:%String,TimeStamp:%String,EventSource:%String,EventType:%String,Event:%String,Pid:%String,SessionID:%String,Username:%String,Description:%String,UTCTimeStamp:%String,Group:%String,JobNumber:%String,Authentication:%String,ClientExecutableName:%String,ClientIPAddress:%String,EventData:%String,Namespace:%String,Roles:%String,RoutineSpec:%String,UserInfo:%String,JobId:%String,Status:%String,OSUsername:%String,StartupClientIPAddress:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef %qHandle As %Binary, BeginDateTime As %String = "", EndDateTime As %String = "", EventSources As %String = "*", EventTypes As %String = "*", Events As %String = "*", Usernames As %String = "*", SystemIDs As %String = "*", Pids As %String = "*", Groups As %String = "*", Authentications As Security.Datatype.Authentication = "*", Flags As %Integer = 0, JSONSearch As %String = "") As %Status [ Internal ]
{
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
#;Make sure the audit database is in the right format
 s Status=..Convert()
 i '$$$ISOK(Status) q Status
 d ..ApplyAuditHeader()
#; Don't audit if the flag was passed in. if we request to not audit, make sure we have %All
 i '($d(%NoAuditList)&&($roles[$$$pAllRoleName)) {
	s CRLF=$c(13)_$c(10),String="",Pad=$j("",20)
	s String=String_$e($$$GetMsg($$$AuditMsg,"QueryNameC")_Pad,1,$l(Pad))_"List"_CRLF
 	s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 	i BeginDateTime="" {
 		s Node=$q(^$$$AuditDataName(""))
 		i Node="" {
			s BDateTime=$zdatetime($h,3)
		} else {
 			s BDateTime=..ConvertUTCToLocal($li(@Node,15))
		}
		s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 	} else {
		s String=String_BeginDateTime
	}
 	s String=String_CRLF
 	s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 	i EndDateTime="" {
		s Node=$q(^$$$AuditDataName(""),-1)
		i Node="" {
			s EDateTime=$zdateTime($h,3)
		} else {
			s EDateTime=..ConvertUTCToLocal($li(@Node,15))
		}
		s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 	} else {
		s String=String_EndDateTime
 	}
 	s String=String_CRLF
	s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
	s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
	s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
	s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
	s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
	s String=String_$e($$$GetMsg($$$AuditMsg,"PidsC")_Pad,1,$l(Pad))_Pids_CRLF
	s String=String_$e($$$GetMsg($$$AuditMsg,"GroupsC")_Pad,1,$l(Pad))_Groups_CRLF
	s String=String_$e($$$GetMsg($$$AuditMsg,"AuthenticationC")_Pad,1,$l(Pad))_Authentications_CRLF
	Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditReport,String,$$$GetMsg($$$AuditMsg,"ListQuery"))
 }
 i EndDateTime="" {
	s UTCEndDateTime=..ConvertLocalHToUTC($p($H,",",1)_","_$p($h,",",2)_".999")
 } else {
	s UTCEndDateTime=$zdatetimeh(EndDateTime,$s(EndDateTime["-":3,1:-1),,,6)
	i $p(UTCEndDateTime,",",2)=0 s UTCEndDateTime=(+UTCEndDateTime-1)_","_86399.999
	s UTCEndDateTime=..ConvertLocalHToUTC(UTCEndDateTime)
 }
 i BeginDateTime="" {
#;47117 is earliest UTC date allowed. To prevent an Illegal value error
#;for GMT+x time zones, we set it to 47118
	s UTCBeginDateTime=..ConvertLocalHToUTC("47118,0")
 } else {
	s UTCBeginDateTime=$zdatetimeh(BeginDateTime,$s(BeginDateTime["-":3,1:-1),,,6)
	s UTCBeginDateTime=..ConvertLocalHToUTC(UTCBeginDateTime)
 }
 i Authentications'="*" {
	 s InternalAuthentications=$$AuthenticationDisplayToLogical^%SYS.SECURITY(Authentications)
 } else {
	 s InternalAuthentications=Authentications
 }
 s %qHandle("Flags")=Flags
 #EXECUTE s %msqlvar="%qHandle" 
 i Flags=0 {
	&SQL(DECLARE ListCursor CURSOR for 
	SELECT SystemID,AuditIndex,UTCTimeStamp,EventSource,EventType,Event,Pid,CSPSessionID,Username,
	Description,GroupName,JobNumber,Authentication,ClientExecutableName,ClientIPAddress,EventData,
	Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress
	FROM Audit
	WHERE UTCTimeStamp BETWEEN :UTCBeginDateTime AND :UTCEndDateTime
		AND (%SYSTEM.Util_CheckName(:Usernames,Username)=1)
		AND	(%SYSTEM.Util_CheckName(:Events,Event)=1)
		AND	(%SYSTEM.Util_CheckName(:EventTypes,EventType)=1)
		AND (%SYSTEM.Util_CheckName(:EventSources,EventSource)=1)
		AND	(%SYSTEM.Util_CheckName(:SystemIDs,SystemID)=1)
		AND	(%SYSTEM.Util_CheckName(:Pids,Pid)=1)
		AND	(%SYSTEM.Util_CheckName(:Groups,GroupName)=1)
 		AND (%SYS.Audit_CheckAuthentication(:InternalAuthentications,Authentication)=1)
		AND (%SYSTEM.Util_CheckAuditJSONString(:JSONSearch,EventData)=1)
	ORDER BY UTCTimeStamp DESC, SystemID DESC, AuditIndex DESC)
 } else {
 	&SQL(DECLARE ListCursorR CURSOR for 
	SELECT SystemID,AuditIndex,UTCTimeStamp,EventSource,EventType,Event,Pid,CSPSessionID,Username,
	Description,GroupName,JobNumber,Authentication,ClientExecutableName,ClientIPAddress,EventData,
	Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress
	FROM Audit
	WHERE UTCTimeStamp BETWEEN :UTCBeginDateTime AND :UTCEndDateTime
		AND (%SYSTEM.Util_CheckName(:Usernames,Username)=1)
		AND	(%SYSTEM.Util_CheckName(:Events,Event)=1)
		AND	(%SYSTEM.Util_CheckName(:EventTypes,EventType)=1)
		AND (%SYSTEM.Util_CheckName(:EventSources,EventSource)=1)
		AND	(%SYSTEM.Util_CheckName(:SystemIDs,SystemID)=1)
		AND	(%SYSTEM.Util_CheckName(:Pids,Pid)=1)
		AND	(%SYSTEM.Util_CheckName(:Groups,GroupName)=1)
 		AND (%SYS.Audit_CheckAuthentication(:InternalAuthentications,Authentication)=1)
		AND (%SYSTEM.Util_CheckAuditJSONString(:JSONSearch,EventData)=1)
	ORDER BY UTCTimeStamp ASC, SystemID ASC, AuditIndex ASC)
 }
 #EXECUTE k %msqlvar
 i Flags=0 {
 	&SQL(OPEN ListCursor)
 } else {
 	&SQL(OPEN ListCursorR)
 }
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

ClassMethod ListFetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListExecute ]
{
 s Flags=%qHandle("Flags")
 i Flags=0 {
 &SQL(FETCH ListCursor
	INTO :SystemID,:AuditIndex,:UTCTimeStamp,:EventSource,:EventType,:Event,:Pid,:CSPSessionID,
	:Username,:Description,:GroupName,:JobNumber,:Authentication,:ClientExecutableName,:ClientIPAddress,
	:EventData,:Namespace,:Roles,:RoutineSpec,:UserInfo,:JobId,:Status,:OSUsername,:StartupClientIPAddress)
 } else {
 &SQL(FETCH ListCursorR
	INTO :SystemID,:AuditIndex,:UTCTimeStamp,:EventSource,:EventType,:Event,:Pid,:CSPSessionID,
	:Username,:Description,:GroupName,:JobNumber,:Authentication,:ClientExecutableName,:ClientIPAddress,
	:EventData,:Namespace,:Roles,:RoutineSpec,:UserInfo,:JobId,:Status,:OSUsername,:StartupClientIPAddress)
 }
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 If SQLCODE=100 {
	Set Row="",AtEnd=1
 } Else {
	Set Row=$LB(SystemID,AuditIndex,..ConvertUTCToLocal(UTCTimeStamp),EventSource,EventType,Event,Pid,
	CSPSessionID,Username,..DescriptionLogicalToDisplay(Description),UTCTimeStamp,GroupName,JobNumber,
	$$AuthenticationLogicalToDisplay^%SYS.SECURITY(Authentication),ClientExecutableName,ClientIPAddress,
	EventData,Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress)
	Set AtEnd=0
 }
 Quit $$$OK
}

ClassMethod ListClose(ByRef %qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListExecute ]
{
 s Flags=%qHandle("Flags")
 i Flags=0 {
	 &SQL(CLOSE ListCursor)
 } else {
	 &SQL(CLOSE ListCursorR)
 }
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

/// List audit records ordered by Username.  
/// Parameters:
/// BeginDateTime - $zdatetime($H,3) value of the first audit record, "" = first record<br>
/// EndDateTime - $zdatetime($H,3) value of the Last audit record, "" = Last record<br>
/// The following parameters may be specified as a comma separated list as follows:<br>
/// "*" - All records match<br>
/// "String,String1" - Any records matching one of these elements<br>
/// "String*" - Any record starting with "String"<br>
/// "String,String1*,String2" - Any record matching one of these elements, or starting with "String1"<br>
/// Note that these are all case insensitive matches<br>
/// EventSources - Comma separated list of valid event sources<br>
/// EventTypes - Comma separated list of valid event types<br>
/// Events - Comma separated list of event names<br>
/// Usernames - Comma separated list of user names<br>
/// SystemIDs - Comma separated list of System:Config names<br> 
/// Requires %Admin_Secure:"Use" privilege.<br>
Query ListByUser(BeginDateTime As %String, EndDateTime As %String, EventSources As %String, EventTypes As %String, Events As %String, Usernames As %String, SystemIDs As %String, Pids As %String, Groups As %String, Authentications As Security.Datatype.Authentication) As %Query(ROWSPEC = "SystemID:%String,AuditIndex:%String,TimeStamp:%String,EventSource:%String,EventType:%String,Event:%String,Pid:%String,SessionID:%String,Username:%String,Description:%String,UTCTimeStamp:%String,Group:%String,JobNumber:%String,Authentication:%String,ClientExecutableName:%String,ClientIPAddress:%String,EventData:%String,Namespace:%String,Roles:%String,RoutineSpec:%String,UserInfo:%String,JobId:%String,Status:%String,OSUsername:%String,StartupClientIPAddress:%String") [ SqlProc ]
{
}

ClassMethod ListByUserExecute(ByRef %qHandle As %Binary, BeginDateTime As %String = "", EndDateTime As %String = "", EventSources As %String = "*", EventTypes As %String = "*", Events As %String = "*", Usernames As %String = "*", SystemIDs As %String = "*", Pids As %String = "*", Groups As %String = "*", Authentications As Security.Datatype.Authentication = "*") As %Status [ Internal ]
{
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
#;Make sure the audit database is in the right format
 s Status=..Convert()
 i '$$$ISOK(Status) q Status
 d ..ApplyAuditHeader()
 s CRLF=$c(13)_$c(10),String="",Pad=$j("",20)
 s String=String_$e($$$GetMsg($$$AuditMsg,"QueryNameC")_Pad,1,$l(Pad))_"ListByUser"_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
 	s Node=$q(^$$$AuditDataName(""))
 	i Node="" {
		s BDateTime=$zdatetime($h,3)
	} else {
 		s BDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s Node=$q(^$$$AuditDataName(""),-1)
	i Node="" {
		s EDateTime=$zdatetime($h,3)
	} else {
		s EDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"PidsC")_Pad,1,$l(Pad))_Pids_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"GroupsC")_Pad,1,$l(Pad))_Pids_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"AuthenticationC")_Pad,1,$l(Pad))_Authentications_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditReport,String,$$$GetMsg($$$AuditMsg,"ListByUserQuery"))
 i EndDateTime="" {
	s UTCEndDateTime=..ConvertLocalHToUTC($p($H,",",1)_","_$p($h,",",2)_".999")
 } else {
	s UTCEndDateTime=$zdatetimeh(EndDateTime,$s(EndDateTime["-":3,1:-1),,,6)
	i $p(UTCEndDateTime,",",2)=0 s UTCEndDateTime=(+UTCEndDateTime-1)_","_86399.999
	s UTCEndDateTime=..ConvertLocalHToUTC(UTCEndDateTime)
 }
 i BeginDateTime="" {
	s UTCBeginDateTime=..ConvertLocalHToUTC("47118,0")
 } else {
	s UTCBeginDateTime=$zdatetimeh(BeginDateTime,$s(BeginDateTime["-":3,1:-1),,,6)
	s UTCBeginDateTime=..ConvertLocalHToUTC(UTCBeginDateTime)
 }
 i Authentications'="*" {
	 s InternalAuthentications=$$AuthenticationDisplayToLogical^%SYS.SECURITY(Authentications)
 } else {
	 s InternalAuthentications=Authentications
 }
 #EXECUTE s %msqlvar="%qHandle" 
 &SQL(DECLARE ListByUserCursor CURSOR for 
	SELECT SystemID,AuditIndex,UTCTimeStamp,EventSource,EventType,Event,Pid,CSPSessionID,Username,
	Description,GroupName,JobNumber,Authentication,ClientExecutableName,ClientIPAddress,EventData,
	Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress
	FROM Audit
	WHERE UTCTimeStamp BETWEEN :UTCBeginDateTime AND :UTCEndDateTime
		AND (%SYSTEM.Util_CheckName(:Usernames,Username)=1)
		AND	(%SYSTEM.Util_CheckName(:Events,Event)=1)
		AND	(%SYSTEM.Util_CheckName(:EventTypes,EventType)=1)
		AND (%SYSTEM.Util_CheckName(:EventSources,EventSource)=1)
		AND	(%SYSTEM.Util_CheckName(:SystemIDs,SystemID)=1)
		AND	(%SYSTEM.Util_CheckName(:Pids,Pid)=1)
		AND	(%SYSTEM.Util_CheckName(:Groups,GroupName)=1)
 		AND (%SYS.Audit_CheckAuthentication(:InternalAuthentications,Authentication)=1)
	ORDER BY Username DESC,UTCTimeStamp DESC, AuditIndex DESC)
 #EXECUTE k %msqlvar
 &SQL(OPEN ListByUserCursor)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

ClassMethod CheckAuthentication(Select, Data) As %Boolean [ Internal, SqlProc ]
{
 q:(Select="*") 1  i $zb(+Select,+Data,1) {q 1} else {q 0}
}

ClassMethod ListByUserFetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListByUserExecute ]
{
 &SQL(FETCH ListByUserCursor
	INTO :SystemID,:AuditIndex,:UTCTimeStamp,:EventSource,:EventType,:Event,:Pid,:CSPSessionID,
	:Username,:Description,:GroupName,:JobNumber,:Authentication,:ClientExecutableName,:ClientIPAddress,
	:EventData,:Namespace,:Roles,:RoutineSpec,:UserInfo,:JobId,:Status,:OSUsername,:StartupClientIPAddress)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 If SQLCODE=100 {
	Set Row="",AtEnd=1
 } Else {
	Set Row=$LB(SystemID,AuditIndex,..ConvertUTCToLocal(UTCTimeStamp),EventSource,EventType,Event,Pid,
	CSPSessionID,Username,..DescriptionLogicalToDisplay(Description),UTCTimeStamp,GroupName,JobNumber,
	$$AuthenticationLogicalToDisplay^%SYS.SECURITY(Authentication),ClientExecutableName,ClientIPAddress,
	EventData,Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress)
	Set AtEnd=0
 }
 Quit $$$OK
}

ClassMethod ListByUserClose(ByRef %qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListByUserExecute ]
{
 &SQL(CLOSE ListByUserCursor)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

/// List audit records ordered by Event Source, Event Type, and Event.<br>
/// Parameters:<br>
/// BeginDateTime - $zdatetime($H,3) value of the first audit record, "" = first record<br>
/// EndDateTime - $zdatetime($H,3) value of the Last audit record, "" = Last record<br>
/// The following parameters may be specified as a comma separated list as follows:<br>
/// "*" - All records match<br>
/// "String,String1" - Any records matching one of these elements<br>
/// "String*" - Any record starting with "String"<br>
/// "String,String1*,String2" - Any record matching one of these elements, or starting with "String1"<br>
/// Note that these are all case insensitive matches<br>
/// EventSources - Comma separated list of valid event sources<br>
/// EventTypes - Comma separated list of valid event types<br>
/// Events - Comma separated list of event names<br>
/// Usernames - Comma separated list of user names<br>
/// SystemIDs - Comma separated list of System:Config names<br> 
/// Requires %Admin_Secure:"Use" privilege.<br>
Query ListByEvent(BeginDateTime As %String, EndDateTime As %String, EventSources As %String, EventTypes As %String, Events As %String, Usernames As %String, SystemIDs As %String, Pids As %String, Groups As %String, Authentications As Security.Datatype.Authentication) As %Query(ROWSPEC = "SystemID:%String,AuditIndex:%String,TimeStamp:%String,EventSource:%String,EventType:%String,Event:%String,Pid:%String,SessionID:%String,Username:%String,Description:%String,UTCTimeStamp:%String,Group:%String,JobNumber:%String,Authentication:%String,ClientExecutableName:%String,ClientIPAddress:%String,EventData:%String,Namespace:%String,Roles:%String,RoutineSpec:%String,UserInfo:%String,JobId:%String,Status:%String,OSUsername:%String,StartupClientIPAddress:%String") [ SqlProc ]
{
}

ClassMethod ListByEventExecute(ByRef %qHandle As %Binary, BeginDateTime As %String = "", EndDateTime As %String = "", EventSources As %String = "*", EventTypes As %String = "*", Events As %String = "*", Usernames As %String = "*", SystemIDs As %String = "*", Pids As %String = "*", Groups As %String = "*", Authentications As Security.Datatype.Authentication = "*") As %Status [ Internal ]
{
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
#;Make sure the audit database is in the right format
 s Status=..Convert()
 i '$$$ISOK(Status) q Status
 d ..ApplyAuditHeader()
 s CRLF=$c(13)_$c(10),String="",Pad=$j("",20)
 s String=String_$e($$$GetMsg($$$AuditMsg,"QueryNameC")_Pad,1,$l(Pad))_"ListByEvent"_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
 	s Node=$q(^$$$AuditDataName(""))
 	i Node="" {
		s BDateTime=$zdatetime($h,3)
	} else {
 		s BDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s Node=$q(^$$$AuditDataName(""),-1)
	i Node="" {
		s EDateTime=$zdatetime($h,3)
	} else {
		s EDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"PidsC")_Pad,1,$l(Pad))_Pids_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"GroupsC")_Pad,1,$l(Pad))_Groups_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"AuthenticationC")_Pad,1,$l(Pad))_Authentications_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditReport,String,$$$GetMsg($$$AuditMsg,"ListByEventQuery"))
 i EndDateTime="" {
	s UTCEndDateTime=..ConvertLocalHToUTC($p($H,",",1)_","_$p($h,",",2)_".999")
 } else {
	s UTCEndDateTime=$zdatetimeh(EndDateTime,$s(EndDateTime["-":3,1:-1),,,6)
	i $p(UTCEndDateTime,",",2)=0 s UTCEndDateTime=(+UTCEndDateTime-1)_","_86399.999
	s UTCEndDateTime=..ConvertLocalHToUTC(UTCEndDateTime)
 }
 i BeginDateTime="" {
	s UTCBeginDateTime=..ConvertLocalHToUTC("47118,0")
 } else {
	s UTCBeginDateTime=$zdatetimeh(BeginDateTime,$s(BeginDateTime["-":3,1:-1),,,6)
	s UTCBeginDateTime=..ConvertLocalHToUTC(UTCBeginDateTime)
 }
 i Authentications'="*" {
	 s InternalAuthentications=$$AuthenticationDisplayToLogical^%SYS.SECURITY(Authentications)
 } else {
	 s InternalAuthentications=Authentications
 }
 #EXECUTE s %msqlvar="%qHandle" 
 &SQL(DECLARE ListByEventCursor CURSOR for 
	SELECT SystemID,AuditIndex,UTCTimeStamp,EventSource,EventType,Event,Pid,CSPSessionID,Username,
	Description,GroupName,JobNumber,Authentication,ClientExecutableName,ClientIPAddress,EventData,
	Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress
	FROM Audit
	WHERE UTCTimeStamp BETWEEN :UTCBeginDateTime AND :UTCEndDateTime
		AND (%SYSTEM.Util_CheckName(:Usernames,Username)=1)
		AND	(%SYSTEM.Util_CheckName(:Events,Event)=1)
		AND	(%SYSTEM.Util_CheckName(:EventTypes,EventType)=1)
		AND (%SYSTEM.Util_CheckName(:EventSources,EventSource)=1)
		AND	(%SYSTEM.Util_CheckName(:SystemIDs,SystemID)=1)
		AND	(%SYSTEM.Util_CheckName(:Pids,Pid)=1)
		AND	(%SYSTEM.Util_CheckName(:Groups,GroupName)=1)
 		AND (%SYS.Audit_CheckAuthentication(:InternalAuthentications,Authentication)=1)
	ORDER BY EventSource,EventType,Event DESC, UTCTimeStamp DESC, AuditIndex DESC)
 #EXECUTE k %msqlvar
 &SQL(OPEN ListByEventCursor)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

ClassMethod ListByEventFetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListByEventExecute ]
{
 &SQL(FETCH ListByEventCursor
	INTO :SystemID,:AuditIndex,:UTCTimeStamp,:EventSource,:EventType,:Event,:Pid,:CSPSessionID,
	:Username,:Description,:GroupName,:JobNumber,:Authentication,:ClientExecutableName,:ClientIPAddress,
	:EventData,:Namespace,:Roles,:RoutineSpec,:UserInfo,:JobId,:Status,:OSUsername,:StartupClientIPAddress)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 If SQLCODE=100 {
	Set Row="",AtEnd=1
 } Else {
	Set Row=$LB(SystemID,AuditIndex,..ConvertUTCToLocal(UTCTimeStamp),EventSource,EventType,Event,Pid,
	CSPSessionID,Username,..DescriptionLogicalToDisplay(Description),UTCTimeStamp,GroupName,JobNumber,
	$$AuthenticationLogicalToDisplay^%SYS.SECURITY(Authentication),ClientExecutableName,ClientIPAddress,
	EventData,Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress)
	Set AtEnd=0
 }
 Quit $$$OK
}

ClassMethod ListByEventClose(ByRef %qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListByEventExecute ]
{
 &SQL(CLOSE ListByEventCursor)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

/// List audit records ordered by Pid.<br>
/// Parameters:<br>
/// BeginDateTime - $zdatetime($H,3) value of the first audit record, "" = first record<br>
/// EndDateTime - $zdatetime($H,3) value of the Last audit record, "" = Last record<br>
/// The following parameters may be specified as a comma separated list as follows:<br>
/// "*" - All records match<br>
/// "String,String1" - Any records matching one of these elements<br>
/// "String*" - Any record starting with "String"<br>
/// "String,String1*,String2" - Any record matching one of these elements, or starting with "String1"<br>
/// Note that these are all case insensitive matches<br>
/// EventSources - Comma separated list of valid event sources<br>
/// EventTypes - Comma separated list of valid event types<br>
/// Events - Comma separated list of event names<br>
/// Usernames - Comma separated list of user names<br>
/// SystemIDs - Comma separated list of System:Config names<br> 
/// Requires %Admin_Secure:"Use" privilege.<br>
Query ListByPid(BeginDateTime As %String, EndDateTime As %String, EventSources As %String, EventTypes As %String, Events As %String, Usernames As %String, SystemIDs As %String, Pids As %String, Groups As %String, Authentications As Security.Datatype.Authentication) As %Query(ROWSPEC = "SystemID:%String,AuditIndex:%String,TimeStamp:%String,EventSource:%String,EventType:%String,Event:%String,Pid:%String,SessionID:%String,Username:%String,Description:%String,UTCTimeStamp:%String,Group:%String,JobNumber:%String,Authentication:%String,ClientExecutableName:%String,ClientIPAddress:%String,EventData:%String,Namespace:%String,Roles:%String,RoutineSpec:%String,UserInfo:%String,JobId:%String,Status:%String,OSUsername:%String,StartupClientIPAddress:%String") [ SqlProc ]
{
}

ClassMethod ListByPidExecute(ByRef %qHandle As %Binary, BeginDateTime As %String = "", EndDateTime As %String = "", EventSources As %String = "*", EventTypes As %String = "*", Events As %String = "*", Usernames As %String = "*", SystemIDs As %String = "*", Pids As %String = "*", Groups As %String = "*", Authentications As Security.Datatype.Authentication = "*") As %Status [ Internal ]
{
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
#;Make sure the audit database is in the right format
 s Status=..Convert()
 i '$$$ISOK(Status) q Status
 d ..ApplyAuditHeader()
 s CRLF=$c(13)_$c(10),String="",Pad=$j("",20)
 s String=String_$e($$$GetMsg($$$AuditMsg,"QueryNameC")_Pad,1,$l(Pad))_"ListByPid"_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"BeginDateC")_Pad,1,$l(Pad))
 i BeginDateTime="" {
 	s Node=$q(^$$$AuditDataName(""))
 	i Node="" {
		s BDateTime=$zdatetime($h,3)
	} else {
 		s BDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Beginning",BDateTime)
 } else {
	s String=String_BeginDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EndDateC")_Pad,1,$l(Pad))
 i EndDateTime="" {
	s Node=$q(^$$$AuditDataName(""),-1)
	i Node="" {
		s EDateTime=$zdatetime($h,3)
	} else {
		s EDateTime=..ConvertUTCToLocal($li(@Node,15))
	}
	s String=String_$$$FormatMsg($$$AuditMsg,"Ending",EDateTime)
 } else {
	s String=String_EndDateTime
 }
 s String=String_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventSourcesC")_Pad,1,$l(Pad))_EventSources_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventTypesC")_Pad,1,$l(Pad))_EventTypes_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"EventsC")_Pad,1,$l(Pad))_Events_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"UsernamesC")_Pad,1,$l(Pad))_Usernames_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"SystemIDsC")_Pad,1,$l(Pad))_SystemIDs_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"PidsC")_Pad,1,$l(Pad))_Pids_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"GroupsC")_Pad,1,$l(Pad))_Groups_CRLF
 s String=String_$e($$$GetMsg($$$AuditMsg,"AuthenticationC")_Pad,1,$l(Pad))_Authentications_CRLF
 Do ..WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameAuditReport,String,$$$GetMsg($$$AuditMsg,"ListByPidQuery"))
 i EndDateTime="" {
	s UTCEndDateTime=..ConvertLocalHToUTC($p($H,",",1)_","_$p($h,",",2)_".999")
 } else {
	s UTCEndDateTime=$zdatetimeh(EndDateTime,$s(EndDateTime["-":3,1:-1),,,6)
	i $p(UTCEndDateTime,",",2)=0 s UTCEndDateTime=(+UTCEndDateTime-1)_","_86399.999
	s UTCEndDateTime=..ConvertLocalHToUTC(UTCEndDateTime)
 }
 i BeginDateTime="" {
	s UTCBeginDateTime=..ConvertLocalHToUTC("47118,0")
 } else {
	s UTCBeginDateTime=$zdatetimeh(BeginDateTime,$s(BeginDateTime["-":3,1:-1),,,6)
	s UTCBeginDateTime=..ConvertLocalHToUTC(UTCBeginDateTime)
 }
 i Authentications'="*" {
	 s InternalAuthentications=$$AuthenticationDisplayToLogical^%SYS.SECURITY(Authentications)
 } else {
	 s InternalAuthentications=Authentications
 }
 #EXECUTE s %msqlvar="%qHandle" 
 &SQL(DECLARE ListByPidCursor CURSOR for 
	SELECT SystemID,AuditIndex,UTCTimeStamp,EventSource,EventType,Event,Pid,CSPSessionID,Username,
	Description,GroupName,JobNumber,Authentication,ClientExecutableName,ClientIPAddress,EventData,
	Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress
	FROM Audit
	WHERE UTCTimeStamp BETWEEN :UTCBeginDateTime AND :UTCEndDateTime
		AND (%SYSTEM.Util_CheckName(:Usernames,Username)=1)
		AND	(%SYSTEM.Util_CheckName(:Events,Event)=1)
		AND	(%SYSTEM.Util_CheckName(:EventTypes,EventType)=1)
		AND (%SYSTEM.Util_CheckName(:EventSources,EventSource)=1)
		AND	(%SYSTEM.Util_CheckName(:SystemIDs,SystemID)=1)
		AND	(%SYSTEM.Util_CheckName(:Pids,Pid)=1)
		AND	(%SYSTEM.Util_CheckName(:Groups,GroupName)=1)
 		AND (%SYS.Audit_CheckAuthentication(:InternalAuthentications,Authentication)=1)
	ORDER BY +Pid,CSPSessionID,UTCTimeStamp DESC, AuditIndex DESC)
 #EXECUTE k %msqlvar
 &SQL(OPEN ListByPidCursor)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

ClassMethod ListByPidFetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListByPidExecute ]
{
 &SQL(FETCH ListByPidCursor
	INTO :SystemID,:AuditIndex,:UTCTimeStamp,:EventSource,:EventType,:Event,:Pid,:CSPSessionID,
	:Username,:Description,:GroupName,:JobNumber,:Authentication,:ClientExecutableName,:ClientIPAddress,
	:EventData,:Namespace,:Roles,:RoutineSpec,:UserInfo,:JobId,:Status,:OSUsername,:StartupClientIPAddress)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 If SQLCODE=100 {
	Set Row="",AtEnd=1
 } Else {
	Set Row=$LB(SystemID,AuditIndex,..ConvertUTCToLocal(UTCTimeStamp),EventSource,EventType,Event,Pid,
	CSPSessionID,Username,..DescriptionLogicalToDisplay(Description),UTCTimeStamp,GroupName,JobNumber,
	$$AuthenticationLogicalToDisplay^%SYS.SECURITY(Authentication),ClientExecutableName,ClientIPAddress,
	EventData,Namespace,Roles,RoutineSpec,UserInfo,JobId,Status,OSUsername,StartupClientIPAddress)
	Set AtEnd=0
 }
 Quit $$$OK
}

ClassMethod ListByPidClose(ByRef %qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListByPidExecute ]
{
 &SQL(CLOSE ListByPidCursor)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

/// Open an Audit Log item, given its ID information (UTC date, system ID, and audit index). <br>
/// Requires %Admin_Secure:"Use" privilege.<br>
/// If you wish to modify the returned object, use the Modify() method.<br>
ClassMethod OpenAuditItem(UTCTimeStamp As %String, SystemID As %String, AuditIndex As %BigInt) As %SYS.Audit
{
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary ; verified 10/31/18 STC
 q ..%OpenId(UTCTimeStamp_"||"_SystemID_"||"_AuditIndex)
}

Method %OnOpen() As %Status [ Internal, Private, ServerOnly = 1 ]
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 s ..Namespace=..NamespaceLogicalToDisplay(..Namespace)
 s ..Description=..DescriptionLogicalToDisplay(..Description)
 s ..EventData=..EventDataLogicalToDisplay(..EventData)
 q $$$OK
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

Storage Audit
{
<Data name="AuditDefaultData">
<Value name="1">
<Value>AuditIndex</Value>
</Value>
<Value name="2">
<Value>ClientExecutableName</Value>
</Value>
<Value name="3">
<Value>ClientIPAddress</Value>
</Value>
<Value name="4">
<Value>Description</Value>
</Value>
<Value name="5">
<Value>Event</Value>
</Value>
<Value name="6">
<Value>EventData</Value>
</Value>
<Value name="7">
<Value>EventSource</Value>
</Value>
<Value name="8">
<Value>EventType</Value>
</Value>
<Value name="9">
<Value>Namespace</Value>
</Value>
<Value name="10">
<Value>Pid</Value>
</Value>
<Value name="11">
<Value>Roles</Value>
</Value>
<Value name="12">
<Value>RoutineSpec</Value>
</Value>
<Value name="13">
<Value>SystemID</Value>
</Value>
<Value name="14">
<Value>Username</Value>
</Value>
<Value name="15">
<Value>UTCTimeStamp</Value>
</Value>
<Value name="16">
<Value>CSPSessionID</Value>
</Value>
<Value name="17">
<Value>UserInfo</Value>
</Value>
<Value name="18">
<Value>JobId</Value>
</Value>
<Value name="19">
<Value>GroupName</Value>
</Value>
<Value name="20">
<Value>Status</Value>
</Value>
<Value name="21">
<Value>OSUsername</Value>
</Value>
<Value name="22">
<Value>Authentication</Value>
</Value>
<Value name="23">
<Value>StartupClientIPAddress</Value>
</Value>
<Value name="24">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^IRIS.AuditD</DataLocation>
<DefaultData>AuditDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^IRIS.AuditD</IdLocation>
<IndexLocation>^IRIS.AuditI</IndexLocation>
<StreamLocation>^IRIS.AuditS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
