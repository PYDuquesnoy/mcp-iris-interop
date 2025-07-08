/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a listBox that gets its list from an SQL query.<br/>
/// Refer to the <class>%ZEN.Component.querySource</class> class for
/// a description of how to provide data for this component.<br/>
/// The dataListBox control will support both drag and drop. If 
/// <property>dragEnabled</property> is true, then the user can drag values
/// from the list box and drop them on other drop-enabled components.<br/>
/// If <property>dropEnabled</property> is true, then values can be dropped
/// onto the list. The value of the list box will be set to the value of the
/// dropped data.
Class %ZEN.Component.dataListBox Extends (abstractListBox, querySource) [ Deprecated, Inheritance = right, System = 3 ]
{

/// If true (the default), then display multiple columns in the data
/// list if the result set contains more than 2 columns.
Property multiColumn As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If there are multiple data columns displayed within the  data list
/// this is the column number (1-based) of the column that will provide the display
/// value for this control.<br>
/// If this value is greater than the number of columns in the query
/// then the second column will be used.
Property choiceColumn As %ZEN.Datatype.integer(MINVAL = 1, ZENSETTING = 0) [ InitialExpression = 2 ];

/// If there are multiple data columns displayed in the data list
/// this is the column number (1-based) of the column that will provide the logical
/// value for this control.<br>
/// If this value is greater than the number of columns in the query
/// then the first column will be used.
Property valueColumn As %ZEN.Datatype.integer(MINVAL = 1, ZENSETTING = 0) [ InitialExpression = 1 ];

/// If there are multiple data columns displayed in the data list,
/// this optional property defines a comma-delimited list of the column numbers
/// of the column that should be displayed.
Property displayColumns As %ZEN.Datatype.csv(ZENSETTING = 0);

/// Indicates how display values should be rendered:<br>
/// If <property>contentType</property> is "text" (the default) then the display values
/// will be HTML-escaped before being rendered.<br>
/// If <property>contentType</property> is "html" then the display values
/// will not be HTML-escaped before being rendered. 
/// Use this when your display values contain HTML markup that you do not want escaped.<br>
Property contentType As %ZEN.Datatype.string(VALUELIST = ",text,html") [ InitialExpression = "text" ];

/// (optional) SQL statement that, given a value, finds a display
/// value. If present, this is used
/// to find the initial display value for cases where the
/// logical and display values are different.
Property sqlLookup As %ZEN.Datatype.sql;

/// Number of options within the list.<br>
/// This is calculated when the query for this component is run.
Property itemCount As %ZEN.Datatype.integer(XMLPROJECTION = "none");

/// User-defined list of query parameters.<br>
/// These values are passed on
/// to the user callback function that provides the query for this component
/// in order to provide values for any run-time query parameters.
Property parameters As list Of %ZEN.Auxiliary.parameter(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// (optional) Name of Server-side callback method that is called for each
/// item in the list before it is displayed. This callback is passed the logical
/// and display value for the current item. It returns the HTML that is to be
/// displayed within the cell for the given item.<br>
/// This must be the name of a server-only method in the page
/// class that contains this dataListBox.
/// Note: If using multi-column output, it is being called individually for each column
Property OnDrawItem As %ZEN.Datatype.delegator(FORMALSPEC = "pRS:%SQL.StatementResult,pValue:%String,pText:%String", RETURNTYPE = "%String");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

</style>
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	#; default query for testing
	Set ..queryClass = "%ZEN.Utils"
	Set ..queryName = "EnumerateComponents"
}

/// Lookup up the display value for the combobox given
/// a logical value.<br>
/// This is called when the control is initially drawn.
/// A logical value of "", must have a display value of "".
Method %GetDisplayValue(pValue As %String) As %String
{
	Set tDisplay = pValue
	
	Do {
		#; if sqlLookup is defined, use it
		If ((pValue '= "") && (..sqlLookup '= "")) {
			Set tStatement = ##class(%SQL.Statement).%New(2,"DEFAULT_SCHEMA")
			Set tSC = tStatement.%Prepare(..sqlLookup)
			If ($$$ISERR(tSC)) {
				Quit
			}
	
			Set tRS = tStatement.%Execute(..value)
			If tRS.%SQLCODE {
				Quit
			}
			
			#; assume one result
			If (tRS.%Next()) {
				Set tDisplay = tRS.%GetData(1)
			}						
		}
		#; if sql is defined use that
		#; as we can't make any assumption over the semantic of the used query
		#; loop over it and compare pValue to ..valueColumn
		elseIf ((pValue'="") && (..sql'="") && (..valueColumn'="")) {
			Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
			Set tSC = tStatement.%Prepare(..sql)
			If ($$$ISERR(tSC)) {
				Quit
			}

			Set tRS = tStatement.%Execute()
			If tRS.%SQLCODE {
				Quit
			}
			
			while (tRS.%Next()) {				
				if (pValue=tRS.%GetData(..valueColumn)){
					Set tDisplay = tRS.%GetData($S(..choiceColumn'="":..choiceColumn,1:1))
					Quit					
				}
			}
		}
	} While(0)

	Quit $S(..contentType="text":tDisplay,1:$ZCVT(tDisplay,"I","HTML"))
}

/// Server-side method to provide contents of the list box.
Method %DrawListContents()
{
	Set tRS = ""
	Set tHasDisplay = 0
	Set value =  ..value
	
	#; create result set
	#; create QueryInfo object to hold query info
	Set tInfo = ##class(%ZEN.Auxiliary.QueryInfo).%New()

	#; additional query parms
	Set tInfo.tableName = $$$ZENVAL(..tableName)
	Set tInfo.columnName = $$$ZENVAL(..columnName)
	Set tInfo.whereClause = $$$ZENVAL(..whereClause)
	Set tInfo.orderByClause = $$$ZENVAL(..orderByClause)
	Set tInfo.groupByClause = $$$ZENVAL(..groupByClause)

	#; get query parms
	Set tCount = ..parameters.Count()
	For n=1:1:tCount {
		Set tParam = ..parameters.GetAt(n)
		Set tInfo.parms(n) = $$$ZENVAL(tParam.value)
	}

	Set tRS = ..%CreateResultSet(.tSC,tInfo)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
		Quit
	}
	Set tInfo = ""
	Set tCount = 0
	Set selIdx = ""
	If ($IsObject(tRS)) {
		Set tColCount = tRS.%ResultColumnCount
		
		
		Set tColCount = tRS.%ResultColumnCount
		Set tColCount = $S(..multiColumn:tColCount,tColCount=1:1,1:2)
		Set tValueCol = +$S(tColCount=1:1,..valueColumn<=tColCount:..valueColumn,1:1)
		Set tChoiceCol = +$S(tColCount=1:1,..choiceColumn<=tColCount:..choiceColumn,1:2)
	

		#;check multicolumns
		If (tColCount >= 1) {
			#; index of columns to show
			If (..displayColumns '= "") {
				For n = 1:1:$L(..displayColumns,",") {
					Set tColIdx(n) = +$P(..displayColumns,",",n)
					If (tColIdx(n)=0) {
						Set tSC = $$$ERROR($$$GeneralError,"displayColumns must contain integer values")
						Quit
					}
				}
				Set tColCount = n
			}
			Else {
				Set n = 1
				For c=1:1:tColCount {
					If (c '= tValueCol) {
						Set tColIdx(n) = c
						Set n = n + 1
					}
				}
			}
		}
		If $$$ISERR(tSC) Quit tSC
		
		&html<<table class="listBoxTable" width="100%" border="0" cellpadding="0" cellspacing="0">>

		While (tRS.%Next() && ((..maxRows=0)||(tCount < ..maxRows))) {
			Set tValue = $S(+tValueCol:tRS.%GetData(tValueCol),1:"")
			Set:tValue=$C(0) tValue=""
			Set tText = $S(+tChoiceCol:tRS.%GetData(tChoiceCol),1:"")
		
			
			Set:tText=$C(0) tText=""

			Set tValue = $ZCVT(tValue,"O","HTML")
			Set tText = $S(..contentType="text":$ZCVT(tText,"O","HTML"),1:tText)
       
			If (tValue=value) {
				Set selIdx = tCount
				Set tCls = "listBoxItemSelected"
			}
			Else {
				Set tCls = "listBoxItem"
			}

			Set tTextAttr = "zenText="""_tText_""""
			Set tValAttr = "zenValue="""_tValue_""""
			#; if we support drag & drop we need additional mouse event handling
			Set tMouseEvents = ""
			If (%page.dragAndDrop) {
				Set tMouseEvents = " onmousedown=""zenPage.getComponent("_..index_").itemMouseDown(event,"_tCount_");""" _
								" onmouseup=""zenPage.getComponent("_..index_").itemMouseUp(event);"""
			}

			If (tValue '= "") {
				&html<<tr #(tMouseEvents)# id="#(..%MakeId("item_"_tCount))#" class="#(tCls)#" #(tValAttr)# #(tTextAttr)# onclick="zenPage.getComponent(#(..index)#).clickItem(#(tCount)#);return false;" ondblclick="zenPage.getComponent(#(..index)#).dblClickItem(#(tCount)#);">>
				If (tColCount = 1) {
					SET:(..OnDrawItem'="") tText=..%DrawItem(tRS,tValue,tText)
					&html<<td>#($S(tText="":"&nbsp;",..contentType="text":$ZCVT(tText,"O","HTML"),1:tText))#</td>>
				}
				Else {
					Set c = $O(tColIdx(""))
					While (c '= "") {
						Set tData = tRS.%GetData(tColIdx(c))
						Set:tData=$C(0) tData=""
						SET:(..OnDrawItem'="") tData=..%DrawItem(tRS,tValue,tData)
						&html<<td>#($S(tData="":"&nbsp;",..contentType="text":$ZCVT(tData,"O","HTML"),1:tData))#</td>>
						Set c = $O(tColIdx(c))
					}
				}
				&html<</tr>>
				Set tCount = tCount + 1
			}
		}

		If (tCount > 0 && tRS.%Next()) {
			#; more rows
			&html<<tr><td><i>#("...")#</i></td></tr>>
		}
	}
    &html<</table>>
	#; update selected index & item count
	Set:selIdx="" selIdx = -1
	Set ..selectedIndex = selIdx
	Set ..itemCount = tCount
}

/// Internal method.<br>
/// Invoke the OnDrawItem callback, if present.
Method %DrawItem(pRS As %SQL.StatementResult, pValue As %String, pText As %String) As %Text [ Internal ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK
	Set tRet = pText

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnDrawItem '= "")) {
		Set tRet = $zobjmethod(tHost,..OnDrawItem,pRS,pValue,pText)
	}
Done
	Quit tRet
Trap
	Set $ZT=""
	Set tRet = pText
	Goto Done
}

/// Execute the server-side associated with this dataListBox.<br>
/// The query is executed asynchronously, so results may not be available 
/// immediately.
ClientMethod executeQuery() [ Language = javascript ]
{
	this.refreshContents();
}

/// Return number of items in list.<br>
ClientMethod getOptionCount() [ Language = javascript ]
{
	return !zenIsMissing(this.itemCount) ? this.itemCount : 0;
}

/// Return the logical value of the given item (0-based) in the list.<br>
ClientMethod getOptionValue(idx) [ Language = javascript ]
{
	// find matching item
	var value = '';
	var item = self.document.getElementById('item_' + idx + '_' + this.index);
	if (item) {
		value = item.getAttribute('zenValue');
	}
	return value;
}

/// Return the display text for the given item (0-based) in the list.<br>
ClientMethod getOptionText(idx) [ Language = javascript ]
{
	// find matching item
	var value = '';
	var item = self.document.getElementById('item_' + idx + '_' + this.index);
	if (item) {
		value = item.getAttribute('zenText');
	}
	return value;
}

ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'itemCount':
		this.itemCount = value;
		break;
	case 'parameters':
		// set value of parameter: note that value will
		// be 1-based, so we have to convert it.
		// changing parameter always forces a query execution,
		// even in snapshot mode.
		if ('' != value) {
			value = value - 1;
			if (this.parameters[value]) {
				if (this.parameters[value].value != value2) {
					this.parameters[value].value = value2;
					this.executeQuery();
				}
			}
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
		break;
	}

	return true;
}

}
