/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is a persistent object that transparently encapsulates any type of persistable stream object
Class Ens.StreamContainer Extends (%Persistent, Ens.Util.MessageBodyMethods, %XML.Adaptor) [ System = 4 ]
{

Property OriginalFilename As %String(MAXLEN = "");

/// This property can be used to store a folder identifier to be used on output.<br>
/// Used for example in the EnsLib.MFT.Operation.Passthrough <br>
Property OutputFolder As %String(MAXLEN = "");

/// This property can be used to store a filename to be used on output<br>
/// Used for example in the EnsLib.MFT.Operation.Passthrough <br>
Property OutputFilename As %String(MAXLEN = "");

Property Stream As %Stream.Object [ Calculated, Transient ];

Property Type As %String(MAXLEN = 2) [ ReadOnly ];

Property StreamFC As %Library.FileCharacterStream(XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

Property StreamFB As %Library.FileBinaryStream(XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

Property StreamGC As %Library.GlobalCharacterStream(XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

Property StreamGB As %Library.GlobalBinaryStream(XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

Property StreamCF As %Stream.FileCharacter(CLASSNAME = 2, XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

Property StreamBF As %Stream.FileBinary(CLASSNAME = 2, XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

Property StreamCG As %Stream.GlobalCharacter(CLASSNAME = 2, XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

Property StreamBG As %Stream.GlobalBinary(CLASSNAME = 2, XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

Property CharEncodingTable As %String(XMLPROJECTION = "NONE") [ Internal, ReadOnly ];

/// An array of strings containing any attribute values
Property Attributes As array Of %String(MAXLEN = "");

Method %OnNew(pInput As %RawString = {$$$NULLOREF}, pAttributes As %Collection.ArrayOfDT = {$$$NULLOREF}) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	#dim tSC As %Status = $$$OK
	Set tSC = ..StreamSet(pInput)
	If $$$ISERR(tSC) Quit tSC
	Do ..SetAttributes(.pAttributes)
	Quit tSC
}

Method StreamGet() As %Stream.Object
{
	Quit $Case(..Type
				, "FC":..StreamFC
				, "FB":..StreamFB
				, "GC":..StreamGC
				, "GB":..StreamGB
				, "CF":..StreamCF
				, "BF":..StreamBF
				, "CG":..StreamCG
				, "BG":..StreamBG
				, :$$$NULLOREF)
}

Method StreamSet(pInput As %Stream.Object) As %Status
{
	Set tOldStream=$Case(..Type
				, "FC":..StreamFC
				, "FB":..StreamFB
				, "GC":..StreamGC
				, "GB":..StreamGB
				, "CF":..StreamCF
				, "BF":..StreamBF
				, "CG":..StreamCG
				, "BG":..StreamBG
				, :$$$NULLOREF)
	Quit:tOldStream=pInput $$$OK
	If '$IsObject(pInput) Do:..Type'="" Clear()  Set i%Type=""  Quit $$$OK
	If pInput.%Extends("%Library.FileCharacterStream")       { Do:..Type'="FC" Clear()  Set r%StreamFC=pInput, i%Type="FC", i%CharEncodingTable=pInput.TranslateTable }
	ElseIf pInput.%Extends("%Library.FileBinaryStream")      { Do:..Type'="FB" Clear()  Set r%StreamFB=pInput, i%Type="FB" }
	ElseIf pInput.%Extends("%Library.GlobalCharacterStream") { Do:..Type'="GC" Clear()  Set r%StreamGC=pInput, i%Type="GC" }
	ElseIf pInput.%Extends("%Library.GlobalBinaryStream")    { Do:..Type'="GB" Clear()  Set r%StreamGB=pInput, i%Type="GB" }
	ElseIf pInput.%Extends("%Stream.FileCharacter")   { Do:..Type'="FC" Clear()  Set r%StreamCF=pInput, i%Type="CF", i%CharEncodingTable=pInput.TranslateTable }
	ElseIf pInput.%Extends("%Stream.FileBinary")      { Do:..Type'="BF" Clear()  Set r%StreamBF=pInput, i%Type="BF" }
	ElseIf pInput.%Extends("%Stream.GlobalBinary")    { Do:..Type'="BG" Clear()  Set r%StreamBG=pInput, i%Type="BG" } ; must come first because extends %Stream.GlobalCharacter
	ElseIf pInput.%Extends("%Stream.GlobalCharacter") { Do:..Type'="CG" Clear()  Set r%StreamCG=pInput, i%Type="CG" }
	Else { Do:..Type'="" Clear()  Set i%Type=""  Quit $$$ERROR($$$GeneralError, "Input Stream object class "_$classname(pInput)_" not recognized") }
	Set ..OriginalFilename=$S(pInput.%Extends("%Library.AbstractStream"):pInput.GetAttribute("Filename"), 1:"")
	Quit $$$OK
Clear()
	#; Avoid going through clearance checks on initial set
	If ..Type="" Quit
	If ..Type="FC"     { Set r%StreamFC=$$$NULLOREF,i%StreamFC=$$$NULLOREF }
	ElseIf ..Type="FB" { Set r%StreamFB=$$$NULLOREF,i%StreamFB=$$$NULLOREF }
	ElseIf ..Type="GC" { Set r%StreamGC=$$$NULLOREF,i%StreamGC=$$$NULLOREF }
	ElseIf ..Type="GB" { Set r%StreamGB=$$$NULLOREF,i%StreamGB=$$$NULLOREF }
	ElseIf ..Type="CF" { Set r%StreamCF=$$$NULLOREF,i%StreamCF=$$$NULLOREF }
	ElseIf ..Type="BF" { Set r%StreamBF=$$$NULLOREF,i%StreamBF=$$$NULLOREF }
	ElseIf ..Type="CG" { Set r%StreamCG=$$$NULLOREF,i%StreamCG=$$$NULLOREF }
	ElseIf ..Type="BG" { Set r%StreamBG=$$$NULLOREF,i%StreamBG=$$$NULLOREF }
	Quit
}

/// Set values into the Attributes array property
/// Pass in an array object, a ObjectScript array, a ObjectScript array reference, a %AbstractStream with its own Attributes to copy from, a %Net.HttpResponse object with its own Headers to copy from, or a string of the form 'a=1,b=2,c=3'.
Method SetAttributes(ByRef pAttributes)
{
	If $IsObject(pAttributes) {
		If pAttributes.%Extends("%Collection.ArrayOfDT") {
			Set ..Attributes=pAttributes
		} ElseIf pAttributes.%Extends("%ArrayOfDataTypes") {
			Set ..Attributes=pAttributes
		} ElseIf pAttributes.%Extends("%Net.HttpResponse") {
			Set k="" For { Set k=$O(pAttributes.Headers(k),1,val)  Quit:""=k
				Do ..Attributes.SetAt(val,k)
			}
		} ElseIf pAttributes.%Extends("%AbstractStream") {
			Set k="" For { Set k=$O(pAttributes.Attributes(k),1,val)  Quit:""=k
				Do ..Attributes.SetAt(val,k)
			}
		}
	} ElseIf pAttributes["=" {
		For i=1:1:$L(pAttributes,",") { Set k=$P(pAttributes,",",i)  Set val=$ZStrip($P(k,"=",2),"<>W"), k=$ZStrip($P(k,"="),"<>W") Continue:""=k  
			Do ..Attributes.SetAt(val,k)
		}
	} ElseIf ""'=pAttributes {
		Set k="" For { Set k=$O(@pAttributes@(k),1,val)  Quit:""=k
			Do ..Attributes.SetAt(val,k)
		}
	} ElseIf $D(pAttributes)>1 {
		Set k="" For { Set k=$O(pAttributes(k),1,val)  Quit:""=k
			Do ..Attributes.SetAt(val,k)
		}
	}
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	New %tID  Set %tID=$$$oidPrimary(oid)
	Do ##class(EnsLib.XML.SearchTable).RemoveIndex(%tID,%tID,1)
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New %tID,index,segid  Set %tID={%%ID}
	Do ##class(EnsLib.XML.SearchTable).RemoveIndex(%tID,%tID,1)
	Quit
}

Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	Set tStream=$Case(..Type
				, "FC":..StreamFC
				, "CF":..StreamCF
				, :$$$NULLOREF)
	Set:$IsObject(tStream) tStream.TranslateTable=..CharEncodingTable
	Quit $$$OK
}

/// Override since need to handle writing the Stream to the correct Stream type and ignoring Type.
ClassMethod XMLNew(document As %XML.Document, node As %Integer, containerOref As %RegisteredObject = "") As %RegisteredObject [ Internal ]
{
	#dim tNewObject = ..%New()
	/*
		Find "Type" and "Stream"
			Populate correct Stream in tNewObject
			Remove Type from node
			No need to remove Stream from node since XMLImportInternal does nothing with it.
	*/
	#dim tmpNode=document.GetNode(node)
	#dim tType = ""
	#dim tStreamNode = ""
	#dim tTypeNode = ""
	#; Type and Stream at top level
	Do tmpNode.MoveToFirstChild()
	Do {
		If (tmpNode.LocalName="Type"){
			Set tTypeNode = tmpNode.NodeId
			Do tmpNode.MoveToFirstChild()
			Set tType = tmpNode.NodeData
			Do tmpNode.MoveToParent()
			If tStreamNode'="" Quit ; We know where Stream node is
		} ElseIf (tmpNode.LocalName="Stream") {
			Set tStreamNode = tmpNode.NodeId
			If tType '= "" Quit ; We know type
		}
	} While tmpNode.MoveToNextSibling()
	#; Replace "Type" tag so skipped in import
	If tTypeNode '= "" {
		#dim tSkipDoc =##class(%XML.Document).CreateDocument("Stream")
		#dim tSkipNode = tSkipDoc.GetDocumentElement()
		Set tmpNode=document.GetNode(tTypeNode)
		Do tmpNode.ReplaceNode(tSkipNode)
	}
	If tStreamNode '= "" {
		#dim tStreamType = $Case(tType
							, "FC":"%Library.FileCharacterStream"
							, "FB":"%Library.FileBinaryStream"
							, "GC":"%Library.GlobalCharacterStream"
							, "GB":"%Library.GlobalBinaryStream"
							, "CF":"%Stream.FileCharacter"
							, "BF":"%Stream.FileBinary"
							, "CG":"%Stream.GlobalCharacter"
							, "BG":"%Stream.GlobalBinary"
							,:"%Stream.GlobalCharacter")
		#dim tStream = $classmethod(tStreamType,"%New")
		#; Now get the data from the node
		#dim sc=##CLASS(%XML.ImportHandler).SerializeNode(document.DocumentId,tStreamNode,1,0,.tStream,0,0)
		If sc Set tNewObject.Stream = tStream
	}
	Quit tNewObject
}

Storage Default
{
<Data name="Attributes">
<Attribute>Attributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"Attributes"</Subscript>
</Data>
<Data name="StreamContainerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>OriginalFilename</Value>
</Value>
<Value name="3">
<Value>StreamFB</Value>
</Value>
<Value name="4">
<Value>StreamFC</Value>
</Value>
<Value name="5">
<Value>StreamGB</Value>
</Value>
<Value name="6">
<Value>StreamGC</Value>
</Value>
<Value name="7">
<Value>Type</Value>
</Value>
<Value name="8">
<Value>StreamCF</Value>
</Value>
<Value name="9">
<Value>StreamBF</Value>
</Value>
<Value name="10">
<Value>StreamCG</Value>
</Value>
<Value name="11">
<Value>StreamBG</Value>
</Value>
<Value name="12">
<Value>FileCharEncodingTable</Value>
</Value>
<Value name="13">
<Value>CharEncodingTable</Value>
</Value>
<Value name="14">
<Value>OutputFolder</Value>
</Value>
<Value name="15">
<Value>OutputFilename</Value>
</Value>
</Data>
<DataLocation>^Ens.StreamContainerD</DataLocation>
<DefaultData>StreamContainerDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.StreamContainerD</IdLocation>
<IndexLocation>^Ens.StreamContainerI</IndexLocation>
<StreamLocation>^Ens.StreamContainerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
