/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsRecordMap)

/// Model of the Complex RecordMap structures that is used to manage and manipulate ComplexBatch definitions.
Class EnsLib.RecordMap.Model.ComplexBatch Extends (%RegisteredObject, %XML.Adaptor, Ens.Util.PortalModelBase) [ System = 4 ]
{

Parameter XMLSEQUENCE = 1;

Parameter NAMESPACE = "http://www.intersystems.com/Ensemble/RecordMap";

/// Name of the ComplexMap.
Property name As %String(MAXLEN = 210, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Character encoding for imported data records
Property charEncoding As %String(XMLNAME = "char_encoding", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "UTF-8", Required ];

/// Name of the InterSystems IRIS class to represent the persistent Complex RecordMap.
/// This class will be generated as a subclass of EnsLib.RecordMap.ComplexBatch.
/// If the RECORDMAPGENERATED parameter of the existing class is 0, then the target class will 
/// not be modified by the RecordMap framework - all changes are then the responsibility
/// of the user.
Property targetClassname As %String(MAXLEN = 220, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Comments for the ComplexBatch. This text will appear as part of the class comments.
Property annotation As %String(MAXLEN = 1024);

/// An optional Header that precedes the main part of the batch.
Property Header As EnsLib.RecordMap.Model.HeaderRecord;

/// The main sequence of <class>RecordReference</class> and <class>RecordSequence</class> objects.
Property Elements As list Of EnsLib.RecordMap.Model.BatchElement(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Required ];

/// An optional Trailer that appears after the main part of the batch.
Property Trailer As EnsLib.RecordMap.Model.TrailerRecord;

ClassMethod Exists(pComplexBatchName As %String, Output pStatus As %Status) As %Boolean
{
	Set tExists = 0
	Set pStatus = $$$OK
	Try {
		
		Set pComplexBatchName = $$$NormalizeClassname($get(pComplexBatchName))
		If pComplexBatchName = "" Quit
		
		If '##class(%Dictionary.ClassDefinition).%ExistsId(pComplexBatchName) Quit
		
		Set tDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pComplexBatchName,,.pStatus)
		If $$$ISERR(pStatus) Quit
		
		If '(tDefinition.Super [ "EnsLib.RecordMap.ComplexMap") Quit
		
		If "" '= tDefinition.XDatas.FindObjectId(pComplexBatchName_"||ComplexBatch") {
			Set tExists = 1
			Quit
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tExists = 0
	}
	Quit tExists
}

/// Validates and then serializes the current Complex RecordMap structure into XML inside the ComplexBatch
/// XData block in the relevant Complex RecordMap class.
Method SaveToClass() As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = ..%ValidateObject(1)
		If $$$ISERR(tStatus) Quit
		For i=1:1:..Elements.Count() {
			Set tStatus = ..Elements.GetAt(i).%ValidateObject(1)
			If $$$ISERR(tStatus) Quit
		}
		If $$$ISERR(tStatus) Quit

		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.NoXMLDeclaration = 1
		Set tWriter.Indent = 1

		Set tStream = ##class(%Stream.TmpCharacter).%New()
		Set tStatus = tWriter.OutputToStream(tStream)
		If $$$ISERR(tStatus) Quit
		
		Set tStatus = tWriter.RootObject($this)
		If $$$ISERR(tStatus) Quit
		
		Set tClassname = $$$NormalizeClassname(..name)
		
		Set tDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassname,,.tStatus)
		If $system.Status.Equals(tStatus,$$$LoadObjectNotFound) {
			Set tStatus = $$$OK
			Set tDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tDefinition.Name = tClassname
			Set tDefinition.Super = "EnsLib.RecordMap.ComplexMap"
			Set tDefinition.ClassVersion = $$$CLASSDEFINITIONVERSION
		}
		ElseIf $$$ISERR(tStatus) {
			Quit
		}
		Else {
			// Remove current XData block
			Set tXDataLoc = tDefinition.XDatas.FindObjectId(tClassname_"||ComplexBatch")
			If tXDataLoc'="" Do tDefinition.XDatas.RemoveAt(tXDataLoc)
		}
		Do ##class(EnsLib.RecordMap.GenUtils).updateAnnotation(tDefinition,..annotation)
		
		Set tXData = ##class(%Dictionary.XDataDefinition).%New()
		
		Set tXData.Name = "ComplexBatch"
		Set tXData.parent = tDefinition
		Set tXData.XMLNamespace = ..#NAMESPACE
		Do tStream.Rewind()
		
		Set tStatus = tXData.Data.CopyFrom(tStream)
		If $$$ISERR(tStatus) Quit
	
		Set tStatus = tDefinition.%Save()
		If $$$ISERR(tStatus) Quit

		Set ..Timestamp = $zdatetime(tDefinition.TimeChanged,3,,6)
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Deserialize the XML from the ComplexBatch XData block into a ComplexBatch model.
ClassMethod LoadFromClass(pClassname As %String, Output pStatus As %Status, Output pReadOnly As %Boolean, pConcurrency As %Integer = -1) As EnsLib.RecordMap.Model.ComplexBatch
{
	Try {
		Set pStatus = $$$OK
		Set tDocument = $$$NULLOREF
		Set pReadOnly = 0
		
		If $get(pClassname)= "" {
			Set pStatus = $$$ERROR($$$ClassNameInvalid, "")
			Quit
		}
		
		Set pClassname = $$$NormalizeClassname(pClassname)
		
		Set tDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassname,pConcurrency, .pStatus)
		If $$$ISERR(pStatus) Quit
		
		Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(pClassname,"ComplexBatch",pConcurrency,.pStatus)
		If tXData = "" {
			Set pStatus = $$$ERROR($$$XDataBlockMissing,pClassname,"ComplexBatch")
			Quit
		}
		
		Set tReader = ##class(%XML.Reader).%New()
		Set pStatus = tReader.OpenStream(tXData.Data)
		If $$$ISERR(pStatus) Quit
		
		Do tReader.Correlate("ComplexBatch", "EnsLib.RecordMap.Model.ComplexBatch")
		
		If 'tReader.Next(.tComplexBatch, .pStatus) {
			If $$$ISERR(pStatus) Quit
			Set pStatus = $$$ERROR($$$XDataBlockMissingNode,pClassname,"ComplexBatch","ComplexBatch")
			Quit
		}
		If $IsObject(tComplexBatch) {
			Set tComplexBatch.Timestamp = $zdatetime(tDefinition.TimeChanged,3,,6)
			Set tComplexBatch.ReadOnly = pReadOnly
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	If $$$ISERR(pStatus) Quit $$$NULLOREF

	Quit tComplexBatch
}

/// Ensure that the model is valid.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	Set tStatus = $$$OK
	If $IsObject(..Trailer) {
		Set tIdent = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(..Trailer.recordMap)
		If tIdent = "" {
			Set tExplicit = 1
			For i=1:1:..Elements.Count() {
				Set tExplicit = ..Elements.GetAt(i).isExplicitSpec()
				If 'tExplicit Quit
			}
			If 'tExplicit Quit $$$ERROR($$$EnsRecordMapErrIdentifierRequired,..Trailer.recordMap,..Trailer.name)
		}
	}
	Set tStatus = ..CheckNameCollisions(1)
	If $$$ISERR(tStatus) Quit tStatus
	Quit ..CheckIdentifierCollisions()
}

/// Method that checks for identifier collisions in a Complex Batch definition.
Method CheckIdentifierCollisions() As %Status
{
	Set tStatus = $$$OK
	Try {
		For i=1:1:..Elements.Count() {
			Kill tIdents
			Set tElement = ..Elements.GetAt(i)
			If $classname(tElement) = "EnsLib.RecordMap.Model.RecordSequence" {
				Set tStatus = ..checkSequenceIdentifiers(tElement)
				If $$$ISERR(tStatus) Quit
				Do tElement.getIdentifiers(.tIdents)
				If $D(tPrevIdents) {
					Set tIdentifier = $O(tIdents(""))
					// If the only identifier for this sequence matches an identifier from the previous element, then it is impossible to distinguish between the two
					// Check to see if there is exactly one identifier for this sequence and then if that identifier is also used by the previous element
					If ((""'=tIdentifier) && (""=$O(tIdents(tIdentifier))) && $D(tPrevIdents(tIdentifier),tPrevElement)) {
						Set tSeqElement = tIdents(tIdentifier)
						Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,tSeqElement.recordMap,tSeqElement.name)
						Quit
					}
				}
			} Elseif $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
				Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(tElement.recordMap)
				If $D(tPrevIdents(tIdentifier),tPrevElement) {
					Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,tElement.recordMap,tElement.name)
					Quit
				}
				If 'tElement.isExplicitSpec() {
					Set tIdents(tIdentifier) = tElement
				}
			}
			If $$$ISERR(tStatus) Quit
			Kill tPrevIdents
			If 'tElement.isExplicitSpec() {
				Merge tPrevIdents = tIdents
			}
		}
		If $$$ISERR(tStatus) Quit
		If $IsObject(..Trailer) {
			Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(..Trailer.recordMap)
			If $D(tPrevIdents(tIdentifier),tPrevElement) {
				Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,..Trailer.recordMap,..Trailer.name)
			}
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// Helper method to check that a supplied sequence doesn't contain any identifier collisions.
Method checkSequenceIdentifiers(pSequence As EnsLib.RecordMap.Model.RecordSequence) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	For i=1:1:pSequence.Elements.Count() {
		Kill tIdents
		Set tElement = pSequence.Elements.GetAt(i)
		If $classname(tElement) = "EnsLib.RecordMap.Model.RecordSequence" {
			Set tStatus = ..checkSequenceIdentifiers(tElement)
			If $$$ISERR(tStatus) Quit
			Do tElement.getIdentifiers(.tIdents)
			If $D(tPrevIdents) {
				Set tIdentifier = $O(tIdents(""))
				// If the only identifier for this sequence matches an identifier from the previous element, then it is impossible to distinguish between the two
				// Check to see if there is exactly one identifier for this sequence and then if that identifier is also used by the previous element
				If ((""'=tIdentifier) && (""=$O(tIdents(tIdentifier))) && $D(tPrevIdents(tIdentifier),tPrevElement)) {
					Set tSeqElement = tIdents(tIdentifier)
					Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,tSeqElement.recordMap,tSeqElement.name)
				}
			}
		} Elseif $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
			Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(tElement.recordMap)
			If $D(tPrevIdents(tIdentifier),tPrevElement) {
				Set tStatus = $$$ERROR($$$EnsRecordMapErrIdentifierCollision,tPrevElement.recordMap,tPrevElement.name,tElement.recordMap,tElement.name)
			} If 'tElement.isExplicitSpec() {
				Set tIdents(tIdentifier) = tElement
			}
		}
		If $$$ISERR(tStatus) Quit
		Kill tPrevIdents
		If 'tElement.isExplicitSpec() {
			Merge tPrevIdents = tIdents
		}
	}
	Quit tStatus
}

/// Method that checks for name collisions in a Complex Batch definition.
Method CheckNameCollisions(pValidate As %Boolean = 0) As %Status
{
	Set tStatus = $$$OK
	Try {
		If $IsObject(..Header) {
			If pValidate {
				Set tStatus = ..Header.%ValidateObject()
				If $$$ISERR(tStatus) Quit
			}
			If (..Header.name '= "") Set tNames(..Header.name) = ..Header
		}
		For i=1:1:..Elements.Count() {
			Set tElement = ..Elements.GetAt(i)
			If $IsObject(tElement) {
				If pValidate {
					Set tStatus = tElement.%ValidateObject()
					If $$$ISERR(tStatus) Quit
				}
				If (tElement.name '= "") {
					If $data(tNames(tElement.name)) && (tNames(tElement.name) '= tElement) {
						Set tStatus = $$$ERROR($$$EnsRecordMapErrRecNameCollision,tElement.name)
						Quit
					}
					Set tNames(tElement.name) = tElement
				}
			}
			If $classname(tElement) = "EnsLib.RecordMap.Model.RecordSequence" {
				Set tStatus = ..checkSequence(tElement,.tNames,pValidate)
				If $$$ISERR(tStatus) Quit
			}
		}
		If $$$ISERR(tStatus) Quit
		If $IsObject(..Trailer) {
			If pValidate {
				Set tStatus = ..Trailer.%ValidateObject()
				If $$$ISERR(tStatus) Quit
			}
			If (..Trailer.name '= "") {
				If $data(tNames(..Trailer.name)) && (tNames(..Trailer.name) '= ..Trailer) {
					Set tStatus = $$$ERROR($$$EnsRecordMapErrRecNameCollision,..Trailer.name)
					Quit
				}
			}
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// Helper method to check that a supplied sequence doesn't contain any name collisions.
Method checkSequence(pSequence As EnsLib.RecordMap.Model.RecordSequence, ByRef pNames As %String, pValidate As %Boolean = 0) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	For i=1:1:pSequence.Elements.Count() {
		Set tElement = pSequence.Elements.GetAt(i)
		If $IsObject(tElement) {
			If pValidate {
				Set tStatus = tElement.%ValidateObject()
				If $$$ISERR(tStatus) Quit
			}
			If (tElement.name '= "") {
				If $data(pNames(tElement.name)) && (pNames(tElement.name) '= tElement) {
					Set tStatus = $$$ERROR($$$EnsRecordMapErrRecNameCollision,tElement.name)
					Quit
				}
				Set pNames(tElement.name) = tElement
			}
		}
		If $classname(tElement) = "EnsLib.RecordMap.Model.RecordSequence" {
			Set tStatus = ..checkSequence(tElement,.pNames,pValidate)
			If $$$ISERR(tStatus) Quit
		}
	}
	Quit tStatus
}

ClassMethod validatePropertyName(pPropName As %String) As %Status
{
	Set tValid = $$$OK

	Set tPropName = pPropName
	For j=1:1:$length(tPropName) If $ziswide($extract(tPropName,j)) Set $extract(tPropName,j) = "A"
	If '$zname(tPropName, 6) { // ensure valid property names
		Set tValid = $$$ERROR($$$PropertyNameInvalid,pPropName)
	}
	Quit tValid
}

}
