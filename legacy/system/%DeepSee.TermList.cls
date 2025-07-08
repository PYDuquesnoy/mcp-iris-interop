/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// This class contains the APIs for DeepSee Term Lists.
/// A Term List is a simple lookup table that can be used to translate
/// values when creating DeepSee models or can be referenced at run-time.
Class %DeepSee.TermList Extends %RegisteredObject [ System = 4 ]
{

/// Get a list of currently defined term lists. This is returned as:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type)<br/>
ClassMethod %GetTermLists(Output pList As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		// Term lists are stored within ^DeepSee.TermList
		// The structure is:
		// ^DeepSee.TermList(NAME,"name") = Logical Name
		// ^DeepSee.TermList(NAME,"caption") = User-visible Caption
		// ^DeepSee.TermList(NAME,"pattern") = Pattern
		// ^DeepSee.TermList(NAME,"modDate") = yyyy-mm-dd
		// ^DeepSee.TermList(NAME,"subectArea") = CubeName
		// ^DeepSee.TermList(NAME,"fieldList") = ^-delimited-list-of-fields
		// ^DeepSee.TermList(NAME,"hideValue") = hide-value-column
		// ^DeepSee.TermList(NAME,"data",key,"VALUE") = primary-value
		// ^DeepSee.TermList(NAME,"data",key,PROP) = additional-field

		Set k = $O(^DeepSee.TermList(""))
		While (k'="") {
			Set tName = $G(^DeepSee.TermList(k,"name"),k)
			Set tCaption = $G(^DeepSee.TermList(k,"caption"),tName)
			Set tModDate = $G(^DeepSee.TermList(k,"modDate"))
			Try {
				Set tModDateH = $ZDTH(tModDate,3)
			}
			Catch(ex) {
				Set tModDateH = ""
			}
			Set pList($I(n)) = $LB(tName,tCaption,tModDateH,"termlist")
			Set k = $O(^DeepSee.TermList(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all currently defined DeepSee TermLists
/// in a format that can be used by a finderDialog.
ClassMethod %GetTermListArray(ByRef pParameters, Output pMetaData, Output %pData) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetTermLists(.tList)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%DeepSee.Utils).%BuildItemListArray(.tList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given term list exists.
ClassMethod %TermListExists(pTermList As %String, Output pSC As %Status) As %Boolean
{
	Set tExists = 0
	Set pSC = $$$OK
	Try {
		If (pTermList'="") {
			Set tID = $$$UPPER(pTermList)
			Set tExists = +$D(^DeepSee.TermList(tID))
		}
	}
	Catch(ex) {
		Set pSC = ex.AsStatus()
	}
	Quit tExists
}

/// Delete the specified term list.
ClassMethod %DeleteTermList(pTermList As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pTermList'="") {
			Set tID = $$$UPPER(pTermList)
			Kill ^DeepSee.TermList(tID)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Lookup a single value within the term list <var>pTermList</var>.
/// <var>pKey</var> is the unique key for the item in the term list.<br/>
/// <var>pField</var> is the name of the value field to use; if not supplied, "value" is used.<br/>
/// <var>pDefault</var> is a value to return if the key or property value do not exist.<br/>
/// If the termlist has a pattern associated with it, and the requested field is the "value"
/// field, then the pattern is applied to value before it is returned.
ClassMethod %Lookup(pTermList As %String, pKey As %String, pField As %String = "", pDefault As %String = "") As %String
{
	Set tValue = ""
	If ((pTermList'="")&&(pKey'="")) {
		Set:pField="" pField="value"
		Set pField = $$$UPPER(pField)
		Set tID = $$$UPPER(pTermList)
		Set tValue = $G(^DeepSee.TermList(tID,"data",pKey,pField),pDefault)
		If ((tValue'="")&&(pField="VALUE")) {
			// Is there a lookup pattern?
			Set tPattern = $G(^DeepSee.TermList(tID,"pattern"))
			If (tPattern'="") {
				// **
				Set tPattern = $Replace(tPattern,"**",$C(1))
				Set tValue = $Replace(tPattern,"*",tValue)
				Set tValue = $Replace(tValue,$C(1),"*")
			}
		}
	}
	Quit tValue
}

/// Lookup all values (the "value" field) from the term list <var>pTermList</var> and copy them into a local array.
/// The output is:<br/>
/// pArray(key) = value<br/>
/// If <var>pField</var> is supplied, then use the value of that field.<br/>
ClassMethod %GetValueArray(pTermList As %String, Output pArray As %String, pField As %String = "") As %Status
{
	Kill pArray
	If (pTermList'="") {
		Set tID = $$$UPPER(pTermList)
		Set tKey = $O(^DeepSee.TermList(tID,"data",""))
		While (tKey'="") {
			Set tValue = ..%Lookup(tID,tKey,pField)
			Set pArray(tKey) = tValue
			Set tKey = $O(^DeepSee.TermList(tID,"data",tKey))
		}
	}
	Quit $$$OK
}

/// Create (or update if present) the given term list.<br/>
/// <var>pTermList</var> is the name of the term list.<br/>
/// <var>pCaption</var> is the optional caption (display name) of the term list.<br/>
/// <var>pFieldList</var> is an optional ^-delimited list of fields.<br/>
/// <var>pPattern</var> is an optional pattern to apply to the "value" field.<br/>
/// <var>pDescription</var> is the description of the term list.<br/>
/// <var>pSubjectArea</var> is the optional name of the subject area the term list applies to.<br/>
ClassMethod %CreateTermList(pTermList As %String, pCaption As %String = "", pFieldList As %String = "", pPattern As %String = "", pDescription As %String = "", pSubjectArea As %String = "", pHideValue As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	If (pTermList'="") {
		Set tID = $$$UPPER(pTermList)
		Kill ^DeepSee.TermList(tID)
		Set ^DeepSee.TermList(tID,"name") = pTermList
		Set ^DeepSee.TermList(tID,"modDate") = $ZDT($H,3)
		Set:pCaption'="" ^DeepSee.TermList(tID,"caption") = pCaption
		Set:pFieldList'="" ^DeepSee.TermList(tID,"fieldList") = pFieldList
		Set:pPattern'="" ^DeepSee.TermList(tID,"pattern") = pPattern
		Set:pDescription'="" ^DeepSee.TermList(tID,"description") = pDescription
		Set:pSubjectArea'="" ^DeepSee.TermList(tID,"subjectArea") = pSubjectArea
		Set:+pHideValue'=0 ^DeepSee.TermList(tID,"hideValue") = +pHideValue
	}
	Quit tSC
}

/// Set a value within the term list <var>pTermList</var>
/// using the given key value. If <var>pField</var> is provided, then set the value of 
/// that field.
ClassMethod %SetValue(pTermList As %String, pKey As %String, pValue As %String, pField As %String = "") As %Status
{
	Set tSC = $$$OK
	If ((pTermList'="")&&(pKey'="")) {
		Set:pField="" pField="value"
		Set pField = $$$UPPER(pField)
		Set tID = $$$UPPER(pTermList)
		Set ^DeepSee.TermList(tID,"data",pKey,pField) = pValue
		Set ^DeepSee.TermList(tID,"modDate") = $ZDT($H,3)
	}
	Quit tSC
}

ClassMethod %GetTermListNameFromStream(pFileName As %String, ByRef pTermListName As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tName = ""
		If $IsObject(pFileName) {
			// read from stream
			Set tFile = pFileName
		}
		Else {
			#dim tFile as %File
			Set tFile = ##class(%File).%New(pFileName)
			Set tSC = tFile.Open("R")
			If $$$ISERR(tSC) Quit
		}

		// read meta-data values (starting with %%)
		While ('tFile.AtEnd) {
			Set tLine = tFile.ReadLine()
			If ($E(tLine,1,2)'="%%") Quit

			Do ..%ParseCSVRecord(tLine,.tRecord)

			Set tKey = $$$UPPER($G(tRecord(1)))
			Set tValue = $G(tRecord(2))
			If (tKey="%%NAME") {
				// If not supplied, use name from file
				Set:tName="" tName = tValue
			}
		}
		Set pTermListName = tName
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Load a TermList from the CSV-file, <var>pFileName</var>.
/// The first value on each line is used as a key value, the second as the "value" field. All
/// other values are ignored unless there is a field list defined. In this case, the field list
/// determines how the values within each record are used.<br/>
/// If <var>pTermListName</var> is supplied, use it. Otherwise use the %%NAME field found
/// in the file.<br/>
/// If <var>pFileName</var> is a stream, then import from it.
/// WAL041 -- pTermListName is returned
ClassMethod %ImportCSV(pFileName As %String, ByRef pTermListName As %String = "", pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tName = pTermListName

		If $IsObject(pFileName) {
			// read from stream
			Set tFile = pFileName
		}
		Else {
			#dim tFile as %File
			Set tFile = ##class(%File).%New(pFileName)
			Set tSC = tFile.Open("R")
			If $$$ISERR(tSC) Quit
		}
		
		// + WAL057 -- skip over BOM if present
		Set tLine = tFile.ReadLine()
		Do tFile.Rewind()
		If (($E(tLine,4,5)="%%") && ($E(tLine,1,2)'="%%")) {
			Do tFile.MoveTo(4)	
		}
		// - WAL057

		// read meta-data values (starting with %%)
		While ('tFile.AtEnd) {
			Set tLine = tFile.ReadLine()
			If ($E(tLine,1,2)'="%%") Quit

			Do ..%ParseCSVRecord(tLine,.tRecord)

			Set tKey = $$$UPPER($G(tRecord(1)))
			Set tValue = $G(tRecord(2))
			If (tKey="%%NAME") {
				// If not supplied, use name from file
				Set:tName="" tName = tValue
			}
			If (tKey="%%CAPTION") {
				Set tCaption = tValue
			}
			If (tKey="%%FIELDLIST") {
				Set tFieldList = tValue
			}
			ElseIf (tKey="%%PATTERN") {
				Set tPattern = tValue
			}
			ElseIf (tKey="%%DESCRIPTION") {
				Set tDesc = tValue
			}
			ElseIf (tKey="%%SUBJECTAREA") {
				Set tSubjectArea = tValue
			}
			ElseIf (tKey="%%MODDATE") {
				Set tModDate = tValue
			}
			ElseIf (tKey="%%HIDEVALUE") {
				Set tHideValue = +tValue
			}
		}

		If ($G(tName)="") {
			Set tSC=$$$ERROR($$$GeneralError,"Missing termlist name")
			Quit
		}

		Do ..%DeleteTermList(tName)
		Do ..%CreateTermList(tName,$G(tCaption),$G(tFieldList),$G(tPattern),$G(tDesc),$G(tSubjectArea),$G(tHideValue))

		If ($G(tModDate)'="") {
			// use moddate from file
			Set ^DeepSee.TermList($$$UPPER(tName),"modDate") = tModDate
		}

		// start over; read data
		Do tFile.Rewind()
		
		// + WAL057 -- skip over BOM if present
		Set tLine = tFile.ReadLine()
		Do tFile.Rewind()
		If (($E(tLine,4,5)="%%") && ($E(tLine,1,2)'="%%")) {
			Do tFile.MoveTo(4)	
		}
		// - WAL057

		While ('tFile.AtEnd) {
			Set tLine = tFile.ReadLine()
			Set tLine = $ZSTRIP(tLine,"<>W")
			If ((tLine="")||($E(tLine,1,2)="%%")) Continue

			Do ..%ParseCSVRecord(tLine,.tRecord)

			Set tKey = $G(tRecord(1))
			If (tKey'="") {
				If ($G(tFieldList)="") {
					Do ..%SetValue(tName,tKey,$G(tRecord(2)))
				}
				Else {
					Do ..%SetValue(tName,tKey,$G(tRecord(2))) // WAL090 -- we still need to handle the "value" field in this case
					// multi-fields
					For f = 1:1:$L(tFieldList,"^") {
						Set tField = $P(tFieldList,"^",f)
						If (tField'="") {
							Do ..%SetValue(tName,tKey,$G(tRecord(f+2)),tField) // WAL090 -- fieldList fields follow "value" field
						}
					}
				}
			}

		}
		Set tFile = ""
		
		// + WAL041
		Set pTermListName = tName
		// - WAL041
		
		If (pVerbose) {
			Write "Termlist '",tName,"' loaded successfully.",!
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Export a TermList to the CSV-file, <var>pFileName</var>.
/// The meta-data for the term list is written to the starting lines of the file
/// using %% as a prefix for key values.
/// + WAL044 -- add pIncludeEncoding; this is not needed in %DeepSee.UI.TermListExport
ClassMethod %ExportCSV(pTermList As %String, pFileName As %String = "", pIncludeEncoding As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Set io = ""
	Try {
		Set tID = $$$UPPER(pTermList)
		If ((pTermList="")||('$D(^DeepSee.TermList(tID)))) {
			Set tSC=$$$ERROR($$$GeneralError,"Missing or invalid termlist: "_pTermList)
			Quit
		}

		If (pFileName'="") {
			Set io = $IO
			Open pFileName:"WNS":0 Else  Set tSC=$$$ERROR($$$FileCanNotOpen,pFileName) Quit
			Use pFileName
		}

		// write out properties of csv file as name value pairs
		Set tName = $G(^DeepSee.TermList(tID,"name"))
		Set tCaption = $G(^DeepSee.TermList(tID,"caption"))
		Set tFieldList = $G(^DeepSee.TermList(tID,"fieldList"))
		Set tPattern = $G(^DeepSee.TermList(tID,"pattern"))
		Set tDescription = $G(^DeepSee.TermList(tID,"description"))
		Set tSubjectArea = $G(^DeepSee.TermList(tID,"subjectArea"))
		Set tModDate = $G(^DeepSee.TermList(tID,"modDate"))

		Kill tRecord
		Set tRecord(1) = "%%NAME",tRecord(2) = tName
		Do ..%WriteCSVRecord(.tRecord,pIncludeEncoding)

		If (tCaption'="") {
			Kill tRecord
			Set tRecord(1) = "%%CAPTION",tRecord(2) = tCaption
			Do ..%WriteCSVRecord(.tRecord,pIncludeEncoding)
		}
		If (tFieldList'="") {
			Kill tRecord
			Set tRecord(1) = "%%FIELDLIST",tRecord(2) = tFieldList
			Do ..%WriteCSVRecord(.tRecord,pIncludeEncoding)
		}
		If (tPattern'="") {
			Kill tRecord
			Set tRecord(1) = "%%PATTERN",tRecord(2) = tPattern
			Do ..%WriteCSVRecord(.tRecord,pIncludeEncoding)
		}
		If (tDescription'="") {
			Kill tRecord
			Set tRecord(1) = "%%DESCRIPTION",tRecord(2) = tDescription
			Do ..%WriteCSVRecord(.tRecord,pIncludeEncoding)
		}
		If (tSubjectArea'="") {
			Kill tRecord
			Set tRecord(1) = "%%SUBJECTAREA",tRecord(2) = tSubjectArea
			Do ..%WriteCSVRecord(.tRecord,pIncludeEncoding)
		}
		If (tModDate'="") {
			Kill tRecord
			Set tRecord(1) = "%%MODDATE",tRecord(2) = tModDate
			Do ..%WriteCSVRecord(.tRecord,pIncludeEncoding)
		}

		// data
		// JMD1170: make sure "value" is in field list
		If (tFieldList="") {
			Set tFieldList = "value"
		}
		Else {
			Set tFieldList = "value^"_tFieldList
		}
		Set tFieldList = $$$UPPER(tFieldList)

		Set tKey = $O(^DeepSee.TermList(tID,"data",""))
		While (tKey'="") {
			Kill tRecord
			Set tRecord(1) = tKey
			// loop over fields
			For f = 1:1:$L(tFieldList,"^") {
				Set tField = $P(tFieldList,"^",f)
				If (tField'="") {
					Set tRecord(f+1) = $G(^DeepSee.TermList(tID,"data",tKey,tField))
				}
			}
			Do ..%WriteCSVRecord(.tRecord,pIncludeEncoding)
			Set tKey = $O(^DeepSee.TermList(tID,"data",tKey))
		}

		If (pFileName'="") {
			Use io
			Close pFileName
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		If ($G(io)'="") {
			Use io
		}
	}
	Quit tSC
}

/// Write out the contents of the integer-indexed array <var>pRecord</var> in csv format.
/// There should be no gaps in the array.
ClassMethod %WriteCSVRecord(ByRef pRecord, pEncode As %Boolean)
{
	Set k = $O(pRecord(""))
	While (k'="") {
		Set tValue = $G(pRecord(k))
		// + WAL044
		If ($G(pEncode)) {
			Set tValue = $ZCVT(tValue,"O","UTF8")	
		}
		// - WAL044
		Write $S(((tValue)["""")||((tValue)[","):$$$quote(tValue),1:(tValue))
		Set k = $O(pRecord(k))
		Write:k'="" ","
	}
	Write !
}

/// Parse a CSV record and split it into an ordinally index array.
ClassMethod %ParseCSVRecord(pText As %String, Output pValues)
{
	Kill pValues
	
	// + WAL044 -- Expect a UTF8 encoded termlist
	Set pText = $ZCVT(pText,"I","UTF8")
	// - WAL044

	If (pText'["""") {
		// do it the old-fashioned way
		Set tItem = 1
		Set p1 = 1
		While (p1) {
			Set p2 = $Find(pText,",",p1)
			Set pValues(tItem) = $E(pText,p1,$S(p2:p2-2,1:$L(pText)))
			Set p1 = p2
			Set tItem = tItem + 1
		}
	}
	Else {
		// deal with quoted values
		Kill tVals
		Set tLine = pText_$C(0)
		Set tToken = ""
		Set tItem = 1
		Set tState = 0
		For p=1:1:$L(tLine) {
			Set ch = $E(tLine,p)
			If (tState=0) {
				If (ch="""") {
					Set tState = 1
				}
				ElseIf ((ch=",")||(ch=$C(0))) {
					Set pValues(tItem) = tToken
					Set tToken = ""
					Set tItem = tItem+1
				}
				Else {
					Set tToken = tToken_ch
				}
			}
			ElseIf (tState=1) { // in ""
				If ((ch="""")||(ch=$C(0))) {
					If ($E(tLine,p+1)="""") {
						Set tToken = tToken_""""
						Set p = p+1
					}
					Else {
						Set pValues(tItem) = tToken
						Set tToken = ""
						Set tItem = tItem+1
						Set tState = 2
					}
				}
				Else {
					Set tToken = tToken_ch
				}
			}
			Else { // , after ""
				If (ch=",") {
					Set tState = 0
				}
			}
		}
	}
}

ClassMethod %ToObj(pTermList As %String, Output pSC) As %DeepSee.UserLibrary.TermList
{
	// Method added by WAL301
	Set tObject = ""
	Try {
		Set tID = $$$UPPER(pTermList)
		If ((pTermList="")||('$D(^DeepSee.TermList(tID)))) {
			Set tSC=$$$ERROR($$$GeneralError,"Missing or invalid termlist: "_pTermList)
			Quit
		}
		
		// Make a new object
		Set tObject = ##class(%DeepSee.UserLibrary.TermList).%New()
		
		// write out properties of csv file as name value pairs
		Set tObject.name = $G(^DeepSee.TermList(tID,"name"))
		Set tObject.caption = $G(^DeepSee.TermList(tID,"caption"))
		Set tObject.fieldListString = $G(^DeepSee.TermList(tID,"fieldList"))
		For i=1:1:$L(tObject.fieldListString,"^") d tObject.fieldList.Insert($P(tObject.fieldListString,"^",i))
		// make field list
		Set tObject.pattern = $G(^DeepSee.TermList(tID,"pattern"))
		Set tObject.description = $G(^DeepSee.TermList(tID,"description"))
		Set tObject.subjectArea = $G(^DeepSee.TermList(tID,"subjectArea"))
		Set tObject.modDate = $G(^DeepSee.TermList(tID,"modDate"))

		If (tObject.fieldListString="") {
			Set tFieldList = "value"
		}
		Else {
			Set tFieldList = "value^"_tObject.fieldListString
		}
		Set tFieldList = $$$UPPER(tFieldList)
		Set tKey = $O(^DeepSee.TermList(tID,"data",""))
		While (tKey'="") {
			D tObject.keyList.Insert(tKey)
			// loop over fields
			For f = 1:1:$L(tFieldList,"^") {
				//w tKey, "  ",f,!!
				Set tField = $P(tFieldList,"^",f)
				If (tField'="") {
					D tObject.valueList.SetAt($G(^DeepSee.TermList(tID,"data",tKey,tField)),tKey_"^"_tField)
				}
			}
			Set tKey = $O(^DeepSee.TermList(tID,"data",tKey))
		}
	}
	Catch ex {
		Set pSC = ex.AsStatus()	
	}
	Quit tObject
}

ClassMethod %FromObj(pObject As %DeepSee.UserLibrary.TermList) As %Status
{
	// Method added by WAL301
	Set tSC = $$$OK
	Try {
		If ('$IsObject(pObject)) {
			Set tSC=$$$ERROR($$$GeneralError,"Missing or invalid object")
			Quit
		}
		// WAL313 -- protect against unnamed termlists causing <SUBSCRIPT> errors
		If (pObject.name="") {
			Set tSC=$$$ERROR($$$GeneralError,"Term List must be named")
			Quit
		}
		
		Set tID = $$$UPPER(pObject.name)
		
		// write metadata to global
		Set ^DeepSee.TermList(tID,"name") = pObject.name 
		Set ^DeepSee.TermList(tID,"caption") = pObject.caption
		Set ^DeepSee.TermList(tID,"fieldList") = pObject.fieldListString
		Set ^DeepSee.TermList(tID,"pattern") = pObject.pattern
		Set ^DeepSee.TermList(tID,"description") = pObject.description
		Set ^DeepSee.TermList(tID,"subjectArea") = pObject.subjectArea
		Set ^DeepSee.TermList(tID,"modDate") = pObject.modDate
		
		// write values to global
		Do pObject.valueList.GetNext(.tKey)
		While tKey'="" {
			Set tK = $P(tKey,"^",1)
			Set tF = $P(tKey,"^",2)
			Set ^DeepSee.TermList(tID,"data",tK,tF) = pObject.valueList.GetAt(tKey)
			Do pObject.valueList.GetNext(.tKey)
		} 
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
