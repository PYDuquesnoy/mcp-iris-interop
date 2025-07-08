/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog adds a new Calculated Member to a DeepSee pivot (or cube) definition.<br>
Class %DeepSee.UI.Dialog.AddCalculatedMember Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Name of cube.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Name of cube.
Property pivotName As %ZEN.Datatype.string(ZENURL = "PIVOT");

/// Index of member that launched this dialog.
Property memberIndex As %ZEN.Datatype.integer(ZENURL = "INDEX");

/// Dimension.
Property dimension As %ZEN.Datatype.string(ZENURL = "DIMENSION");

/// Member.
Property memberName As %ZEN.Datatype.string(ZENURL = "MEMBER");

/// Expression.
Property valueExpression As %ZEN.Datatype.string(ZENURL = "EXPR");

/// List of locally defined calculated dimensions.
Property dimList As %ZEN.Datatype.string(ZENURL = "DIMLIST");

/// Format string.
Property formatString As %ZEN.Datatype.string(ZENURL = "FORMAT");

/// Solve order.
Property solveOrder As %ZEN.Datatype.integer(ZENURL = "SOLVEORDER");

/// Storage option
Property storeWithPivot As %ZEN.Datatype.boolean(ZENURL = "LOCAL") [ InitialExpression = 1 ];

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
xmlns:deepsee="http://www.intersystems.com/deepsee" import="%DeepSee.Component.searchBox"
cellStyle="padding-bottom:8px;">

<radioSet id="rsType" label="Member type" valueList="measure,dimension" displayList="Measure,Dimension" onchange="zenPage.changeType();" />
<checkbox id="storageOption" label="Shared Storage" value="true"  hint="Make this calculated member available to all pivots based on this cube."/>

<selector id="textDim" label="Dimension" size="30" onchange="zenPage.changeDimension();" hint="Dimension for the calculated member" />
<text id="textMbr" label="Member name" size="30" hint="Name of the calculated member" />
<select id="selLevel" label="Dimension level" size="1" onchange="zenPage.changeLevel();" showEmpty="false" 
  hint="Choose a dimension level if you want to select existing members to populate the MDX expression" />
<deepsee:searchBox id="srcMbrs" label="Existing members" size="30" multiSelect="true" onchange="zenPage.selectMembers();"
  hint="Select any combination of existing dimension members to populate the MDX expression" />
  <!-->WAL126<-->
  <hgroup>
  <textarea id="textExpr" label="Expression" cols="60" rows="4" hint="MDX expression for the calculated member" dropEnabled="true" ondrop="return zenPage.mdxDrop(zenThis,dragData);" />
  <spacer width="5"/>
  <image src="deepsee/ds2_magnify_44.png" width="16px" onclick="zenPage.buildExpression();" title="Launch expression builder"/>
  </hgroup>
  <!-->WAL126<-->

<hgroup cellVAlign="bottom" cellStyle="padding-right:4px;" label="Format" hint="For example, #,###.#" >
<text id="textFormat" size="50"/>
<image src="deepsee/zoom_16.png" width="16px" onclick="zenPage.editFormatString();" title="Launch format builder"/>
</hgroup>

<select id="solveOrder" label="Solve Order" showEmpty="false" hint="Optional" valueList="0,1,2,3,4,5,6,7,8,9,10"/>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Calculated Member")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Add or edit a calculated member.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var value = '';
	return value;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		// validate names, test for uniqueness!!!
		var dimension = zen('textDim').getValue();
		var memberName = zen('textMbr').getValue();
		var valueExpression = zen('textExpr').getValue();
		var formatString = zen('textFormat').getValue();
		var solveOrder = zen('solveOrder').getValue();
		var storeWithPivot = zen('storageOption').getValue() ? 0 : 1;		// DTB268
		
		if (''==dimension) {
			alert($$$Text('Please provide a dimension name'));
			return false;
		}
		if (''==memberName) {
			alert($$$Text('Please provide a member name'));
			return false;
		}
		if (''==valueExpression) {
			alert($$$Text('Please provide an expression'));
			return false;
		}

		var main = this.getOpener();
		var pivot = main.zenPage.getPivot();
		var index = (''===this.memberIndex) ? Math.NaN : parseInt(this.memberIndex);
		
		if (storeWithPivot) {
			if (pivot && pivot.calculatedMembers) {
				var calcMbr = null;
				if (!isNaN(index)&&(index>=0)) {		// DTB334 - Shared calcs have index of -1
					calcMbr = pivot.calculatedMembers[index];
				}
				else {
					calcMbr = main.zenPage.createComponentNS('http://www.intersystems.com/deepsee','calculatedMember');
				}

				calcMbr.dimension = dimension;
				calcMbr.memberName = memberName;
				calcMbr.valueExpression = valueExpression;
				calcMbr.formatString = formatString;
				calcMbr.solveOrder = solveOrder;
				if (!isNaN(index)&&(index>=0)) {		// DTB334 - Shared calcs have index of -1
					pivot.calculatedMembers[index] = calcMbr;
				}
				else {
					pivot.calculatedMembers[pivot.calculatedMembers.length] = calcMbr;
				}
			}
		}
		else {
			// DTB268 - Send this to the shared storage.
			if (!isNaN(index)&&(index>=0)) {
				// DTB334 - remove the local version if the storage is being switched from
				// Local to Shared.
				main.zenPage.deleteCalculatedMember(1);
			}
			
			var ok = this.SaveSharedCalcMbr(this.cubeName,memberName,dimension,valueExpression,formatString,solveOrder);
		}
		
		// save the pivot, if there is one
		if (pivot&&(''!=pivot.name)) {
			main.zenPage.savePivot(false);
		}
		main.zenPage.updateMemberTree();
		pivot.executeQuery(true);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set rsType = ..%GetComponentById("rsType")
		Set textDim = ..%GetComponentById("textDim")
		Set textMbr = ..%GetComponentById("textMbr")
		Set textExpr = ..%GetComponentById("textExpr")
		Set textFormat = ..%GetComponentById("textFormat")
		Set textSolveOrder = ..%GetComponentById("solveOrder")
		Set tStorageOption = ..%GetComponentById("storageOption")		// DTB268
	
		// DTB268 - These also serve as defaults for the form in the case of a
		// new calculated member.
		Set textDim.value = ..dimension
		Set textMbr.value = ..memberName
		Set textExpr.value = ..valueExpression
		Set textFormat.value = ..formatString
		Set textSolveOrder.value = ..solveOrder
		Set tStorageOption.value = '..storeWithPivot		// DTB268

		// +DTB268 - Lookup a shared calculated member if a name is provided
		If ('..storeWithPivot)&&(..memberName'="") {
			Set tFullName = ..memberName
			If $E(..memberName,1,7)="%SHARED" {
				Set tFullName = $P(..memberName,".",2,*)
			}

			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tFullName,.tParsedInfo)
			Set tDimension = tParsedInfo(1)
			Set tMemberName = tParsedInfo(2)
			
			Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMemberInfo($$$UPPER(..cubeName),$$$UPPER(tDimension),$$$UPPER(tMemberName),.tMbrInfo)
			
			If $D(tMbrInfo) {
				Set textDim.value = tMbrInfo("dimension")
				Set ..dimension = tMbrInfo("dimension")		// DTB410
				Set textMbr.value = tMbrInfo("name")
				Set textExpr.value = tMbrInfo("expression")
				Set textFormat.value = tMbrInfo("format")
				Set textSolveOrder.value = tMbrInfo("solveOrder")
			}
		}
		// -DTB268
		
		// set search context for selector
		Set textDim.context = "%DeepSee.Component.ContextSearch/Dimensions?subject="_..cubeName
		If (..dimList'="") {
			Set textDim.context = textDim.context _ "&list=" _ ..dimList
		}

		If ($$$UPPER(..dimension)="MEASURES") {
			Set rsType.value = "measure"
			Set textDim.disabled = 1
		}
		Else {
			Set rsType.value = "dimension"
		}
		
		if (..dimension'="") {
			set tSC = ..OnChangeDimension(..dimension)
		}
		
		If (..pivotName="") {
			// DTB268 - This was loaded as a shared memebr with no parent pivot
			Set tStorageOption.disabled = 1
			Set tStorageOption.title = "No pivot defined"
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Change of type.
ClientMethod changeType() [ Language = javascript ]
{
	var type = zen('rsType').getValue();
	switch(type) {
	case 'measure':
		zen('textDim').setProperty('disabled',true);
		zen('textDim').setValue('MEASURES');
		zen('selLevel').setProperty('disabled',true);
		zen('srcMbrs').setProperty('disabled',true);
		break;
	case 'dimension':
	default:
		zen('textDim').setProperty('disabled',false);
		zen('textDim').setValue('');
		zen('selLevel').setProperty('disabled',false);
		zen('srcMbrs').setProperty('disabled',false);
		break;
	}
}

/// Change dimension
ClientMethod changeDimension() [ Language = javascript ]
{
	var value = zen('textDim').getValue();
	var sc = zenPage.OnChangeDimension(value);
	zen('selLevel').refreshContents();
	zen('srcMbrs').refreshContents();
}

/// Change dimension: update selLevel contents
Method OnChangeDimension(pValue As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		set tSelLevel = ..%GetComponentById("selLevel")
		
		set tSC = ##class(%DeepSee.Utils).%GetCubeLevels(..cubeName, .tLevels, 1)
		quit:$$$ISERR(tSC)
		
		set tValueList="", tDisplayList="", i=""
		for {
			set i = $o(tLevels(i),1,tLevel)
			quit:i=""
			continue:$li(tLevel,1)'="l"
			continue:$li(tLevel,2)'=pValue
			set tValueList = $s(tValueList="":"", 1:tValueList_",") _ "["_$lts($li(tLevel,2,5),"].[")_"]"
			do ##class(%DeepSee.Utils).%GetMemberCaption(..cubeName, $li(tLevel,2), $li(tLevel,3), $li(tLevel,4), .tCaption)
			set tDisplayList = $s(tDisplayList="":"", 1:tDisplayList_",") _ $replace(tCaption,",","\,")		// DTB765 - Escape commas for html select element
		}
		set tSelLevel.valueList = tValueList
		set tSelLevel.displayList = tDisplayList
		
		set tFirstValue = $p(tValueList,",",1)
		set tSelLevel.value = tFirstValue
		set tSC = ..OnChangeLevel(tFirstValue)
		quit:$$$ISERR(tSC)
		
		// DTB100 - clear previous selection in Existing Members since it no longer has meaning
		set tSrcMbrs = ..%GetComponentById("srcMbrs")
		Set tSrcMbrs.value=""
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Change level
ClientMethod changeLevel() [ Language = javascript ]
{
	var value = zen('selLevel').getValue();
	var sc = zenPage.OnChangeLevel(value);
	zen('srcMbrs').refreshContents();
}

/// Change level: update srcMbrs contents
Method OnChangeLevel(pValue As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tSrcMbrs = ..%GetComponentById("srcMbrs")
		set tSrcMbrs.dataSourceName = ..cubeName _ ".cube"
		set tSrcMbrs.filterName = pValue
		set tSrcMbrs.hidden = 0
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Turn srcMbrs value into a filter spec
ClientMethod selectMembers() [ Language = javascript ]
{
	var dimPrefix = zen('selLevel').getValue() + ".";
	var expr = zen('srcMbrs').getValue();
	
	var isNot = (expr.substring(0,4)=="%NOT");
	if (isNot) { 
		expr = expr.substring(5,expr.length); 
	}
	var isRange = expr.indexOf(']:&[')>0;
	
	if (isRange) { 
		var exprArray = expr.split(']:&[');
		if (!isNot) {
			// standard range expression
			expr = '%OR({' + dimPrefix + exprArray[0] + ']:' + dimPrefix + '&[' + exprArray[1] + '})';
		} else {
			// this is an excluded range using the DayMonthYear calendar control!
			expr = '%OR({%TIMERANGE(,' + 
					dimPrefix + exprArray[0] + ']' +
					',EXCLUSIVE),%TIMERANGE(' + 
					dimPrefix + '&[' + exprArray[1] + 
					',,EXCLUSIVE)})';
		}

	} else {
		// everything that is not a range
		
		if (expr.charAt(0)=='{') { 
			expr = expr.substring(1,expr.length-1); 
		}
		
		var exprArray = expr.split('],&[');		// DTB100 - split on the complete string between member identifiers

		for (i = 0; i<exprArray.length;i++) {
			// DTB100 - expose the identifier used in the member key, then
			// reassemble the full name with [Dim].[Hier].[Level].&[ident]
			
			var ident = exprArray[i];
			if (i==0) {
				// first item, remove leading &[
				ident = ident.substring(2,ident.length);
			} 
			if (i==exprArray.length-1) {
				// last item, remove trailing ]
				ident = ident.substring(0,ident.length-1);
			}
			
			// Each item should be flagged with %NOT if this is an Exclude filter
			exprArray[i] = dimPrefix + '&[' + ident + ']' + (isNot ? '.%NOT' : '');
		}
		
		expr = exprArray.join(', ');

		if (isNot && (exprArray.length>1)) {
			// Several items were excluded, use a tuple of %NOT members
			expr = '(' + expr + ')';
		}
		else if (exprArray.length>1) {
			// Several items selected, use %OR
			expr = '%OR({'+expr+'})';
		}
	}
	
	zen('textExpr').setValue(expr);
}

/// Launch format dialog.
ClientMethod editFormatString() [ Language = javascript ]
{
	var value = zen('textFormat').getValue();
	var parms = {
			CUBE:this.cubeName,
			VALUE:value
			};
	zenLaunchPopupWindow("%DeepSee.UI.Dialog.FormatString.zen","FormatString",'status,scrollbars,resizable=yes,width=640,height=680',parms);
}

/// Launch format dialog.
ClientMethod buildExpression() [ Language = javascript ]
{
	var value = zen('textExpr').getValue();
	var parms = {
			CUBE:this.cubeName,
			PIVOT:this.pivotName,
			VALUE:value
			};
	zenLaunchPopupWindow("%DeepSee.UI.Dialog.ExpressionBuilder.zen","ExpressionBuilder",'status,scrollbars,resizable=yes,width=640,height=680',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'FormatString':
		zen('textFormat').setValue(value);
		break;
	case 'ExpressionBuilder':
		// DTB467 - Capture the value returned by the expressionBuilder
		zen('textExpr').setValue(value);
		break;
	}
}

/// Save a named filter.
ClassMethod SaveSharedCalcMbr(pCube As %String = "", pCalcMbrName As %String = "", pDimension, pValueExpression, pFormatString, pSolveOrder) As %String [ ZenMethod ]
{
	// Method added by DTB268
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		If (pCalcMbrName="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit

		// save the shared calculated member
		Set tSC = ##class(%DeepSee.Utils).%SaveSharedCalcMember(tCube, pCalcMbrName, pDimension, pValueExpression, pFormatString, pSolveOrder)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

}
