/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// This class represents a DeepSee Worksheet within a DeepSee folder.<br/>
/// This class also provides the APIs for working with DeepSee "worksheets".
/// A worksheet can be used in several ways:<br/>
/// 1) You can use a worksheet to define a specialized KPI containing user-entered data that drives other dashboard widgets.<br/>
/// 2) You can use a worksheet to feed values into other DeepSee components, such as pivot tables.<br/>
/// 3) You can use a worksheet to enter and display a grid of values.
/// <br/>
Class %DeepSee.UserLibrary.Worksheet Extends %DeepSee.UserLibrary.FolderItem [ System = 4 ]
{

Parameter XMLNAME = "worksheet";

/// This is the extension returned by this type from the Finder.
Parameter ITEMTYPE = "worksheet";

Parameter ICON = "deepsee/ds2_list_44.png";

Parameter LARGEICON = "deepsee/ds2_list_44.png";

/// Default format to apply to cells in this worksheet.<br/>
Property format As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Additional style to apply to cells in this worksheet.<br/>
Property style As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// Additional style to apply to column headers in this grid.<br/>
Property columnHeaderStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// Additional style to apply to row headers in this grid.<br/>
Property rowHeaderStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// Specify whether cell borders should be "all" (the default) or "none".<br/>
Property borders As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Specify whether zebra striping should be applied to the grid.
Property showZebra As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute");

/// Specifies whether row labels should be displayed.
Property showRowLabels As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Specifies whether column labels should be displayed.
Property showColumnLabels As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// This contains the definition of the row headers for this worksheet.
Property rowHeaders As list Of WorksheetAxis(XMLNAME = "rowHeader", XMLPROJECTION = "ELEMENT");

/// This contains the definition of the column headers for this worksheet.
Property columnHeaders As list Of WorksheetAxis(XMLNAME = "columnHeader", XMLPROJECTION = "ELEMENT");

/// This contains the definition of (overridden) cells for this worksheet.
Property cells As list Of WorksheetCell(XMLNAME = "cellDef", XMLPROJECTION = "ELEMENT");

/// Data mode for the worksheet: "dataSet" or "dataSource".
Property gridMode As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Name of data connector class used by the grid (in "dataSource" mode).
Property dataConnector As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Page size used by the grid (in "dataSource" mode).
Property pageSize As %ZEN.Datatype.integer(XMLPROJECTION = "attribute");

/// Default column width.
Property columnWidth As %ZEN.Datatype.integer;

/// This holds the definition of the cells within this worksheet.<br/>
/// %cells(r,c) = value
Property %cells As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional, Transient ];

/// This holds the values of the cells within this worksheet after any calculations have been resolved.<br/>
/// %values(r,c) = value
Property %values As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional, Transient ];

/// This is used to hold cell values when they are exported to XML.
Property xmlCells As list Of %String(XMLNAME = "cell", XMLPROJECTION = "ELEMENT") [ Transient ];

/// This is used to hold cell (resolved) values when they are exported to XML.
Property xmlValues As list Of %String(XMLNAME = "value", XMLPROJECTION = "ELEMENT") [ Transient ];

/// Index of row names used during calculation.
Property %rowIndex As %Integer(XMLPROJECTION = "none") [ Internal, MultiDimensional, Transient ];

/// Index of column names used during calculation.
Property %columnIndex As %Integer(XMLPROJECTION = "none") [ Internal, MultiDimensional, Transient ];

/// Current row during calculation.
Property %currRow As %Integer(XMLPROJECTION = "none") [ Internal, Transient ];

/// Current column during calculation.
Property %currColumn As %Integer(XMLPROJECTION = "none") [ Internal, Transient ];

/// Array of values from external sources (used during calculation).
Property %externalValues As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional, Transient ];

/// Array of external sources (used during calculation).
Property %externalRefs As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional, Transient ];

/// Return the URL for this item.
Method %GetURL() As %String
{
	Set tURL = "%25DeepSee.UI.WorksheetBuilder.zen"
	Set tURL = tURL _ "?WORKSHEET="_$ZCVT(..fullName,"O","URL")
	Quit tURL
}

/// Return the localized type name for this item.
Method %GetTypeName() As %String
{
	Quit $$$Text("Worksheet","%DeepSee")
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	// save contents of %cells array
	Kill ^DeepSee.FolderItemD(..%Id(),"cells")
	Merge ^DeepSee.FolderItemD(..%Id(),"cells") = ..%cells

	// calculate before saving
	If (1) {
		Set tSC = ..%Calculate()
		If $$$ISERR(tSC) Quit tSC
	}

	// save contents of %values array
	Kill ^DeepSee.FolderItemD(..%Id(),"values")
	Merge ^DeepSee.FolderItemD(..%Id(),"values") = ..%values
	Quit $$$OK
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Kill ^DeepSee.FolderItemD($LG(oid),"cells")
	Quit $$$OK
}

Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	// load contents of %cells array
	Kill ..%cells
	Merge ..%cells = ^DeepSee.FolderItemD(..%Id(),"cells")

	// load contents of %values array
	Kill ..%values
	Merge ..%values = ^DeepSee.FolderItemD(..%Id(),"values")
	Quit $$$OK
}

/// Notification that this item has just been imported.
Method %OnAfterImport() As %Status
{
	// copy collections into md-arrays
	Kill ..%cells
	Kill ..%values

	Set tItem = 0
	Set tRowCount = ..rowHeaders.Count()
	Set tColCount = ..columnHeaders.Count()
	For r=1:1:tRowCount {
		For c=1:1:tColCount {
			Set tItem = tItem + 1
			Set ..%cells(r,c) = ..xmlCells.GetAt(tItem)
			Set ..%values(r,c) = ..xmlValues.GetAt(tItem)
		}
	}
	Quit $$$OK
}

/// Notification before xml export.
Method XMLBeforeExport()
{
	// copy cells into format that can be exported.
	Do ..xmlCells.Clear()
	Do ..xmlValues.Clear()

	Set tRowCount = ..rowHeaders.Count()
	Set tColCount = ..columnHeaders.Count()
	For r=1:1:tRowCount {
		For c=1:1:tColCount {
			Do ..xmlCells.Insert($G(..%cells(r,c)))
			Do ..xmlValues.Insert($G(..%values(r,c)))
		}
	}
}

/// Copy the contents of this definition to pivot table <var>pPivot</var>.
Method %CopyToComponent(pPivot As %DeepSee.Component.pivotTable) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Set the contents of this definition from pivot table <var>pPivot</var>.
Method %CopyFromComponent(pPivot As %DeepSee.Component.pivotTable) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Resolve values of any formulas within this worksheet.
/// This takes the raw values in %cells, executes formulas, and puts the results into %values.
Method %Calculate() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// remove old values
		Kill ..%values

		// get size and labels of worksheet
		Set tRowCount = ..rowHeaders.Count()
		Set tColCount = ..columnHeaders.Count()

		// index of row/column names
		Kill ..%rowIndex
		For r=1:1:tRowCount {
			Set tRowInfo = ..rowHeaders.GetAt(r)
			If (tRowInfo.name'="") {
				Set ..%rowIndex($$$LOWER(tRowInfo.name)) = r
			}
		}
		Kill ..%columnIndex
		For c=1:1:tColCount {
			Set tColInfo = ..columnHeaders.GetAt(c)
			If (tColInfo.name'="") {
				Set ..%columnIndex($$$LOWER(tColInfo.name)) = c
			}
		}

		// first pass: find formulae and literal values
		For c=1:1:tColCount {
			Set tColInfo = ..columnHeaders.GetAt(c)
			Set tColValue = tColInfo.value
			Set tCPrio = $S(tColInfo.priority="":1,1:tColInfo.priority)
			For r=1:1:tRowCount {
				Set tRowInfo = ..rowHeaders.GetAt(r)
				Set tRowValue = tRowInfo.value
				Set tRPrio = $S(tRowInfo.priority="":1,1:tRowInfo.priority)

				Set tValue = $G(..%cells(r,c))
				If (tValue="") {
					If (tCPrio>tRPrio) {
						Set tValue = $S(tColValue'="":tColValue,1:tRowValue)
					}
					Else {
						Set tValue = $S(tRowValue'="":tRowValue,1:tColValue)
					}
				}

				If ($E(tValue,1)="=") {
					// queue up for later
					Set tCalc(c,r) = $LB(tCPrio,tRPrio,tValue)
				}
				Else {
					Set ..%values(r,c) = tValue
				}
			}
		}

		// now resolve the formulae
		Set tMaxAttempts = (tRowCount*tColCount)+2
		Set tAttempts = 0
		While ($D(tCalc) && (tAttempts<tMaxAttempts)) {
			Set tCalcs = 0
			Kill ..%externalRefs

			Set c = $O(tCalc(""))
			While (c'="") {
				Set ..%currColumn = c

				Set r = $O(tCalc(c,""))
				While (r'="") {
					Set tCPrio = $LG(tCalc(c,r),1)
					Set tRPrio = $LG(tCalc(c,r),2)
					Set tValue = $LG(tCalc(c,r),3)

					Set ..%currRow = r

					// try to evaluate
					If (..%EvaluateCell($E(tValue,2,*),r,c,.tResult,.tSC)) {
						Set ..%values(r,c) = tResult
						Set tCalcs = tCalcs + 1
						Kill tCalc(c,r)
					}
					If $$$ISERR(tSC) Quit
					Set r = $O(tCalc(c,r))
				}
				If $$$ISERR(tSC) Quit
				Set c = $O(tCalc(c))
			}
			If $$$ISERR(tSC) Quit

			Set tAttempts = tAttempts + 1
			// test for external refs
			If ($D(..%externalRefs)) {
				// resolve
				Set tKey = $O(..%externalRefs(""))
				While (tKey'="") {
					Set tAnswer = ##class(%DeepSee.UserLibrary.Worksheet).%LookupReference(.tContext,tKey)
					Set ..%externalValues(tKey) = tAnswer

					Set tKey = $O(..%externalRefs(tKey))
				}
			}
			ElseIf (tCalcs=0) {
				Quit
			}

			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Evaluate formula for one cell.<br/>
/// Return false if it has unresolved dependencies.
Method %EvaluateCell(pValue As %String, pRow As %Integer, pCol As %Integer, Output pResult As %String, Output pSC As %Status) As %Boolean [ Internal ]
{
	Set tResolved = 0
	Set pResult = ""
	Set pSC = $$$OK

	Set pResult = ##class(%DeepSee.WorksheetEngine).%Evaluate(pValue,##this,.tMsg,.pSC)
	If (tMsg '= "") {
		Set pResult = tMsg
		Set tResolved = 1
	}
	ElseIf (pResult'="@REF") {
		Set tResolved = 1
	}
	Quit tResolved
}

/// Formula function: Lookup the value of the given identifier.
Method %Lookup(pIdent As %String) As %String
{
	Set tValue = "@REF"

	// pull apart ident (which has [] around each piece)
	Set tItemCount = $L(pIdent,"].")
	For p=1:1:tItemCount {
		Set t = $E($P(pIdent,"].",p),2,*)
		Set:$E(t,*)="]" t = $E(t,1,*-1)
		Set tItems(p) = $$$LOWER(t)
	}

	Set tCol = 0
	Set tRow = 0
	If (tItemCount = 1) {
		If (tItems(1)="$col") {
			Set tCol = ..%currColumn
		}
		Else {
			Set tCol = +$G(..%columnIndex(tItems(1)))
		}
		Set tRow = ..%currRow
	}
	ElseIf (tItemCount = 2) {
		If (tItems(1)="$col") {
			Set tCol = ..%currColumn
		}
		Else {
			Set tCol = +$G(..%columnIndex(tItems(1)))
		}
		If (tItems(2)="$row") {
			Set tRow = ..%currRow
		}
		Else {
			Set tRow = +$G(..%rowIndex(tItems(2)))
		}
	}
	ElseIf (tItemCount = 3) {
		// external ref
		// in cache?
		Set tKey = $$$LOWER(pIdent)
		If $D(..%externalValues(tKey)) {
			Set tValue = ..%externalValues(tKey)
		}
		Else {
			Set ..%externalRefs(tKey) = ""
			Set tValue = "@REF"
		}
	}
	Else {
		Set tValue = "@IDENT"
	}

	If (tRow && tCol && $D(..%values(tRow,tCol))) {
		Set tValue = ..%values(tRow,tCol)
	}

	Quit tValue
}

/// Lookup the value of a complete cell reference: [source].[col].[row]
/// <var>pContext</var> tracks all the data sources that have been referenced.
ClassMethod %LookupReference(ByRef pContext, pIdent As %String) As %String [ Internal ]
{
	Set tValue = "@REF"

	// pull apart ident (which has [] around each piece)
	Set tItemCount = $L(pIdent,"].")
	For p=1:1:tItemCount {
		Set t = $E($P(pIdent,"].",p),2,*)
		Set:$E(t,*)="]" t = $E(t,1,*-1)
		Set tItems(p) = $$$LOWER(t)
	}
	
	If (tItemCount=3) {
		Set tDSName = tItems(1)
		Set tExt = $P(tDSName,".",$L(tDSName,"."))
		If (tExt=tDSName) {
			Set tDSName = tDSName _ ".worksheet"
			Set tExt = "worksheet"
		}
		Set tDSObject = $G(pContext(tDSName))
		If (tExt = "worksheet") {
			// short-cut
			If (tDSObject="") {
				Set tDSObject = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDSName,.tSC)
				If ($IsObject(tDSObject)) {
					// make sure worksheet is up-to-date
					// and indices are in place
					Set tSC = tDSObject.%Calculate()
				}
			}

			If '$IsObject(tDSObject) {
				Set pContext(tDSName) = "missing"
				Set tValue = "@MISSING"
			}
			Else {
				Set pContext(tDSName) = tDSObject
				Set tValue = tDSObject.%Lookup("["_tItems(2)_"].["_tItems(3)_"]")
			}
		}
		Else {
			// other data source types !!!
			Set tValue = "@NODATA"
			Set pContext(tDSName) = "missing"
		}
	}

	Quit tValue
}

Storage Default
{
<Data name="WorksheetDefaultData">
<Subscript>"Worksheet"</Subscript>
<Value name="1">
<Value>rowHeaders</Value>
</Value>
<Value name="2">
<Value>columnHeaders</Value>
</Value>
<Value name="3">
<Value>cells</Value>
</Value>
<Value name="4">
<Value>format</Value>
</Value>
<Value name="5">
<Value>style</Value>
</Value>
<Value name="6">
<Value>columnHeaderStyle</Value>
</Value>
<Value name="7">
<Value>rowHeaderStyle</Value>
</Value>
<Value name="8">
<Value>borders</Value>
</Value>
<Value name="9">
<Value>showZebra</Value>
</Value>
<Value name="10">
<Value>showRowLabels</Value>
</Value>
<Value name="11">
<Value>showColumnLabels</Value>
</Value>
<Value name="12">
<Value>gridMode</Value>
</Value>
<Value name="13">
<Value>dataConnector</Value>
</Value>
<Value name="14">
<Value>pageSize</Value>
</Value>
<Value name="15">
<Value>columnWidth</Value>
</Value>
</Data>
<DefaultData>WorksheetDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
