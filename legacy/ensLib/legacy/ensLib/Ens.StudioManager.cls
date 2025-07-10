/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.StudioManager [ Abstract, ClassType = "", Owner = {_PUBLIC}, ProcedureBlock, System = 4 ]
{

Query HostList(pProduction As %String, pCategory As %String) As %Query(ROWSPEC = "ConfigName:%String") [ SqlProc ]
{
}

ClassMethod HostListExecute(ByRef qHandle As %Binary, pProduction As %String, pCategory As %String = "") As %Status
{
	Set tSC=$$$OK
	do {
		Set index=$increment(^IRIS.Temp) Kill ^IRIS.Temp(index)
		Set qHandle=$lb(index,"")
		;
		Set tProdObj=##class(Ens.Config.Production).%OpenId(pProduction)
		If $IsObject(tProdObj)=0 Quit
		;
		For i=1:1:tProdObj.Items.Count() {
			Set tItemObj=tProdObj.Items.GetAt(i)
			If tItemObj.BusinessType()=pCategory Set ^IRIS.Temp(index,i)=tItemObj.Name
		}
	} while (0)
	Quit tSC
}

ClassMethod HostListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = HostListExecute ]
{
	Set index=$list(qHandle,1)
	Set order=$list(qHandle,2)
	Set order=$order(^IRIS.Temp(index,order))
	If order="" Set Row="",AtEnd=1
	Else        Set Row=$lb(^IRIS.Temp(index,order)),AtEnd=$order(^IRIS.Temp(index,order))=""
	Set qHandle=$lb(index,order)
	Quit $$$OK
}

ClassMethod HostListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = HostListExecute ]
{
	Set index=$list(qHandle,1)
	Kill ^IRIS.Temp(index)
	Set qHandle=""
	Quit $$$OK
}

Query ClassList(pCategory As %String = "", pHint As %String = "") As %Query(ROWSPEC = "Name:%String,IconType:%Integer") [ SqlProc ]
{
}

ClassMethod ClassListExecute(ByRef qHandle As %Binary, pCategory As %String = "", pHint As %String = "") As %Status
{
#;
#define Adapters           1
#define InboundAdapters    2
#define OutboundAdapters   3
#;
#define Messages           4
#define Requests           5
#define Responses          6
#;
#define BusinessServices   7
#define BusinessProcesses  8
#define BusinessOperations 9
#;
#define DataTransformation 10
#define Production         11
#define BusinessHost       12
#define Dashboard          13
#define Rule               14

#;
	Set tSC=$$$OK
	do {
		do {
			If pCategory=$$$Adapters           Set super="Ens.Adapter" Quit
			If pCategory=$$$InboundAdapters    Set super="Ens.InboundAdapter",classestoo=1 Quit
			If pCategory=$$$OutboundAdapters   Set super="Ens.OutboundAdapter" Quit
			#;
			If pCategory=$$$Messages           Set super="Ens.MessageBody,EnsLib.EDI.Document" Quit
			If pCategory=$$$Requests           Set classestoo=..findMessages("Request",pHint,"Ens.MessageBody,EnsLib.EDI.Document",.super) Quit
			If pCategory=$$$Responses          Set classestoo=..findMessages("Response",pHint,"Ens.MessageBody,EnsLib.EDI.Document",.super) Quit
			#;
			If pCategory=$$$BusinessServices   Set super="Ens.BusinessService" Quit
			If pCategory=$$$BusinessProcesses  Set super="Ens.BusinessProcess" Quit
			If pCategory=$$$BusinessOperations Set super="Ens.BusinessOperation" Quit
			#;
			If pCategory=$$$DataTransformation Set super="Ens.DataTransform" Quit
			If pCategory=$$$Production         Set super="Ens.Production" Quit
			If pCategory=$$$BusinessHost       Set super="Ens.Host" Quit
			If pCategory=$$$Dashboard          Set super="Ens.Dashboard" Quit
			If pCategory=$$$Rule               Set super="Ens.Rule.Definition" Quit
			#;
			#; Unknown category
			#; 
			Set super=""
		} while (0)
		
		If super="" {
			Set tSC=$$$ERROR($$$GeneralError,"Category '"_pCategory_"' is invalid.")
			Quit
		}
		
		for i=1:1:$l(super,",") {
			set class=$p(super,",",i)
			kill list
			
			// Note: GetAllDerivedClasses doesn't include the [super] class itself.
			Set tSC=$$GetAllDerivedClasses^%occLibrary(class,.list) 
			If $$$ISERR(tSC) Quit
			merge fulllist=list
			
			Set:+$G(classestoo) fulllist(class)=""
		}

		Set class="" for  {
			Set class=$o(fulllist(class)) Quit:class=""
			If $e(class)="%" Kill fulllist(class)
			If +$$$defClassKeyGet(class,$$$cCLASShidden) Kill fulllist(class)
		}
		If pCategory=$$$Rule {
			Kill fulllist("Ens.Rule.RuleSet")
			Kill fulllist("Ens.Rule.Router.RoutingRule")
		}
	
		Set index=$increment(^IRIS.Temp) Merge ^IRIS.Temp(index)=fulllist Set qHandle=$lb(index,"")
	} while (0)
	Quit tSC
}

ClassMethod ClassListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ClassListExecute ]
{
	Set index=$list(qHandle,1)
	Set class=$list(qHandle,2)
	Set class=$order(^IRIS.Temp(index,class))
	If class="" Set Row="",AtEnd=1
	Else        Set Row=$lb(class)_$listbuild($select($isobject($get(%SourceControl))=1:$select(%SourceControl.IconStatus\2=1:%SourceControl.ItemIconState(class),1:0),1:0)),AtEnd=$order(^IRIS.Temp(index,class))=""
	Set qHandle=$lb(index,class)
	Quit $$$OK
}

ClassMethod ClassListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ClassListExecute ]
{
	Set index=$list(qHandle,1)
	Kill ^IRIS.Temp(index)
	Set qHandle=""
	Quit $$$OK
}

/// Helper method to dig out requests and responses for a particular class (business operation or business process)
ClassMethod findMessages(pType As %String, pClass As %String, pDefault As %String, ByRef pResults As %String) As %Boolean [ Internal ]
{
	#dim tMessages As %List
	#dim tResult As %String
	#dim tI As %Integer
	
	Set $ZT="Trap"
	Set tMessages = $ZOBJCLASSMETHOD(pClass,"Get"_pType_"ClassList")
	For tI=1:1:$LL(tMessages) {
		Set pResults=$S(tI>1:pResults_",",1:"")_$LI(tMessages,tI)
	}
	Quit 1
Trap
	// Could be <CLASS DOES NOT EXIST> or <METHOD DOES NOT EXIST>
	Set pResults = pDefault
	Quit 0
}

}
