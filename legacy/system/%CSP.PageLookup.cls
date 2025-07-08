/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// CSP page that provides a standard lookup for wizard-generated forms.
/// 
/// It expects the following input:
/// <p>
/// <table cols="2" cellpadding="5">
/// <tr><td><b>CLASSNAME</b></td><td>Name of class to perform lookup on.</td></tr>
/// <tr><td><b>OBJID</b></td><td>ID of current instance.</td></tr>
/// <tr><td><b>SELECT</b></td><td>A comma-delimited list of fields to display in the search result table.   Each field is of the form 'property alias|desc' where alias and |desc are optional.  If not specified, the WHERE list is used as the SELECT list.</td></tr>
/// <tr><td><b>WHERE</b></td><td>A comma-delimited list of fields to search on.  Each field is of the form 'property alias|desc' where alias and |desc are optional. </td></tr>
/// <tr><td><b>ORDER</b></td><td>A comma-delimited list of fields used to sort the search results.  Each field is of the form 'property |desc' where |desc is optional.</td></tr>
/// <tr><td><b>MAXROWS</b></td><td>Maximum rows to display; if missing don't execute query.</td></tr>
/// <tr><td><b>TARGET</b></td><td>URL of page to return to with results.</td></tr>
/// <tr><td><b>CAPTION</b></td><td>Caption for search window.</td></tr>
/// <tr><td><b>OPTIONS</b></td><td>Comma separated list of feature codes. These include popup, create, and clear.</td></tr>
/// <tr><td><b>OBJIDATTR</b></td><td>The name of the OBJID attribute for the associated form.</td></tr>
/// </table></p>
/// <p>Note: For range operations the value in the WHERE parameter contains two values delimited by &amp;.</p>
Class %CSP.PageLookup Extends %CSP.Page [ Not ProcedureBlock, System = 3 ]
{

/// Make default charset for the page UTF-8.
Parameter CHARSET = "utf-8";

/// Override PRIVATE from %CSP.Page
Parameter PRIVATE = 1;

/// Override ENCODED from %CSP.Page
Parameter ENCODED = 1;

/// Caption displayed if none specified (for normal mode).
Parameter DEFAULTCAPTION = "IRIS Search";

/// List of values displayed in search predicate combo box.
Parameter PREDICATELIST = "equals,not equal to,starts with,between,less than,greater than,contains,select";

/// No matching items message.
Parameter NOMATCH = "No matching items found.";

/// Caption for Search Button.
Parameter SEARCHBTN = "Search";

/// Caption for Cancel Button.
Parameter CANCELBTN = "Cancel";

/// Caption for Clear Button.
Parameter CLEARBTN = "Clear";

/// First half of &quot;Find all&quot; message.
Parameter FINDMSG1 = "Find all instances of ";

/// Second half of &quot;Find all&quot; message.
Parameter FINDMSG2 = " that meet the following conditions:";

/// First half of &quot;Items Found&quot; message.
Parameter FOUNDMSG1;

/// Second half of &quot;Items Found&quot; message.
Parameter FOUNDMSG2 = " matching item(s) found.";

/// First half of &quot;Items Shown&quot; message.
Parameter SHOWNMSG1 = "The first ";

/// Second half of &quot;Items Shown&quot; message.
Parameter SHOWNMSG2 = " are displayed below:";

/// Error message to display when no criteria are specified
/// for a search and the search button is pressed.
Parameter NOCRITERIA = "At least one search condition must be specified.  Search not executed.";

/// URL Name of this class
ClassMethod PageName() As %String [ CodeMode = generator ]
{
	New cls
	Set %code=0
	Set cls=%class
	Set:$e(cls)="%" cls="_"_$e(%class,2,$l(%class))
	$$$GENERATE(" Quit """_cls_".cls""")
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// display a csp page.
ClassMethod OnPage() As %Status [ Final ]
{
	New showcount,i,j,classname,maxrows,where,select,sort,restrict,idxlist,idname
	New name,val,pred,info,cat,s,alias,n,display,nodisplay,orderIndex
	New wherelist,selectlist,orderlist,predicatelist,direction,sc
	New showresults,criteriaSpecified
	
	// idname is name of idfield: "" for default
	set idname=""
	if %request.IsEncrypted("IDNAME") {
		set idname=$get(%request.Data("IDNAME",1))
	}
	
	Set sort = ""
	Set where = ""
	Set select = ""
	Set maxrows = $get(%request.Data("MAXROWS",1),100)
	
	// normalize value for OPTIONS
	Set %request.Data("OPTIONS",1)=$zcvt($get(%request.Data("OPTIONS",1)),"U")
	
	// showcount = 1 causes calculate and display of row count
	Set showcount = ($get(%request.Data("OPTIONS",1))["SHOWCOUNT")
	
	// was there a search error (programmatic error)
	If %request.IsDefined("SEARCHERROR") {
		&html<<div class="Error">#($get(%request.Data("SEARCHERROR",1)))#</div>> 
		QUIT $$$ERROR($$$CSPLookupSearch)
	}
	Set classname="",wherelist="",selectlist="",predicatelist=""
	if %request.IsEncrypted("CLASSNAME") {
		set classname=$get(%request.Data("CLASSNAME",1))
	}
	if %request.IsEncrypted("WHERE") {
		set wherelist=$get(%request.Data("WHERE",1))
	}
	if %request.IsEncrypted("SELECT") {
		set selectlist=$get(%request.Data("SELECT",1))
	}
	if %request.IsEncrypted("PREDICATES") {
		set predicatelist=$get(%request.Data("PREDICATES",1))
	}
	Set orderIndex=$order(%request.Data("ORDER",""),-1,orderlist)
	Set orderlist = $get(orderlist)
	
	// test for required parms
	If (classname="") {
		QUIT $$$ERROR($$$CSPLookupClassName)
	}
	
	Set classname = $$$NormalizeClassname(classname)
	If '##class(%ClassDefinition).%ExistsId(classname) {
		QUIT $$$ERROR($$$CSPLookupClassName)
	}
	
	If (wherelist="")  {
		QUIT $$$ERROR($$$CSPLookupWhere)
	}
	
	// build query spec
	// 	where is $LB($LB(field,predicate,value,alias),...)
	// 	select is $LB($LB(field,alias,asc|desc),...)
	// 	order is $LB($LB(field,asc|desc),...)
	
	// build criteria from WHERE input
	Set sc=$$$OK
	Set n=1
	For i=1:1:$length(wherelist,",") {
		Set s = $zstrip($piece(wherelist,",",i),"<>W")
		Set direction=$zstrip($zcvt($piece(s,"|",2),"U"),"<>W")
		If $case(direction,"ASC":0,"DESC":0,"":0,:1) {
			Set sc=$$$ERROR($$$CSPInvalidSortDirection)
			Quit
		}
		Set s=$piece(s,"|",1)
		Set name = $zstrip($piece(s," ",1),">W")
		Set pred = $get(%request.Data("PRED",i))
		if pred="" {
			Set pred=$P(predicatelist,",",i)
			set pred=$zcvt(pred,$select($extract(pred)="%":"U",1:"L"))
		}
		Set val = $get(%request.Data("PARM",i))
		If (name '= "") {
			If (pred = "") { 
				Set cat = ..GetPropType(classname,name)
				Set pred = $select(cat="STRING":"%STARTSWITH",cat="NAME":"%STARTSWITH",1:"=")
			}
			
			Set alias = ""
			If ($length(s," ")>1) {
				Set alias = $piece(s," ",2,$length(s," "))
				Set s = $zstrip(alias,"<W")
				If ($length(s," ")>1) && ($zcvt($piece(s," ",1),"L")="as") {
					Set alias = $piece(s," ",2,$length(s," "))
				}
			}
			
			Set $list(where,n) = $lb(name,pred,val,alias)
			If (selectlist="") {
				Set $list(select,n) = $lb(name,alias,direction)
			}
		
			// only count non-"" fields
			Set n = n + 1
		}
	}
	If $$$ISERR(sc) Quit sc
	
	// if specified, build select list
	If (selectlist'="") {
		Set n = 1
		For i=1:1:$length(selectlist,",") {
			Set s = $zstrip($piece(selectlist,",",i),"<>W")
			Set direction=$zstrip($zcvt($piece(s,"|",2),"U"),"<>W")
			If $case(direction,"ASC":0,"DESC":0,"":0,:1) {
				Set sc=$$$ERROR($$$CSPInvalidSortDirection)
				Quit
			}
			Set s=$piece(s,"|",1)
			Set name = $zstrip($piece(s," ",1),">W")
			If (name '= "") {
				Set alias = ""
				If ($length(s," ")>1) {
					Set alias = $piece(s," ",2,$length(s," "))
					Set s = $zstrip(alias,"<W")
					If ($length(s," ")>1) && ($zcvt($piece(s," ",1),"L")="as") {
						Set alias = $piece(s," ",2,$length(s," "))
					}
				}
				
				Set $list(select,n) = $lb(name,alias,direction)
				// only count non-"" fields
				Set n = n + 1
			}
		}
	}
	If $$$ISERR(sc) Quit sc
	
	// build sort list
	If (orderlist'="") {
		For i=1:1:$length(orderlist,",") {
			Set s = $piece(orderlist,",",i)
			Set direction=$zstrip($zcvt($piece(s,"|",2),"U"),"<>W")
			If $case(direction,"ASC":0,"DESC":0,"":0,:1) {
				Set sc=$$$ERROR($$$CSPInvalidSortDirection)
				Quit
			}
			Set s=$piece(s,"|",1)
			If direction="" {
				// If direction not specified, see if there is a 
				//   default in the select list
				If s=+s {
					Set direction=$list($list(select,s),3)
				} Else {
					For j=1:1:$listlength(select) {
						If $list($list(select,j),1)=s {
							Set direction=$list($list(select,j),3)
							Quit
						}
					}
				}
			}
			Set $list(sort,i) = $lb(s,direction)
		}
	}
	If $$$ISERR(sc) Quit sc
	
	&html<<html><head>>
	
	Do ..ShowTitle()
	Do ..ShowStyleSheet()
	Do ..ShowScripts()
	
	&html<</head>>
	&html<<body onload="searchOnLoad();">>
	
	Do ..ShowCaption()
	
	// display form for criteria
	Do ..ShowForm(classname,where,select,$piece($piece(orderlist,","),"|",1))
	
	// If user has requested a search (via submit) do it (or if there are any values submitted)
	Set showresults = 0
	Set nodisplay = ($get(%request.Data("OPTIONS",1))["NODISPLAY")
	Set display=0
	if 'nodisplay Set display = ($get(%request.Data("OPTIONS",1))["DISPLAY")
	If display || $data(%request.Data("SEARCH",1)) || ('nodisplay && ($get(%request.Data("ORDER",1)) '= "")) {
		Set showresults = 1
	}
	
	// see if any values are submitted
	Set i = 1
	Set criteriaSpecified = 0
	While ('criteriaSpecified && (i '> %request.Count("PARM"))) {
		If ($get(%request.Data("PARM",i)) '= "") {
			Set criteriaSpecified = 1
		}
		Set i = i + 1
	}
	
	If criteriaSpecified Set showresults = 1
	
	If (showresults) {
		If 'criteriaSpecified && ($get(%request.Data("OPTIONS",1))["CRITERIAREQUIRED") {
			Do ..ShowNoCriteria()
		} Else {
			Do ..ShowResults(classname,select,where,sort,maxrows,showcount,idname)
		}
	}

	&html<</body>>
	
	&html<</html>>
	
	QUIT $$$OK
}

/// Returns the type (SQL Category) of property <VAR>prop</VAR> for class <VAR>classname</VAR>.
ClassMethod GetPropType(classname As %String, prop As %String) As %List [ Final ]
{
	New type,cat
	
	If (classname="")!(prop="") {
		QUIT ""
	}
	
	Set type=$$$comMemberKeyGet(classname,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
	Set cat = $select(type="":"",1:$$$comClassKeyGet(type,$$$cCLASSsqlcategory))
	QUIT cat
}

/// Returns the SQL name of property <VAR>prop</VAR> for class <VAR>classname</VAR>
/// in <var>field</var>.
ClassMethod GetPropSqlName(classname As %String, prop As %String, ByRef column As %String) As %Status [ Final ]
{
	if (prop="ID")||(prop="%Id()") set column="%ID" quit $$$OK
	new col
	set col=$Get($$$EXTPROPsqlcolumnname($$$pEXT,classname,prop))
	if col="" {
		set column="" 
		quit $$$ERROR($$$PropertyNameInvalid,prop)
	}
	quit $$QuoteId^%occStorageUtil(col,.column)
}

/// Display an error message when search criteria must be specified
/// before a search is requested (OPTIONS=CriteriaRequired) and no criteria are specified.
ClassMethod ShowNoCriteria() [ Private ]
{
	Write "<script language=""JavaScript"" type=""text/javascript"">",!
	&html<alert("#(%response.GetText("","%CSPSearch","NoCriteria",..#NOCRITERIA))#");>
	Write "</script>",!
}

/// Display the client scripts for the lookup page.
/// <p>This has to be called within the HEAD section of the document.
ClassMethod ShowScripts() [ Private ]
{
	Write "<script language=""JavaScript"" type=""text/javascript"">",!
	&html<
	function searchOnLoad()
	{
		var form = self.document.MainForm;
		var control = (form.PARM.length == null) ? form.PARM : form.PARM[0];
		control.focus();
		if (control.type == "text") control.select();
		return true;
	}
	function searchClear()
	{
		var form = self.document.MainForm;
		if (form.PARM.length == null) {
			form.PARM.value = '';
		}
		else {
			for (var i = 0; form.PARM.length != i; i++) {
				form.PARM[i].value = '';
			}
		}
		form.ORDER.value = '';
		form.submit();
		return true;
	}
	function searchSort(field) {
		self.document.MainForm.ORDER.value = field;
		self.document.MainForm.submit();
		return true;
	}
	>
	
	if ($get(%request.Data("OPTIONS",1))["POPUP") {
		New onselect
		Set onselect = $get(%request.Data("ONSELECT",1))
		If (onselect '= "") {
			Set onselect = "opener." _ onselect _ "(id);"
		}
		&html<
	function searchSelect(id,url)
	{>
		if ($get(%request.Data("OPTIONS",1))'["LEAVEOPEN") {
			Write $c(9,9)_"opener.cspPopupWindow = null;",!
		}
		if (onselect '= "") {
			Write $c(9,9)_onselect,!
		}
		elseif (%request.IsEncrypted("TARGET")) {
			Write $c(9,9)_"opener.document.location = url;",!
		}
		if ($get(%request.Data("OPTIONS",1))'["LEAVEOPEN") {
			Write $c(9,9)_"window.close();",!
			Write $c(9,9)_"return true;",!
		}
		&html<
	}
	function searchCancel() {
		opener.cspPopupWindow = null;
		window.close();
		return true;
	}>
	}
	else {
		If (%request.IsEncrypted("TARGET")) {
			New nvp
			If %request.IsEncrypted("OBJID") {
				Set nvp($get(%request.Data("OBJIDATTR",1),"OBJID")) = $get(%request.Data("OBJID",1))
			}
			Else {
				Set nvp($get(%request.Data("OBJIDATTR",1),"OBJID")) = ""
			}
			&html<
	function searchSelect(id,url)
	{
		self.document.location = url;
		return true;
	}
	function searchCancel() {
		self.document.location='#(..Link($get(%request.Data("TARGET",1)),.nvp))#';
		return true;
	}>
		}
	}
	
	Write "</script>",!
	
	QUIT
}

/// Display the HTML Style Sheet for the lookup page.
/// <p>This has to be called within the HEAD section of the document.
ClassMethod ShowStyleSheet() [ Private ]
{
 &html<<style type="text/css">
 <!--
 body { color: black; background: #DDDDDD; font-family: Helvetica,Arial; }
 h1 { font-family: Helvetica,Arial; background: #000088; color: white; }
 h1.BM { font-family: Helvetica,Arial; background: #884488; color: white; }

 .SearchTable { background: white; border-color: black; border-width: 1px; border-style: solid; }

 .Caption { font-family: Helvetica,Arial;  font-style: bold; color: white; background: #000088; }
 .SortedCaption { font-family: Helvetica,Arial;  font-style: bold; color: yellow; background: #000088; }

 .DarkRow { font-family: Helvetica,Arial;  background: #DDDDDD; }
 .LightRow { font-family: Helvetica,Arial; background: #FFFFFF; }
 .HighlightRow { font-family: Helvetica,Arial; background: silver; }

 .Sort   { background: #CCCCCC; 
 border-color: black; border-width: 1px; border-style: solid; }

 .Criteria   { background: #CCCCCC; 
 border-color: black; border-width: 1px; border-style: solid; }

 .SortCell   { padding-left: 5px; padding-right: 5px; padding-top: 2px; padding-bottom: 2px; }

 .Error   { font-style: bold; color: red; }

 -->
 </style>
 >

 QUIT
}

/// Display the title for a lookup page.
ClassMethod ShowTitle() [ Private ]
{
	&html<<title>#($get(%request.Data("CAPTION",1),%response.GetText("","%CSPSearch","DefaultCaption",..#DEFAULTCAPTION)))#</title>>
	
	QUIT
}

/// Display the caption for a lookup page.
ClassMethod ShowCaption() [ Private ]
{
	if ($get(%request.Data("OPTIONS",1))["POPUP") {
		Write $get(%request.Data("CAPTION",1)),!
		QUIT
	}
	&html<<h1>&nbsp;#($get(%request.Data("CAPTION",1),%response.GetText("","%CSPSearch","DefaultCaption",..#DEFAULTCAPTION)))#</h1>>
	Write %response.GetText("","%CSPSearch","FindMsg",..#FINDMSG1_"<b>%1</b>"_..#FINDMSG2,$select(%request.IsEncrypted("CLASSNAME"):$get(%request.Data("CLASSNAME",1),"missing"),1:"missing")),!
	
	QUIT
}

/// Display the criteria form for a lookup page.
/// <p><VAR>where</VAR> is $list of criteria, each element is $LB(name,pred,val,alias)
/// <p><VAR>select</VAR> is $list of fields that can be sorted on
/// <p><VAR>currval</VAR> is current sort field
ClassMethod ShowForm(classname As %String, where As %List, select As %List, currval As %String) [ Private ]
{
	New name,val,i,pred,op,token,nvp
	
	&html<<form name="MainForm">>
	
	// render hidden field to hold encrypted stateinfo
	Set token = $get(%request.Data("CSPToken",1))
	&html<<input type="hidden" name="CSPToken" value='#(token)#'>>
	Write ..InsertHiddenFields("")
	
	Do ..ShowCriteria(classname,where)
	
	Do ..ShowSort(select,currval)
	
	&html<</form>>
	QUIT
}

/// Display the criteria form for a lookup page.
/// <p><VAR>where</VAR> is $list of criteria, each element is $LB(name,pred,val...)
ClassMethod ShowCriteria(classname As %String, where As %List) [ Private ]
{
	New name,val,i,pred,op,alias,showOptions
	
	If ($get(%request.Data("OPTIONS",1))["NOPREDICATES") {
		Set showOptions = 0
	} Elseif ($get(%request.Data("OPTIONS",1))["PREDICATES") {
		Set showOptions = 1
	} Else {
		Set showOptions = ($get(%request.Data("OPTIONS",1))'["POPUP")
	}
	
	&html<<table class="Criteria" border="0" cellspacing="0"><tr valign="top"><td><table>>
	
	If (where'="") {
		For i=1:1:$LL(where) {
			Set name = $LG($LG(where,i),1)
			Set pred = $LG($LG(where,i),2)
			Set val = $LG($LG(where,i),3)
			Set alias = $LG($LG(where,i),4)
			If alias="" Set alias = name
			If alias = "%Id()" Set alias="ID"
			
			Write "<tr><td align=""right""><b>"_alias_"</b></td>"
			Write "<td>"
			Do ..ShowPredicates(name,pred,showOptions)
			Write "</td>",!
			
			Write "<td>"
			If pred'="select" {
				Write "<input type=""text"" name=""PARM"" value="""_..EscapeHTML(val)_""">"
			} Else {
				Do ..ShowSelectChoices(classname,name,val,pred)
			}
			Write "</td></tr>",!
		}
	}
	
	&html<</table></td><td><table border="0" cellspacing="0">
	<tr valign="top"><td>
	<input type="submit" name="SEARCH" value="#(%response.GetText("","%CSPSearch","SearchBtn",..#SEARCHBTN))#">
	<input type="button" name="CANCEL" value="#(%response.GetText("","%CSPSearch","CancelBtn",..#CANCELBTN))#" onclick="searchCancel();">>
	If ($get(%request.Data("OPTIONS",1)) [ "CLEARBTN") {
		&html<<input type="button" name="CLEAR" value="#(%response.GetText("","%CSPSearch","ClearBtn",..#CLEARBTN))#" onclick="searchClear();">>
	}
	&html<</td>
	</tr></table>
	</tr></table>>
	QUIT
}

/// Display a list of predicates in a SELECT box.
ClassMethod ShowPredicates(name As %String, pred As %String, showOptions As %Boolean) [ Private ]
{
	New pvlist,pdlist,i,test
	Set pvlist = $LB("=","<>","%STARTSWITH","between","<",">","contains","select")
	Set pdlist = %response.GetText("","%CSPSearch","PredicateList",..#PREDICATELIST)
	
	If ('showOptions) {
		Write "<input type=""hidden"" name=""PRED"" value="""_pred_""">"
		QUIT
	}
	
	Set test=$select(pred="select":"!=",1:"==")
	Write "<select name=""PRED"" onchange=""if (options[selectedIndex].value"_test_"'select') submit();"">",!
	
	For i=1:1:$L(pdlist,",") {
		Write "  <option value=""",$LI(pvlist,i),""" ",$S(pred=$LI(pvlist,i):"selected",1:""),">",$P(pdlist,",",i),"</option>",!
	}
	
	Write "</select>"
	QUIT
}

/// Display the choices for a select predicate.
ClassMethod ShowSelectChoices(classname As %String, name As %String, initval As %String, pred As %String) [ Private, ProcedureBlock = 1 ]
{
	Set ref=($length(name,"->")=2)
	If ref {
		Set reference=$piece(name,"->",1)
		Set name=$piece(name,"->",2)
		Set selectList=$LB($LB(name,"val"),$LB("ID","id"))
		If ##class(%CSP.DwxUtils).GetReferenceInfo(classname,reference,.type)="" {
			Set sc=$$$ERROR($$$PropertyNameInvalid,name)
		} Else {
			Set sc=..BuildSelectStatement(type,selectList,.query,0,"-","SELECT")
		}
		Set sc=..GetPropSqlName(type,name,.column)
	} Else {
		Set selectList=$LB($LB(name,"val"))
		Set sc=..BuildSelectStatement(classname,selectList,.query,0,"-","SELECT DISTINCT")
		Set sc=..GetPropSqlName(classname,name,.column)
	}
	
	If $$$ISOK(sc) {
		Set query=query_" ORDER BY "_column
		Set resultset = ##class(%ResultSet).%New("%DynamicQuery.SQL")
		If (resultset=$$$NULLOREF) Set sc=$$$ERROR($$$CSPLookupResultSet)
	}
	
	If $$$ISOK(sc) {
		Set resultset.RuntimeMode=2	; Run query in display format
		Set sc = resultset.Prepare(query,1,"RUNTIME")
		If $$$ISOK(sc) Set sc=resultset.Execute()
	}

	If $$$ISOK(sc) {
		Write "<select name=""PARM"">",!
		Set (currid,currval)=""
		While resultset.Next() {
			Set val=resultset.GetData(1)
			If (currval'=val) {
				Do ..ShowOneChoice(currval,currid,initval)
				Set currval=val
				Set currid=$select(ref:resultset.GetData(2),1:"")
			} Else {
				Set currid=""
			}
		}
		Do ..ShowOneChoice(currval,currid,initval)
		Write "</select>"
	}

	If $$$ISERR(sc) Do ..ShowError(sc)
	Quit
}

/// Display a choice option.
ClassMethod ShowOneChoice(val As %String, id As %String, initval As %String) [ Private, ProcedureBlock = 1 ]
{
	Write "  <option"
	If id'="" {
		Write " value="""_$c(1)_..EscapeHTML(id)_""""
		If $c(1)_id=initval Write " selected"
	} Else {
		If val=initval Write " selected"
	}
	Write ">"_..EscapeHTML(val)_"</option>",!
}

/// Display the sort options for a lookup page.
/// <p><VAR>select</VAR> is a list of selected fields.
ClassMethod ShowSort(select As %List, currval As %String) [ Private ]
{
	New i,value,orderby,alias,prop
	
	Set index=$order(%request.Data("ORDER",""),-1,order)

	if ($get(%request.Data("OPTIONS",1))'["SORTBOX") {
		&html<<input type="hidden" name="ORDER" value="#(currval)#">>
		Quit
	}
	
	&html<<br><table class="Sort"><tr>
	<td><b>#(%response.GetText("","%CSPSearch","SortBy","Sort by:"))#</b></td>
	<td class="SortCell"><input type="radio" name="ORDER" value="" #($S(currval="":"checked",1:""))#>#(%response.GetText("","%CSPSearch","NotSorted","Not Sorted"))#</td>>
	
	For i=1:1:$LL(select) {
		Set value = $LG($LG(select,i),1)
		Set alias = $LG($LG(select,i),2)
		If alias="" Set alias = value
		If alias = "%Id()" Set alias="ID"
		&html<<td class="SortCell"><input type="radio" name="ORDER" value="#(i)#" #($S(value=currval:"checked",1:0))#>#(..EscapeHTML(alias))#</td>>
	}
	
	&html<</tr></table>>
	
	Quit
}

/// Display the results of the lookup in an HTML table.
ClassMethod ShowResults(classname As %String, select As %List, where As %List, sort As %List, maxrows As %Integer, showcount As %Boolean = 1, idname As %String = "") As %Status [ Private ]
{
	New result,row,i,cols,val,rcount,sc,countstar,target,width,nvp,id,url,
		idfield,firstcol,order,orderIndex
	
	Set rcount = 0
	
	// save space for popup
	If ('$get(%request.Data("OPTIONS",1))["POPUP") {
		Write "<hr>",!
	}
	
	Set result = $$$NULLOREF
	
	Set sc = ..CreateResultSet(classname,where,select,sort,showcount,.result,.rcount,idname,.idfield)
	
	If $$$ISERR(sc) {
		Do ..ShowError(sc)
		QUIT sc
	}
	
	If (result=$$$NULLOREF) {
		QUIT $$$ERROR($$$CSPLookupResultSet)
	}
	
	// showcount indicates whether to display a row count
	
	// rcount < 0 indicates that col 1 of the result set contains the row count
	Set countstar = $S(rcount=-1:1,1:0)
	Set firstcol=$select(idfield=0:1,1:0)+countstar+1
	If idfield=0 Set idfield=1

	Set cols = result.GetColumnCount()
	
	// lookup grid
	Set row = 0
	
	While (result.Next() && (row < maxrows)) {
		//first row--set up table
		If ((row=0) && (showcount=1)) {
			If (countstar=1) { 
				Set rcount = result.GetData(firstcol-1)
			}
			Write "<p><font size=""-1"">",%response.GetText("","%CSPSearch","FoundMsg",..#FOUNDMSG1_"<b>%1</b>"_..#FOUNDMSG2,rcount),!
			If (rcount>maxrows) {
				Write "&nbsp;",%response.GetText("","%CSPSearch","ShownMsg",..#SHOWNMSG1_"%1"_..#SHOWNMSG2,maxrows),!
			}
			Write "<br></font></p>&nbsp;",!
		}
	
		// show heading
		If (row = 0) {
			Set width = $S(($get(%request.Data("OPTIONS",1))["POPUP"):"100%",1:"")
			Write "<table class=""SearchTable"" cols="""_cols_""" width="""_width_""" border=""0"" cellpadding=""3"" cellspacing=""0"">",!
			For i=1:1:$listlength(select) {
				Set value = $listget($listget(select,i),1)
				Set alias = $listget($listget(select,i),2)
				If alias="" Set alias = value
				If alias = "%Id()" Set alias="ID"
				Set alias = ..EscapeHTML(alias)
				If ($get(%request.Data("OPTIONS",1))["SORTBOX") {
					Write "<th class=""Caption"" align=""left"">&nbsp;"_alias_"&nbsp;</th>",!
				}
				Else {
					Write "<th class=""Caption"" align=""left"">"
					Write "&nbsp;<a href=""javascript:searchSort("_..QuoteJS(value)_");"" title=""Sort Results by "_alias_""">"
					Set orderIndex=$order(%request.Data("ORDER",""),-1,order)
					Write "<span class="""_$select($get(order)=value:"SortedCaption",1:"Caption")_""">"
					Write alias
					Write "</span></a>&nbsp;</th>",!
				}
			}
		}
		
		// show results
		Set row = row + 1
		Set target = $select(%request.IsEncrypted("TARGET"):$get(%request.Data("TARGET",1)),1:"")
		Set id = ..QuoteJS(result.GetData(idfield))
		Set nvp($get(%request.Data("OBJIDATTR",1),"OBJID")) = result.GetData(idfield)
		Set url = ..QuoteJS(..Link(target,.nvp))
		
		Write "<tr class="""_$S(row#2:"LightRow",1:"DarkRow")_""""
		Write " onmouseover=""oldClassName=className;className='HighlightRow';""" 
		Write " onmouseout=""className=oldClassName;""",!
		Write "  onclick=""searchSelect("_id_","_url_");"">",!
		
		For i = firstcol:1:cols {
			If i = firstcol {
				// make first column selectable
				// make link for NetScape
				Write "<td><a href=""javascript:searchSelect("_id_","_url_");"">"
				Write ..EscapeHTML(result.GetData(i))_"</a></td>",!
			}
			Else {
				Write "<td>"_..EscapeHTML(result.GetData(i))_"</td>",!
			}
		}
		Write "</tr>",!
	}
	
	If (row > 0) {
		Write "</table>",!
	}
	Else {
		Write "<p><b>",%response.GetText("","%CSPSearch","NoMatch",..#NOMATCH),"</b></p>",!
	}
	
	QUIT $$$OK
}

/// Constructs a SELECT statement for the property list <VAR>proplist</VAR>.
ClassMethod BuildSelectStatement(class As %String, proplist As %List, ByRef statement As %String, getcount As %Boolean = 0, idname As %String = "", select As %String = "SELECT", Output idfield As %Integer) As %Status
{
	New sc,column,property,ptr,temp,colsep,columns
	
	Set idfield=0
	Set columns=""
	Set colsep=""
	If getcount {
		Set columns = columns_colsep_"count(*)"
		Set colsep=","
	}
	
	// convert props into SQL column names...
	Set sc = $$$OK
	For ptr=1:1:$LL(proplist) {
		Set temp = $LG(proplist,ptr)
		Set property = $LG(temp,1)
		If (property'="") {
			// test for implicit joins: (must use sql names!)
			If ($L(property,"->")>1) {
				Set column = property
			}
			Else {
				Set sc=..GetPropSqlName(class,property,.column)
			}
			If $$$ISOK(sc) {
				If (idname="") {
					If column="%ID" Set idfield=ptr
				} ElseIf idname'="-" {
					If column=idname Set idfield=ptr
				}
				Set columns = columns _ colsep _ column
				Set colsep=","
			}
		}
		
		If $$$ISERR(sc) Quit
	}
	
	If $$$ISERR(sc) QUIT sc
	
	// select rowid first
	Set select=select_" "
	If idfield=0 {
		If (idname="") {
			Set select = select_$$$comMemberKeyGet(class,$$$cCLASSstorage,$$$comClassKeyGet(class,$$$cCLASSstoragestrategy),$$$cSDEFsqlrowidname)_","
		} ElseIf idname'="-" {
			Set select=select_idname_"," ;!!!!
		}
	} ElseIf getcount {
		Set idfield=idfield+1
	}
	
	Set select=select_columns
		
	// Get full SQL table name
	Set statement = select _ " FROM " _ $$$comClassKeyGet(class,$$$cCLASSsqlqualifiednameQ)
	QUIT $$$OK
}

/// Constructs a query using the input values, opens a <CLASS>%ResultSet</CLASS> object 
/// using this query and returns it via <VAR>resultset</VAR>.
/// <p>
/// <dl>
/// <dt><VAR>class</VAR></dt>
/// <dd>The name of the class to perform the lookup on.</dd>
/// <dt><VAR>restrict</VAR></dt>
/// <dd>A list of restrictions as $lb(property,value).</dd>
/// <dt><VAR>return</VAR></dt>
/// <dd>A $list of properties to return in the resultset.</dd>
/// <dt><VAR>orderby</VAR></dt>
/// <dd>A list of $lb(property,ASC|DESC) that specify the order of the result set.</dd>
/// <dt><VAR>getcount</VAR></dt>
/// <dd>If true, the query should fetch the number of rows in the result.</dd>
/// <dt><VAR>resultset</VAR></dt>
/// <dd>Returns a <CLASS>%ResultSet</CLASS> object by reference.</dd>
/// <dt><VAR>rcount</VAR></dt>
/// <dd>Returns number of selected rows by reference. -1 indicates that the row count is in column 1 of the result set.</dd>
/// </dl></p>
/// <p>Returns a <CLASS>%Status</CLASS> indicating success or failure.</p>
ClassMethod CreateResultSet(class As %String, restrict As %List, return As %List, orderby As %List, getcount As %Boolean, ByRef resultset As %ResultSet, ByRef rcount As %Integer, idname As %String = "", ByRef idfield As %Integer) As %Status
{
	// if we are getting count, it will be in column of query
	// so set rcount to -1
	Set rcount = $S(getcount:-1,1:0)
	
	New %sc,column,formal,args,parameter,predicate,property,ptr,query,rowid,sdef,select,sort,tablename,temp,type,value,where,setStmt,direction,base
	Set %sc = $$$OK
	Set resultset = $$$NULLOREF
	If '$$$comClassDefined(class) {
		Quit $$$ERROR($$$CompiledClassDoesNotExist,class)
	}
	
	// get SELECT statement
	Set query = ""
	Set %sc = ..BuildSelectStatement(class,return,.query,getcount,idname,,.idfield)
	If $$$ISERR(%sc) {
		QUIT %sc
	}
	
	// convert restrict into SQL column names...
	Set formal = ""
	Set parameter = 0
	Set where = ""
	Set %sc = $$$OK
	
	For ptr=1:1:$LL(restrict) {
		Set temp = $li(restrict,ptr)
		Set property = $li(temp,1)
		Set predicate = $li(temp,2)
		Set value = $li(temp,3)
		If (property'="") {
			// test for implicit joins: (must use sql names!)
			If ($L(property,"->")>1) {
				Set column = property
			} Else {
				Set %sc = ..GetPropSqlName(class,property,.column)
			}
			If ($$$ISOK(%sc)) {
				// don't test when parm is ""
				If value'="" {
					If (predicate="between")&&($L(value,"&")'=2) {
						Set predicate = ">="
					} ElseIf (predicate="%STARTSWITH")&&(idname'="") {
						// assume external table
						Set predicate = "LIKE"
						Set value = value _ "%"
					} ElseIf (predicate="contains") {
						Set predicate = "LIKE"
						Set value = "%"_value _ "%"
					} ElseIf (predicate="select") {
						If $extract(value)=$c(1) {
							Set value=$extract(value,2,$length(value))
							Set column=$piece(column,"->",1)
						}
						Set predicate="="
					}

					If (predicate="between") {
						Set parameter = parameter + 1
						//Set setStmt=##class(%CSP.DwxUtils).GetLogicalValue(
						//		class, property, "args("_parameter_")",
						//		"$ZSTRIP($P(value,""&"",1),""<>W"")")
						//X setStmt
						Set args(parameter)=$ZSTRIP($P(value,"&",1),"<>W")
						Set parameter = parameter + 1
						//Set setStmt=##class(%CSP.DwxUtils).GetLogicalValue(
						//		class, property, "args("_parameter_")",
						//		"$ZSTRIP($P(value,""&"",2),""<>W"")")
						//X setStmt
						Set args(parameter)=$ZSTRIP($P(value,"&",2),"<>W")
						Set where = where_" AND ("_column_" >="_" ? AND "_column_" <="_" ?)"
					} Else {
						Set parameter = parameter + 1
		
						//!!!
						Set args(parameter)=$ZSTRIP(value,"<>W")
						//Set setStmt=##class(%CSP.DwxUtils).GetLogicalValue(
						//		class, property, "p"_parameter,
						//		"$ZSTRIP(value,""<>W"")")
						//X setStmt
						Set where = where _ " AND " _ column _ " " _ predicate _ " ? "
					}
				}
			}
		}
		
		If ($$$ISERR(%sc)) {
			Quit
		}
	}
	
	If $$$ISERR(%sc) {
		QUIT %sc
	}
	
	If (where'="") {
		Set query = query _ $$$NL _ " WHERE " _ $e(where,6,$l(where))
	}
	
	// convert orderby into SQL column names...
	Set sort = ""
	Set base=(idfield=0)+(''getcount)
	Set %sc = $$$OK
	For ptr=1:1:$Listlength(orderby) {
		Set temp = $lg(orderby,ptr)
		Set property = $lg(temp,1)
		Set direction = $lg(temp,2)
		If (property '="") {
			// test for implicit joins: (must use sql names!)
			If ($L(property,"->")>1) {
				Set column = property
			} ElseIf property=+property {
				Set column=base+property
			} Else {
				Set %sc = ..GetPropSqlName(class,property,.column)
			}
			If ($$$ISOK(%sc)) {
				Set sort = sort_", "_column_$Select(direction="":"",1:" "_direction)
			}
		}
		
		If ($$$ISERR(%sc)) {
			Quit
		}
	}
	
	If $$$ISERR(%sc) {
		QUIT %sc
	}
	
	If (sort'="") {
		Set query = query _ $$$NL _ " ORDER BY " _ $e(sort,3,$l(sort))
	}
	
	// create result set
	Set resultset = ##class(%ResultSet).%New("%DynamicQuery.SQL")
	
	If (resultset=$$$NULLOREF) {
	Quit $$$ERROR($$$CSPLookupResultSet)
	}
	
	Set resultset.RuntimeMode=2	; Run query in display format
	
	If (%request.IsEncrypted("SHOWSQL")&&$get(%request.Data("SHOWSQL",1)) = 1) {
		&html<<table class=Sort>>
		&html<<tr><td class=SortCell>#(query)#</td></tr>>
		&html<<tr><td class=SortCell><table cellpadding=2 border=1>>
		For ptr=1:1:parameter {
			Write " <tr><td align=""right"">p",ptr,":</td><td>",$get(args(ptr),"&nbsp;"),"</td></tr>"
		}
		&html<</table></td></tr></table>>
	}
	
	Set %sc = resultset.Prepare(query,1,"RUNTIME")
	
	If $$$ISERR(%sc) {
		QUIT %sc
	}
	
	Set args=parameter
	Set %sc = resultset.Execute(args...)
	Quit %sc
}

}
