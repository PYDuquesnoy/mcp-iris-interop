/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This page allows the user to create a value expression using drag and drop
Class %DeepSee.UI.Dialog.ExpressionBuilder Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Expression Builder";

/// Cube name. 
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Name of cube.
Property pivotName As %ZEN.Datatype.string(ZENURL = "PIVOT");

Property valueExpression As %ZEN.Datatype.string(ZENURL = "VALUE");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

#body {
	overflow: hidden;
}

#groupLeft {
	width: 250px;
	height: 530px;
	overflow: auto;
}
/* group on right-hand side */
#groupRight {
	vertical-align: top;
	height: 500px;
	overflow: auto;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<!-->WAL126<-->
<hgroup>
<vgroup id="groupLeft">
<dynaTree id="dimTree4" 
 imageContracted="portal/disc_up_16.gif"
 imageExpanded="portal/disc_down_16.gif"
 imageNode="deepsee/ds2_brightness_44.png"
	showLines="false" showFolders="false" dragEnabled="true" 
	OnGetTreeInfo="GetDimensionInfo">
<parameter id="pcubed" paramName="subjectArea" value="#(%page.cubeName)#" />
<parameter id="ppivotd" paramName="pivot" value="#(%page.pivotName)#" />
</dynaTree>
</vgroup>
<vgroup id="groupRight">
<textarea id="textExprDialog" label="Expression" cols="45" rows="10" hint="MDX expression for the calculated member" dropEnabled="true" ondrop="return zenPage.mdxDrop(zenThis,dragData);" />
</vgroup>
</hgroup>
<!-->WAL126<-->
</pane>
}

/// Provide contents of the dimension tree.
ClassMethod GetDimensionInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $G(pParms("subjectArea"))
		Set tPivotName = $G(pParms("pivot"))

		If (tCube'="") {
			If (tPivotName'="") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tPivotName,.tSC)
				If $$$ISERR(tSC) Quit
				If $IsObject(tPivot) {
					// get local calc members
					For n = 1:1:tPivot.calculatedMembers.Count() {
						Set tCalcMbr = tPivot.calculatedMembers.GetAt(n)
						If ((tCalcMbr.dimension'="")&&(tCalcMbr.memberName'="")) {
							Set tCalcMbrs($$$UPPER(tCalcMbr.dimension),$$$UPPER(tCalcMbr.memberName)) = $LB(tCalcMbr.dimension,tCalcMbr.memberName)
						}
					}

					// get local named sets
				}
			}

			Set tSC = ##class(%DeepSee.Utils).%GetMemberTree(tCube,.pTree,,,pRoot,.tCalcMbrs,.tNamedSets)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Expression Builder")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Create Value Expression for a Calculated Member")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	try {
		// DTB467 - Encode the return value to protect entries in a URL
		var dialogValue = encodeURIComponent(zen('textExprDialog').getValue());
		return dialogValue;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return '';
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	// Method added by WAL126
	zen('textExprDialog').setValue(this.valueExpression);
}

/// User has dropped an item on the textarea.
ClientMethod mdxDrop(textarea, dragData) [ Language = javascript ]
{
	// Method added by WAL126
	// append drop to query
	var mdx = textarea.getValue();
	
	// DTB617 - Check value for any internal tokens and remove them
	var value = dragData.value;
	if ('%SHAREDCALC'==value.split('.')[0]) {
		value = value.split('.').splice(1).join('.')
	}

	if (mdx.length) {		// DTB444 - Add condition on length
		mdx = mdx + ' ' + value;
	}
	else {
		mdx = value;
	}

	textarea.setValue(mdx);
	return false;
}

}
