/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDI

IncludeGenerator (Ensemble, %occInclude)

/// Abstract persistent VDoc document wrapper class for arbitrary %DynamicObject instances
/// 
/// This class is used internally by InterSystems IRIS.
Class EnsLib.REST.DynamicObjVDoc Extends (%SerialObject, Ens.VDoc.Interface) [ System = 4 ]
{

/// The in-memory object that VDoc property paths will be evaluated against; may be a DynamicArray or a DynamicObject
Property Obj As %DynamicAbstractObject [ Transient ];

/// The serialized object that will be stored; also serves for lazy FromJSON() as properties of this class need not be deserialized unless needed
Property %JSON As %String(MAXLEN = "") [ Internal ];

Method %OnNew(initvalue As %DynamicObject) As %Status
{
	If $$$IsdefObject(initvalue) && initvalue.%IsA("%DynamicAbstractObject") { Set r%Obj = initvalue }
	ElseIf $Case($E($G(initvalue)), "":1, "[":1, "{":1, :0) { Set i%%JSON = $Get(initvalue) }
	Else { Quit $$$ERROR($$$EnsErrGeneral,"Invalid JSON initializer '"_$E(initvalue,1,77)_"...") }
	Quit $$$OK
}

/// Serialize into JSON from Obj
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	Set:$IsObject(r%Obj) i%%JSON = r%Obj.%ToJSON(), r%Obj = ""
	Quit $$$OK
}

Method ObjSet(pObj As %DynamicAbstractObject) As %Status
{
	If ""=pObj || pObj.%IsA("%DynamicAbstractObject") {
		Set r%Obj = pObj, i%%JSON = ""
	} Else {
		Quit:$Case($E(pObj),"{":0,"[":0,"":0,:1) $$$ERROR($$$EnsErrGeneral,"Invalid JSON: '"_$E(pObj,1,77)_"...")
		Set i%%JSON = pObj, r%Obj = ""
	}
	Quit $$$OK
}

Method ObjGet() As %DynamicObject
{
	Quit:$IsObject(r%Obj)||'$L(i%%JSON) r%Obj
	Do ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(..%JSON,,.obj) ; support parsing unquoted property names
	Do ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.tStream,obj,,,,"aeilow4")
	Set c1 = tStream.Read(1)
	Set r%Obj = $S(c1="{":##class(%DynamicObject).%FromJSON(c1_tStream.Read()),1:##class(%DynamicArray).%FromJSON(c1_tStream.Read()))
	Set i%%JSON = ""
	Quit r%Obj

		Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.tStream,pObj,,,,"aeilow4")  Quit:$$$ISERR(tSC) tSC
		Set c1 = tStream.Read(1)
		Set r%Obj = $S(c1="{":##class(%DynamicObject).%FromJSON(c1_tStream.Read()),1:##class(%DynamicArray).%FromJSON(c1_tStream.Read()))
		Set i%%JSON = ""
}

Method %DispatchMethod(Method As %String, Args...)
{
	Set tObj=..Obj
	Quit:'$IsObject(tObj) ""
	Quit $method(tObj,Method,Args...)
}

/// Return the value of the designated virtual property.<br>
/// <var>pPropertyPath</var> contains a text expression representing the address within the document of the value of interest.<br>
/// <var>pFormat</var> contains additional context that may be used to influence the form of the result value<br>
/// If no value can be found matching <var>pPropertyPath</var> in the current document an empty string is returned and output argument <var>pStatus</var> returns status information explaining the failure<br>
/// This is implemented by the document subclass.
Method GetValueAt(pPropertyPath As %String, pFormat As %String = "", Output pStatus As %Status) As %String
{
#define MinNum -1.5e308
#define MaxNum 1.5e308
	Set pStatus=$$$OK
	Set tVal = ..Obj
	Quit:'$IsObject(tVal) ""
	Set tPath=$Replace(pPropertyPath,".(",$C(0))
	Set tPath=$Replace(tPath,"(",".(")
	Set tPath=$Replace(tPath,$C(0),".(")
	Set listProps = $ListFromString(tPath,".")
	Set p=0  While $ListNext(listProps,p,tProp) { Set iProp=$I(iProp)
		If '$IsObject(tVal) {
			Set pStatus = $$$ERROR($$$EnsErrGeneral,"No parent object found for property '"_tProp_"'")
			Return ""
		}
		Set:"*"=$E(tProp) tProp="("_tProp_")"
		If "("=$E(tProp) {
			Set idx = $E(tProp,2,*-1)
			If "*"=$E(idx)||("""*"=$E(idx,1,2)) {
				Set:"""*"""=$E(idx,1,3) $E(idx,1,3) = "*" ; handle "*"-1 case
				Set:"""*"=$E(idx,1,2) idx = $E(idx,2,*-1) ; handle "*-1" and "*avg" case
				Set idx=$ZStrip(idx,"*W") ; remove whitespace
				Return:'tVal.%IsA("%DynamicArray") ""
				Set count = tVal.%Size()
				If "*"=idx {
					Set px=p
					Return:'$ListNext(listProps,px,tProp) count
					Set idx = count
				} ElseIf $Case($E(idx,2), "-":1, "+":1, :0) {
					Set idx = count - $E(idx,3,*)
					Return:(idx<1)||(idx>count) ""
				} Else {
					Set tSep = $G(pFormat,","), pos = $F(tSep,"separator:"), tSep = $S(pos:$Replace($E(tSep,pos)_$P($E(tSep,pos+1,*),","),"\0",""), 1:tSep)
					For iter=0:1:count-1 {
						Set tPart = tVal.%Get(iter)
						Set:$IsObject(tPart) tPart = ##class(EnsLib.REST.DynamicObjVDoc).%New(tPart).GetValueAt($ListToString($List(listProps,iProp+1,*),"."),.pFormat)
						Set:tPart'="*cat"&&$IsObject(tPart) tPart = ""
						Set tAgg = $Case(idx
										, "*cat": $S($D(tAgg):tAgg_tSep,1:"")_tPart
										, "*min": $$min($G(tAgg),tPart)
										, "*max": $$max($G(tAgg),tPart)
										, "*sum": $G(tAgg)+tPart
										, "*avg": $G(tAgg)+tPart
										, :"*bogus")
					}
					If tAgg="*bogus" { Set pStatus = $$$ERROR($$$GeneralError,"Unrecognized aggregator '"_idx_"' found in property path '"_$ListToString($List(listProps,1,iProp),".")_"'.") }
					Return $Case(idx, "*avg":tAgg/count, "*min":$S(tAgg=$$$MaxNum:"",1:tAgg), "*max":$S(tAgg=$$$MinNum:"",1:tAgg), "*bogus":"", :tAgg)
				}
			}
			Set tVal = tVal.%Get(idx-1)
		} Else {
			Set tVal = $property(tVal,tProp)
		}
	}
	Quit $S($IsObject(tVal)&&(pFormat["obj:json"):tVal.%ToJSON(), 1:tVal)

min(a,b)
	Set:b=""&&$L(a) b=$$$MaxNum
	Set:""=a a=$$$MaxNum
	return $S(b<a:b,1:a)
max(a,b)
	Set:b=""&&$L(a) b=$$$MinNum
	Set:""=a a=$$$MinNum
	return $S(b>a:b,1:a)
}

Storage Default
{
<Data name="DynamicObjVDocState">
<Value name="1">
<Value>%JSON</Value>
</Value>
<Value name="2">
<Value>DocType</Value>
</Value>
<Value name="3">
<Value>TimeCreated</Value>
</Value>
<Value name="4">
<Value>Source</Value>
</Value>
<Value name="5">
<Value>IsMutable</Value>
</Value>
<Value name="6">
<Value>OriginalDocId</Value>
</Value>
<Value name="7">
<Value>UserValues</Value>
</Value>
</Data>
<State>DynamicObjVDocState</State>
<StreamLocation>^EnsLib.REST.DynamicObjVDocS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
