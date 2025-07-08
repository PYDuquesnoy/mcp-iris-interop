/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Component for editing SQL Tables, Views, Procedures, ML Configurations, and Foreign Servers on the User and Role edit pages
Class %CSP.UI.Component.SQLTables Extends (%ZEN.Component.component, %CSP.UI.Component.SelectBoxUtils) [ System = 3 ]
{

Parameter DOMAIN [ Internal ] = "%Utility";

/// This is the XML namespace for this component.
Parameter NAMESPACE [ Internal ] = "http://www.intersystems.com/zen";

Property includeSystem As %ZEN.Datatype.integer [ InitialExpression = 0 ];

Property namespace As %ZEN.Datatype.string;

Property nsDisplayList As %ZEN.Datatype.string;

Property nsValueList As %ZEN.Datatype.string;

Property pageType As %ZEN.Datatype.string(VALUELIST = ",Users,Roles");

/// Name of the User/Role being edited
Property PID As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// If true, tables are for display only
Property readOnly As %ZEN.Datatype.boolean(ZENEXPRESSION = 1) [ InitialExpression = 0 ];

Property showSystemBox As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property tab As %ZEN.Datatype.integer;

Property type As %ZEN.Datatype.string;

/// Allow this component to page its results.
Property usePaging As %ZEN.Datatype.boolean(ZENEXPRESSION = 1) [ InitialExpression = 1 ];

/// The current page of results being displayed. If usePaging=0 this setting will be ignored.
Property resultsPage As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ InitialExpression = 1 ];

/// The desired number of tables to display per results page. If usePaging=0 this setting will be ignored.
Property resultsPageSize As %ZEN.Datatype.integer [ InitialExpression = 100 ];

/// The final page of results as calculated from the actual results given the resultsPageSize. If usePaging=0 this setting will be ignored.
Property resultsMaxPage As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
.Text2:first-letter {
    font-size:1.4em;
}
.Text2 {
    font-size:13px;
    max-width:575px;
    margin-bottom:5px;
}
.sectionLabel {
	font-size:13px;
	font-weight:normal;
	color:black;
	margin-top:15px;
}
</style>
}

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML()
{
	Try {
		Set PID = $$$ZENVAL(..PID)
		
		If ..namespace = "" {
			Set ..namespace = $G(%session.Data("$NAMESPACE"),$namespace)
		}
		If (","_..namespace_"," '[ ","_..nsValueList_",") Set ..namespace = $namespace
		// update the session $NAMESPACE now
		Set %session.Data("$NAMESPACE") = ..namespace
		
		Set ..includeSystem = $G(%session.Data("includeSystemItems"),0)
		
		New $namespace
		Set $namespace = ..namespace
		
		If ..type = "STORED PROCEDURE" {
			Set PrivilegeString = "EXECUTE"
		} elseif ..type = "ML CONFIGURATION" || (..type = "FOREIGN SERVER") {
			Set PrivilegeString = "USE"
		} elseif ..type = "VIEW" {
			Set PrivilegeString = "%ALTER,SELECT,INSERT,UPDATE,DELETE"
		} else {
			Set PrivilegeString = "%ALTER,SELECT,INSERT,UPDATE,DELETE,REFERENCES"
		}
		Set nPrivilegesLen = $L(PrivilegeString,",")
		
		// DP-413589 - Move the query setup earlier in order to collect table size information 
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserPrivs")
		Set tSC = tRS.Execute(PID,..includeSystem)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		set tNameCount = 0
		While tRS.Next() {
			If tRS.Data("TYPE") = ..type {
				Set tLastName = tRS.Data("NAME")
				
				Do:'$D(tObjects(tLastName)) $I(tNameCount)		// DP-413589 - Tally the number of table names
				
				Set tGrantedVia = $SELECT(tRS.Data("GRANTED_VIA")="":0,1:tRS.Data("GRANTED_VIA"))
				Set tGrantedBy = $SELECT(tRS.Data("GRANTED_BY")="":0,1:tRS.Data("GRANTED_BY"))
				Set tPrivName = tRS.Data("PRIVILEGE")
				Set tGrant = tRS.Data("GRANT_OPTION")
				Set tObjects(tLastName,tGrantedVia,tGrantedBy,0) = tRS.Data("TYPE")
				For i=1:1:nPrivilegesLen {
					If $P(PrivilegeString,",",i) = tPrivName {
						Set $P(tObjects(tLastName,tGrantedVia,tGrantedBy),",",i) = $S(tGrant="Yes":2,1:1)	
					}
				}
				Set $P(tObjects(tLastName,tGrantedVia,tGrantedBy),",",i+1) = tRS.Data("GRANTED_VIA")
				Set $P(tObjects(tLastName,tGrantedVia,tGrantedBy),",",i+2) = tRS.Data("GRANTED_BY")
				Set $P(tObjects(tLastName,tGrantedVia,tGrantedBy),",",i+3) = tRS.Data("HAS_COLUMN_PRIV")
			}
		}

		&html<
			<div id="#(..%MakeId("Controls"))#" style="display: flex;margin-bottom:3px;flex-direction: row;">
			<span class="zenLabel">#($$$TextHTML("Namespace"))#</span>
			<select id="#(..%MakeId("Namespace"))#" onchange="zenPage.getComponent('#(..index)#').changeNS(this);" value="#($zconvert(..namespace,"O","HTML"))#">>
		For i=1:1:$LENGTH(..nsValueList,",") {
			Set val = $PIECE(..nsValueList,",",i)
			Set display = $PIECE(..nsDisplayList,",",i)
			Set selected = $SELECT(val=..namespace:"selected",1:"")
			&html<<option value="#($zconvert(val,"O","HTML"))#" #(selected)#>#(display)#</option>>
		}
		&html<</select>>
		If (..showSystemBox) {
			Set checked = $SELECT(..includeSystem=1:"checked",1:"")
			&html<
			<label style="margin-left:10px;">
				<input type="checkbox" id="#(..%MakeId("SystemItems"))#" #(checked)# onchange="zenPage.getComponent('#(..index)#').changeSysItems(this);"/>
				<span class="normal">#($$$Text("Include System Items"))#</span>
			</label>>
		}
		If '$$$ZENVAL(..readOnly) {
			Set lblAdd = $CASE(..type,"TABLE":$$$TextHTML("Add Tables..."),"VIEW":$$$TextHTML("Add Views..."),"ML CONFIGURATION":$$$TextHTML("Add ML Configurations..."),"FOREIGN SERVER":$$$TextHTML("Add Foreign Servers..."),:$$$TextHTML("Add Procedures..."))
			if ..type="ML CONFIGURATION" {
				&html<<input type="button" value='#(lblAdd)#' onclick="zenPage.getComponent('#(..index)#').doLaunchMLConfigurations('#($ZCVT($ZCVT(PID,"O","JS"),"O","HTML"))#','','');">>
			} else {
				&html<<input type="button" value='#(lblAdd)#' onclick="zenPage.getComponent('#(..index)#').doLaunchSchemas('#($ZCVT($ZCVT(PID,"O","JS"),"O","HTML"))#','','');">>
				If (..type="TABLE") || (..type="VIEW") {
					&html<<input type="button" value='#($$$TextHTML("Add Columns..."))#' onclick="zenPage.getComponent('#(..index)#').doLaunchColumns('#($ZCVT($ZCVT(PID,"O","JS"),"O","HTML"))#','');">>
				}
			}
		} 
		If ((..usePaging) && (tNameCount>..resultsPageSize)) {
			// DP-413589 - Draw the paging controls if needed
			Set ..resultsMaxPage = $S((tNameCount/..resultsPageSize)=(tNameCount\..resultsPageSize):(tNameCount/..resultsPageSize),1:(tNameCount\..resultsPageSize)+1)
			Set tPageMsg = $$$FormatText($$$Text("Page %1 of %2"),..resultsPage,..resultsMaxPage)
			&html<<div id="#(..%MakeId("pageCtrls"))#" style="margin-left: 15px;"><span class="normal">#(tPageMsg)#</span>>
			&html<<input type="button" id="#(..%MakeId("pageFirst"))#" value="|<" onclick="zenPage.getComponent('#(..index)#').gotoPage(1)">
				<input type="button" id="#(..%MakeId("pagePrev"))#" value="<" onclick="zenPage.getComponent('#(..index)#').prevPage()">
				<input type="text" id="#(..%MakeId("pageNo"))#" style="width:30px;" value="#(..resultsPage)#" onchange="zenPage.getComponent('#(..index)#').gotoPage(this.value)">
				<input type="button" id="#(..%MakeId("pageNext"))#" value=">" onclick="zenPage.getComponent('#(..index)#').nextPage()">
				<input type="button" id="#(..%MakeId("pageLast"))#" value=">|" onclick="zenPage.getComponent('#(..index)#').gotoPage(zenPage.getComponent('#(..index)#').resultsMaxPage)">>
			&html<</div>>
		}
		&html<</div>>		// Close the 'Controls' div
		
		&html<
			<div>
			<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">>
		&html<
			<thead class="tpHead">
				<th nowrap>#($$$Text("Name"))#</th>>
		For i = 1:1:nPrivilegesLen {
			&html<
				<th nowrap>#($P(PrivilegeString,",",i))#</th>>
		}
		&html<
				<th nowrap>#($$$TextHTML("Granted Via"))#</th>
				<th nowrap>#($$$TextHTML("Granted By"))#</th>>
		If ..type '= "STORED PROCEDURE" && ( ..type '= "ML CONFIGURATION" ) && ( ..type '= "FOREIGN SERVER" ){
			&html<
				<th nowrap>#($$$TextHTML("Column Priv"))#</th>>
		}
		&html<
				<th>&nbsp;</th>
				<th>&nbsp;</th>
			</thead>
			<tbody class="tpBody">>

		// Emit the content accumulated in tObjects as paged HTML content.	
		Set tFirstVisibleRow = (..resultsPage-1)*..resultsPageSize + 1
		Set tLastVisibleRow = ..resultsPage*..resultsPageSize
		Set tRow = 0
		Set tLastName = $O(tObjects(""))
		While (tLastName '= "") && (tRow<=tLastVisibleRow) {
			Set tRow = tRow + 1

			// DP-413589 - Skip output of this table information if it isn't on the currently visible results page
			If (..usePaging && (tRow<tFirstVisibleRow)) {
				Set tLastName = $O(tObjects(tLastName))
				Continue
			}

			Set rowClass = $CASE(tRow#2,1:"tpOdd",:"tpEven")
			Set tGrantedVia = $O(tObjects(tLastName,""))
			While tGrantedVia '= "" {
				Set tGrantedBy = $O(tObjects(tLastName,tGrantedVia,""))
				While tGrantedBy '= "" {
					Set tObj = tObjects(tLastName,tGrantedVia,tGrantedBy)
					&html<
					<tr class="#(rowClass)#">
						<td class="tpStr" nowrap>#($ZCVT(tLastName,"O","HTML"))#</td>>
					Do ..BuildLine(tObj,nPrivilegesLen)
					If ..type '= "STORED PROCEDURE" && (..type '= "ML CONFIGURATION") && (..type '= "FOREIGN SERVER") {
						// Column Priv column
						If $P(tObj,",",nPrivilegesLen+3) = 1 {
							&html<
						<td class="tpAction" style="text-align:center;"><a href="##(..tab)#" onclick="zenPage.getComponent('#(..index)#').doLaunchColumns('#($ZCVT($ZCVT(PID,"O","JS"),"O","HTML"))#','#(tLastName)#');">#($$$TextHTML("Edit Columns"))#</a></td>>
						} Else {
							&html<
						<td nowrap>&nbsp;</td>>
						}
					}
					If $P(tObj,",",nPrivilegesLen+1) = "Direct" {
						&html<
						<td class="tpAction" style="text-align:center;"><a href="##(..tab)#" onclick="zenPage.getComponent('#(..index)#').doLaunchSchemas('#($ZCVT($ZCVT(PID,"O","JS"),"O","HTML"))#','#($ZCVT(tLastName,"O","JS"))#','#(tObj)#');">#($$$TextHTML("Edit"))#</a></td>
						<td class="tpAction" style="text-align:center;"><a href="##(..tab)#" onclick="zenPage.getComponent('#(..index)#').doRevokeObj('#($ZCVT($ZCVT(PID,"O","JS"),"O","HTML"))#','#($ZCVT(tLastName,"O","JS"))#','#($ZCVT(tGrantedBy,"O","JS"))#');">#($$$TextHTML("Revoke"))#</a></td>>
					} Else {
						&html<
						<td nowrap>&nbsp;</td>
						<td nowrap>&nbsp;</td>>
					}
					&html<
					</tr>>
					Set tGrantedBy = $O(tObjects(tLastName,tGrantedVia,tGrantedBy))
				}
				Set tGrantedVia = $O(tObjects(tLastName,tGrantedVia))	
			}
			Set tLastName = $O(tObjects(tLastName))
		}
		
		If tRow = 0 {
			&html<<tr><td colspan="12">#($$$TextHTML("None."))#</td></tr>>	
		} Else {
			&html<<tr><td colspan="12">&nbsp;&nbsp;>
			&html<#($$$TextHTML("Legend"))#: <span style="font-size:14px;">&nbsp;-&nbsp;</span>>
			&html<#($$$TextHTML("Not Granted"))#<span style="font-size:14px;">&nbsp;&nbsp;&#186;&nbsp;</span>>
			&html<#($$$TextHTML("Granted"))#<span style="font-size:14px;">&nbsp;&nbsp;&#8226;&nbsp;</span>>
			&html<#($$$TextHTML("Granted with Grant Admin Option"))#</td></tr>>
		}
		&html<</tbody></table></div>>
	} Catch Error {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,Error.AsStatus())
	}
	Quit
}

/// Navigate to a requested page in a multi-page resultset. If the requested page is out of the actual page
/// range, it will automatically be reset to reuqest the first or lastreal page.
ClientMethod gotoPage(pageNo) [ Language = javascript ]
{
	// Method added by DP-413589
	// Check the input and reset the provided page number if it is outside the bounds of the valid page numbers
	if (pageNo > this.resultsMaxPage) {
		pageNo = this.resultsMaxPage;
	} else if (pageNo < 1) {
		pageNo = 1;
	}
	var pageChanged = this.resultsPage = pageNo;

	// Store the value in the component's state and reset the control if the request had to be changed
	this.resultsPage = pageNo;
	this.findElement('pageNo').value = pageNo;

	// Redraw the table if this page number is new
	if (pageChanged) {
		this.refreshContents();
	}
}

/// Navigate to the previous page of results
ClientMethod prevPage() [ Language = javascript ]
{
	// Method added by DP-413589
	this.gotoPage(parseInt(this.resultsPage)-1);
}

/// Navigate to the next page of results
ClientMethod nextPage() [ Language = javascript ]
{
	// Method added by DP-413589
	this.gotoPage(parseInt(this.resultsPage)+1);
}

ClientMethod changeNS(sel) [ Language = javascript ]
{
	var newVal = sel.options[sel.selectedIndex].value;  
	zenPage.changeNS(newVal);
}

ClientMethod changeSysItems(chbox) [ Language = javascript ]
{
	var newVal = Number(chbox.checked);
	this.includeSystem = newVal;
	this.SetIncludeSystem(newVal);
	this.refreshContents();
}

ClassMethod SetIncludeSystem(newVal As %Integer) [ ZenMethod ]
{
	Set %session.Data("includeSystemItems") = newVal
}

ClientMethod doRevokeObj(PID, tblname, grantedby) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.RevokeRow(this.namespace,PID,tblname,"*",this.tab,this.pageType,grantedby);
	if (st != "") {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod doLaunchSchemas(PID, objName, objPriv) [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Dialog.SchemaPriv.zen?Type='+this.type+'&PID='+encodeURIComponent(PID)+'&IncludeSystem='+this.includeSystem+'&ObjName='+encodeURIComponent(objName)+'&ObjPriv='+encodeURIComponent(objPriv)+'&$NAMESPACE='+encodeURIComponent(this.namespace));
	zenLaunchPopupWindow(url,this.type+'-UserSchemas','status,scrollbars,resizable=yes,width=700,height=700');
}

ClientMethod doLaunchMLConfigurations(PID, objName, objPriv) [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Dialog.MLConfigurationPriv.zen?Type='+this.type+'&PID='+encodeURIComponent(PID)+'&IncludeSystem='+this.includeSystem+'&ObjName='+encodeURIComponent(objName)+'&ObjPriv='+encodeURIComponent(objPriv)+'&$NAMESPACE='+encodeURIComponent(this.namespace));
	zenLaunchPopupWindow(url,this.type+'-UserSchemas','status,scrollbars,resizable=yes,width=700,height=700');
}

ClientMethod doLaunchColumns(PID, objName) [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Dialog.ColumnPriv.zen?Type='+this.type+'&PID='+encodeURIComponent(PID)+'&IncludeSystem='+this.includeSystem+'&ObjName='+encodeURIComponent(objName)+'&$NAMESPACE='+encodeURIComponent(this.namespace));
	zenLaunchPopupWindow(url,this.type+'-UserColumns','status,scrollbars,resizable=yes,width=900,height=700');
}

ClassMethod BuildLine(tVal As %String, nPrivilegesLen As %Integer)
{
	Set tInd = 1
	While tInd '> nPrivilegesLen {
  		Set IsSelected = $P(tVal,",",tInd)
  		Set Icon = $CASE(IsSelected,1:"&#186;",2:"&#8226;",:"-")
  		Set Title = $CASE(IsSelected,1:$$$TextHTML("Granted"),2:$$$TextHTML("Granted with Grant Admin Option"),:$$$TextHTML("Not Granted"))
  		&html<<td class="tpStr" nowrap style="font-size:14px;text-align:center;" title="#(Title)#">#(Icon)#</td>>
		Set tInd = tInd + 1
	}
	// write Granted Via
	Set tGrantedVia = $ZCVT($P(tVal,",",tInd),"U")
	If tGrantedVia = "SUPERUSER" {
		Set tGV = $$$TextHTML("SuperUser")
	} ElseIf tGrantedVia = "SCHEMA PRIVILEGE" {
		Set tGV = $$$TextHTML("Schema Privilege")
	} ElseIf tGrantedVia = "PUBLIC" {
		Set tGV = $$$TextHTML("Public")
	} ElseIf tGrantedVia = "DIRECT" {
		Set tGV = $$$TextHTML("Direct")
	} ElseIf tGrantedVia = "OWNER PRIVILEGE" {
		Set tGV = $$$TextHTML("Owner Privilege")
	} ElseIf tGrantedVia [ "ROLE:" {
		Set tGV = $$$TextHTML("Role")_":"_$P(tGrantedVia,"ROLE:",2)
	} ElseIf tGrantedVia [ "USER:" {
		Set tGV = $$$TextHTML("User")_":"_ $P(tGrantedVia,"USER:",2)
	} Else {
		Set tGV = tGrantedVia
	}
	Set GrantedBy = $P(tVal,",",tInd+1)
	&html<<td class="tpStr" nowrap>#($S(tGV'="":tGV,1:"&nbsp;"))#</td>>
	&html<<td class="tpStr" nowrap>#($S(GrantedBy'="":GrantedBy,1:"&nbsp;"))#</td>>
}

ClassMethod RevokeRow(NAMESPACE, Grantee, cbState, sActs, tab, sType, GrantedBy) As %String [ ZenMethod ]
{
	Try {
		New $namespace
		Set $namespace = NAMESPACE
		
		Set tResult = ""

		//For Users: tab=3:tables, tab=4:views, tab=5:procedures, tab=6:ml configurations, tab=7:foreign servers
		//For Roles: tab=4:tables, tab=5:views, tab=6:procedures, tab=7:ml configurations, tab=8:foreign servers
		If sType = "Roles" {
			Set nType = $S(tab="4":1,tab="5":3,tab=7:6,tab=8:7,1:9)
		} Else {
			Set nType = $S(tab="3":1,tab="4":3,tab=6:6,tab=7:7,1:9)
		}
		If $E(cbState) = "," Set cbState = $E(cbState,2,$L(cbState))

		For i=1:1:$LENGTH(cbState,",") {
			Set sObj = $P(cbState,",",i)
				// this is kindof a kludge here.  The procname may contain ".", as in {..SQLNAME}.
				// It really should be schema_"."_$tr(procname,".",$c(2), but we don't seem to be able to handle that here.
				// Unfortunatly assume schema has no "." (and of course neither can have a ",")
			if $l(sObj,".")>2 { set sObj=$p(sObj,".",1)_"."_$tr($p(sObj,".",2,*),".",$c(2)) }
			Set tSC = ##class(%SQL.Manager.API).SaveObjPriv(sActs,nType,sObj,Grantee,0,1,.SQLCODE,.sMsg,GrantedBy)
			If SQLCODE '= 0 {
				Set tResult = tResult_sObj_" "_"["_SQLCODE_"]"_sMsg_"\n"
			}
		}
    } Catch Error {
		Set tResult = $System.Status.GetErrorText(Error.AsStatus())
	}
	Set tResult = $ZCVT(tResult,"O","JS")
	Quit tResult
}

}
