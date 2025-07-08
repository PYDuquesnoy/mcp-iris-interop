/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %SQL.Manager's Web UI Methods
Class %SQL.Manager.UI Extends %Persistent [ Abstract, System = 3 ]
{

/// Writes out common JavaScript code for wizard pages.
ClassMethod CommonJS()
{
	&html<
	<script Language=JavaScript>
  	// cancel button for end of popup
	function popupCancel()
	{
		opener.autopagePopupWindow = null;
		window.close();
		return true;
	}

    // called by popup when it is finished (ok)
    function updatePage()
    {
        self.document.location.reload();
        return true;
    }
	function popupSubmit(update)
	{
		opener.autopagePopupWindow = null;
		if (update) {
			// if update, reload parent page
			opener.updatePage()
		}
		window.close();
		return true;
	}
	
function pageStatus(document,max)
{
	var page = document.seltable.PAGE.value - 1;
	window.status = page + " of " + max;
}	
	
</script>
>
}

/// Write out alert box
ClassMethod DisplayError(ze As %String)
{
	set err=""
	Do $System.Status.DecomposeStatus(ze,.err)
	If $g(err(1)) set err = ..EscapeHTML(err(1))
	Write "<script language='javascript'>alert(",err,")</script>"
	quit
}

/// Writes out JavaScript code for selecting and deselecting properties
/// and move selected properties up and down
ClassMethod SelectJS() As %Status
{
	&html<
	<script language=JavaScript>

function moveList(from,to)
{
	// move one or multiple selected items from one box to another
	var len = from.options.length;
	var o;
	for(var i = 0; i < len; i++) {
	o = from.options[i];
	if (o.selected) {
		if (o.value != "_") {
			to.options[to.options.length] = new Option(o.text,o.value,false,true);
		}
	}
	}
	for(var i = len-1; i >=0; i--) {
	o = from.options[i];
	if (o.selected) {
		if (o.value != "_") {
			from.options[i] = null;
		}
	}
	}
	from.selectedIndex = from.options.length > 1 ? 1 : -1
}
function moveAll(from,to)
{
	//first move all from From list to To list
	var len = from.options.length;
	for(var i = 0; i < len; i++)
	   {
		var o = from.options[i];
		// skip width dummy - new Option(text,value,[defaultSelected],[selected])
		if (o.value != "_") to.options[to.options.length] =  new Option(o.text,o.value,false,true);
	   }
	//second set From list to null
	var len = len - 1;
	for(var i = len; i>=0; i--) {
		var o = from.options[i];
		if (o.value != "_") from.options[i] = null;
	}
	// set the default to the to's last
	to.selectedIndex = to.options.length-1;
	to.focus;

}
function moveItem(list,bUp) 
{
	var currentIdx = list.selectedIndex;
	if (currentIdx == -1) return false;
	if (list.options[currentIdx].value == "_") return false;
	var newIdx = bUp ? currentIdx - 1 : currentIdx + 1;
	if (newIdx < 1 || newIdx > (list.options.length - 1) ) return false;
	var sSwap = list[newIdx].value;
	var sSwapText = list[newIdx].text;
	var sTarget = list[currentIdx].value;
	var sTargetText = list[currentIdx].text;
	list[newIdx].value = sTarget;
	list[newIdx].text = sTargetText;
	list[currentIdx].value = sSwap;
	list[currentIdx].text = sSwapText;
	list.selectedIndex = newIdx;
	return false;
}
</script>
>
}

/// Returns export steps that should be shown
ClassMethod ExportSteps(Step As %Integer = 1) As %String
{
	if Step = 1 quit "Select File"
	else  if Step = 2 quit "Select Schema Name"
	else  if Step = 3 quit "Select Table Name"
	else  if Step = 4 quit "Select Columns"
	else  if Step = 5 quit "Select Delimiter"
	else  if Step = 6 quit "Finish"
	else  quit ""
}

/// Returns import steps that should be shown
ClassMethod ImportSteps(Step As %Integer = 1) As %String
{
	if Step = 1 quit "Select File"
	else  if Step = 2 quit "Select Schema Name"
	else  if Step = 3 quit "Select Table Name"
	else  if Step = 4 quit "Select Columns"
	else  if Step = 5 quit "Select Delimiter"
	else  if Step = 6 quit "Finish"
}

/// This init is called by the w*.csp
ClassMethod WizardInit()
{
	set Wizard = %request.Get("Wizard")
	set Namespace = %request.Get("Namespace")
	set dsnname = %request.Get("dsnname")
	set total = %request.Get("total")
	set port = $S($G(^%SYS("SSPort"))'="":^%SYS("SSPort"),1:1972)
  	set:$g(%msql)="" %msql = %request.Get("Username")
  	&html<<input type="hidden" name="Wizard" value="#(Wizard)#">>
    	&html<<input type="hidden" name="Namespace" value="#(Namespace)#">>
      	&html<<input type="hidden" name="dsnname" value="#(dsnname)#">>
        &html<<input type="hidden" name="Username" value="#(%msql)#">>
}

/// Write common code that is used by link table wizards
ClassMethod WizardStyle()
{
	&html<
	<style type="text/css">
.wizard {  font-family: Verdana, Arial, Helvetica, sans-serif; 
	background-color: #DDDDFF; 
	font-style: normal; 
	z-index: 100
	}
.wizardtop {  background-color: #003366; height: 40px; width=100%;
	padding-top: 7px; padding-right: 2px; padding-bottom: 1px; padding-left: 4px; 
	font-family: Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; 
	font-weight: bold;
	z-index: 101;
	}
.wizardbottom { background-color: #CCCCCC; height: 20px; 
	padding-top: 1px; padding-right: 1px; padding-bottom: 1px; 
	padding-left: 3px; font-family: "Courier New", Courier, mono; 
	border-color: #FFFFFF #FFFFFF #FFFFFF; border-style: inset; border-top-width: thin; 
	border-right-width: thin; border-bottom-width: thin; border-left-width: thin;
	z-index: 101;
	}

.wizbuttons {width:100px;}
.selbuttons {width:100px;}
.movbuttons {width:40px;}
div.result { 
 	border:	solid #FFCE84 thin; 
  	padding:	1em;
  	margin-left: 10px; margin-right: 10px;
 	}
div.para1 { color: black;
	margin-left: 10px; margin-right: 10px; margin-top: 20px;
	font-family: Verdana,Arial,sans-serif; font-size: 1em;
	}
div.para1:first-letter	{ color: black; font-size: 1.6em;}
p.para1 { color: black;
	margin-left: 10px; 
	font-family: Verdana,Arial,sans-serif; font-size: 1em;
	}
h3.para1 { color: black;
	margin-left: 10px; 
	font-family: Verdana,Arial,sans-serif; 
	}
table.box	{ 
	border: solid gray 1px; font-size: 12px; align-horizontal: center;
	font-family: font-family: courier new;
}
table.box TR {
	background-color: #FFFFFF;
}
INPUT	{	font-family: Verdana,Arial,Helvetica,sans-serif; 
		color: black;
		font-size: 10pt;
		}

.Label	{	font-size: 10pt;
			font-weight: bold;
		}
tr.light { background-color: #FFFFFF; }
th.yellow { background-color: blue; color: yellow; }

</style>

	>
}

ClassMethod listTableOpen()
{
	/// This is the generic list table style - the first table with background color
	&html<<table border="1" width="98%" cellpadding="0" cellspacing="1">
	<tr><td>
	<table border="0" width="100%" cellpadding="2" cellspacing="1">
	>
}

ClassMethod listTableClose(total)
{
	/// If table is opened with listTableOpen then use listTableClose to close
	&html<</table>>
 	if +total>0 {
 		&html<<tr class="light">Total: #(total)#</td></tr>>	
 	}
	&html<</td></tr>
	</table>>
}

ClassMethod listSteps(Step, finalstep)
{
 /// set up steps for Data Migration, Link Table and Link Procedure Wizard
 /// Step passing in is the current step which should be highlighted
	set Wizard = %request.Get("Wizard")
	set width(1) = 12, width(2) = 10, width(3) = 150
	set step(1) = "Select Data Source"
	set step(2) = "Select Schema"
	if Wizard = "DataMigration" {
		set step(3) = "Select Tables"
		set finalstep = 4
	} elseif Wizard = "LinkTable" {
		set step(3) = "Select Table"
		set step(4) = "Select Properties"
		set step(5) = "Prepare Names"
		set finalstep = 6
		if %request.Get("tname") '= "" set Step = 4
		if %request.Get("Next") '= "" set Step = 5
		if %request.Get("Submit") = "Finish" set Step = finalstep
	} else {
		// Procedure Wizard
		set step(3) = "Select Procedure"
		set step(4) = "Prepare Names"
		set finalstep = 5
		if %request.Get("tname") '= "" set Step = 4
		if %request.Get("Submit") '= "" set Step = finalstep
	} 
	set step(finalstep) = "Finish"
	// The following code write out the step box
	//&html<
	//<div id="stepLayer" style="position:absolute; width:183px; height:1000px; z-index:6; left: 10px; top: 8px">
	//<table width="183" height="200" border="0" cellspacing="0" cellpadding="1" bgcolor="#8d9fa0">
	//<tr> 
	//<td><table width="100%" height="199" border="0" cellpadding="2" cellspacing="1" bgcolor="#FFCC00">
	//<tr> 
	//<td>&nbsp;</td>
	//<td>&nbsp;</td>
	//<td>&nbsp;</td>   
	//</tr>
	//>
	//set s = 1
	//while s '> finalstep {
	//	if Step = s set stepsel = "class=""stepSelected""",col(1) = "*",col(2)=s_". ",col(3)=step(s)
	//	else  set stepsel="",col(1) = "&nbsp;",col(2) = s_". ",col(3) = step(s)
	////	&html<<tr>>
	//	for t = 1:1:3 &html<<td width="#(width(t))#" valign="top" #(stepsel)#>#(col(t))#</td>>
    //    &html<</tr>>
    //    set s = s + 1
	//}
    //&html<<tr>
   //     <td>&nbsp;</td>
	//	<td>&nbsp;</td>
	//	<td>&nbsp;</td>   
   //  </tr> 
	//	</table> 
	//	</td>
	//	</tr>
	//</table>
	//</div>
	//>
	Quit step(Step)
}

/// Return text that is shown in wizard header
ClassMethod writeHeader(Wizard) As %String
{
 if Wizard = "DataMigration" quit "Data Migration Wizard"
 if Wizard = "LinkTable"!(Wizard = "LinkProcedure") quit "Link "_$p(Wizard,"Link",2)_" Wizard"
 if Wizard = "Export" quit "Export Wizard"
 if Wizard = "Import" quit "Import Wizard"
 else  quit Wizard
}

/// Return text that is shown in wizard status bar
ClassMethod writeStatus(text)
{
 /// private method for this page to write out sub headers
 &html<
 <div class="wizardbottom">
 #(text)#
</div>
>
}

Storage Default
{
<Data name="UIDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%SQL.Man.UID</DataLocation>
<DefaultData>UIDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%SQL.Man.UID</IdLocation>
<IndexLocation>^%SQL.Man.UII</IndexLocation>
<StreamLocation>^%SQL.Man.UIS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
