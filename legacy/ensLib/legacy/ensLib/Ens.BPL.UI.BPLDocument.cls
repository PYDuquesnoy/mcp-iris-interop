/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Abstract Document used to load BPL diagrams into Studio.
Class Ens.BPL.UI.BPLDocument Extends Ens.Util.AbstractDocument [ System = 4 ]
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentExtension = "BPL", DocumentNew = 0);

Parameter EXTENSION = ".bpl";

/// URL to use to get actual editor for Studio to display.
Parameter EDITORURL = "EnsPortal.BPLEditor.zen";

/// Name of superclass used for documents of this type.<br>
Parameter DOCUMENTCLASS = "Ens.BusinessProcessBPL";

Property ImportFlag As %Boolean [ InitialExpression = 0, Private ];

/// Deserialize the BPL Diagram and save it as a BPL class.
Method Save() As %Status
{
	Set $ZT="Trap",tSC=$$$OK

	If (..ImportFlag) {
		// we are in an import and are already saved
		Set ..ImportFlag = 0
		Quit tSC
	}

	Set tSaveMsg = $$$Text("Saved successfully.")
	
	Write !,$$$FormatText($$$Text("Saving BPL Diagram '%1'"),..Name),"..."

	Do {
		// ..Code contains a serialized BPL diagram
		Do ..Code.Rewind()

		Set tSC = ##class(Ens.BPL.UI.Diagram).CreateDiagramFromXML(..Code, .tDiagram)
		If ($$$ISERR(tSC)) {
			Write !,$$$Text("UNABLE TO SAVE: Unable to parse BPL Diagram.")
			Do $System.Status.DisplayError(tSC)
			
			Write !,"--- Begin BPL Diagram ---",!
			Do ..Code.Rewind()
			Do ..Code.OutputToDevice()
			Do ..Code.Rewind()
			Write !,"--- End BPL Diagram ---",!
			
			Quit
		}
		
		// convert BPL diagram to BPL DOM
		Set tXDataName = "BPL"
		Set bplStream = ##class(%GlobalCharacterStream).%New()
		Set tConverted = 0
		If ('tDiagram.HasErrors) {
			// if no logical errors in diagram, try to convert to BPL
			Set tSC = tDiagram.ConvertToBPL(bplStream,.tConverted)
		}
		If (tDiagram.HasErrors || $$$ISERR(tSC)) {
			If $$$ISERR(tSC) {
				Do $System.Status.DecomposeStatus(tSC, .tErrors)
			}

			// errors
			// write out syntax errors
			Set e = $O(tErrors(""))
			Set num = 0
			While (e '= "") {
				Write:num=0 !,$$$Text("ERROR(s) in the BPL Diagram")
				Set num = num + 1
				Write !,num,": ",tErrors(e)
				Set e = $O(tErrors(e))
			}

			Write !,$$$Text("ERROR(s) in BPL diagram:")
			Set tSaveMsg = "Saved with errors."

			// if we were unable to generate BPL, save an Error block instead
			If ('tConverted) {
				// save the Diagram XML instead of the BPL
				Set tXDataName = "BPLError"
				Do bplStream.Rewind()
				Do bplStream.CopyFrom(..Code)
			}
		}

		// now save the serialized BPL DOM into the class' xdata
		Do bplStream.Rewind()

		Set tSC = ..SaveBPLClass(bplStream, tXDataName, tDiagram.Annotation)
		If $$$ISERR(tSC) Quit
		
		Write !,tSaveMsg

	} While(0)
Exit
	Write !
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Does the actual work of saving BPL stream to a BPL class
Method SaveBPLClass(pBPLStream As %Stream.Object, pXDataName As %String, pDescription As %String) As %Status [ Private ]
{
	Set $ZT="Trap"
	#dim tSC=$$$OK
	
	Do {
		#dim tClassName = ..GetClassName(..Name)
		
		#; open the class definition
		Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName)
		If ($IsObject(tClassDefinition)) {
			#; delete the old XDATA block named BPL
			#dim tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"||BPL")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
	
			#; delete the old XDATA block named BPLError (if any)
			Set tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"||BPLError")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
		}
		Else {
			// create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = tClassName
			Set tClassDefinition.Super = "Ens.BusinessProcessBPL"
			Set tClassDefinition.ClassType = "persistent"
			Set tClassDefinition.ProcedureBlock = 1
		}
		
		If $data(pDescription)#2 {
			Set pDescription = $replace(pDescription,$c(10),$c(13,10))
			Set pDescription = $replace(pDescription,$c(13,13),$c(13))
			Set tClassDefinition.Description = pDescription
		}

		#; define a new XDATA block named (BPL or BPLError)
		Set tXDataDefinition = ##class(%Dictionary.XDataDefinition).%New()
		$$$ASSERT($IsObject(tClassDefinition))
		
		If (pXDataName = "BPLError") {
			// add a comment to the Error block
			Set tXDataDefinition.Description = "This BPLError block indicates that a BPL Diagram " _ $C(13,10) _ 
			"containing errors was saved." _ $C(13,10) _
			"To correct this class:" _ $C(13,10) _
			"* Open it using the Studio BPL Editor," _ $C(13,10) _
			"* Correct the errors, and," _ $C(13,10) _
			"* Save the diagram." _ $C(13,10) _
			"Do not edit the contents of the BPLError block"  _ $C(13,10) _
			"or you may lose your diagram."
		}
		Else {
			Set tXDataDefinition.Description = "BPL Definition"
			Set tXDataDefinition.XMLNamespace = "http://www.intersystems.com/bpl"

			#; Examine stream for contextsuperclass (similar code to Ens.BPL.Compiler.cls::CompileStream && EnsPortal.BPLEditor::%SaveBPLClass)
			#dim tParser=##class(Ens.BPL.Parser).%New()
			$$$ASSERT($IsObject(tParser))
			#dim tProcessObject As Ens.BPL.Process
			Set tSC=tParser.ParseStream(pBPLStream,.tProcessObject)
			Do pBPLStream.Rewind()
			Set tParser = $$$NULLOREF
			If $$$ISERR(tSC) Quit
			$$$ASSERT($IsObject(tProcessObject)&&tProcessObject.%IsA("Ens.BPL.Process"))
			If tProcessObject.ContextSuperClass '= "" {
				Set tClassDefinition.DependsOn = tProcessObject.ContextSuperClass
			}
			Else {
				Do tClassDefinition.DependsOnReset()
			}
			Set tProcessObject = $$$NULLOREF
		}

		Set tXDataDefinition.Name = pXDataName
		Set tXDataDefinition.parent = tClassDefinition
	
		Set tSC = tXDataDefinition.Data.CopyFrom(pBPLStream)
		If $$$ISERR(tSC) Quit
		
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)

Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Compile this document
Method CompileDocument(flags As %String) As %Status
{
	If '##class(%Dictionary.XDataDefinition).IDKEYExists(..GetClassName(..Name),"BPL") {
		Set tSC = $$$ERROR($$$EnsErrMissingBPL)
		Do $System.Status.DisplayError(tSC)
		Quit tSC
	}
	If $get($$$qualifierGetValue(flags,"displaylog")) Write !,$$$FormatText($$$Text("Compiling BPL document '%1'"),..Name)
	Quit $System.OBJ.Compile(..GetClassName(..Name),.flags)
}

/// Return 1 if the given BPL document exists and 0 if it does not.
ClassMethod Exists(name As %String) As %Boolean
{
	If $G(^Ens.Debug("EditBPLAsClass")) Quit 0
	Set $ZT="Trap",tExists=0
	
	Do {
		If (name = "") {
			Quit	
		}
		
		// strip off extension
		Set cls = ..GetClassName(name)
		
		// see if this class contains valid BPL
		
		// see if there is an BPLError block
		If ($$$defMemberDefined(cls,$$$cCLASSxdata,"BPLError")) {
			// this is an error BPL
			Set tExists = 1
			Quit
		}

		// is there a BPL block
		If ($$$defMemberDefined(cls,$$$cCLASSxdata,"BPL")) {
		
			// is this BPL valid
			Set tSC = ##class(Ens.Util.BPL).ValidateBPL(cls)
			If ($$$ISERR(tSC)) {
				Write !,$$$FormatText($$$Text("Class '%1' contains an invalid BPL document:"),cls)
				Do $System.Status.DisplayError(tSC)
				Write !,$$$FormatText($$$Text("Opening '%1' for text editing."),cls)
				Quit
			}
		
			Set tExists = 1
		}

	} While(0)

Exit
	Quit tExists
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method CopyFrom(source As %Stream.Object) As %Status
{
	Quit:'$IsObject(source) $$$ERR($$$OrefInvalid)
	If 'source.%IsA("Ens.UI.BPLDocument") {
		Quit ##super(source)
	}

	Do source.Rewind()
	Set sc=$$$OK
	Set inDiagram = 0
	
	// empty out this document
	Do ..Clear()
	
	// skip HTML wrapper for diagram
	While ('source.Code.AtEnd && $$$ISOK(sc)) {
		Set line = source.ReadLine()
		If ($E(line,1,8) = "<diagram") {
			Set inDiagram = 1
		}
		
		If (inDiagram) {
			Set sc = ..WriteLine(line)
	
			If ($E(line,1,9) = "</diagram") {
				Set inDiagram = 0
			}
		}
	}

	Quit sc
}

/// This method saves BPL XML to the given class
Method SaveBPLToClass()
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		// strip off extension; find TimeChanged for class
		Set tClassName = ..GetClassName(..Name)
		
		#; open the class definition
		Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName)
		$$$ASSERT($IsObject(tClassDefinition))
		
		#; delete the old XDATA block named BPL
		Set tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"|BPL")
		If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
		
		#; define a new XDATA block named BPL
		Set tXDataDefinition = ##class(%Dictionary.XDataDefinition).%New()
		$$$ASSERT($IsObject(tClassDefinition))

		Set tXDataDefinition.Name="BPL"
		Set tXDataDefinition.parent=tClassDefinition
		Set tSC=bplStream.XMLExportToStream(tXDataDefinition.Data) Quit:$$$ISERR(tSC)
	
		Set tSC=tClassDefinition.%Save() Quit:$$$ISERR(tSC)
	
		Quit
	} while (0)
Exit
	Quit tSC	
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Export this document to the current device in XML format
Method ExportToXML(flags As %String) As %Status
{
	// Find BPL for this document and export that
	Set tCls = ..GetClassName(..Name)
	Set tStream = ##class(Ens.BPL.UI.Diagram).GetBPLStream(tCls, .tXDataName, .tDesc)
	
	If ('$IsObject(tStream)) {
		Quit $$$ERROR($$$GeneralError,"NO BPL defined for item: " _ ..Name)
	}

	// write out BPL xml
	Do tStream.OutputToDevice()

	Quit $$$OK
}

/// Passed a stream containing the XML document, this method should insert this
/// into the current document. Once this is done the importer will call Save
/// on the document. This default handler in assumes the export <method>ExportToXML</method>
/// just wrote the data in a CDATA structure
Method ImportFromXML(stream As %RegisteredObject, flags As %String) As %Status
{
	// create a BPL class and plug in the given BPL XDATA block
	Do stream.Rewind()
	Set tHeader = stream.Read(8)
	If (tHeader = "<process") {
		Set tXDataName = "BPL"
	}
	Else {
		Set tXDataName = "BPLError"
	}
	Do stream.Rewind()

	Set tSC = ..SaveBPLClass(stream, tXDataName)

	// flag to prevent subsequent save
	Set ..ImportFlag = 1

	Quit tSC
}

ClassMethod GetURL(pName As %String) As %String
{
	Quit ..#EDITORURL _ "?BP="_$zconvert($zconvert(pName,"O","UTF8"),"O","URL")_"&STUDIO=1" _ $select(..Exists(pName):"", 1:"&NEW=1")
}

}
