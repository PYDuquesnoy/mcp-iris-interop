/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Abstract Document used to load DTL diagrams into Studio.
Class Ens.DTL.UI.DTLDocument Extends Ens.Util.AbstractDocument [ System = 4 ]
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentExtension = "dtl", DocumentNew = 0);

Parameter EXTENSION = ".dtl";

/// URL to use to get actual editor for Studio to display.
Parameter EDITORURL = "EnsPortal.DTLEditor.zen";

/// If set, name of superclass used for documents of this type.<br>
/// For example, Ens.DataTransformDTL
Parameter DOCUMENTCLASS = "Ens.DataTransformDTL";

Property ImportFlag As %Boolean [ InitialExpression = 0, Private ];

/// Deserialize the DTL Diagram and save it as a DTL class.
Method Save() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	
	If (..ImportFlag) {
		// we are in an import and are already saved
		Set ..ImportFlag = 0
		Quit tSC
	}
	
	// cache name for DTL editor!!!
	Set ^ENSLASTDTLNAME = ..Name
	
	Write !,$$$FormatText($$$Text("Saving DTL Diagram '%1'"),..Name),"..."
	Do {

		// strip off extension;
		Set tClassName = ..GetClassName(..Name)

		Set tSC = ..SaveDTLToClass(tClassName, ..Code)
		If $$$ISERR(tSC) Quit

		Write !,$$$Text("Saved successfully.")
	} While (0)
	
Exit
	Write !
	Quit tSC
Trap
	Set $ZT="",tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

/// Return 1 if the given DTL document exists and 0 if it does not.
ClassMethod Exists(name As %String) As %Boolean
{
	If $G(^Ens.Debug("EditDTLAsClass")) Quit 0
	Set $ZT="Trap",tExists=0
	
	Do {
		// strip off extension
		Set cls = ..GetClassName(name)
		
		// see if this class contains valid DTL
		
		// see if there is an DTLError block
		If ($$$defMemberDefined(cls,$$$cCLASSxdata,"DTLError")) {
			// this is an error DTL
			Set tExists = 1
			Quit
		}

		// is there a DTL block
		If ($$$defMemberDefined(cls,$$$cCLASSxdata,"DTL")) {
		
			// is this DTL valid
			Set tSC = ##class(Ens.Util.DTL).ValidateDTL(cls)
			If ($$$ISERR(tSC)) {
				Write !,$$$FormatText($$$Text("Class '%1' contains an invalid DTL document:"),cls)
				Do $System.Status.DisplayError(tSC)
				Write !,$$$FormatText($$$Text("Opening '%1' for text editing:"),cls)
				Quit
			}
		
			Set tExists = 1
		}

	} While(0)

Exit
	Quit tExists
Trap
	Set $ZT="",tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

/// Get DTL info for a class
ClassMethod GetTransform(Output pTransform As Ens.DTL.Transform, pClassName As %String) As %Status
{
	Set pTransform = ""
	Set tSC = $$$OK

	Do {
		// Get DTL block from class
		Set tSC = ..GetDTLStream(.tStream, pClassName, .tDesc)
		If $$$ISERR(tSC) Quit
		
		// Now parse it into a Transform object
		Set tSC = ##class(Ens.DTL.Compiler).ParseStream(.pTransform, tStream)
		If $$$ISERR(tSC) Quit

	} While (0)
	
	Quit tSC
}

/// Find the DTL definition (as a stream) for the given
/// DTL class; return "" if not found.<BR>
/// Also returns Description for this class
ClassMethod GetDTLStream(Output pStream As %Stream.Object, pClassName As %String, ByRef pDesc As %String) As %Status
{
	Set pStream = ""
	Set tSC = $$$OK

	Do {
		// cls is the name of a DTL class, try to find it
		Set cdef = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
		If ('$IsObject(cdef)) {
			// no class
			Set tSC = $$$ERROR($$$GeneralError, "Unable to open class: " _ pClassName)
			Quit
		}
		
		Set pDesc = cdef.Description
		
		// try to find XDATA block "DTL"
		Set tIndex = cdef.XDatas.FindObjectId(cdef.Name_"||DTL")
	
		// no xdata found, quit
		If (tIndex = "") {
			Set tSC = $$$ERROR($$$GeneralError, "Unable to find DTL block within class: " _ pClassName)
			Quit
		}
		
		// get XDATA as stream
		Set pStream = cdef.XDatas.GetAt(tIndex).Data
		If ($IsObject(pStream)) {
			Do pStream.Rewind()
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError, "Unable to open DTL stream within class: " _ pClassName)
			Quit
		}

	} While(0)
	
	Quit tSC
}

/// Save the given DTL document to the specified class' XDATA block.
/// If class does not exist, create a new one
ClassMethod SaveDTLToClass(pClassName As %String, pDTL As %Stream.Object) As %Status
{
	Set tSC = $$$OK

	// save this DTL document into the DTL class
	Try {
		Set tSC = ##class(Ens.DTL.Compiler).ParseStream(.tTransform,pDTL)
		If $$$ISERR(tSC) Quit

		#; open the class definition
		Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
		If ($IsObject(tClassDefinition)) {
			#; delete the old XDATA block named DTL
			Set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||DTL")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
		}
		Else {
			// create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = pClassName
			Set tClassDefinition.Super = "Ens.DataTransformDTL"
			Set tClassDefinition.ClassVersion = $$$CLASSDEFINITIONVERSION
			Set tReportErrors = ##class(%Dictionary.ParameterDefinition).%New()
			Set tReportErrors.Name = "REPORTERRORS"
			Set tReportErrors.Default = 1
			Do tClassDefinition.Parameters.Insert(tReportErrors)
			Set tIgnoreMissingSource = ##class(%Dictionary.ParameterDefinition).%New()
			Set tIgnoreMissingSource.Name = "IGNOREMISSINGSOURCE"
			Set tIgnoreMissingSource.Default = 1
			Set tIgnoreMissingSource.parent = tClassDefinition
			Set tTreatEmptyRepeatingFieldAsNull = ##class(%Dictionary.ParameterDefinition).%New()
			Set tTreatEmptyRepeatingFieldAsNull.Name = "TREATEMPTYREPEATINGFIELDASNULL"
			Set tTreatEmptyRepeatingFieldAsNull.Default = 0
			Do tClassDefinition.Parameters.Insert(tTreatEmptyRepeatingFieldAsNull)
		}

		Set tDependsOn = ""
		If (tTransform.SourceClass '= "") { Set tDependsOn = tTransform.SourceClass }
		If (tTransform.TargetClass '= "") && (tTransform.TargetClass '= tTransform.SourceClass) {
			Set tDependsOn = tDependsOn _ $select(tDependsOn '= "": ",", 1: "") _ tTransform.TargetClass
		}
		If tDependsOn '= "" {
			Set tClassDefinition.DependsOn = tDependsOn
		}
		Else {
			Do tClassDefinition.DependsOnReset()
		}

		#; define a new XDATA block named (DTL)
		Set tXDataDefinition = ##class(%Dictionary.XDataDefinition).%New()

		Set tXDataDefinition.Name = "DTL"
		Set tXDataDefinition.parent = tClassDefinition
		Set tXDataDefinition.XMLNamespace = "http://www.intersystems.com/dtl"

		Set tSC = tTransform.GenerateXML(tXDataDefinition.Data)
		If $$$ISERR(tSC) Quit
		
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Export this document to the current device in XML format
Method ExportToXML(flags As %String) As %Status
{
	// Find BPL for this document and export that
	Set tCls = ..GetClassName(..Name)
	
	// Get DTL block from class
	Set tSC = ..GetDTLStream(.tStream, tCls, .tDesc)
	If $$$ISERR(tSC) Quit tSC
	If ('$IsObject(tStream)) {
		Quit $$$ERROR($$$GeneralError,"NO DTL defined for item: " _ ..Name)
	}

	Do tStream.Rewind()
	Write "<![CDATA["
	While '(tStream.AtEnd) {
		Write ..escapeCData(tStream.Read(16000))
	}
	Write "]]>"
	Quit $$$OK
}

/// Passed a stream containing the XML document, this method should insert this
/// into the current document. Once this is done the importer will call Save
/// on the document. This default handler in assumes the export <method>ExportToXML</method>
/// just wrote the data in a CDATA structure
Method ImportFromXML(stream As %RegisteredObject, flags As %String) As %Status
{
	// create a DTL class and plug in the given DTL XDATA block
	Set tClassName = ..GetClassName(..Name)
	
	Set data=stream.Read(9)
	If data'="<![CDATA[" Quit $$$ERROR($$$GeneralError,"Data not formatted as CDATA")
	Do ..Clear()
	While 'stream.AtEnd {
		Set data=stream.Read(32000)
		Set data=..unescapeCData(data)
		If (stream.AtEnd) && ($E(data,$L(data)-2,$L(data))="]]>") Set data = $E(data,1,$L(data)-3)
		Do ..Write(data)
	}

	Set tSC = ..SaveDTLToClass(tClassName, ..Code)

	// flag to prevent subsequent save
	Set ..ImportFlag = 1

	Quit tSC
}

ClassMethod GetURL(pName As %String) As %String
{
	Quit ..#EDITORURL_"?DT="_$zconvert($zconvert(pName,"O","UTF8"),"O","URL")_"&STUDIO=1"_$select(..Exists(pName):"",1:"&NEW=1")
}

}
