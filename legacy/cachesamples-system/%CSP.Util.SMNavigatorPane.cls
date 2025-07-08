/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Navigator Pane for System Managment Portal. 
Class %CSP.Util.SMNavigatorPane Extends %CSP.Util.Pane [ ServerOnly = 1, System = 4 ]
{

/// If true, then the max rows textbox is display.
Property ShowMaxRows As %Boolean [ InitialExpression = 0 ];

/// If 1, then namespace listbox displays.
/// If 0, then namespace name displays.
Property ShowNamespaces As %Boolean;

/// If 1, then namespace listbox allows choice of databases as well.
Property ShowDatabases As %Boolean [ InitialExpression = 0 ];

/// If true, then schema listbox is display.
Property ShowSchemas As %Boolean [ InitialExpression = 0 ];

/// Border of table (default is 0)
Property border As %Integer;

/// Cellspacing (default is 0)
Property cellspacing As %Integer;

/// Cellpadding (default is 0)
Property cellpadding As %Integer;

/// Table background color
Property bgcolor As %String(TRUNCATE = 1);

Method DrawBODY(pInstance As PageInstance) As %Status
{
	Do GetPortalSettings^%SYS.cspServer2(%session.Username,.PortalSettings)	
	Set bgcolor = $S(..bgcolor'="":"bgcolor="""_..bgcolor_"""",1:"")
	Set SpaceImage = ##class(%CSP.Page).Link("/csp/sys/images/spacer.gif")
	Set ArrowImage = ##class(%CSP.Page).Link("/csp/sys/images/prod-box-arrow.gif")
	Set lblNamespace = $$$TextHTML("Namespaces")
	Set lblDatabase = $$$TextHTML("Databases")

	#;YSD2507: the following only works for Firefox. It changes hover color in <select> <option> for schema list
	&html<<style type="text/css">
	select option:hover {
		color:rgb(218,72,72);
	}
	</style>>
	&html<<table width="100%" height="100%" border="0" cellpadding="0" cellspacing="0">
	<!--<tr valign="top"><td height="100%" align="left"></td>
	<td width="*">&nbsp;</td></tr>-->
	<tr valign="top"><td>
	<table class="MenuNS" width="100%" height="100%" border="#(+..border)#" cellpadding="#(+..cellpadding)#" cellspacing="#(+..cellspacing)#">
	>
	&html<<form name="NamespaceForm" action="#(..CommandSubmitPage)#">>

	// namespace list
	Set defaultNS = $namespace

	If (..ShowNamespaces) {
		// should we show NS or directories?
		Set tShowNS = 1
		If (..ShowDatabases) {
			If (($G(%request.Data("$DIR",1))="N")) {
				Set tShowNS = 1
			}
			ElseIf (($G(%request.Data("$DIR",1))="D")) {
				// implied namespace
				Set tShowNS = 0
			}
			ElseIf (($E(defaultNS,1)="^")) {
				// implied namespace
				Set tShowNS = 0
			}
		}
		
		&html<<tr height="100%"><td class="NSTitle" width="100%">>

		If (..ShowDatabases) {
			// show namespace/database radiobuttons
			&html<
			<form name="RadioForm" action="#(..CommandSubmitPage)#"><div>
			<input type="radio" name="$NSMODE" value="namespace" #($S(tShowNS:"checked",1:"onclick=""form.submit();"""))#><span style="font-variant:small-caps;" nowrap>#(lblNamespace)#</span><br>
			<input type="radio" name="$NSMODE" value="implied" #($S('tShowNS:"checked",1:"onclick=""form.submit();"""))#><span style="font-variant:small-caps;" nowrap>#(lblDatabase)#</span></div>>
		}
		Else {
			&html<<div><span style="font-variant:small-caps;" nowrap>#(lblNamespace)#</span></div>>
		}

		// --- (HTML version)
		&html<<table class="NSTable" width="100%" cellspacing="0" border="0" cellpadding="0">
		<tr><td><hr></td></tr>>
		If (tShowNS) {
			// make list of namespaces
			Set tCnt = ..GetAllNamespaces(.Namespaces)
			For i=1:1:tCnt {
				Set cls = $S(Namespaces(i) = defaultNS:"NSSelected",1:"NSNormal")
				#;YSD2507 &html<<tr><td width="100%" onclick="gotoNamespace('#($ZCVT(Namespaces(i),"O","JS"))#');" class="#(cls)#">#(Namespaces(i))#</td></tr>> 
				&html<<tr><td width="100%" onclick="gotoNamespace('#($ZCVT(Namespaces(i),"O","JS"))#');" class="#(cls)#" onmouseover="style.color='rgb(218,72,72)';style.cursor='pointer';" onmouseout="style.color=''" >#($ZCVT(Namespaces(i),"O","HTML"))#</td></tr>> 
			}
		}
		Else {
			// make list of databases
			Set tCnt = ..GetAllDatabases(.Databases)
			// get normalized ns info to compare against
			Set t = $E($namespace,2,*) // strip off @
			Set tCurrDir = $ZCVT($P(t,"^",$L(t,"^")),"L")   // last piece is directory
			Set tCurrSys = $ZCVT($P(t,"^",$L(t,"^")-1),"L") // first piece is system

			Set dbName = $O(Databases(""))
			While dbName '= "" {
				Set tValue = Databases(dbName)
				Set tSystem = $P(tValue,"^",2)
				Set tDirectory = $P(tValue,"^",3)
				/* YSD2101		
				// this is what is displayed in the list box
				// Get db name
				Set x=$$DatasetsByDirectory^%SYS.CONFIG(tSystem,tDirectory,.dblist)
				If (x && $LL(dblist)) {
					#; YSD2053 Set tDisplay = $S(tSystem="":"",1:tSystem_"@") _ $LG(dblist,1)
					Set tDisplay = $LG(dblist,1)_$S(tSystem="":"",1:"@"_tSystem)
				}
				Else {
					// some error, show verbose form
					#; YSD2053 Set tDisplay = $S(tSystem="":"",1:tSystem_"@") _ tDirectory
					Set tDisplay = tDirectory_$S(tSystem="":"",1:"@"_tSystem)
				}
				*/
				Set tDisplay = dbName_$S(tSystem="":"",1:"@"_tSystem)
				Set cls = $S(($ZCVT(tDirectory,"L")=tCurrDir)&&($ZCVT(tSystem,"L")=tCurrSys):"NSSelected",1:"NSNormal")
				#;YSD2507 &html<<tr><td width="100%" onclick="gotoNamespace('#($ZCVT(tValue,"O","JS"))#');" class="#(cls)#">#($ZCVT(tDisplay,"O","HTML"))#</td></tr>> 
				&html<<tr><td width="100%" onclick="gotoNamespace('#($ZCVT(tValue,"O","JS"))#');" class="#(cls)#" onmouseover="style.color='rgb(218,72,72)';style.cursor='pointer';" onmouseout="style.color=''" >#($ZCVT(tDisplay,"O","HTML"))#</td></tr>> 
				Set dbName = $O(Databases(dbName))
			}
		}
		&html<<tr><td><hr></td></tr></table>>

		If (..ShowDatabases) {
			&html<</form>>
		}

		// ---

		If ($G(%session.Data("$NSERROR"))'="") {
			// we were unable to switch the requested namespace
			// !!! localize msg
			Set badns = $G(%session.Data("$NSERROR"))
			If ($E(badns)="^") {
				i $p(badns,"^",2)'="" {
					Set badns = $P(badns,"^",3)_"@"_$p(badns,"^",2)
				} else {
					Set badns = $P(badns,"^",3)
				}
				Set msg1 = $$$FormatText($$$Text("Database %1 is not available. Either the database is not mounted, or you do not have permission to access it."),##class(%CSP.Page).EscapeHTML(badns))
				&html<<div>#(msg1)#</div><hr>>
			}
			Else {
				Set msg1 = $$$FormatText($$$Text("Namespace %1 is not available. Either the default database is not mounted, or you do not have permission to access it."),##class(%CSP.Page).EscapeHTML(badns))
				&html<<div>#(msg1)#</div><hr>>
			}
			Kill %session.Data("$NSERROR")
		}

		&html<</td></tr>>
			
	}
	Else {
		// do not show namespaces
		Set lblTitle = $$$TextHTML("click to change namespace")
		Set lblSelect = $$$TextHTML("you may click on any schema listed below to view tables for that schema")
		&html<<tr height="100%"><td class="NSTitle"><a href="#(pInstance.MakeLink("UtilSqlSchemas.csp"))#" title="#(lblTitle)#"><div>#(lblNamespace)#</a>:&nbsp;<b>#(defaultNS)#</b></div>>
		&html<<input type="hidden" name="$NAMESPACE" value="#(defaultNS)#">>
		If (..ShowSchemas = 1) {
			Set defaultSchema = $G(%request.Data("$ID1",1))
			&html<<div title="#(lblSelect)#">#($$$Text("Available Schemas"))#</div>
			<select name="SCHEMA" class="SelectNS" size="25" onchange="changeSchema(form);">>
			Set tCnt = ..GetSchemas(.Schemas)
			// make list of Schemas
			For i=1:1:tCnt {
				Set sel = $S(Schemas(i) = defaultSchema:"selected",1:"")
				&html<<option value="#(Schemas(i))#" #(sel)#>#(Schemas(i))#</option>> 
			}
			&html<</select>
			</td></tr>>
		}
	}

	//&html<<table class="Menu" cols="1" cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" cols="1">>
	Set pPage = "" // !!!
	Set tHi = 0
	For a = 1:1:..Commands.Count() {

		Set tAction = ..Commands.GetAt(a)
		Set tItem = ..LocalizeText(tAction.Caption)

		Set tLink = ##class(%CSP.Page).Link("/csp/sys"_tAction.HREF)
		If (tLink = "") {
			Set tLink = pPage
		}

		// get current id values
		Kill ids
		Do tAction.GetIDValues(.ids)
		
		If (tAction.Type = "popup") {
			Set tURL = pInstance.MakePopupLink(tLink,.ids)
		}
		Else {
			// link
			Set tURL = pInstance.MakeLink(tLink,.ids)
		}

		Set tPopup = ..LocalizeText(tAction.Popup)
	/*
		If ('tHi && (tAction.HREF = pPage)) {
			// assume this is the current choice
			Set tCls = "MenuItem"
			Set tHiCls = "MenuItemCurrHi"
			Set tHi = 1 // only allow one hilite...
		}
		Else {
			Set tCls = "MenuItemCurr"
			Set tHiCls = "MenuItemHi"
		}
	*/
		If (tAction.Confirm '= "") {
			Set tConfirm = " onclick=""return confirm(" _ ##class(%CSP.Page).QuoteJS(tAction.Confirm) _ ");"""
		}
		Else {
			Set tConfirm = ""
		}
		&HTML<<tr valign="top">
				<td nowrap>
				<img src="#(ArrowImage)#" alt="*" width="11" height="11" border="0">
				<a class="productBullets" target="_top" title="#(tPopup)#" href="#(tURL)#" #(tConfirm)#>
				#(tItem)#</a>
				<td></tr>>


	}

	&html<<tr><td>&nbsp;</td></tr>>

	&html<<input type="hidden" name="PAGE" value="#($zconvert(pPage,"O","HTML"))#">>
	
	Kill tID
	Merge tID = pInstance.IDValues
	Set id = $O(tID(""))
	While (id '= "") {
		&html<<input type="hidden" name="$ID#(id)#" value="#($zconvert(tID(id),"O","HTML"))#">>
		Set id = $O(tID(id))
	}
	
	// max rows control
	If (..ShowMaxRows) {
		Set lblRows = $$$Text("Rows")
		Set lblGo = $$$Text("Go")
		Set msgTitle1 = $$$Text("Maximum number of rows to display for a table.")
		&html<<br><div class="NavLabel">#(lblRows)#:<br>
			<nobr>
			<input class="NavControl" title="#(msgTitle1)#" type="TEXT" name="MAXROWS" size="5" value="#($G(PortalSettings("MAXROWS"),50))#">
			<input class="NavButton" type="SUBMIT" name="$MAXROWS" value="#(lblGo)#">
			</nobr></div>>
	}

	&html<</form></td></tr>>
	&html<</table>>
	
	Quit $$$OK
}

Method OnGenerateCode() As %String
{
	Set code = ""
	If (..ShowSchemas '= "") {
		Set code = code _ " Set tPane.ShowSchemas = " _ +..ShowSchemas _ $$$EOL
	}
	If (..ShowDatabases '= "") {
		Set code = code _ " Set tPane.ShowDatabases = " _ +..ShowDatabases _ $$$EOL
	}
	If (..ShowNamespaces '= "") {
		Set code = code _ " Set tPane.ShowNamespaces = " _ +..ShowNamespaces _ $$$EOL
	}
	If (..border '= "") {
		Set code = code _ " Set tPane.border = " _ +..border _ $$$EOL
	}
	If (..cellpadding '= "") {
		Set code = code _ " Set tPane.cellpadding = " _ +..cellpadding _ $$$EOL
	}
	If (..cellspacing '= "") {
		Set code = code _ " Set tPane.cellspacing = " _ +..cellspacing _ $$$EOL
	}
	If (..bgcolor '= "") {
		Set code = code _ " Set tPane.bgcolor = " _ ..bgcolor _ $$$EOL
	}

	Quit code
}

/// Overwritten by subclasses to draw anything this pane needs for the HEAD section.
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	#; Set CSPSHARE so that the CSPCHD is built
	Set linkURL = ##class(%CSP.Page).Link(%request.URL)
	#; Remove the $NAMESPACE built by .Link because we need the new NS user selected to be built later
	Set pageURL = $P(linkURL,"?",1)_"?"
	Set tablesPage = ##class(%CSP.Page).Link("UtilSqlTables.csp",,1)
	&html<<script language="javascript">
function changeSchema(formObj)
{
	var schema = formObj.SCHEMA.options[formObj.SCHEMA.selectedIndex].value;
	var url = '#(tablesPage)#$ID1=' + cspEncodeUTF8(schema) + '&$NAMESPACE=' + cspEncodeUTF8('#($ZCVT($namespace,"O","JS"))#');
	self.document.location = url;
}

function gotoNamespace(ns)
{
	self.document.location = '#(pageURL)#$NAMESPACE=' + cspEncodeUTF8(ns);
}

	</script>>

	&html<<style>

.MenuNS {
	background: rgb(179,210,235);
	border-right: solid 1px gray;
}

.SelectNS {
	background: rgb(249,243,204);
	width: 100%;
}

.NSTitle div {
	color: rgb(27,60,87);
	font-size: 0.8em;
	padding: 2px;
}

table.NSTable {
	font-size: 0.8em;
}

td.NSNormal {
	padding: 2px;
	padding-left: 5px;
	color: rgb(27,60,87);
	cursor: hand;
}

td.NSSelected {
	padding: 2px;
	padding-left: 5px;
	background:  rgb(249,243,204);
	color: darkblue;
	font-weight: bold;
	cursor: hand;
}

	</style>>
	
	Quit $$$OK
}

/// Generic method to get Schemas for the current namespace.
/// Namespace array is returned by reference.
ClassMethod GetSchemas(ByRef Schemas As %String) As %Integer
{
	Set tNS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Schemas")
	Set tSC = tNS.Execute()
	Set cnt = 1
	If $$$ISOK(tSC) {
		For cnt = 1:1 Quit:'tNS.Next()  Set Schemas(cnt) = tNS.GetData(1)
	}
	Kill tNS
	Quit +$G(cnt)-1
}

/// Generic method to get namespaces from the ACTIVE Configuration file.<br>
/// Namespace array is returned by reference.<br>
ClassMethod GetAllNamespaces(ByRef Namespaces As %String, ByRef ShardInfo As %String = 0) As %Integer
{
	Set Type = 5   		// 5 - Returns array of all namespaces on the system we have access to plus remote unmounted ones
	Set Remote = 1 		// 1 - Return remote namespaces as well
	Set DontConnect = 1	// 1 - Do not attempt to connect 
	
	Do List^%SYS.NAMESPACE(.NspList,Type,Remote,DontConnect)
	If ShardInfo {
		New %sqlcontext,%SNMasterIPAddress,%SNMyHostname
	}
	Set cnt = 0,ns=""
	For {
		Set ns = $O(NspList(ns)) Quit:ns=""
		#; Exclude the ones that are no longer enabled
		If $lg(NspList(ns),1) = 1 {
			Set cnt = cnt+1
			Set Namespaces(cnt) = ns
		}
		If ShardInfo {
			Set shardRole = ##class(%BigData.ShardingManager).GetShardingRole(ns,.dataMaster,.shardNumber)
			If shardRole '= "" {
				Set tRole = $Case($E(shardRole,1,2),"DS":$$$Text("data shard"),"QS":$$$Text("query shard"),"DM": $$$Text("data master"),"AM":$$$Text("application master"),:shardRole)
				Set ShardInfo(cnt)=$lb(shardRole,"("_tRole_")")
			}
		}
	}
	Quit cnt
}

/// Generic method to get databases
/// Databases array is returned by reference.<br>
/// Remote databases are included
ClassMethod GetAllDatabases(ByRef Databases As %String) As %Integer
{
	// get list of implied namespaces
	// Returns array of all databases on the system we have access to plus remote unmounted ones
	Do ListImplied^%SYS.NAMESPACE(.NspList,5,1,1)
	Set cnt = 0,ns=""
	For {
		Set ns=$o(NspList(ns)) Quit:ns=""
		Set db=$lg(NspList(ns),3) 
		If db'="", $lg(NspList(ns),1)=1 Set cnt=cnt+1,Databases(db)=ns
	}
	Quit cnt
}

/// Generic method to get namespaces from the ACTIVE Configuration file.
/// Namespace array is returned by reference.
/// Returns array of namespaces the user has Read or Write privileges in.
ClassMethod GetNamespaces(ByRef Namespaces As %String) As %Integer
{
	Do List^%SYS.NAMESPACE(.NspList,0)
	Set cnt = 0,ns=""
	For {
		Set ns=$o(NspList(ns)) Quit:ns=""
		If $lg(NspList(ns),1)=1 Set cnt=cnt+1,Namespaces(cnt)=ns
	}
	Quit cnt
}

}
