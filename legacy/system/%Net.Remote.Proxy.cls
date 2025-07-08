/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Remote.Proxy Extends %RegisteredObject [ System = 3 ]
{

Property Gateway As %Net.Remote.Gateway;

Property Eager As %Boolean;

Property SyncGet As %ArrayOfDataTypes;

Property SyncSet As %ArrayOfDataTypes;

Property %gateway As %Net.Remote.Gateway;

Method %SetEager(eager As %Boolean)
{
	Set ..Eager=eager
}

Method %FetchObject()
{
	Quit:'..Eager
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this,18)
	Set x=$zobjexport($i(..%gateway.SequenceNumber,2),1)
	Set x=$zobjexport("YF",8)
	do ..%GetResponse(..%gateway,"YF",.orefCache)
	Set count=$zobjexport(12)
	Do ..SyncGet.Clear()
	For i=1:1:count {
		Set name=$zobjexport(12)
		Set type=$zobjexport(12)
		// this is datatype
		If (type = 0) {
			Set value=$zobjexport(12)
		// this is an oref
		} ElseIf (type = 1) {
			Set value=$zobjref($zobjexport(12))
		// this is an array
		} ElseIf (type = 2) {
			Set value=..%ReadArrayArgument(..%gateway)
		}
		Do ..SyncGet.SetAt(value,name)
	}
	do ..%PostInvokeNew(..%gateway)
	quit
}

Method %SendObject()
{
	Quit:'..Eager
	If ..SyncSet.Count()=0 {
		Quit
	}
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this,18)
	Set x=$zobjexport(..SyncSet.Count(),18)
	Set name=..SyncSet.Next()
	While (name'="") {
		Set value=..SyncSet.GetAt(name)
		Set x=$zobjexport(name,18)
		If ($isobject(value)) {
			// see if this is an array
			If (value.%IsA("%GlobalBinaryStream")) {
				//Set x=$zobjexport(2,18)
				Do ..%WriteArray(..%gateway,"[B",value)
			} ElseIf (value.%IsA("%GlobalCharacterStream")) {
				//Set x=$zobjexport(2,18)
				Do ..%WriteArray(..%gateway,"[C",value)
			} ElseIf (value.%IsA("%ListOfDataTypes")) {
				//Set x=$zobjexport(2,18)
				Do ..%WriteArray(..%gateway,"other",value)
			// this is an oref
			} Else {	
				//Set x=$zobjexport(1,18)
				Set x=$zobjexport(value,18)
			}
		// this is datatype
		} Else {
			//Set x=$zobjexport(0,18)
			Set x=$zobjexport(value,18)
		}
		Set name=..SyncSet.Next(name)
	}
	Set x=$zobjexport($i(..%gateway.SequenceNumber,2),1)
	Set x=$zobjexport("YS",8)
	do ..%GetResponse(..%gateway,"YS",.orefCache)
	do ..%PostInvokeNew(..%gateway)
	Do ..SyncSet.Clear()
}

Method %OnClose() As %Status
{
	If ($isobject(..%gateway)=1) {
		set ..%gateway.ClosedProxies($this_"") = ""
	}
	Quit $$$OK
}

Method %RegisterOnDestructCallback(callbackName As %String) As %Status [ Final ]
{
	Quit:..%gateway.Closed $$$OK
	Try {
		do ..%PreInvokeNew(..%gateway)
		Set x=$zobjexport($this,18)
		Set x=$zobjexport(callbackName,18)
		Set x=$zobjexport($i(..%gateway.SequenceNumber,2),1)
		Set x=$zobjexport("YR",8)
		do ..%GetResponse(..%gateway,"YR",.orefCache)
		do ..%PostInvokeNew(..%gateway)
	} Catch exception {
		Set status=..%gateway.%SetStatus(exception)
	}
	do ..%PostInvokeNew(..%gateway)
	Quit status
}

ClassMethod %GuessType(par As %ObjectHandle) [ Final ]
{
	If $isobject(par) {
		Set type=$classname(par)
	} ElseIf $lb(par_"")=$lb(par) {
		Set type="%String"
	} ElseIf $lb(+par)=$lb(par) {
		If $extract($lb(par),2)=6 {
			Set type="%Float" 
		} Else { 
			Set type="%Integer" 
		}
	} Else {
		Set type="%String"
	}
	Return type
}

ClassMethod %OverloadWrite(gateway As %Net.Remote.Gateway, par As %ObjectHandle) [ Final ]
{
	Set type = ..%GuessType(par)
	If ($isobject(par) && par.%IsA("%Collection.AbstractList")) {	
		Set elem = par.GetAt(1)
		Set elemType = ..%GuessType(elem)
		Set type = "%Collection.AbstractList"_":"_elemType
		Set x=$zobjexport(type,18)
		Do ..%WriteArray(gateway, "other", par)
		Quit
	}
	ElseIf (type="%GlobalBinaryStream")||(type="%GlobalCharacterStream")||(type="%Library.GlobalBinaryStream")||(type="%Library.GlobalCharacterStream") {
		Set x=$zobjexport("%"_$E(type,10,100),18)
	    Do ..%WriteGlobalArray(gateway,type,par)
		Quit	
	}
	Set x=$zobjexport(type,18)
	Set x=$zobjexport(par,18)
}

ClassMethod %GetObject(gateway As %Net.Remote.Gateway, ByRef orefCache) As %ObjectHandle [ Final ]
{
    Set x=$zobjexport($i(gateway.SequenceNumber,2),1)
	Set x=$zobjexport("Y1",8)
	do ..%GetResponse(gateway,"Y1",.orefCache)
	If '$zobjexport(17) Quit $C(1)
	Set kind=$zobjexport(12)
	Set x=$zobjexport(12)
	If ..%IsDataType(kind) {
		Quit x
	}
	// One-dimensional array
	If (kind="%ListOfDataTypes") {
		Set size=x
		If (size=-1) {
			Quit ""
		}
		Set x=##class(%ListOfDataTypes).%New()
   		For i=1:1:size {
			Set value=$zobjexport(12)
    		Do x.Insert(value)
   		}
	} ElseIf (kind="%ListOfObjects") {
		Set size=x
		If (size=-1) {
			Quit ""
		}
		Set x=##class(%ListOfObjects).%New()
   		For i=1:1:size {
			Set value=$zobjref($zobjexport(12))
    		Do x.Insert(value)
   		}
	} ElseIf ((kind="%GlobalBinaryStream")||(kind="%GlobalCharacterStream")||(kind="%Library.GlobalBinaryStream")||(kind="%Library.GlobalCharacterStream")) {
		Set size=x
		If (size=-1) {
			Quit ""
		}
		If (kind="%GlobalBinaryStream")||(kind="%Library.GlobalBinaryStream") {
			Set stream=##class(%GlobalBinaryStream).%New()
		} Else {
			Set stream=##class(%GlobalCharacterStream).%New()
			Set x=$zu(96,18,2,"UTF8"),settoUTF8=1
		}
		If (size=0) {
			Do stream.Write("")
		} Else {
			For {
				Set data=$zobjexport($S(size>32000:32000,1:size),13)
				Do stream.Write(data)
				Set size=size-$L(data)
				Quit:size=0
			}
		}
		if $g(settoUTF8) Set x=$zu(96,18,2,"RAW")
		Quit stream
	} ElseIf '..%IsDataType(kind) {
		Set x=$zobjref(x)
	}
    Quit x
}

ClassMethod %WriteArray(gateway As %Net.Remote.Gateway, type As %String, array As %ObjectHandle) [ Final ]
{
    if ((type="[B")||(type="[C")) {
	    Do ..%WriteGlobalArray(gateway,type,array)
		Quit	
	}
	Set x=$zobjexport(type,18)
	If (array="") {
		Set x=$zobjexport(-1,18)
		Quit
	}
	Set x=$zobjexport(array.Count(),18)
	For i=1:1:array.Count() {
		Set x=$zobjexport(array.GetAt(i),18)
	}
}

ClassMethod %WriteGlobalArray(gateway As %Net.Remote.Gateway, type As %String, array As %ObjectHandle) [ Final ]
{
	Set size=array.SizeGet(),total=0
	Do array.Rewind()
	If (type="[B")||(type="%GlobalBinaryStream")||(type="%Library.GlobalBinaryStream") {
		Set x=$zobjexport("byte",18)
		Set x=$zobjexport(size,18)
		For  Quit:array.AtEnd  Set chunk=$select(size-total>32000:32000,1:size-total) Set x=$zobjexport(array.Read(chunk),5) Set total=total+chunk Quit:total=size
	} Else {
		Set x=$zobjexport("char",18)
		Set x=$zobjexport(size,18)
		Set x=$zu(96,18,2,"UTF8") 
		For  Quit:array.AtEnd  Set chunk=$select(size-total>32000:32000,1:size-total) Set x=$zobjexport(array.Read(chunk),5) Set total=total+chunk Quit:total=size
		Set x=$zobjexport($C(0),5)
		Set x=$zu(96,18,2,"RAW")
	}
	Do array.Rewind()
}

ClassMethod %ReadArrayArgument(gateway As %Net.Remote.Gateway) As %ObjectHandle [ Final ]
{
	Set kind=$zobjexport(12)
	Set size=$zobjexport(12)
	If (size=-1) {
		Quit ""
	}
	If ((kind="%GlobalBinaryStream") || (kind="%Library.GlobalBinaryStream") || (kind="%GlobalCharacterStream") || (kind="%Library.GlobalCharacterStream")) {
		Quit ..%ReadGlobalArray(kind,size)
	}
	If (kind="%ListOfDataTypes") {
		Set x=##class(%ListOfDataTypes).%New()
   		For i=1:1:size {
			Set value=$zobjexport(12)
    		Do x.Insert(value)
   		}
   		Quit x
	} ElseIf (kind="%ListOfObjects") {
		Set x=##class(%ListOfObjects).%New()
   		For i=1:1:size {
			Set value=$zobjref($zobjexport(12))
    		Do x.Insert(value)
   		}
		Quit x
	}
	Set stream=##class(%GlobalBinaryStream).%New()
	If (size=0) {
		Do stream.Write("")
	} Else {
		For {
			Set data=$zobjexport($S(size>32000:32000,1:size),13)
			Do stream.Write(data)
			Set size=size-$L(data)
			Quit:size=0
		}
	}
	Quit stream
}

ClassMethod %ReadGlobalArray(kind As %String, size As %Integer)
{
	If (kind="%GlobalBinaryStream")||(kind="%Library.GlobalBinaryStream") {
		Set stream=##class(%GlobalBinaryStream).%New()
	} ElseIf (kind="%GlobalCharacterStream")||(kind="%Library.GlobalCharacterStream") {
		Set stream=##class(%GlobalCharacterStream).%New()
		Set x=$zu(96,18,2,"UTF8") 
	}
	If (size=0) {
		Do stream.Write("")
	} Else {
		For {
			Set data=$zobjexport($S(size>32000:32000,1:size),13)
			Do stream.Write(data)
			Set size=size-$L(data)
			Quit:size=0
		}
	}
	If (kind="%GlobalCharacterStream") {
		Set x=$zu(96,18,2,"RAW") 
	}
	Quit stream
}

ClassMethod %IsDataType(type As %String) As %Boolean [ Final ]
{
   Quit (type="%Boolean")!(type="%TinyInt")!
    	(type="%Numeric")!(type="%Float")!(type="%Double")!
    	(type="%Integer")!(type="%SmallInt")!
    	(type="%String")!(type="%Date")!
    	(type="%Time")!(type="%TimeStamp")
}

Method %Get(propertyName As %String) As %ObjectHandle [ Final ]
{
	If (..Eager=1) {
		Set propertyName=$E(propertyName,4,9999)
		Set x=..SyncSet.GetAt(propertyName)
		Quit:x'="" x
		Quit ..SyncGet.GetAt(propertyName)
	}
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this_"",18)
	Set x=$zobjexport(propertyName,18)
	Set x=..%GetObject(..%gateway)
	do ..%PostInvokeNew(..%gateway)
	Quit x
}

ClassMethod %GetStatic(gateway As %Net.Remote.Gateway, propertyName As %String, className As %ObjectHandle) As %ObjectHandle [ Final ]
{
	do ..%PreInvokeNew(gateway)
	Set x=$zobjexport(className,18)
	Set x=$zobjexport(propertyName,18)
	Set x=..%GetObject(gateway)
	do ..%PostInvokeNew(gateway)
	Quit x
}

Method %Set(propertyName As %String, value As %ObjectHandle, arrayType As %String) [ Final ]
{
	If ..Eager=1 {
		Do ..SyncSet.SetAt(value,$E(propertyName,4,9999))
		Quit
	}
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this_"",18)
	Set x=$zobjexport(propertyName,18)
	If ($D(arrayType)) {
		Do ..%WriteArray(..%gateway,arrayType,value)
	} Else {
		Set x=$zobjexport(value,18)
	}
	Set x=$zobjexport($i(..%gateway.SequenceNumber,2),1)
	Set x=$zobjexport("Y1",8)
	do ..%GetResponse(..%gateway,"Y1",.orefCache)
	do ..%PostInvokeNew(..%gateway)
	quit
}

ClassMethod %SetStatic(gateway As %Net.Remote.Gateway, propertyName As %String, value As %ObjectHandle, className As %ObjectHandle, arrayType As %String) [ Final ]
{
	do ..%PreInvokeNew(gateway)
	Set x=$zobjexport(className,18)
	Set x=$zobjexport(propertyName,18)
	If ($D(arrayType)) {
		Do ..%WriteArray(gateway,arrayType,value)
	} Else {
		Set x=$zobjexport(value,18)
	}
	Set x=$zobjexport($i(gateway.SequenceNumber,2),1)
	Set x=$zobjexport("Y1",8)
	do ..%GetResponse(gateway,"Y1",.orefCache)
	do ..%PostInvokeNew(gateway)
}

Method %I(methodName As %String, ByRef p1 As %ObjectHandle, ByRef p2 As %ObjectHandle, ByRef p3 As %ObjectHandle, ByRef p4 As %ObjectHandle, ByRef p5 As %ObjectHandle) [ Final ]
{
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this_"",18)
	Set x=$zobjexport(methodName,18)
	Set x=$zobjexport(-1,18)
	Set:$D(p1) x=$zobjexport(p1,18)
	Set:$D(p2) x=$zobjexport(p2,18)
	Set:$D(p3) x=$zobjexport(p3,18)
	Set:$D(p4) x=$zobjexport(p4,18)
	Set:$D(p5) x=$zobjexport(p5,18)
	Set x=$zobjexport($i(..%gateway.SequenceNumber,2),1)
	Set x=$zobjexport("Y1",8)
	do ..%GetResponse(..%gateway,"Y1",.orefCache)
	If $D(p1) Set:$zobjexport(17) p1=..%ReadArrayArgument(..%gateway)
	If $D(p2) Set:$zobjexport(17) p2=..%ReadArrayArgument(..%gateway)
	If $D(p3) Set:$zobjexport(17) p3=..%ReadArrayArgument(..%gateway)
	If $D(p4) Set:$zobjexport(17) p4=..%ReadArrayArgument(..%gateway)
	If $D(p5) Set:$zobjexport(17) p5=..%ReadArrayArgument(..%gateway)
	do ..%PostInvokeNew(..%gateway)
}

Method %IR(methodName As %String, ByRef p1 As %ObjectHandle, ByRef p2 As %ObjectHandle, ByRef p3 As %ObjectHandle, ByRef p4 As %ObjectHandle, ByRef p5 As %ObjectHandle) As %ObjectHandle [ Final ]
{
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this_"",18)
	Set x=$zobjexport(methodName,18)
	Set x=$zobjexport(-1,18)
	Set:$D(p1) x=$zobjexport(p1,18)
	Set:$D(p2) x=$zobjexport(p2,18)
	Set:$D(p3) x=$zobjexport(p3,18)
	Set:$D(p4) x=$zobjexport(p4,18)
	Set:$D(p5) x=$zobjexport(p5,18)
	Set x=..%GetObject(..%gateway,.orefCache)
	If $D(p1) Set:$zobjexport(17) p1=..%ReadArrayArgument(..%gateway)
	If $D(p2) Set:$zobjexport(17) p2=..%ReadArrayArgument(..%gateway)
	If $D(p3) Set:$zobjexport(17) p3=..%ReadArrayArgument(..%gateway)
	If $D(p4) Set:$zobjexport(17) p4=..%ReadArrayArgument(..%gateway)
	If $D(p5) Set:$zobjexport(17) p5=..%ReadArrayArgument(..%gateway)
	do ..%PostInvokeNew(..%gateway)
	Quit x
}

Method %IOL(methodName As %String, ByRef p1 As %ObjectHandle, ByRef p2 As %ObjectHandle, ByRef p3 As %ObjectHandle, ByRef p4 As %ObjectHandle, ByRef p5 As %ObjectHandle) [ Final ]
{
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this_"",18)
	Set x=$zobjexport(methodName,18)
	Set x=$zobjexport($D(p1)+$D(p2)+$D(p3)+$D(p4)+$D(p5),18)
	Do:$D(p1) ..%OverloadWrite(..%gateway,p1)
	Do:$D(p2) ..%OverloadWrite(..%gateway,p2)
	Do:$D(p3) ..%OverloadWrite(..%gateway,p3)
	Do:$D(p4) ..%OverloadWrite(..%gateway,p4)
	Do:$D(p5) ..%OverloadWrite(..%gateway,p5)
	Set x=$zobjexport($i(..%gateway.SequenceNumber,2),1)
	Set x=$zobjexport("Y1",8)
	do ..%GetResponse(..%gateway,"Y1",.orefCache)
	If $D(p1) Set:$zobjexport(17) p1=..%ReadArrayArgument(..%gateway)
	If $D(p2) Set:$zobjexport(17) p2=..%ReadArrayArgument(..%gateway)
	If $D(p3) Set:$zobjexport(17) p3=..%ReadArrayArgument(..%gateway)
	If $D(p4) Set:$zobjexport(17) p4=..%ReadArrayArgument(..%gateway)
	If $D(p5) Set:$zobjexport(17) p5=..%ReadArrayArgument(..%gateway)
	do ..%PostInvokeNew(..%gateway)
}

Method %IOLR(methodName As %String, ByRef p1 As %ObjectHandle, ByRef p2 As %ObjectHandle, ByRef p3 As %ObjectHandle, ByRef p4 As %ObjectHandle, ByRef p5 As %ObjectHandle) As %ObjectHandle [ Final ]
{
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this_"",18)
	Set x=$zobjexport(methodName,18)
	Set x=$zobjexport($D(p1)+$D(p2)+$D(p3)+$D(p4)+$D(p5),18)
	Do:$D(p1) ..%OverloadWrite(..%gateway,p1)
	Do:$D(p2) ..%OverloadWrite(..%gateway,p2)
	Do:$D(p3) ..%OverloadWrite(..%gateway,p3)
	Do:$D(p4) ..%OverloadWrite(..%gateway,p4)
	Do:$D(p5) ..%OverloadWrite(..%gateway,p5)
	Set x=..%GetObject(..%gateway,.orefCache)
	If $D(p1) Set:$zobjexport(17) p1=..%ReadArrayArgument(..%gateway)
	If $D(p2) Set:$zobjexport(17) p2=..%ReadArrayArgument(..%gateway)
	If $D(p3) Set:$zobjexport(17) p3=..%ReadArrayArgument(..%gateway)
	If $D(p4) Set:$zobjexport(17) p4=..%ReadArrayArgument(..%gateway)
	If $D(p5) Set:$zobjexport(17) p5=..%ReadArrayArgument(..%gateway)
	do ..%PostInvokeNew(..%gateway)
	Quit x
}

/// static methods
ClassMethod %S(gateway As %Net.Remote.Gateway, methodName As %String, className As %ObjectHandle, ByRef p1 As %ObjectHandle, ByRef p2 As %ObjectHandle, ByRef p3 As %ObjectHandle, ByRef p4 As %ObjectHandle, ByRef p5 As %ObjectHandle) [ Final ]
{
	do ..%PreInvokeNew(gateway)
	Set x=$zobjexport(className,18)
	Set x=$zobjexport(methodName,18)
	Set x=$zobjexport(-1,18)
	Set:$D(p1) x=$zobjexport(p1,18)
	Set:$D(p2) x=$zobjexport(p2,18)
	Set:$D(p3) x=$zobjexport(p3,18)
	Set:$D(p4) x=$zobjexport(p4,18)
	Set:$D(p5) x=$zobjexport(p5,18)
	Set x=$zobjexport($i(gateway.SequenceNumber,2),1)
	Set x=$zobjexport("Y1",8)
	do ..%GetResponse(gateway,"Y1",.orefCache)
	If $D(p1) Set:$zobjexport(17) p1=..%ReadArrayArgument(gateway)
	If $D(p2) Set:$zobjexport(17) p2=..%ReadArrayArgument(gateway)
	If $D(p3) Set:$zobjexport(17) p3=..%ReadArrayArgument(gateway)
	If $D(p4) Set:$zobjexport(17) p4=..%ReadArrayArgument(gateway)
	If $D(p5) Set:$zobjexport(17) p5=..%ReadArrayArgument(gateway)
	do ..%PostInvokeNew(gateway)
}

ClassMethod %SR(gateway As %Net.Remote.Gateway, methodName As %String, className As %ObjectHandle, ByRef p1 As %ObjectHandle, ByRef p2 As %ObjectHandle, ByRef p3 As %ObjectHandle, ByRef p4 As %ObjectHandle, ByRef p5 As %ObjectHandle) As %ObjectHandle [ Final ]
{
	do ..%PreInvokeNew(gateway)
	Set x=$zobjexport(className,18)
	Set x=$zobjexport(methodName,18)
	Set x=$zobjexport(-1,18)
	Set:$D(p1) x=$zobjexport(p1,18)
	Set:$D(p2) x=$zobjexport(p2,18)
	Set:$D(p3) x=$zobjexport(p3,18)
	Set:$D(p4) x=$zobjexport(p4,18)
	Set:$D(p5) x=$zobjexport(p5,18)
	Set x=..%GetObject(gateway,.orefCache)
	If $D(p1) Set:$zobjexport(17) p1=..%ReadArrayArgument(gateway)
	If $D(p2) Set:$zobjexport(17) p2=..%ReadArrayArgument(gateway)
	If $D(p3) Set:$zobjexport(17) p3=..%ReadArrayArgument(gateway)
	If $D(p4) Set:$zobjexport(17) p4=..%ReadArrayArgument(gateway)
	If $D(p5) Set:$zobjexport(17) p5=..%ReadArrayArgument(gateway)
	do ..%PostInvokeNew(gateway)
	Quit x
}

ClassMethod %SOL(gateway As %Net.Remote.Gateway, methodName As %String, className As %ObjectHandle, ByRef p1 As %ObjectHandle, ByRef p2 As %ObjectHandle, ByRef p3 As %ObjectHandle, ByRef p4 As %ObjectHandle, ByRef p5 As %ObjectHandle) [ Final ]
{
	do ..%PreInvokeNew(gateway)
	Set x=$zobjexport(className,18)
	Set x=$zobjexport(methodName,18)
	Set x=$zobjexport($D(p1)+$D(p2)+$D(p3)+$D(p4)+$D(p5),18)
	Do:$D(p1) ..%OverloadWrite(gateway,p1)
	Do:$D(p2) ..%OverloadWrite(gateway,p2)
	Do:$D(p3) ..%OverloadWrite(gateway,p3)
	Do:$D(p4) ..%OverloadWrite(gateway,p4)
	Do:$D(p5) ..%OverloadWrite(gateway,p5)
	Set x=$zobjexport($i(gateway.SequenceNumber,2),1)
	Set x=$zobjexport("Y1",8)
	do ..%GetResponse(gateway,"Y1",.orefCache)
	If $D(p1) Set:$zobjexport(17) p1=..%ReadArrayArgument(gateway)
	If $D(p2) Set:$zobjexport(17) p2=..%ReadArrayArgument(gateway)
	If $D(p3) Set:$zobjexport(17) p3=..%ReadArrayArgument(gateway)
	If $D(p4) Set:$zobjexport(17) p4=..%ReadArrayArgument(gateway)
	If $D(p5) Set:$zobjexport(17) p5=..%ReadArrayArgument(gateway)
	do ..%PostInvokeNew(gateway)
}

ClassMethod %SOLR(gateway As %Net.Remote.Gateway, methodName As %String, className As %ObjectHandle, ByRef p1 As %ObjectHandle, ByRef p2 As %ObjectHandle, ByRef p3 As %ObjectHandle, ByRef p4 As %ObjectHandle, ByRef p5 As %ObjectHandle) As %ObjectHandle [ Final ]
{
	do ..%PreInvokeNew(gateway)
	Set x=$zobjexport(className,18)
	Set x=$zobjexport(methodName,18)
	Set x=$zobjexport($D(p1)+$D(p2)+$D(p3)+$D(p4)+$D(p5),18)
	Do:$D(p1) ..%OverloadWrite(gateway,p1)
	Do:$D(p2) ..%OverloadWrite(gateway,p2)
	Do:$D(p3) ..%OverloadWrite(gateway,p3)
	Do:$D(p4) ..%OverloadWrite(gateway,p4)
	Do:$D(p5) ..%OverloadWrite(gateway,p5)
	Set x=..%GetObject(gateway,.orefCache)
	If $D(p1) Set:$zobjexport(17) p1=..%ReadArrayArgument(gateway)
	If $D(p2) Set:$zobjexport(17) p2=..%ReadArrayArgument(gateway)
	If $D(p3) Set:$zobjexport(17) p3=..%ReadArrayArgument(gateway)
	If $D(p4) Set:$zobjexport(17) p4=..%ReadArrayArgument(gateway)
	If $D(p5) Set:$zobjexport(17) p5=..%ReadArrayArgument(gateway)
	do ..%PostInvokeNew(gateway)
	Quit x
}

Method %Constructor(gateway As %ObjectHandle, className As %String, count As %Integer, p1 As %ObjectHandle, p2 As %ObjectHandle, p3 As %ObjectHandle, p4 As %ObjectHandle, p5 As %ObjectHandle, p6 As %ObjectHandle, p7 As %ObjectHandle, p8 As %ObjectHandle, p9 As %ObjectHandle, p10 As %ObjectHandle, p11 As %ObjectHandle, p12 As %ObjectHandle, p13 As %ObjectHandle, p14 As %ObjectHandle, p15 As %ObjectHandle, p16 As %ObjectHandle, p17 As %ObjectHandle, p18 As %ObjectHandle, p19 As %ObjectHandle, p20 As %ObjectHandle, p21 As %ObjectHandle, p22 As %ObjectHandle, p23 As %ObjectHandle, p24 As %ObjectHandle, p25 As %ObjectHandle) As %Status
{
	Quit:'$D(gateway) $$$OK
	Set ..%gateway=gateway
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this_"",18)
	Set x=$zobjexport(className,18)
	Set x=$zobjexport(count,18)
	Do:$D(p1) ..%OverloadWrite(..%gateway,p1)
	Do:$D(p2) ..%OverloadWrite(..%gateway,p2)
	Do:$D(p3) ..%OverloadWrite(..%gateway,p3)
	Do:$D(p4) ..%OverloadWrite(..%gateway,p4)
	Do:$D(p5) ..%OverloadWrite(..%gateway,p5)
	Do:$D(p6) ..%OverloadWrite(..%gateway,p6)
	Do:$D(p7) ..%OverloadWrite(..%gateway,p7)
	Do:$D(p8) ..%OverloadWrite(..%gateway,p8)
	Do:$D(p9) ..%OverloadWrite(..%gateway,p9)
	Do:$D(p10) ..%OverloadWrite(..%gateway,p10)
	Do:$D(p11) ..%OverloadWrite(..%gateway,p11)
	Do:$D(p12) ..%OverloadWrite(..%gateway,p12)
	Do:$D(p13) ..%OverloadWrite(..%gateway,p13)
	Do:$D(p14) ..%OverloadWrite(..%gateway,p14)
	Do:$D(p15) ..%OverloadWrite(..%gateway,p15)
	Do:$D(p16) ..%OverloadWrite(..%gateway,p16)
	Do:$D(p17) ..%OverloadWrite(..%gateway,p17)
	Do:$D(p18) ..%OverloadWrite(..%gateway,p18)
	Do:$D(p19) ..%OverloadWrite(..%gateway,p19)
	Do:$D(p20) ..%OverloadWrite(..%gateway,p20)
	Do:$D(p21) ..%OverloadWrite(..%gateway,p21)
	Do:$D(p22) ..%OverloadWrite(..%gateway,p22)
	Do:$D(p23) ..%OverloadWrite(..%gateway,p23)
	Do:$D(p24) ..%OverloadWrite(..%gateway,p24)
	Do:$D(p25) ..%OverloadWrite(..%gateway,p25)
	Set x=$zobjexport($i(..%gateway.SequenceNumber,2),1)
	Set x=$zobjexport("Y3",8)
	do ..%GetResponse(..%gateway,"Y3",.orefCache)
	do ..%PostInvokeNew(..%gateway)
	Quit $$$OK
}

/// backwards compatible version to be called by generated user classs
Method %PreInvoke() [ Final ]
{
	do ..%PreInvokeNew(..%gateway)
	Set x=$zobjexport($this,18)
	quit
}

/// backwards compatible version to be called by generated user classs
ClassMethod %PreInvokeStatic(gateway As %Net.Remote.Gateway, classname As %String) [ Final ]
{
	do ..%PreInvokeNew(gateway)
	Set x=$zobjexport(classname,18)
	quit
}

ClassMethod %PreInvokeNew(gateway As %Net.Remote.Gateway) [ Final ]
{
	#; Protect against lost connection to Gateway
	if gateway.AttemptReconnect && gateway.%LostConnectionCleanup() $$$ThrowOnError(gateway.%Reconnect())
	do gateway.%PushGatewayDevice()
	// Update oref registry
	if $d(gateway.ClosedProxies) {
		do gateway.%RegUpdate()
	} else {
		set x=$zobjexport(0,18)
	}
	quit
}

/// backwards compatible version to be called by generated user classs
Method %PostInvoke() [ Final ]
{
	do ..%PostInvokeNew(..%gateway)
	quit
}

/// backwards compatible version to be called by generated user classs
ClassMethod %PostInvokeStatic(gateway As %Net.Remote.Gateway) [ Final ]
{
	do ..%PostInvokeNew(gateway)
	quit
}

ClassMethod %PostInvokeNew(gateway As %Net.Remote.Gateway) [ Final ]
{
	if $zobjexport(16)>0 set:$zobjexport(17) out=$zobjexport(12)
	if $zobjexport(16)>0 set:$zobjexport(17) err=$zobjexport(12)
	do gateway.%PopGatewayDevice()
	if ($IO["TRM") {
		write:$D(out) "System.out: "_out,!
		write:$D(err) "System.err: "_err,!
	}
	quit
}

ClassMethod %GetResponse(gateway As %Net.Remote.Gateway, functionCode As %String, ByRef orefCache)
{
	set sequenceNumber = gateway.SequenceNumber
	for  {
		; read from wire
		set msgid=$zobjexport(21),fun=$zobjexport(15)
		; messageCount is odd for all messages initiated from Java
		if msgid#2=1 {
			; push gateway context stack
			do $system.Context.Gateway().push(gateway)
			; dispatch to system to handle
			set x = $system.IS.Execute(0,msgid,1,$sconvert(fun,"U2",0),-1)
			; pop gateway context stack
			do $system.Context.Gateway().pop()
			; $system.IS.Execute returns 0 on success
			if x=0 continue
			do ..%ProcessErrorNew(gateway,$$$FormatText("Reentrancy execution error, return value %1",x))
		}
		if (msgid=0)&&(fun="DC") {
			do ..%ProcessErrorNew(gateway,$$$FormatText("Connection closed by External Language Server"))
		} elseif msgid'=sequenceNumber {
			do ..%ProcessErrorNew(gateway,$$$FormatText("Invalid message sequence number, expecting %1, received %2",sequenceNumber,msgid))
		} elseif fun=functionCode {
			quit
		} elseif fun="Y5" {
			do ..%ProcessErrorNew(gateway)			
		} elseif fun="Y9" {
			set count=$zobjexport(12)
			set classname=$zobjexport(12)
			for i=1:1:count {
				try {
					// We cannot use an OREF that is currently pending release in ..ClosedProxies
					for attempt=1:1 {
						set oref(attempt) = $classmethod(classname,"%New")
						if $d(gateway.ClosedProxies(oref(attempt)_"")) continue
						set oref = oref(attempt)
						quit
					}
				} catch ex {
					if ex.Name="<CLASS DOES NOT EXIST>" {
						set oref=$classmethod("%Net.Remote.Object", "%New")
					} else {
						throw ex
					}
				}
				set oref.%gateway=gateway
				set orefCache(oref_"")=oref
				set x=$zobjexport(oref,18)
			}
			Set x=$zobjexport(msgid,1)
			set x=$zobjexport("Y9",8)
			continue
		} else {
			do ..%ProcessErrorNew(gateway,$$$FormatText("Invalid function code, expecting %1, received %2",functionCode,fun))
		}
	}
	quit
}

/// backwards compatible version to be called by generated user classs
Method %ProcessError(fun, id) [ Final ]
{
	do ..%ProcessErrorNew(..%gateway)
	quit
}

/// backwards compatible version to be called by generated user classs
ClassMethod %ProcessErrorStatic(gateway As %Net.Remote.Gateway, fun, id) [ Final ]
{
	do ..%ProcessErrorNew(gateway)
	quit
}

ClassMethod %ProcessErrorNew(gateway As %Net.Remote.Gateway, error As %String) [ Final ]
{
	if $d(error)=0 {
		set error=$zobjexport(12)
		do gateway.%PopGatewayDevice()
	} else {
		; if error text is set, then it's a non-Y5 error, which is catastrophic, we close the device
		do gateway.%ClearGatewayDevice()
		close gateway.GatewayDevice
		set gateway.Closed=1
	}
	set x = $$$ERROR($$$RemoteGatewayError,error)
	zt "JGTW"
}

Method GatewayGet() As %Net.Remote.Gateway
{
	quit ..%gateway
}

Method GatewaySet(value As %Net.Remote.Gateway) As %Status
{
	set ..%gateway = value
	quit $$$OK
}

}
