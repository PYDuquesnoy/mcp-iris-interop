/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Object representation of a RecordMap Record
/// Note that this class is responsible for the persistence
/// and swizzling of the Contents object graph containing Field and Composite objects
Class EnsLib.RecordMap.Model.Record Extends (%RegisteredObject, %XML.Adaptor, Ens.Util.PortalModelBase) [ System = 4 ]
{

Parameter XMLSEQUENCE = 1;

Parameter NAMESPACE = "http://www.intersystems.com/Ensemble/RecordMap";

/// Name of the RecordMap.
Property name As %String(MAXLEN = 220, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// The type of Record; options include delimited and fixed width types.
Property type As EnsLib.RecordMap.Model.DataType.RecordType(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "delimited", Required ];

/// Character encoding for imported data records
Property charEncoding As %String(XMLNAME = "char_encoding", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "UTF-8", Required ];

/// Name of the InterSystems IRIS class to represent the Record.
/// This class will be generated as a subclass of EnsLib.RecordMap.Base.
/// If the RECORDMAPGENERATED parameter of the existing class is 0, then the target class will 
/// not be modified by the RecordMap framework - all changes are then the responsibility
/// of the user.
Property targetClassname As %String(MAXLEN = 220, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Name of the batch class (if any) which should be associated with this RecordMap.
/// NOTE: This only applies to simple Batch classes which extend EnsLib.RecordMap.Batch.
Property batchClass As %String(MAXLEN = 220, XMLPROJECTION = "ATTRIBUTE");

/// Flag to indicate whether the RecordMap can be included in a ComplexMap.
Property complexBatchManaged As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Leading character data prior to the actual record contents.
Property label As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

/// Character(s) to use for padding. Required for fixed width Records
Property paddingChars As %String(XMLPROJECTION = "ATTRIBUTE");

/// Controls right justification (i.e. padding from the left).
Property padFromLeft As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Character(s) used to indicate the end of a particular record.
Property recordTerminator As %String(XMLPROJECTION = "ATTRIBUTE");

/// Property for fixed width Record types only.
/// The Record will fail validation if this is set for other Record types.
/// This indicates whether a character (or characters) must appear between all Fields.
/// Note that the width of this separator will be included in calculations for later Fields.
Property fieldSeparator As %String(XMLPROJECTION = "ATTRIBUTE");

/// Property for delimited Record types only.
/// The Record will fail validation if this is set for other Record types.
/// If a delimited record contains repeating fields, this separator indicates what character(s)
/// should be used to delimit the repeating data.
Property repeatSeparator As %String(XMLPROJECTION = "ATTRIBUTE");

/// Property for delimited Record types only.
/// The Record will fail validation if this is set for other Record types.
/// This is a list of Separators (or delimiters), in nesting order from outermost to innermost.
Property Separators As list Of %String(XMLITEMNAME = "Separator");

/// Property for delimited Record types only.
/// The Record will fail validation if this is set for other Record types.
/// Indicate which escape strategy is in use, where the <property>escapeSequence</property>
/// captures the characters to be used.
Property escaping As %String(VALUELIST = ",,quote,all", XMLPROJECTION = "ATTRIBUTE");

/// Property for delimited Record types only.
/// The Record will fail validation if this is set for other Record types.
/// This represents the character(s) used for escaping as determined by the value
/// of the <property>escaping</property> property.
Property escapeSequence As %String(XMLPROJECTION = "ATTRIBUTE");

/// Property for delimited Record types only.
/// The Record will fail validation if this is set for other Record types.
/// The Record will also fail validation if escaping strategy is empty string.
/// This enables support for the record terminator character(s) to be
/// included in field data.
Property allowEmbeddedRecordTerminator As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Property for fixedwidth Record types only.
/// The Record will fail validation if this is set for other Record types.
/// When true, this flag indicates whether an earlier than expected record terminator will simply set
/// all subsequent properties to "" instead of treating the short record as invalid.
Property allowEarlyTerminator As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Comments for the Record. This text will appear as part of the class comments.
Property annotation As %String(MAXLEN = 1024);

/// List of all Composite and Field objects which are contained in the first level of this Record -
/// each Composite object must contain at least one embedded Composite or Field, and those embedded
/// objects do not appear directly in this list.
Property Contents As list Of EnsLib.RecordMap.Model.RecordProperty(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Required ];

/// Validates and then serializes the current RecordMap structure into XML inside the RecordMap XData block
/// in the relevant RecordMap class.
Method SaveToClass() As %Status
{
	Try {
		Set tSC = ..%ValidateObject(1)
		If $$$ISERR(tSC) Quit
		
		Set tWriter = ##class(%XML.Writer).%New()
		//Set tWriter.Charset = "UTF-8"
		Set tWriter.NoXMLDeclaration = 1
		Set tWriter.Indent = 1
		
		Set tStream = ##class(%Stream.TmpCharacter).%New()
		
		Set tSC = tWriter.OutputToStream(tStream)
		If $$$ISERR(tSC) Quit
		
		Set tSC = tWriter.RootObject($this)
		If $$$ISERR(tSC) Quit
		
		Set tClassname = $$$NormalizeClassname(..name)
		
		Set tDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassname)
		If '$IsObject(tDefinition) {
			Set tDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tDefinition.Name = tClassname
			Set tDefinition.Super = "EnsLib.RecordMap.RecordMap"
			Set tDefinition.ClassVersion = $$$CLASSDEFINITIONVERSION
		}
		Else {
			// Remove current XData block
			Set tXDataLoc = tDefinition.XDatas.FindObjectId(tClassname_"||RecordMap")
			If tXDataLoc'="" Do tDefinition.XDatas.RemoveAt(tXDataLoc)
		}
		Do ##class(EnsLib.RecordMap.GenUtils).updateAnnotation(tDefinition,..annotation)
		
		Set tXData = ##class(%Dictionary.XDataDefinition).%New()
		
		Set tXData.Name = "RecordMap"
		Set tXData.parent = tDefinition
		Set tXData.XMLNamespace = ..#NAMESPACE
		Do tStream.Rewind()
		
		Set tSC = tXData.Data.CopyFrom(tStream)
		If $$$ISERR(tSC) Quit
		
		Set tSC = tDefinition.%Save()
		If $$$ISERR(tSC) Quit

		Set ..Timestamp = $zdatetime(tDefinition.TimeChanged,3,,6)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Deserialize the XML from the RecordMap XData block and create a Record object based on that XML.
ClassMethod LoadFromClass(pClassname As %String, Output pStatus As %Status, Output pReadOnly As %Boolean, pConcurrency As %Integer = -1) As EnsLib.RecordMap.Model.Record
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

		Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(pClassname,"RecordMap",pConcurrency,.pStatus)
		If tXData = "" {
			Set pStatus = $$$ERROR($$$XDataBlockMissing,pClassname,"RecordMap")
			Quit
		}
		
		Set tReader = ##class(%XML.Reader).%New()
		Set pStatus = tReader.OpenStream(tXData.Data)
		If $$$ISERR(pStatus) Quit
		
		Do tReader.Correlate("Record", "EnsLib.RecordMap.Model.Record")
		
		If 'tReader.Next(.tRecord, .pStatus) {
			If $$$ISERR(pStatus) Quit
			
			Set pStatus = $$$ERROR($$$XDataBlockMissingNode,pClassname,"RecordMap","Record")
			Quit
		}
		If $IsObject(tRecord) {
			Set tRecord.Timestamp = $zdatetime(tDefinition.TimeChanged,3,,6)
			Set tRecord.ReadOnly = pReadOnly
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	If $$$ISERR(pStatus) Quit $$$NULLOREF
	
	Quit tRecord
}

/// Method to check whether a specified RecordMap exists.
ClassMethod Exists(pRecordMapName As %String, ByRef pStatus As %Status) As %Boolean
{
	Try {
		Set tExists = 0
		Set pStatus = $$$OK
		Set pRecordMapName = $$$NormalizeClassname($get(pRecordMapName))
		If pRecordMapName = "" Quit
		
		If '##class(%Dictionary.ClassDefinition).%ExistsId(pRecordMapName) Quit
		
		Set tDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pRecordMapName,,.pStatus)
		If $$$ISERR(pStatus) Quit
		
		If '(tDefinition.Super [ "EnsLib.RecordMap.RecordMap") Quit
		
		If "" '= tDefinition.XDatas.FindObjectId(pRecordMapName_"||RecordMap") {
			Set tExists = 1
			Quit
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tExists = 0
	}
	If ('tExists) && $$$ISOK(pStatus) {
		Set pStatus = $$$ERROR($$$ClassDoesNotExist,pRecordMapName)
	}
	Quit tExists
}

/// Perform validation on properties specific to the particular Record type
Method %OnValidateObject() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set tSC = $$$OK
	If '(..type="fixedwidth") {
		If ..fieldSeparator'="" Quit $$$ERROR($$$EnsRecordMapErrInvalidRecordProp,..type,"fieldSeparator")
		If (0'=+..allowEarlyTerminator) Quit $$$ERROR($$$EnsRecordMapErrInvalidRecordProp,..type,"allowEarlyTerminator")
	}
	
	If (..type="fixedwidth") {
		If ..paddingChars="" Quit $$$ERROR($$$EnsRecordMapErrInvalidRecordProp,..type,"paddingChars")
	}
	
	If '(..type="delimited") {
		If ..escaping '= "" Quit $$$ERROR($$$EnsRecordMapErrInvalidRecordProp,..type,"escaping")
		If ..escapeSequence '= "" Quit $$$ERROR($$$EnsRecordMapErrInvalidRecordProp,..type,"escapeSequence")
		If ..repeatSeparator '= "" Quit $$$ERROR($$$EnsRecordMapErrInvalidRecordProp,..type,"repeatSeparator")
		If (0'=+..allowEmbeddedRecordTerminator) Quit $$$ERROR($$$EnsRecordMapErrInvalidRecordProp,..type,"allowEmbeddedRecordTerminator")
	}
	
	If (..type="delimited") {
		If ..Separators.Count()=0 Quit $$$ERROR($$$CollectionPropertyRequired,"Separators")
		Set seps = 0
		Set tSC = $$$OK
		For i=1:1:..Separators.Count() {
			Set currSep = ..Separators.GetAt(i)
			If currSep = "" {
				Set tSC = $$$ERROR($$$EnsRecordMapErrEmptySeparator,..name, i)
				Quit
			}
			Else {
				For j=1:1:seps {
					If ($find(seps(j), currSep) > 0)||($find(currSep, seps(j)) > 0) {
						Set tSC = $$$ERROR($$$EnsRecordMapErrDuplicateSeps)
						Quit
					}
				}
				If $$$ISERR(tSC) Quit
				Set seps($i(seps)) = currSep
			}
		}
		If $$$ISERR(tSC) Quit tSC
		
		Set tMaxDepth = 0
		Set tHasRepeats = 0
		For j=1:1:..Contents.Count() {
			Set tObject = ..Contents.GetAt(j)
			Set tDepth = tObject.GetDepth(.tHasRepeats)
			If tDepth > tMaxDepth Set tMaxDepth = tDepth
		}
		If (tMaxDepth > ..Separators.Count()) Quit $$$ERROR($$$EnsRecordMapErrNotEnoughSeps)
		If $get(tHasRepeats) && (..repeatSeparator = "") Quit $$$ERROR($$$EnsRecordMapErrNoRepSeparator)
	}
	Else {
		If ..Separators.Count()>0 Quit $$$ERROR($$$EnsRecordMapErrInvalidRecordProp,..type,"Separators")
	}
	
	If ..complexBatchManaged && (..batchClass '= "") Quit $$$ERROR($$$EnsRecordMapErrBatchClassNotPermitted)
	
	For i=1:1:..Contents.Count() {
		Set tObject = ..Contents.GetAt(i)
		Set tObject.RecordType = ..type
		Set tSC = tObject.%ValidateObject(1)
		If $$$ISERR(tSC) Quit
	}
	If $$$ISERR(tSC) Quit tSC
	
	Quit ..ValidateObjectMap($this)
}

/// Check for collisions in object names before save
ClassMethod ValidateObjectMap(pRecord As EnsLib.RecordMap.Model.Record) As %Status
{
	Quit ##class(EnsLib.RecordMap.Generator).getStructure(pRecord)
}

}
