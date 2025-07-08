/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class represents the saved state of a dashboard element.
/// Instances are stored using a generic name-value pair mechanism to provide maximum flexibility.
Class %DeepSee.Dashboard.Element Extends %RegisteredObject [ System = 3 ]
{

/// Internal property used to track if this object is modified.
Property %changed As %ZEN.Datatype.boolean [ InitialExpression = 0, Internal, Transient ];

/// Parent storage location (if any).
Property %parentGLVN As %String [ Internal, Transient ];

/// For child element, this the type of its container (or containing array key).
Property %container As %String [ Internal, Transient ];

/// Id used to save the element (based on the name).
Property %id As %String(MAXLEN = 255) [ Internal ];

/// User-specified name of the element.
Property %name As %String(MAXLEN = 255);

/// Type of this element.
Property %type As %String(MAXLEN = 255);

/// Time this element was created.
Property %createTime As %TimeStamp;

/// Time this item was most recently modified.
Property %modifiedTime As %TimeStamp;

/// Holder of name/value pairs.
Property %data [ Internal, MultiDimensional ];

/// Property dispatch method to catch references to 
/// virtual properties.<br>
/// This should not be called directly.<br>
Method %DispatchGetProperty(pProperty As %String) [ Final, Internal ]
{
	Quit $G(..%data(pProperty))
}

/// Property dispatch method to catch references to 
/// virtual properties.<br>
/// This should not be called directly.<br>
Method %DispatchSetProperty(pProperty As %String, pValue As %String) [ Final, Internal ]
{
	If ('$D(..%data(pProperty)) || (..%data(pProperty)'=pValue)) {
		Set ..%changed = 1
		Set ..%data(pProperty) = pValue
	}
}

/// Delete all name/value pairs currently in this object.
Method %Clear() [ Final ]
{
	Kill ..%data
}

/// Copy the name/value pairs in this element into
/// a local array subscripted by property name.
Method %CopyToArray(Output pArray) [ Final ]
{
	Kill pArray
	Merge pArray = ..%data
}

/// Copy the values from a local array 
/// (subscripted by property name) into
/// this element.
Method %CopyFromArray(ByRef pArray) [ Final ]
{
	Kill ..%data
	Merge ..%data = pArray
}

/// Save this element.
Method %Save() As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		If (..%parentGLVN'="") {
			Set tGLVN = $Name(@..%parentGLVN@(..%id,..%container))
		}
		Else {
			If (..%id = "") {
				// first save
				Set tID = $$$UPPER(..%name)
				If (..%ExistsId(tID)) {
					Set tSC = $$$ERROR($$$GeneralError,"element with name already exists")
					Quit
				}
				Set ..%id = tID
				Set ..%createTime = $ZDT($H,3)
			}
			Else {
				Set tID = ..%id
			}
			Set tGLVN = $Name($$$DeepSeeElementGLVN(tID))
			Set ..%modifiedTime = $ZDT($H,3)
		}
		If (..%id = "") {
			Set tSC = $$$ERROR($$$GeneralError,"name is required for element")
			Quit
		}
		Kill @tGLVN
		Set:..%name'="" @tGLVN = ..%name 	// no name for sub-element
		Set @tGLVN@("%type") = ..%type
		Set:..%createTime'="" @tGLVN@("%createTime") = ..%createTime
		Set:..%modifiedTime'="" @tGLVN@("%modifiedTime") = ..%modifiedTime

		Set p = $O(..%data(""),1,tValue)
		While (p'="") {
			If $IsObject($G(tValue)) {
				If (tValue.%IsA("%DeepSee.Dashboard.Element")) {
					Set tValue.%id = p
					Set tValue.%container = ">"
					Set tValue.%parentGLVN = tGLVN
					Set tSC = tValue.%Save()
					If $$$ISERR(tSC) Quit
				}
				ElseIf (tValue.%IsA("%Library.ListOfObjects")) {
					For n=1:1:tValue.Count() {
						Set tItem = tValue.GetAt(n)
						Set tItem.%id = p
						Set tItem.%container = n
						Set tItem.%parentGLVN = tGLVN
						Set tSC = tItem.%Save()
						If $$$ISERR(tSC) Quit
					}
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Unknown object type in element save")
					Quit
				}
			}
			Else {
				Set @tGLVN@(p) = tValue
			}
			Set p = $O(..%data(p),1,tValue)
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Open this element given its unique name.
ClassMethod %ExistsId(pID As %String) As Element [ CodeMode = expression, Final ]
{
''$D($$$DeepSeeElementGLVN(pID))
}

/// Delete all elements.
ClassMethod %KillExtent() As %Status [ Final ]
{
	Kill $$$DeepSeeElementGLVN
	Quit $$$OK
}

/// Open this element given its unique name.
ClassMethod %OpenId(pID As %String, Output pSC As %Status) As Element [ Final ]
{
	Set pSC = $$$OK
	Set tElement = ""
	Try {
		Set pID = $$$UPPER(pID)
		If $D($$$DeepSeeElementGLVN(pID)) {
			Set tElement = ..%New()
			Set tElement.%id = pID
			Set tElement.%name = $$$DeepSeeElementGLVN(pID)
			Set tElement.%type = $G($$$DeepSeeElementGLVN(pID,"%type"))
			Set tElement.%createTime = $G($$$DeepSeeElementGLVN(pID,"%createTime"))
			Set tElement.%modifiedTime = $G($$$DeepSeeElementGLVN(pID,"%modifiedTime"))
			Merge tElement.%data = $$$DeepSeeElementGLVN(pID)
			Kill tElement.%data("%type")
			Kill tElement.%data("%createTime")
			Kill tElement.%data("%modifiedTime")
		}
	}
	Catch(ex) {
		Set pSC = ex.AsStatus()
	}
	Quit tElement
}

/// Delete this element given it unique name.
Method %DeleteId(pID As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set pID = $$$UPPER(pID)
		If $D($$$DeepSeeElementGLVN(pID)) {
			Kill $$$DeepSeeElementGLVN(pID)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Copy data from an object into this element.
Method %CopyFromObject(pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..%GetSettings(..%type,.tSettings)
		If $$$ISERR(tSC) Quit

		// copy values of settings into our n/v array
		Set p = $O(tSettings(""),1,tDefault)
		While (p'="") {
			Set tValue = $zobjproperty(pObject,p)
			If ($E(tDefault,1,2)="@@") { // reference
				Set tType = $E(tDefault,3,*)
				If $IsObject(tValue) {
					Set tEl = ..%New()
					Set tEl.%type = tType
					Set tSC = tEl.%CopyFromObject(tValue)
					If $$$ISERR(tSC) Quit
					Set ..%data(p) = tEl
				}
			}
			ElseIf ($E(tDefault,1,2)="##") { // list
				If $IsObject(tValue) {
					Set tType = $E(tDefault,3,*)
					Set tList = ##class(%ListOfObjects).%New()
					Set ..%data(p) = tList
					For n=1:1:tValue.Count() {
						Set tItem = tValue.GetAt(n)
						If $IsObject(tItem) {
							Set tEl = ..%New()
							Set tEl.%type = tType
							Set tSC = tEl.%CopyFromObject(tItem)
							If $$$ISERR(tSC) Quit
							Do tList.Insert(tEl)
						}
					}
				}
			}
			Else { // literal
				Set:tValue'=$G(tDefault) ..%data(p) = tValue
			}
			Set p = $O(tSettings(p),1,tDefault)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Copy data from this element to an object.
Method %CopyToObject(pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..%GetSettings(..%type,.tSettings)
		If $$$ISERR(tSC) Quit

		// copy values of settings into our n/v array
		Set p = $O(tSettings(""),1,tDefault)
		While (p'="") {
			Set $zobjproperty(pObject,p) = $G(..%data(p),tDefault)
			Set p = $O(tSettings(p),1,tDefault)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get settings meta-data for the given element type.
ClassMethod %GetSettings(pType As %String, Output pSettings) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pSettings
		If (pType = "pivot") {
			Set pSettings("table") = "@@pivotTable"
			Set pSettings("chart") = "@@chart"
		}
		ElseIf (pType = "pivotTable") {
			Set pSettings("cubeName") = ""
			Set pSettings("caption") = ""
			Set pSettings("pageSize") = 100
			Set pSettings("showEmptyRows") = 0
			Set pSettings("showEmptyColumns") = 0
			Set pSettings("selectedCellColor") = "white"
			Set pSettings("selectedCellBackground") = "rgb(47,98,128)"

			// @@ = reference
			Set pSettings("rowAxisOptions") = "@@pivotLevel"
			Set pSettings("columnAxisOptions") = "@@pivotLevel"

			// ## = list
			Set pSettings("rowLevels") = "##pivotLevel"
			Set pSettings("columnLevels") = "##pivotLevel"
			Set pSettings("filters") = "##pivotLevel"
		}
		ElseIf (pType = "pivotLevel") {
			Set pSettings("spec") = ""
			Set pSettings("headEnabled") = 0
			Set pSettings("headCount") = ""
			Set pSettings("filterEnabled") = 0
			Set pSettings("filterExpression") = ""
			Set pSettings("orderEnabled") = 0
			Set pSettings("orderExpression") = ""
			Set pSettings("orderDirection") = "BDESC"
			Set pSettings("aggEnabled") = 0
			Set pSettings("aggFunction") = ""

			Set pSettings("childLevels") = "##pivotLevel"
		}
		ElseIf (pType = "chart") {
			Set pSettings("labelsVisible") = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
