/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Configuration information for the Task Manager
/// This table contains Parameter/Value pairs for the Configuration information
/// <br><br>
/// Users may access the Email parameters/values using the EmailSet() or EmailGet() methods.
Class %SYS.Task.Config Extends %Persistent [ System = 4 ]
{

Parameter DOMAIN = "%Utility";

/// Parameter Name
Property ParamName As %String(MAXLEN = 1024);

/// Parameter Value
Property Data As %String(MAXLEN = 32000);

Index ParamNameIndex On ParamName [ Unique ];

/// Return data associated with Parameter
ClassMethod GetData(ParamName As %String) As %String [ Internal ]
{
	&SQL(SELECT Data INTO :Data FROM %SYS_Task.Config 
		WHERE ParamName=:ParamName)
	Quit $S(SQLCODE:"",1:Data)
}

/// Return object associated with Parameter
/// If the row is not found return a New object with the parameter Name set
ClassMethod GetObject(ParamName As %String) As %String [ Internal ]
{
	&SQL(SELECT ID INTO :ID FROM %SYS_Task.Config 
		WHERE ParamName=:ParamName)
	If SQLCODE {Set obj=##class(%SYS.Task.Config).%New(),obj.ParamName=ParamName}
	Else {Set obj=##class(%SYS.Task.Config).%OpenId(ID)}
	
	Quit obj
}

/// Update the data associated with Parameter
ClassMethod UpdateData(ParamName As %String, Data As %String, Message As %String) As %Status [ Internal ]
{
	Set oldData=..GetData(ParamName)
	&SQL(UPDATE %SYS_Task.Config SET Data=:Data 
		WHERE ParamName=:ParamName)
	If SQLCODE=100 {
		&SQL(INSERT INTO %SYS_Task.Config SET Data=:Data,ParamName=:ParamName)
	}
	If 'SQLCODE {
		If $g(Message)="" {
			If ParamName="MailAuthPassword" Set Message=$$$Text("TASKMGR Parameter (MailAuthPassword) reset.")
			Else  Set Message=$$$FormatText($$$Text("TASKMGR Parameter (%1) set to %2"),ParamName,Data)
		}
		Do ##class(%SYS.Task.History).WriteLog(1,$$$Text("Success"),$h,$h,Message,0,"%SYS","TASKMGR")
		If oldData'=Data {
			Set eventdata=$$$FormatMsg($$$AuditMsg,"OldValue",oldData)_$c(13,10)_$$$FormatMsg($$$AuditMsg,"NewValue",Data)
			Set description=$$$FormatMsg($$$AuditMsg,"ModifyHeader",$$$GetMsg($$$AuditMsg,"Task"),"Config."_ParamName)
			Do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSystem,$$$NameConfigChange,eventdata,description)
            If ParamName = "Suspend", Data Do ##class(%SYS.System).WriteToConsoleLog(Message,0,1)
		}
	}
	Quit $S(SQLCODE:$$$ERROR($$$TASKFailedConfigUpdate,ParamName,"SQLCODE: "_SQLCODE),1:$$$OK)
}

/// Used for New installations or Upgrade to 1.3
ClassMethod Initialize() As %Status [ Internal ]
{
	#; if already initialized we're done
	Quit:..GetData("Version")]"" $$$OK
	Set status=..UpdateData("Version",##class(%SYS.Task).%GetParameter("Version"))
	Set:status status=##class(%SYS.Task).SuspendSet(0)
	Set:status status=##class(%SYS.Task).HistoryPurgeSet(7)
	Set:status status=##class(%SYS.Task).JobTimeoutSet(30)
	Set:status status=##class(%SYS.Task).MailServerSet("")
	Set:status status=##class(%SYS.Task).MailTimeZoneSet("")
	Set:status status=##class(%SYS.Task).MailReplyToSet("")
	Quit status
}

/// Used to return the encoded Mail Authentication Password
ClassMethod AuthPassGet() As %String [ Internal ]
{
	Set pwd=..GetData("MailAuthPassword")
	If pwd]"" {
		try {
			Set pwd=$system.Encryption.Base64Decode(pwd)
		} catch encerr {
			i encerr.Name = "<ILLEGAL VALUE>" s pwd=""
			e  throw encerr
		}
	}
	Quit pwd
}

/// Used to update the encoded Mail Authentication Password
ClassMethod AuthPassSet(pwd As %String) As %String [ Internal ]
{
	Set Status=$$$OK
	If pwd'="" Set pwd=$system.Encryption.Base64Encode(pwd)
	Set Status=..UpdateData("MailAuthPassword",pwd)
	Quit Status
}

/// Available fields for substitution into mail message subject / body
ClassMethod SubstitutionFields() As %String
{
	Quit "ID,DESCRIPTION,NAME,SERVER,INSTANCE,LASTSTARTED,LASTFINISHED,SCHEDULED,CURRENTDATE,CURRENTTIME,STATUS,TASKCLASS,ERROR,SUCCESS"
}

/// Validate substitution fields in a message. 'bad' returns a specific problem field.
ClassMethod SubstitutionsValid(text, ByRef bad) As %Boolean
{
	Set subs=..SubstitutionFields()

	Set ok=1,bad=""
	Quit:'$f(text,"#(") 1
	For i=1:1:$l(text,"#(") {
		Set piece=$p(text,"#(",i+1)
		Set piece=$p(piece,")#",1) if piece="" continue
		If (","_subs_",")'[(","_piece_",") Set ok=0,bad=bad_","_piece
	}
	Set bad=$e(bad,2,$l(bad))
	Quit ok
}

ClassMethod MakeSubstitutions(ByRef text, ByRef sub) [ Internal ]
{
	Set pos=0
	For  {
		Set pos=$f(text,"#(",pos)
		Quit:'pos
		Set piece=$p(text,"#(",2)
		Set piece=$p(piece,")#",1) if piece="" continue
		If $d(sub(piece)) Set text=$p(text,"#(")_sub(piece)_$p(text,")#",2,999)
		Else  Set text=$p(text,"#(")_"******"_$p(text,")#",2,999)
	}
	Quit
}

/// Return the generic Task Manager email subject text
ClassMethod genericMailSubject() As %String
{
	Quit $$$Text("Scheduler process #(NAME)# - #(ID)# #(SUCCESS)#")
}

/// Return the generic Task Manager email message text
ClassMethod genericMailMessage() As %String
{
	Quit $$$Text("Scheduler process #(NAME)# - #(ID)# Scheduled for #(SCHEDULED)# on #(SERVER)#:#(INSTANCE)#, #(SUCCESS)# Executing Code #(TASKCLASS)# at #(LASTFINISHED)# #(ERROR)#")
}

/// Retrieve the email settings for the Task Manager.
/// Available Parameters are:
/// <br><br>
/// "Server","Port","ReplyTo","Sender","TimeZone","AuthUser","AuthPassword",
/// "SubjectSuccess","SubjectFailure","MessageSuccess","MessageFailure","SSLConfiguration","UseSTARTTLS"
ClassMethod EmailGet(Parameter As %String, ByRef Value As %String) As %Status
{
	i '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
	i $g(Parameter)="" q $$$ERROR($$$InvalidParameter,"Parameter",$g(Parameter))
	s parm=",Server,Port,ReplyTo,Sender,TimeZone,AuthUser,AuthPassword,SubjectSuccess,SubjectFailure,MessageSuccess,MessageFailure,SSLConfiguration,UseSTARTTLS,"
	i parm'[(","_Parameter_",") q $$$ERROR($$$InvalidParameter,"Parameter",Parameter)
	i Parameter="AuthPassword" s Value=..AuthPassGet() q $$$OK
	s parm="Mail"_Parameter s Value=..GetData(parm)
	q $$$OK
}

/// Set the email parameters for the Task Manager
/// Available Parameters are:
/// <br><br>
/// "Server","Port","ReplyTo","Sender","TimeZone","AuthUser","AuthPassword",
/// "SubjectSuccess","SubjectFailure","MessageSuccess","MessageFailure","SSLConfiguration","UseSTARTTLS"
ClassMethod EmailSet(Parameter As %String, Value As %String) As %Status
{
	i '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
	i $g(Parameter)="" q $$$ERROR($$$InvalidParameter,"Parameter",Parameter)
	s parm=",Server,Port,ReplyTo,Sender,TimeZone,AuthUser,AuthPassword,SubjectSuccess,SubjectFailure,MessageSuccess,MessageFailure,SSLConfiguration,UseSTARTTLS,"
	i parm'[(","_Parameter_",") q $$$ERROR($$$InvalidParameter,"Parameter",Parameter)
	i Parameter="AuthPassword" s stat=..AuthPassSet(Value) q stat
	i Parameter["Subject"||(Parameter["Message") {
		s err=""
		i '..SubstitutionsValid(Value,.err) q $$$ERROR($$$InvalidParameter,Parameter,err)
	}
	s parm="Mail"_Parameter,msg="" s stat=..UpdateData(parm,Value,.msg)
	q $$$OK
}

Storage Default
{
<Data name="ConfigDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Data</Value>
</Value>
<Value name="3">
<Value>ParamName</Value>
</Value>
</Data>
<DataLocation>^|"^^"_$ZU(12)|SYS("Task","ConfigD")</DataLocation>
<DefaultData>ConfigDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^|"^^"_$ZU(12)|SYS("Task","ConfigD")</IdLocation>
<IndexLocation>^|"^^"_$ZU(12)|SYS("Task","ConfigI")</IndexLocation>
<StreamLocation>^|"^^"_$ZU(12)|SYS("Task","ConfigS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
