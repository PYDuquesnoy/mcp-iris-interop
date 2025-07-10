/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A header class that records raw Adapter Inputs and Outputs
Class Ens.Util.IOLogObj Extends Ens.Util.IOLog [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Property InObject As %Persistent [ Transient ];

Property OutObject As %Persistent [ Transient ];

Property InObjectId As %RawString;

Property OutObjectId As %RawString;

Method IsEmpty() As %Boolean
{
	Quit ""=..%Id()&&'$IsObject(..InObject)&&'$IsObject(..OutObject)
}

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
	If $IsObject(..InObject) {
		Set ..InObjectId=..InObject.%Id()
		If ""=..InObjectId {
			Do ..InObject.%Save()
			Set ..InObjectId=..InObject.%Id()
		}
	}
	If $IsObject(..OutObject) {
		Set ..OutObjectId=..OutObject.%Id()
		If ""=..OutObjectId {
			Do ..OutObject.%Save()
			Set ..OutObjectId=..OutObject.%Id()
		}
	}
	Quit $$$OK
}

Method %OnOpen() As %Status [ Private ]
{
	Set:((""'=..InObjectClass)&&(""'=..InObjectId)) ..InObject=$zobjclassmethod(..InObjectClass,"%OpenId",..InObjectId)
	Set:((""'=..OutObjectClass)&&(""'=..OutObjectId)) ..OutObject=$zobjclassmethod(..OutObjectClass,"%OpenId",..OutObjectId)
	Quit $$$OK
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status
{
	Set tId=$$$oidPrimary(oid)
	&sql(Select InObjectClass,OutObjectClass,InObjectId,OutObjectId Into :tInObjectClass,:tOutObjectClass,:tInObjectId,:tOutObjectId From Ens_Util.IOLogObj where ID = :tId)
	Quit:SQLCODE $$$OK

	#; delete object if no header references it
	Set $ZT="Trap1", tHdrId="" &sql(Select ID Into :tHdrId From Ens.MessageHeader where MessageBodyClassName = :tInObjectClass AND MessageBodyId = :tInObjectId)
	Goto:SQLCODE'=100 Trap1
	Do $zobjclassmethod(tInObjectClass,"%DeleteId",tInObjectId)
Trap1
	Set $ZT="Trap2", tHdrId="" &sql(Select ID Into :tHdrId From Ens.MessageHeader where MessageBodyClassName = :tOutObjectClass AND MessageBodyId = :tOutObjectId)
	Goto:SQLCODE'=100 Trap2
	Do $zobjclassmethod(tOutObjectClass,"%DeleteId",tOutObjectId)
Trap2
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New tInObjectClass,tOutObjectClass,tInObjectId,tOutObjectId
	Set tInObjectClass={InObjectClass}, tInObjectId={InObjectId},
		tOutObjectClass={OutObjectClass}, tOutObjectId={OutObjectId}

	#; delete object if no header references it
	Set $ZT="Trap1", tHdrId="" &sql(Select ID Into :tHdrId From Ens.MessageHeader where MessageBodyClassName = :tInObjectClass AND MessageBodyId = :tInObjectId)
	Goto:SQLCODE'=100 Trap1
	Do $zobjclassmethod(tInObjectClass,"%DeleteId",tInObjectId)
Trap1
	Set $ZT="Trap2", tHdrId="" &sql(Select ID Into :tHdrId From Ens.MessageHeader where MessageBodyClassName = :tOutObjectClass AND MessageBodyId = :tOutObjectId)
	Goto:SQLCODE'=100 Trap2
	Do $zobjclassmethod(tOutObjectClass,"%DeleteId",tOutObjectId)
Trap2
	Quit
}

Storage Default
{
<Data name="IOLogObjDefaultData">
<Subscript>"IOLogObj"</Subscript>
<Value name="1">
<Value>InObjectID</Value>
</Value>
<Value name="2">
<Value>OutObjectID</Value>
</Value>
<Value name="3">
<Value>InObjectId</Value>
</Value>
<Value name="4">
<Value>OutObjectId</Value>
</Value>
</Data>
<DefaultData>IOLogObjDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
