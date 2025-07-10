/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A class representing each client node the Message Bank Server knows about
Class Ens.Enterprise.MsgBank.Node Extends %Persistent [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Index ID On ID [ IdKey ];

/// 3 digit internal node key number
Property ID As %Integer(MAXVAL = 999, MINVAL = 100);

/// composite Node name
Property Name As %String(MAXLEN = "") [ Required ];

Property TimeCreated As Ens.DataType.UTC [ InitialExpression = {$$$timeUTC} ];

/// The last time a change was stored to the IP and Port values
Property TimeUpdated As Ens.DataType.UTC;

/// The last time a Handshake was accepted from a client node
Property TimeConnected As Ens.DataType.UTC;

Index Name On Name [ Unique ];

/// Machine name of the node
Property Machine As %String(MAXLEN = "") [ Calculated, ReadOnly, SqlComputeCode = { Set {Machine}=$P({Name},"|",1) }, SqlComputed, Transient ];

/// Instance name of the node
Property Instance As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {Instance}=$P({Name},"|",2) }, SqlComputed, Transient ];

/// Namespace of the node
Property Namespace As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {Namespace}=$P({Name},"|",3) }, SqlComputed ];

/// Number of times the MessageHeader ID counter has been reset on the node
Property Iteration As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {Iteration}=$P({Name},"|",4) }, SqlComputed, Transient ];

/// Alphabet character to distingush multiple nodes connected simultaneously from different IP Adddresses
Property Clone As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {Clone}=$P({Name},"|",5) }, SqlComputed, Transient ];

/// The node's IP Address and port
Property IPAddress As %String(MAXLEN = "");

/// The IP Address portion of the IPAddress
Property IPAddr As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {IPAddr}=$P({IPAddress},"|",1) }, SqlComputed, Transient ];

/// The Port portion of the IPAddress
Property Port As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {Port}=$P({IPAddress},"|",2) }, SqlComputed, Transient ];

/// The node's webserver IP Address, port, and URL root
Property WebServer As %String(MAXLEN = "");

/// The IP Address portion of the WebServer
Property WebIPAddr As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {WebIPAddr}=$P({WebServer},"|",1) }, SqlComputed, Transient ];

/// The Port portion of the WebServer
Property WebPort As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {WebPort}=$P({WebServer},"|",2) }, SqlComputed, Transient ];

/// The URL Root portion of the WebServer
Property WebURLRoot As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {WebURLRoot}=$P({WebServer},"|",3) }, SqlComputed, Transient ];

Property DisplayName As %String [ Calculated, Transient ];

Method DisplayNameGet() As %String [ CodeMode = expression, Internal ]
{
..GetDisplayName(..ID, ..Name)
}

ClassMethod GetDisplayName(id As %String, name As %String) As %String [ CodeMode = expression ]
{
"+" _ id _ ":" _ name
}

ClassMethod DisplayNameToId(displayName As %String) As %String [ CodeMode = expression ]
{
$P($P(displayName,":"),"+",2)
}

Method MachineGet() As %String [ CodeMode = expression, Internal ]
{
$P(..Name,"|",1)
}

Method InstanceGet() As %String [ CodeMode = expression, Internal ]
{
$P(..Name,"|",2)
}

Method NamespaceGet() As %String [ CodeMode = expression, Internal ]
{
$P(..Name,"|",3)
}

Method IterationGet() As %String [ CodeMode = expression, Internal ]
{
$P(..Name,"|",4)
}

Method CloneGet() As %String [ CodeMode = expression, Internal ]
{
$P(..Name,"|",5)
}

Method IPAddrGet() As %String [ CodeMode = expression, Internal ]
{
$P(..IPAddress,"|",1)
}

Method PortGet() As %String [ CodeMode = expression, Internal ]
{
$P(..IPAddress,"|",2)
}

Method WebIPAddrGet() As %String [ CodeMode = expression, Internal ]
{
$P(..WebServer,"|",1)
}

Method WebPortGet() As %Integer [ CodeMode = expression, Internal ]
{
$P(..WebServer,"|",2)
}

Method WebURLRootGet() As %String [ CodeMode = expression, Internal ]
{
$P(..WebServer,"|",3)
}

ClassMethod DeleteNodes(pUnusedOnly As %Boolean = 1, Output pNumDeleted As %Integer) As %Status
{
	Quit:'pUnusedOnly ..%DeleteExtent(,.pNumDeleted)
	&sql(Delete From Ens_Enterprise_MsgBank.Node Where ID In (SELECT Distinct NodeId From Ens_Enterprise_MsgBank.MessageHeader))
	Set pNumDeleted=ROWCOUNT
	Quit $S('SQLCODE:$$$OK, 1:$$$ERROR($$$EnsErrGeneral,"Error SQLCODE "_SQLCODE_" in Ens.Enterprise.MsgBank.Node.DeleteNodes()"))
}

ClassMethod GetNodeName(pNodeId As %Integer) As %String
{
	&sql(Select Name Into :tName From Ens_Enterprise_MsgBank.Node Where ID = :pNodeId)
	Quit $S('SQLCODE:tName, 1:"")
}

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set tRef=$$$EXTidlocation($$$pEXT,$$$CurrentClass)
	Set:""=..ID ..ID=$I(@tRef)
	If ..ID<100 {
		Lock +@tRef
		Set ..ID=$G(@tRef)
		If ..ID<100 {
			#; leave 100 open for local machine in case future storage enhancements let us use this global for normal storage as well.
			Set ..ID=101 
			Set @tRef=..ID
		} Else {
			Set ..ID=$I(@tRef)
		}
		Lock -@tRef
	}
	If ..ID>999 Set ..ID="" Quit $$$ERROR($$$EnsErrGeneral,"Cannot save node with IdKey > 999")
	Quit $$$OK
}

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set ..Name=$G(initvalue)
	Quit $$$OK
}

/// Return whatever IP address and port we can glean from all the properties
Method GetWebIPAddrPort() As %String
{
	Set tPort=..WebPort
	Quit:""=tPort ""
	Set tWebIPAddr=..WebIPAddr
	Set:""=tWebIPAddr tWebIPAddr=..IPAddr
	Set:""=tWebIPAddr tWebIPAddr=..Machine
	Quit:""=tWebIPAddr ""
	Set tSep=$S(tWebIPAddr[":":"|",1:":")
	Quit tWebIPAddr_tSep_tPort
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	Do ##class(Ens.Enterprise.MonitorClient).rebuildNodeMap()
	Quit $$$OK
}

ClassMethod %OnAfterDelete(oid As %ObjectIdentity) As %Status [ ServerOnly = 1 ]
{
	Do ##class(Ens.Enterprise.MonitorClient).rebuildNodeMap()
	Quit $$$OK
}

Storage Default
{
<Data name="NodeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>TimeCreated</Value>
</Value>
<Value name="4">
<Value>TimeUpdated</Value>
</Value>
<Value name="5">
<Value>TimeConnected</Value>
</Value>
<Value name="6">
<Value>IPAddress</Value>
</Value>
<Value name="7">
<Value>WebServer</Value>
</Value>
</Data>
<DataLocation>^Ens.EntMsgBank.NodeD</DataLocation>
<DefaultData>NodeDefaultData</DefaultData>
<IdLocation>^Ens.EntMsgBank.NodeD</IdLocation>
<IndexLocation>^Ens.EntMsgBank.NodeI</IndexLocation>
<StreamLocation>^Ens.EntMsgBank.NodeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
