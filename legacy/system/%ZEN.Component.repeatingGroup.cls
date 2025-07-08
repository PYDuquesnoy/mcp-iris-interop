/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized group that repeats its contents based on run-time data.<br>
/// A repeating group executes a query and, for each row of the results,
/// creates HTML for all of the members of the group. For example:
/// <example language="xml!fragment">
/// <repeatingGroup sql="SELECT Name FROM Sample.Person">
/// <button caption="Press" onclick="alert('#(%query.Name)#');"/>
/// </repeatingGroup>
/// </example>
/// Each row within the repeating group is referred to as a <i>tuple</i>.
/// For each tuple, the repeating group renders HTML for each of its child components.
/// Note that only one object is created for each child of the repeating group but
/// there are multiple HTML renderings (one per tuple) for each child. The rendered
/// HTML incorporates the current tuple number into the id values used to identify HTML
/// elements to keep track of them.<br/>
/// Applications should keep use of repeatingGroups reasonably simple.
/// Repeating groups within repeating groups are not supported.
Class %ZEN.Component.repeatingGroup Extends (group, querySource) [ Deprecated, Inheritance = right, System = 3 ]
{

/// User-defined list of parameters. These values are passed on
/// to the user callback function that provides the query for this table.
Property parameters As list Of %ZEN.Auxiliary.parameter(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// Indicates which member (0-based) of this repeating group is selected, if any.
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// onclickitem event handler:
/// If defined, this event is fired when
/// the user clicks on an item within the repeating group.
Property onclickitem As %ZEN.Datatype.eventHandler;

XData Style
{
<style type="text/css">
/* @doc="Unselected grouping within a repeating group." */
.repeatingGroup {
}

/* @doc="Selected grouping within a repeating group." */
.repeatingGroupSelected {
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}
</style>
}

/// Draw contents of the group.
Method %DrawHTML()
{
	Set tTuple = 0
	Set tMaxRows = ..maxRows

	#; create result set
	#; create QueryInfo object to hold query info
	Set tInfo = ##class(%ZEN.Auxiliary.QueryInfo).%New()

	#; convert parameters to array
	For n = 1:1:..parameters.Count() {
		Set value = ..parameters.GetAt(n).value
		Set tInfo.parms(n) = $$$ZENVAL(value)
	}

	Set tRS = ..%CreateResultSet(.tSC,tInfo)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
		Quit
	}
	Set tInfo = ""

	If ($IsObject(tRS)) {
		New %query
		Set tColCount = $Select(tRS.%IsA("%Library.ResultSet"):tRS.GetColumnCount(),1:tRS.%ResultColumnCount)

		#; iterate over tuples
		While (tRS.%Next() && ((tMaxRows = 0) || (tTuple < tMaxRows))) {
			Set tTuple = tTuple + 1

			#; set up data context for this tuple
			Set %query = tRS
						
			#; draw children for this tuple
			&html<<div id="#(..%MakeId("div"_tTuple))#" onclick="zenPage.getComponent(#(..index)#).itemClickHandler(#(tTuple-1)#);" class="#($S((tTuple-1)=..selectedIndex:"repeatingGroupSelected",1:"repeatingGroup"))#">>
			Do ..%LayoutChildren(tTuple)
			&html<</div>>
		}
	}
}

/// User has clicked on a member of this repeating group.
/// <var>tuple</var> is 0-based.
ClientMethod itemClickHandler(tuple) [ Language = javascript ]
{
	this.selectItem(tuple);
}

/// Select a member of this repeating group. <var>tuple</var>
/// specifies which member (0-based).
ClientMethod selectItem(tuple) [ Language = javascript ]
{
	// unhighlight old item
	if (this.selectedIndex >= 0) {
		var div = this.findElement('div' + (parseInt(this.selectedIndex)+1));
		if (div) {
			div.className = 'repeatingGroup';
		}
	}

	this.selectedIndex = tuple;

	// highlight new item
	if (this.selectedIndex >= 0) {
		var div = this.findElement('div' + (parseInt(this.selectedIndex)+1));
		if (div) {
			div.className = 'repeatingGroupSelected';
		}
	}

	zenInvokeCallbackMethod(this.onclickitem,this,'onclickitem','item',tuple);
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'selectedIndex':
		this.selectItem(parseInt(value,10));
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
