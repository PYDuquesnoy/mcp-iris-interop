/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Create and edit a view.
Class %CSP.UI.SQL.ViewPane Extends %CSP.Util.Pane [ System = 4 ]
{

/// Overwritten by subclasses to draw anything this pane needs for the BODY section.
Method DrawBODY(pInstance As PageInstance) As %Status
{

	&html<<div class="Text1">#(##class(%CSP.Page).EscapeHTML(..LocalizeText(..Text)))#</div>>
	
	Do ..DrawCommandForm(pInstance)
	Set IsNew = %request.PageName["UtilSqlViewNew"
	Set lblSchema = $$$TextHTML("Schema")
	Set lblName = $$$TextHTML("Name")
	Set lblReadOnly = $$$TextHTML("Is Read Only")
	Set lblYes = $$$TextHTML("Yes")
	Set lblNo = $$$TextHTML("No")
 	Set lblCheckOption = $$$TextHTML("With Check Option")
 	Set lblViewText = $$$TextHTML("View Text")
 	Set lblSaveView = $$$TextHTML("Save View")
 	Set lblQueryBuilder = $$$TextHTML("Query Builder")
 	Set lblLocal = $$$TextHTML("LOCAL")
 	Set lblCascaded = $$$TextHTML("CASCADED")
 	
 	Merge tID = pInstance.IDValues
	
 	Set ID1 = $G(tID(1))
 	Set ID2 = $G(tID(2))
	Set Schema = $G(%request.Data("Schema",1),ID1)
	Set showNewSchema = "none"
	If Schema = "" {
		Set Schema = $G(%request.Data("NewSchemaName",1))
		Set showNewSchema = "block"
	}
	Set ViewName =  $G(%request.Data("ViewName",1),ID2)	
	Set Owner = %session.Username
	Set ReadOnly = $G(%request.Data("ReadOnly",1),0)
	Set CheckOption = $G(%request.Data("CheckOption",1))
	Set ViewText = $G(%request.Data("Query",1))
	#; YSD2149 - handle cases when view text is longer than limit and is turned into stream
	Set IsError = 0
	Set tmsg = ""
	If $IsObject(ViewText) {
		Set tmsg = ..GetStreamText(.ViewText,.IsError)
	}
	If ViewName '= "" {
		If $G(%request.Data("OK",1)) = "" {
			Do ..GetViewInfo2(Schema, ViewName, .Owner, .ReadOnly, .CheckOption)
			Set ViewText = ..GetViewText(Schema, ViewName)
		}
	}
	If ViewName = "" Set ViewName = "NEWVIEW"
	Set NAMESPACE = $G(%request.Data("$NAMESPACE",1),$namespace)
	&html<<form name="ViewForm" method="post" action="#(%request.PageName)#?$NAMESPACE=#($zcvt(NAMESPACE,"O","URL"))#" enctype="multipart/form-data">
	<input type="hidden" name="$ID1" value="#($ZCVT(ID1,"O","HTML"))#">
	<input type="hidden" name="$ID2" value="#($ZCVT(ID2,"O","HTML"))#">
	<input type="hidden" name="$NAMESPACE" value="#($ZCVT(NAMESPACE,"O","HTML"))#">
	<table class="AutoForm">
	<tr class="AutoForm" valign="CENTER">
	<td class="AutoFormCaption" nowrap>&nbsp;#(lblSchema)#:</td>
	<td class="AutoFormControl" nowrap>>
	If IsNew = 1 {
	&html<
	<select name="Schema" onchange="changeSchemaView(this.value)">
	<option value="" #($S(Schema="":"selected",1:""))#></option>>
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Schemas")
	Do tRS.Execute()
	While tRS.Next() {
		Set tSchema = tRS.Data("SCHEMA_NAME")
		Set tSel = $S(Schema=tSchema:"selected",1:"")
		&html<<option value="#(tSchema)#" #(tSel)#>#($ZCVT(tSchema,"O","HTML"))#</option>>	
	}
	&html<
	</select>
	<div id="idNewSchema" style="display:#(showNewSchema)#">
	#($$$TextHTML("New Schema: "))#
	<input type="text" name="NewSchemaName" id="NewSchemaName" value="#($ZCVT($G(%request.Data("NewSchemaName",1)),"O","HTML"))#">
	</div>>
	}
	Else {
		&html<#($ZCVT(Schema,"O","HTML"))# <input type="hidden" name="Schema" value="#($ZCVT(Schema,"O","HTML"))#">>
	}
	&html<
</td>
</tr>
<tr class="AutoForm" valign="CENTER">
<td class="AutoFormCaption" nowrap>&nbsp;#(lblName)#:</td>
<td class="AutoFormControl" nowrap>>
	If IsNew = 1 {
	&html<
	<input class="AutoForm" type="text" name="ViewName" size="30" value="#($ZCVT(ViewName,"O","HTML"))#">>
	} Else {
		&html<#($ZCVT(ViewName,"O","HTML"))# <input type="hidden" name="ViewName" value="#($ZCVT(ViewName,"O","HTML"))#">>
	}
	&html<
</td>
</tr>
<tr class="AutoForm" valign="CENTER">
<td class="AutoFormCaption" nowrap>&nbsp;#(lblReadOnly)#:</td>
<td class="AutoFormControl" nowrap><select class="AutoForm" name="ReadOnly">
<option class="AutoForm" value="" #($S(ReadOnly="":"selected",1:""))#>
<option class="AutoForm" value="0" #($S(ReadOnly="0":"selected",1:""))#>#(lblNo)#
<option class="AutoForm" value="1" #($S(ReadOnly="1":"selected",1:""))#>#(lblYes)#

</select>

</td>
</tr>
<tr class="AutoForm" valign="CENTER">
<td class="AutoFormCaption" nowrap>&nbsp;#(lblCheckOption)#:</td>
<td class="AutoFormControl" nowrap><select class="AutoForm" name="CheckOption">
<option class="AutoForm" value="" #($S(CheckOption="":"selected",1:""))#>
<option class="AutoForm" value="LOCAL" #($S(CheckOption="LOCAL":"selected",1:""))#>#(lblLocal)#
<option class="AutoForm" value="CASCADED" #($S(CheckOption="CASCADED":"selected",1:""))#>#(lblCascaded)#
</select>

</td>
</tr>
<tr class="AutoForm" valign="CENTER">

<td class="AutoFormCaption" nowrap>&nbsp;#(lblViewText)#:</td>
<td class="AutoFormControl" nowrap><textarea class="AutoForm" name="Query" id="Query" cols="60" ROWS="10">#($ZCVT(ViewText,"O","HTML"))#</textarea>
</td>
</tr>
<tr><td>&nbsp;</td>
<td>
<input type="submit" name="OK" value="#(lblSaveView)#">&nbsp;
<input type="button" name="QUERYBUILDER" 
value="#(lblQueryBuilder)#" onclick="launchPopupWindow('%CSP.UI.SQL.QueryBuilderWindow.cls?ClassFilter=&ColumnType=2&$NAMESPACE=#($zcvt(NAMESPACE,"O","URL"))#','resizable','QueryBuilder');">&nbsp;
</td></tr>>
	If $G(%request.Data("OK",1)) '= "" {
		If Schema = "" Set Schema = $$$DefaultSchema
		If 'IsError {
			Set tSC = ..SaveForm(NAMESPACE,Schema,ViewName,Owner,ReadOnly,CheckOption,ViewText)
			If tSC '= 1 {
				Set tmsg = $ZCVT(tSC,"O","HTML")
			} 
		} 
		&html<<tr><td>&nbsp;</td><td><div class="output"><table>>
		// If view is saved then jump to the view info page directly.
		If 'IsError,tSC = $$$OK,ViewName'="" {
			Set tLink = ##class(%CSP.Page).Link("UtilSqlViewInfo.csp")_"&$ID1="_##class(%CSP.Page).EscapeURL(Schema)_"&$ID2="_##class(%CSP.Page).EscapeURL(ViewName)
	 		&html<<script language="javascript">
	 		document.location = "#(tLink)#";
	 		</script>
	 		>
	 	} Else {
	 		&html<<tr><td><div class="ErrorBox">#(tmsg)#</div></td></tr>>
	 	}
	 	&html<</td></tr></table></div></td></tr>>
	}
	&html<
</table>
</form>
</div>
</td>
</tr></table>
>
	Quit $$$OK
}

/// Given schema name and view name, return view info
ClassMethod GetViewInfo2(Schema As %String, ViewName As %String, Output Owner As %String, Output ReadOnly As %Boolean, Output CheckOption As %String) As %Status
{
	Set $ZT="Trap"
	Set currentNS = $namespace
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewInfo2")
	Do tRS.Execute(Schema, ViewName)
	If tRS.Next() {
		Set Owner = tRS.Data("OWNER")
		Set ReadOnly = tRS.Data("DEFINED_AS_READ_ONLY")
		Set CheckOption = tRS.Data("CHECK_OPTION")
	}
	Quit $$$OK
Trap
	Set $ZT="" Quit 0
}

/// Return View Text for new view (from cached query) or existing view.
ClassMethod GetViewText(Schema As %String, ViewName As %String) As %String
{
	Set $ZT="Trap"
	//Determine if we are dealing with cached query or view because you can create a view from an existing cached query
	Set tCreateView = $G(%request.CgiEnvs("HTTP_REFERER"))
	If tCreateView '[ "CQInfo.csp"  {
		//Existing View
		Set ViewText = ""
		Set tRes = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewInfo")
		Do tRes.Execute(Schema,ViewName)
		While tRes.Next() {
        		Set ViewText = ViewText _ tRes.Data("VIEW_QUERY")
		}
	} Else  {
		// Existing Cached Query
		Set (sCreate,sLast,sQueryType) = ""
		Set ViewText = ##class(%SQL.Manager.API).GetCachedQueryInfo(ViewName,.sCreate,.sLast,.bSource,.sQueryType)
	}
	Quit ViewText
Trap
	Set $ZT="" Quit ""
}

/// Overwritten by subclasses to draw anything this pane needs for the HEAD section.
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	&html<
	<script language="javascript">
	function changeSchemaView(thisvalue)
	{
		if (thisvalue == "") {
			document.getElementById("idNewSchema").style.display = "block";
			document.getElementById("NewSchemaName").focus();
		} else {
			document.getElementById("idNewSchema").style.display = "none";
		}
	}
	</script>
	>
	Quit $$$OK
}

/// Process saving the view
Method SaveForm(NAMESPACE As %String, Schema As %String, ViewName As %String, Owner As %String, ReadOnly As %String, CheckOption As %String, ViewText As %String) As %String
{
	Set $ZT = "Trap"	
	Set tSC = $$$OK
	Set sAction = $S(%request.PageName="UtilSqlView.csp":"Alter View ",1:"Create View ")
	Set CheckOption("LOCAL") = "WITH LOCAL CHECK OPTION"
	Set CheckOption("CASCADED") = "WITH CASCADE CHECK OPTION"
	Set sCheckOption = ""
	If ReadOnly = "1" {	// The view is defined as read-only by the author
		Set sCheckOption = "WITH READ ONLY"
	} Else {
		If CheckOption '= "" Set sCheckOption = CheckOption(CheckOption)
	}
	Set Schema = $S(Schema'="":Schema_".",1:"")
	Set gvDummy = ##class(%SQL.Manager.API).CheckIdentifier(.ViewName)
    Set sQueryText = sAction _ Schema _ ViewName _ " AS " _ ViewText _ " " _ sCheckOption
 	ZN NAMESPACE
 	Set tRS = ##class(%ResultSet).%New("%DynamicQuery:SQL")
	Set tSC = tRS.Prepare(sQueryText)
	If $$$ISOK(tSC) {
			#; %call="SMP" will prevent the DDL API from checking the DDLAllowed flag for the class
		n %caller s %caller="SMP", tSC = tRS.Execute() k %caller
	}
	If $$$ISERR(tSC) {
		// If I can parse out the SQLCODe and get the text of it, then I will append it to the end of the message
		Set msg = $System.Status.GetErrorText(tSC)
		If msg [ "SQLCODE" Set SQLCODE = $P($P(msg,"SQLCODE: ",2)," ",1)
		If $G(SQLCODE) '= "" Set sqlcode = $$$FormatMessage(,"%SqlCode","SqlCode"_$zabs(SQLCODE),,)
		Quit msg_" "_$G(sqlcode)
	}
	Quit tSC
Trap
	Set $ZT=""
	Quit $ZE
}

/// ViewText as a stream object is passed in. Rebuild view text from it.
/// If it errored, then return error message. 
Method GetStreamText(ViewText, IsError As %Boolean = 0) As %String
{
	Set $ZT="Trap"	
	Set tStream = ViewText
	Set ViewText = ""
	Do tStream.Rewind()
	While ('tStream.AtEnd) {
		Set ViewText = ViewText _ tStream.Read(32000)
	}
	Quit ViewText
Trap
	Set $ZT=""
	Set IsError = 1
	If $ZE [ "MAXSTRING" {
		Set msg = $$$Text("Your 'View Text' is longer than the supported variable length limit and cannot be processed. View Text has been truncated.")	
	} Else {
		Set msg = $ZE	
	}
	Quit msg
}

}
