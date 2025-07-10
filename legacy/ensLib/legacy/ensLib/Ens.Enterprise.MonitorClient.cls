/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Enterprise.MonitorClient Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Property Name As %String [ Required ];

Index Name On Name [ IdKey, Unique ];

Property WebIPAddress As %String(MAXLEN = 250);

Property Namespace As %String;

Property SOAPCredentials As %String;

Property SSLConfig As %String;

Property HomePath As %String(MAXLEN = 250);

Property HomePage As %String;

Property Version As %String;

Property QueueThreshold As %String;

Property ServicePath As %String(MAXLEN = 250);

Property SSLCheckServerIdentity As %Boolean [ InitialExpression = 1 ];

Method GetURLPath(pServicePath As %Integer = 0) As %String
{
	Set tPath = $Select((pServicePath&&(..ServicePath'="")):..ServicePath,1:$select(..HomePath '= "": ..HomePath, 1: "/csp/"_$zcvt(..Namespace,"L")_"/"))
	Set tPath = "http"_$S(""'=..SSLConfig:"s",1:"")_"://"_..WebIPAddress_tPath
	Quit tPath
}

Query EnumerateClients() As %Query(ROWSPEC = "ID:%String,IsNode:%Boolean,Name:%String,NodeId:%Integer,WebIPAddress:%String,Namespace:%String,SOAPCredentials:%String,SSLConfig:%String,HomePath:%String,HomePage:%String,Version:%String,QueueThreshold:%String,ServicePath:%String,SSLCheckServerIdentity:%Boolean")
{
}

ClassMethod EnumerateClientsExecute(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle  Set qHandle=0, qHandle("pos")=""
	
	#; Build list in qHandle of MonitorClient rows
	&sql(Declare C1 Cursor for
		Select Name,WebIPAddress,Namespace,SOAPCredentials,SSLConfig,HomePath,HomePage,Version,QueueThreshold,ServicePath,SSLCheckServerIdentity
		 Into :tName,:tWebIPAddress,:tNamespace,:tSOAPCredentials,:tSSLConfig,:tHomePath,:tHomePage,:tVersion,:tQueueThreshold,:tServicePath,:tSSLCheckServerIdentity
		 From Ens_Enterprise.MonitorClient)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		Set qHandle($I(qHandle))=tName
		Set qHandle(qHandle,"WebIPAddress")=tWebIPAddress
		Set tSep=$S(tWebIPAddress["|":"|",1:":")
		Set tWebSepLen = $L(tWebIPAddress,tSep)
		Set tIPAddress = $P(tWebIPAddress,tSep,1,$S(tWebSepLen=1: 1, 1: tWebSepLen-1))
		Set qHandle(qHandle,"ipaddr")=tIPAddress
		Set qHandle(qHandle,"port")=$S(tWebSepLen=1: "", 1: $P(tWebIPAddress,tSep,tWebSepLen))
		If $get(qHandle(qHandle,"port")) = "" {
			Set qHandle(qHandle,"port") = $select(tSSLConfig '= "": 443, 1: 80)
			Set qHandle(qHandle,"WebIPAddress") = qHandle(qHandle,"ipaddr") _ tSep _ qHandle(qHandle,"port")
		}
		Set qHandle("ipnsaddrs",qHandle(qHandle,"ipaddr"),qHandle(qHandle,"port"),tNamespace)=qHandle
		Set qHandle(qHandle,"Namespace")=tNamespace
		Set qHandle(qHandle,"SOAPCredentials")=tSOAPCredentials
		Set qHandle(qHandle,"SSLConfig")=tSSLConfig
		Set qHandle(qHandle,"HomePage")=tHomePage
		Set qHandle(qHandle,"HomePath")=tHomePath
		Set qHandle(qHandle,"Version")=tVersion
		Set qHandle(qHandle,"QueueThreshold")=tQueueThreshold
		Set qHandle(qHandle,"ServicePath")=tServicePath
		Set qHandle(qHandle,"SSLCheckServerIdentity")=tSSLCheckServerIdentity
	} &sql(CLOSE C1)

	#; Add in any raw MsgBank Node rows that aren't duplicates
	&sql(Declare C2 Cursor for
		Select ID,Name,Machine,Namespace,IPAddr,WebIPAddr,WebPort
		 Into :tID,:tName,:tMachine,:tNamespace,:tIPAddr,:tWebIPAddr,:tWebPort
		 From Ens_Enterprise_MsgBank.Node)
	&sql(OPEN C2) For { &sql(FETCH C2)  Quit:SQLCODE
		#; Check if the node is already in the configured clients list
		Set:""=tWebPort tWebPort="-"
		Set tMatch=0
		If ""'=tWebIPAddr Set tMatch=$G(qHandle("ipnsaddrs",tWebIPAddr,tWebPort,tNamespace))
		If ""'=tIPAddr&&'tMatch Set tMatch=$G(qHandle("ipnsaddrs",tIPAddr,tWebPort,tNamespace))
		If ""'=tMachine&&'tMatch Set tMatch=$G(qHandle("ipnsaddrs",tMachine,tWebPort,tNamespace))
		If tMatch {
			Set tNode=$G(qHandle(tMatch,"NodeId"))
			Set qHandle(tMatch,"NodeId")=$S(""=tNode:"",1:tNode_",")_tID
			Set:$G(qHandle(tMatch,"isNode")) qHandle(tMatch)="+"_tID_":"_tName ; for nodes, use last-found name
		} Else {
			Set:""=tWebIPAddr tWebIPAddr=tIPAddr  Set:""=tWebIPAddr tWebIPAddr=tMachine
			;Continue::""=tWebIPAddr ; should never happen
			Set qHandle($I(qHandle))="+"_tID_":"_tName
			Set qHandle(qHandle,"WebIPAddress")=tWebIPAddr_$S(tWebIPAddr[":":"|",1:":")_tWebPort
			Set qHandle(qHandle,"ipaddr")=tWebIPAddr
			Set qHandle("ipnsaddrs",tWebIPAddr,tNamespace)=qHandle
			Set qHandle(qHandle,"port")=tWebPort
			Set qHandle(qHandle,"Namespace")=tNamespace

			Set qHandle(qHandle,"isNode")=1
			Set tNode=$G(qHandle(qHandle,"NodeId"))
			Set qHandle(qHandle,"NodeId")=$S(""=tNode:"",1:tNode_",")_tID
		}
	} &sql(CLOSE C2)
	Quit $$$OK
}

ClassMethod EnumerateClientsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateClientsExecute ]
{
	If 0=$G(qHandle("pos"),0) Set Row="", AtEnd=1  Quit $$$OK
	Set pos=$I(qHandle("pos"))  If pos>qHandle Set qHandle("pos")=0, Row="", AtEnd=1  Quit $$$OK
	Set:pos=qHandle AtEnd=1
	Set Row=$LB(qHandle(pos),+$G(qHandle(pos,"isNode")),qHandle(pos),$G(qHandle(pos,"NodeId")),qHandle(pos,"WebIPAddress"),qHandle(pos,"Namespace"),qHandle(pos,"SOAPCredentials"),qHandle(pos,"SSLConfig"),$g(qHandle(pos,"HomePath")),$g(qHandle(pos,"HomePage")),$g(qHandle(pos,"Version")),$g(qHandle(pos,"QueueThreshold")),$g(qHandle(pos,"ServicePath")),$g(qHandle(pos,"SSLCheckServerIdentity")))
	Quit $$$OK
}

ClassMethod EnumerateClientsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateClientsExecute ]
{
	Kill qHandle
	Quit $$$OK
}

/// Find a client connection name for the given NodeId, if possible; otherwise return the NodeId+NodeName
ClassMethod getNodeClient(pNodeId) As %String
{
	If $D(^Ens.MsgBankSvr("nodemap",pNodeId),tName) Quit tName
	Set tNodeName = ##class(Ens.Enterprise.MsgBank.Node).GetNodeName(pNodeId)
	Quit $S(tNodeName="":"", 1:"+"_pNodeId_":"_tNodeName)
}

ClassMethod rebuildNodeMap()
{
	Set tSC=..EnumerateClientsExecute(.tQH)  Quit:$$$ISERR(tSC)
	For { Set tSC=..EnumerateClientsFetch(.tQH,.tRow,.tAtEnd)  Quit:$$$ISERR(tSC)
		Continue:$LG(tRow,2) ; IsNode
		Set tName=$LG(tRow,1), tNodeIds=$LG(tRow,4)
		For iNode=1:1:$L(tNodeIds,",") { Set tNodeId=$P(tNodeIds,",",iNode)  Continue:""=tNodeId
			Set tMap(tNodeId)=tName
		}
		Quit:tAtEnd
	}
	Quit:$$$ISERR(tSC)
	Set tSC=..EnumerateClientsClose(.tQH)  Quit:$$$ISERR(tSC)
	Kill ^Ens.MsgBankSvr("nodemap") Merge ^Ens.MsgBankSvr("nodemap")=tMap
}

/// If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Quit:..Name["|" $$$ERROR($$$EnsErrGeneral,"MonitorClient name ("_..Name_") is not allowed to contain character '|'")
	Quit $$$OK
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	Do ..rebuildNodeMap()
	Quit $$$OK
}

ClassMethod %OnAfterDelete(oid As %ObjectIdentity) As %Status [ ServerOnly = 1 ]
{
	Do ..rebuildNodeMap()
	Quit $$$OK
}

Storage Default
{
<Data name="MonitorClientDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>WebIPAddress</Value>
</Value>
<Value name="3">
<Value>Namespace</Value>
</Value>
<Value name="4">
<Value>SOAPCredentials</Value>
</Value>
<Value name="5">
<Value>SSLConfig</Value>
</Value>
<Value name="6">
<Value>HomePath</Value>
</Value>
<Value name="7">
<Value>HomePage</Value>
</Value>
<Value name="8">
<Value>Version</Value>
</Value>
<Value name="9">
<Value>QueueThreshold</Value>
</Value>
<Value name="10">
<Value>ServicePath</Value>
</Value>
<Value name="11">
<Value>SSLCheckServerIdentity</Value>
</Value>
</Data>
<DataLocation>^Ens.Enterprise.MonitorClientD</DataLocation>
<DefaultData>MonitorClientDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Enterprise.MonitorClientD</IdLocation>
<IndexLocation>^Ens.Enterprise.MonitorClientI</IndexLocation>
<StreamLocation>^Ens.Enterprise.MonitorClientS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
