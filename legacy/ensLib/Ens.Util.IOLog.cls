/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A header class that records raw Adapter Inputs and Outputs
Class Ens.Util.IOLog Extends (%Persistent, Ens.Util.BitmapPurge) [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Index Extent [ Extent, Type = bitmap ];

Property AdapterClass As %String(MAXLEN = 128, TRUNCATE = 1);

Property HostClass As %String(MAXLEN = 128, TRUNCATE = 1);

Property ConfigName As %String(MAXLEN = 128, TRUNCATE = 1);

Property SourceMethod As %String(MAXLEN = 40, TRUNCATE = 1);

Property TimeReceived As Ens.DataType.UTC;

Property TimeResponded As Ens.DataType.UTC;

Property Job As %String(TRUNCATE = 1);

/// this property contains the error status if any
Property Status As %Status [ InitialExpression = {$$$OK} ];

/// The %Id() of the corresponding request
Property CorrespondingRequestId As %Integer;

Property SessionId As %Integer;

Property IsInbound As %Boolean;

Property InObjectClass As %String(MAXLEN = 128, TRUNCATE = 1);

Property InObject As %RegisteredObject;

Property OutObjectClass As %String(MAXLEN = 128, TRUNCATE = 1);

Property OutObject As %RegisteredObject;

Property Annotation As %String(MAXLEN = 1200, TRUNCATE = 1);

Index TimeReceived On TimeReceived;

Index SessionId On SessionId;

Index ConfigName On ConfigName [ Type = bitmap ];

Parameter DOMAIN = "Ensemble";

Method IsEmpty() As %Boolean [ Abstract ]
{
	Quit 1
}

/// Output HTML header information for IOLog object
Method %ShowContentsHead(pZenOutput As %Boolean = 0)
{
	&html<<style type="text/css">
.headerBox {
	font-weight: bold;
}
.streamContent {
	background: white;
	padding: 5px;
	margin: 0;
}
</style>
>
	
	If ('pZenOutput) {
		&html<<style type="text/css">
body {
	background-image: url('images/ensback.png');
	background-repeat: repeat-x;
	background-color: white;
}
</style>
<link rel="stylesheet" type="text/css" href="#(##class(%CSP.Page).Link("/csp/sys/csputils.css"))#" title="Standard Style" />>
	}
	Else {
		&html<<style type="text/css">
table.AutoFormTable {
	font-size: 0.8em;
	border: 1px solid black;
}
td.AutoFormTableCaption, td.AutoFormTableValue {
	padding: 3px;
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
}
td.AutoFormTableCaption {
	font-weight: bold;
}
</style>>
	}
}

/// Output contents of IOLog object in HTML
Method %ShowContents(pZenOutput As %Boolean = 0)
{
	; Zen MessageContents pane performs auditing
	If 'pZenOutput Do $$$AuditViewMessage($$$Text("Message Browser"),0,$classname(), ..%Id())

	&html<<table cols="2" width="100%"><tr>>
	If ..IsInbound {
		Do ..showObject(1,pZenOutput)
		Do ..showObject(0,pZenOutput)
	}
	Else {
		Do ..showObject(0,pZenOutput)
		Do ..showObject(1,pZenOutput)
	}
	&html<</tr></table>>
	Quit
}

Method showObject(pIn As %Boolean, pZenOutput As %Boolean = 0) [ Internal, Private ]
{
	Set tObject = $select(pIn: ..InObject, 1: ..OutObject)
	Set tObjectClass = $select(pIn: ..InObjectClass, 1: ..OutObjectClass)
	Set tTitle = $select(pIn: $$$TextHTML("Input Data"), 1: $$$TextHTML("Output Data"))
	Set tNoObject = $select(pIn: $$$TextHTML("No Input Data"), 1: $$$TextHTML("No Output Data"))
	Set tTime = ""
	Set tTimeTitle = ""
	Set tTimeProp = ""
	If ..IsInbound {
		Set tTimeProp = $select(pIn: "TimeReceived", 1: "TimeResponded")
	}
	Else {
		Set tTimeProp = $select(pIn: "TimeResponded", 1: "TimeReceived")
	}
	If tTimeProp '= "" {
		Set tTime = $classmethod($classname($this),tTimeProp_"LogicalToDisplay",$property($this,tTimeProp))
		Set tTimeTitle = $select(tTimeProp = "TimeReceived": $$$TextHTML("Time Received"), 1: $$$TextHTML("Time Responded"))
	}
	Set tTime = $select(tTime = "": "&nbsp;", 1: $zconvert(tTime,"O","HTML"))
	
	&html<<td width="50%" valign="top">
	
	<div class="Text1 headerBox" style="margin: 3px;">#(tTitle)#:</div><hr/>
		<table class="AutoFormTable" border="0" cellspacing="0" width="100%" style="margin-left: 0px;">>
	If tObjectClass="" {
		&html<<tr class="AutoFormTableRow">
			<td class="AutoFormTableValue">
				<div class="Text1" style="margin: 3px;">#(tNoObject)#</div>
			</td></tr>>
	}
	ElseIf $IsObject(tObject) {
		; Zen MessageContents pane performs auditing
		If 'pZenOutput Do $$$AuditViewMessage($$$Text("Message Browser"),0,$classname(tObject), tObject.%Id())
		Set tDetailLink = $select(pZenOutput: "", ..CorrespondingRequestId = "": "", 1: ##class(%CSP.Page).Link("UtilEnsMsgDetails.csp?$FRAME=Info&$ID1="_..CorrespondingRequestId,,1))
		Set tDetailLink = $select(tDetailLink = "": "&nbsp;", 1: "<a href="""_tDetailLink_""">"_..CorrespondingRequestId_"</a>")
		&html<
			<tr class="AutoFormTableRow"><td class="AutoFormTableCaption">#(tTimeTitle)#</td><td class="AutoFormTableValue">#(tTime)#</td></tr>
			<tr class="AutoFormTableRow"><td class="AutoFormTableCaption">#($$$TextHTML("Object Class"))#</td><td class="AutoFormTableValue">#($select(tObjectClass="":"&nbsp;",1:$ZCVT(tObjectClass,"O","HTML")))#</td></tr>
			<tr class="AutoFormTableRow"><td class="AutoFormTableCaption">#($$$TextHTML("Corresponding Request Id"))#</td><td class="AutoFormTableValue">#(tDetailLink)#</td></tr>
			
		<tr><td colspan="2">>
		If tObject.%Extends("%Stream.Object"){
			If (tObject.Size=0) {
				Set tNoDataMsg = $$$TextHTML("NO DATA")
				&html<<pre class="streamContent">&lt;#(tNoDataMsg)#&gt;</pre>>
			}
			Else {
				Write !,"<pre class=""streamContent"">"
				Set currTab = $zu(96,18,0)
				Try {
					Do ##class(%SYS.NLS.Device).SetIO("HTML")
					Do tObject.OutputToDevice()
				}
				Catch {}
				Do ##class(%SYS.NLS.Device).SetIO(currTab)
				Write "</pre>"
			}
		}
		Else {
			&html<<iframe src="#(##class(%CSP.Page).Link("EnsPortal.MessageContents.cls?HeaderClass="_$classname()_"&HeaderId="_##class(%CSP.Page).EscapeURL(..%Id())))#&IOBody=#(pIn)#" width="100%" height="300px"></iframe>>
		}
		&html<</td></tr>>
	}
	Else {
		Set tError = $select(pIn: $$$TextHTML("Unable to display IO Log Input Data."), 1: $$$TextHTML("Unable to display IO Log Output Data."))
		&html<<div class="Text1" style="margin: 3px;">#(tError)#</div>>
	}
	&html<</table></td>>
	Quit
}

ClassMethod GetRequestIOLogs(pRequestHeader As Ens.MessageHeader, Output pIOLogArray As Ens.Util.IOLog) As %Status
{
	Set tId=pRequestHeader.%Id()
	$$$ASSERT($IsObject(pRequestHeader) && (""'=pRequestHeader.SessionId))
	&sql(DECLARE CReq CURSOR FOR
		Select ID,CorrespondingRequestId into :tIOLogId,:tRequestId from Ens_Util.IOLog
		 where SessionId=:pRequestHeader.SessionId
	)
	&sql(OPEN CReq) For { &sql(FETCH CReq) Quit:SQLCODE  Continue:tRequestId'=tId
	 	Set tIOLog = ..%OpenId(tIOLogId,0,.tSC)  If '$IsObject(tIOLog)||$$$ISERR(tSC) $$$ASSERT(0_"Can't open Id "_tIOLogId) Continue
		Set pIOLogArray=$G(pIOLogArray)+1, pIOLogArray(pIOLogArray)=tIOLog
	} &sql(CLOSE CReq)
 	Quit $$$OK
}

ClassMethod GetSessionIOLogs(pSessionId As %RawString, Output pIOLogArray As Ens.Util.IOLog) As %Status
{
	&sql(DECLARE CSes CURSOR FOR Select ID Into :tIOLogId From Ens_Util.IOLog Where SessionId=:pSessionId)
	&sql(OPEN CSes) For { &sql(FETCH CSes) Quit:SQLCODE
	 	Set tIOLog = ..%OpenId(tIOLogId,0,.tSC)  If '$IsObject(tIOLog)||$$$ISERR(tSC) $$$ASSERT(0_"Can't open Id "_tIOLogId) Continue
		Set pIOLogArray=$G(pIOLogArray)+1, pIOLogArray(pIOLogArray)=tIOLog
	} &sql(CLOSE CSes)
 	Quit $$$OK
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pDummy As %Boolean, pBitmapPurgeRunLimit As %Integer = 600) As %Status
{
	Set:'$TLEVEL tTransactionSuspendedSwitch = ##class(Ens.Util.Purge.SuspendTransaction).%New($$$EnsPurgeJournalOldDataGet)

	#; Purge headerless IOLogObj in & out objects along with the IOLog entry
	New %tDoNotDeleteDate,%tClass,%tID Set %tID="", %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set tSC=$$$OK, SQLCODE=0, pDeletedCount=0
	&sql(DECLARE C1 CURSOR FOR
		Select ID, $Piece(x__ClassName,'~',$Length(x__ClassName,'~')-1) As Class Into :%tID,:%tClass
			From Ens_Util.IOLog Where TimeReceived < :%tDoNotDeleteDate)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		#; %tClass will be empty when the object type is Ens.Util.IOLog, so catch this case
		If %tClass = "" Set %tClass = "Ens.Util.IOLog"
		Set tExists=$G(aClass(%tClass))
		If 0'=tExists {
			Set $zt="deleteError"
			Set tSC1=$zobjclassmethod(%tClass,"%DeleteId",%tID)
			Set:""=tExists aClass(%tClass)=1, tExists=1
			GoTo deleteErrora
deleteError Set:""=tExists aClass(%tClass)=0  Set:'$G(aClass(%tClass,"doneErr")) tSC1=$$$SystemError
deleteErrora Set $zt=""
			If $$$ISERR(tSC1)&&'$G(aClass(%tClass,"doneErr")) {
				Set tOK=$$$StatusEquals(tSC1,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError)
				If 'tOK { Set aClass(%tClass,"doneErr")=1, tSC=$$$ADDSC(tSC,tSC1)  $$$LOGWARNING("Failed to purge ID "_%tID_", Class='"_%tClass_"':"_$$$StatusDisplayString(tSC1)) }
			}
			Set pDeletedCount=pDeletedCount+$$$ISOK(tSC1)
		}
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	Set:SQLCODE&&(SQLCODE'=100) tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID_"; SQLCODE = "_SQLCODE))
	Set tBitmapSC = ..PurgeBitmaps(pBitmapPurgeRunLimit,.tDeletedChunks)
	Merge pDeletedCount("bitmaps") = tDeletedChunks
	Kill tTransactionSuspendedSwitch
	Quit $$$ADDSC(tSC,tBitmapSC)
}

Storage Default
{
<Data name="IOLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>AdapterClass</Value>
</Value>
<Value name="3">
<Value>Annotation</Value>
</Value>
<Value name="4">
<Value>ConfigName</Value>
</Value>
<Value name="5">
<Value>CorrespondingRequestId</Value>
</Value>
<Value name="6">
<Value>HostClass</Value>
</Value>
<Value name="7">
<Value>InObject</Value>
</Value>
<Value name="8">
<Value>InObjectClass</Value>
</Value>
<Value name="9">
<Value>IsInbound</Value>
</Value>
<Value name="10">
<Value>Job</Value>
</Value>
<Value name="11">
<Value>OutObject</Value>
</Value>
<Value name="12">
<Value>OutObjectClass</Value>
</Value>
<Value name="13">
<Value>SessionId</Value>
</Value>
<Value name="14">
<Value>SourceMethod</Value>
</Value>
<Value name="15">
<Value>Status</Value>
</Value>
<Value name="16">
<Value>TimeReceived</Value>
</Value>
<Value name="17">
<Value>TimeResponded</Value>
</Value>
</Data>
<DataLocation>^Ens.Util.IOLogD</DataLocation>
<DefaultData>IOLogDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Util.IOLogD</IdLocation>
<IndexLocation>^Ens.Util.IOLogI</IndexLocation>
<StreamLocation>^Ens.Util.IOLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
