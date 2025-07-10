/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

Class EnsPortal.Setting.Report.ProductionPorts Extends EnsPortal.Template.listPage [ System = 4 ]
{

Parameter RESOURCE = "%Ens_PortSettingsReport:READ";

Parameter PAGENAME = "Port Authority Report";

Parameter DOCDBNAME = "IRISInteroperabilityPorts";

Property currentTab As %Integer [ InitialExpression = 1, Internal ];

Property canEditAuxTables As %Boolean [ InitialExpression = {$classmethod($classname(),"hasAuxEditPrivileges")} ];

Property msgEditingNotAllowed As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Not allowed to modify auxiliary tables")} ];

Property msgCannotImportPortData As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Only Reservation and Advice data can be imported")} ];

Property namespace As %ZEN.Datatype.string [ Internal ];

Property production As %ZEN.Datatype.string [ Internal ];

Property server As %ZEN.Datatype.string [ Internal ];

Property instance As %ZEN.Datatype.string [ Internal ];

Property categories As %ZEN.Datatype.string [ Internal ];

Property partner As %ZEN.Datatype.string [ Internal ];

Property mirror As %ZEN.Datatype.string [ Internal ];

Property mode As %ZEN.Datatype.string [ Internal ];

Property classification As %ZEN.Datatype.string [ Internal ];

Property modeExtended As %ZEN.Datatype.string [ Internal ];

Property docDBAsJSON As %ZEN.Datatype.string [ Internal ];

Property lastModreservation As %ZEN.Datatype.string [ Internal ];

Property lastModadvice As %ZEN.Datatype.string [ Internal ];

Property colDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Delete")} ];

Property colEdit As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Edit")} ];

Property defaultExpiryLength As %ZEN.Datatype.integer [ InitialExpression = 45 ];

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

XData Style
{
<style type="text/css">
.tabGroupBody {
	background-color : white;
	border-right: 0px solid black;
	border-left: 0px solid black;
	border-bottom: 0px solid black;
	overflow: visible;
}

td.tabGroupButtonOn {
	background : white;
}

.tabGroupExtra {
	border-bottom: 0px solid black;
	background: transparent;
	width: 100%;
}

.userEditGroup {
	background: #E0E0F0;
	text-align: left;
	padding: 10px;
	padding-bottom: 20px;
	width: 600px;
}
table#frmUserEdit {
	background: #E0E0F0;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<pane id="PortPane" paneName="PortPane"/>
</pane>
}

XData PortPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup>
<vgroup>
</vgroup>
<spacer width="10"/>
<tabGroup id="tabGroup" showTabBar="true" width="100%" onshowTab="zenPage.onTabChange();">
<tab caption="Production Ports" id="tabportTable">
<hgroup valign="top">
<spacer width="10" />
<vgroup valign="top">
<spacer height="10" />
<tableNavigatorBar id="navportTable" tablePaneId="portTable" showPageSize="true"/>
<tablePane id="portTable"
	cellSpacing="2"
	tableName="ISC_DM.IRISInteroperabilityPorts"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	nowrap="false"
	pageSize="50"
	maxRows=""
	headerLayout="headersOnTop"
	fixedHeaders="true"
	whereClause="document='primary'"
	orderByClause="server, mirror, inbound desc, port"
	>
<column header="Server" colName="server" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Mirror" colName="mirror" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Instance" colName="instance" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Production" colName="production" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="ItemName" colName="itemName" filterType="text"/>
<column header="Port" colName="port" filterType="custom" filterOp="BETWEEN" OnDrawFilter="DrawPortFilters"/>
<column header="Direction" colName="inbound" filterType="enum" filterEnum="1,0" filterEnumDisplay="Inbound,Outbound" OnDrawCell="DrawInboundOutbound"/>
<column header="Interface" colName="interface" filterType="text"/>
<column header="IPAddress" colName="ipAddress" filterType="text"/>
<column header="Enabled" colName="enabled" filterType="enum" filterEnum="1,0" filterEnumDisplay="Yes,No" OnDrawCell="DrawYesNo"/>
<column header="Categories" colName="categories" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Namespace" colName="namespace" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Mode" colName="mode" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Partner" colName="partner" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Date" colName="%LastModified" hidden ="true"/>
</tablePane>
</vgroup>
</hgroup>
</tab>
<tab caption="Port Reservations" id="tabreservationTable">
<hgroup valign="top">
<spacer width="10" />
<vgroup valign="top">
<spacer height="10" />
<image id ="addreservationTableButton" src="deepsee/ds_plus_16.gif" title="Add a Reservation" onclick="zenPage.addEntry('reservationTable');"/>
<tableNavigatorBar id="navreservationTable" tablePaneId="reservationTable" showPageSize="true"/>
<html>
	<div id="addreservationTable" hidden="true" class="userEditGroup">
	<div id="addreservationTableForm">
	</div>
	<button id="cancelreservationTableSave" onclick="zenPage.cancelsaveEntry('reservationTable')" style="line-height:27px" class="commandButton">Cancel</button>
	<button id="addreservationTableSave" onclick="zenPage.saveEntry('reservationTable')" style="line-height:27px" class="commandButton">Save</button>
	<div id="addreservationTableFormErrors">
	</div>
	</div>
</html>
<tablePane id="reservationTable"
	cellSpacing="2"
	tableName="ISC_DM.IRISInteroperabilityPorts"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	nowrap="false"
	pageSize="50"
	maxRows=""
	headerLayout="headersOnTop"
	fixedHeaders="true"
	whereClause="document='reservation'"
	orderByClause="server, mirror, instance, production, mode, port"
	>
	<column header="Server" colName="server" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
	<column header="Mirror" colName="mirror" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
	<column header="Instance" colName="instance" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
	<column header="Production" colName="production" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
	<column header="Mode (extended)" colName="mode" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
	<column header="Port" colName="port" filterType="custom" filterOp="BETWEEN" OnDrawFilter="DrawPortFilters"/>
	<column header="Direction" colName="inbound" filterType="enum" filterEnum="1,0" filterEnumDisplay="Inbound,Outbound" OnDrawCell="DrawInboundOutbound"/>
	<column header="Interface" colName="interface" filterType="text"/>
	<column header="IPAddress" colName="ipAddress" filterType="text"/>
	<column header="ItemName" colName="itemName" filterType="text"/>
	<column header="Comment" colName="comment" filterType="text"/>
	<column header="User" colName="username" filterType="text"/>
	<column header="Partner" colName="partner" filterType="text"/>
	<column header="LastModified" colName="%LastModified" filterType="date" filterOp="BETWEEN"/>
	<column header="Expiry" colName="expiryDate" filterType="date" filterOp="BETWEEN"/>
	<column header="In Use" colName="inUse"  filterType="enum" filterEnum="1,0" filterEnumDisplay="Yes,No" OnDrawCell="DrawYesNo" />
	<column id="reservationTablecolEdit" linkCaption="Edit" link="javascript:zenPage.editEntry('reservationTable','#(%query.ID)#');"/>
	<column id="reservationTablecolDelete" linkCaption="Delete" link="javascript:zenPage.deleteEntry('reservationTable','#(%query.ID)#');" linkConfirm="Are you sure you want to delete this Reservation?" />
	<column colName="ID" hidden="true"/>
	<column header="Reservation ID" colName="%DocumentId" hidden="false"/>
</tablePane>
</vgroup>
</hgroup>
</tab>
<tab caption="Port Usage Advice" id="tabadviceTable">
<hgroup valign="top">
<spacer width="10" />
<vgroup valign="top">
<spacer height="10" />
<image id="addadviceTableButton" src="deepsee/ds_plus_16.gif" title="Add Advice" onclick="zenPage.addEntry('adviceTable');"/>
<tableNavigatorBar id="navadviceTable" tablePaneId="adviceTable" showPageSize="true"/>
<html>
	<div id="addadviceTable" hidden="true" class="userEditGroup">
	<div id="addadviceTableForm">
	</div>
	<button id="canceladviceTableSave" onclick="zenPage.cancelsaveEntry('adviceTable')" style="line-height:27px" class="commandButton">Cancel</button>
	<button id="addadviceTableSave" onclick="zenPage.saveEntry('adviceTable')" style="line-height:27px" class="commandButton">Save</button>
	</div>
</html>
<tablePane id="adviceTable"
	cellSpacing="2"
	tableName="ISC_DM.IRISInteroperabilityPorts"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	nowrap="false"
	pageSize="50"
	maxRows=""
	headerLayout="headersOnTop"
	fixedHeaders="true"
	whereClause="document='advice'"
	orderByClause="classification, server, mirror, instance, production, mode, port"
	>
<column header="Classification" colName="classification" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Server" colName="server" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Mirror" colName="mirror" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Instance" colName="instance" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Production" colName="production" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Mode (extended)" colName="mode" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Start   Port" colName="startPort" filterType="custom" filterOp="BETWEEN" OnDrawFilter="DrawPortFilters"/>
<column header="End   Port" colName="endPort" filterType="custom" filterOp="BETWEEN" OnDrawFilter="DrawPortFilters"/>
<column header="Direction" colName="inbound" filterType="enum" filterEnum="1,0" filterEnumDisplay="Inbound,Outbound" OnDrawCell="DrawInboundOutbound"/>
<column header="Comment" colName="comment" filterType="text"/>
<column header="User" colName="username" filterType="text"/>
<column header="Partner" colName="partner" filterType="text"/>
<column header="LastModified" colName="%LastModified" filterType="date" filterOp="BETWEEN"/>
<column id="adviceTablecolEdit" linkCaption="Edit" link="javascript:zenPage.editEntry('adviceTable','#(%query.ID)#');"/>
<column id="adviceTablecolDelete" linkCaption="Delete" link="javascript:zenPage.deleteEntry('adviceTable','#(%query.ID)#');" linkConfirm="Are you sure you want to delete this Advice?" />
<column header="Advice ID" colName="%DocumentId" hidden="false"/>
</tablePane>
</vgroup>
</hgroup>
</tab>
<tab caption="Inbound Production Conflicts" id="tabconflictTable">
<hgroup valign="top">
<spacer width="10" />
<vgroup valign="top">
<spacer height="10" />
<tableNavigatorBar id="navconflictTable" tablePaneId="conflictTable" showPageSize="true"/>
<tablePane id="conflictTable"
	cellSpacing="2"
	tableName="ISC_DM.IRISInteroperabilityPorts"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	nowrap="false"
	pageSize="50"
	maxRows=""
	headerLayout="headersOnTop"
	fixedHeaders="true"
	whereClause="document='conflict'"
	orderByClause="server, port, mirror, instance, production"
	>
<column header="Server" colName="server"/>
<column header="Mirror" colName="mirror"/>
<column header="Instance" colName="instance"/>
<column header="Namespace" colName="namespace"/>
<column header="Production" colName="production"/>
<column header="ItemName" colName="itemName"/>
<column header="Port" colName="port" filterType="custom" filterOp="BETWEEN" OnDrawFilter="DrawPortFilters"/>
<column header="Interface" colName="interface"/>
<column header="Enabled" colName="enabled" OnDrawCell="DrawYesNo"/>
<column header="Categories" colName="categories" />
<column header="Partner" colName="partner"/>
<column header="Last Modified" colName="%LastModified"/>
</tablePane>
</vgroup>
</hgroup>
</tab>
<tab caption="Ranges not used in Productions" id="tabavailableTable">
<hgroup valign="top">
<spacer width="10" />
<vgroup valign="top">
<spacer height="10" />
<tableNavigatorBar id="navavailableTable" tablePaneId="availableTable" showPageSize="true"/>
<tablePane id="availableTable"
	cellSpacing="2"
	tableName="ISC_DM.IRISInteroperabilityPorts"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	nowrap="false"
	pageSize="50"
	maxRows=""
	headerLayout="headersOnTop"
	fixedHeaders="true"
	whereClause="document='available'"
	orderByClause="server,mirror, port"
	>
<column header="Port Start" colName="startPort" filterType="custom" filterOp="BETWEEN" OnDrawFilter="DrawPortFilters"/>
<column header="Port End" colName="endPort" filterType="custom" filterOp="BETWEEN" OnDrawFilter="DrawPortFilters"/>
<column header="Server" colName="server" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Mirror" colName="mirror" filterType="custom" OnDrawFilter="DrawSelectOptions" filterOp="UP["/>
<column header="Last Modified" colName="%LastModified"/>
</tablePane>
</vgroup>
</hgroup>
</tab>
</tabGroup>
</hgroup>
</pane>
}

Method %OnGetPageName() As %String
{
	Quit $$$TextHTML("Port Authority")
}

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	#dim n = 0
	Set pCommands($I(n)) = $LB("exportButton",$$$TextHTML("Export Current Page"),$$$TextHTML("Export to file via browser in .csv(tab delimited) format."),"zenPage.currentPortspageExport();")

	#dim tLocalImportOnClick = "alert(zenPage.msgEditingNotAllowed); "
	If ..canEditAuxTables {
		Set tLocalImportOnClick = "zenPage.importAuxData();"
	}
	Set pCommands($I(n)) = $LB("importAuxButton",$$$TextHTML("Import Data"),$$$TextHTML("Import data into the Reservations and Advice tables"),tLocalImportOnClick)

	Set pCommands($I(n)) = $LB("resetButton",$$$TextHTML("Reset Column Filters"),$$$TextHTML("Reset Column Filters for current table"),"zenPage.resetFilters();")
	Quit $$$OK
}

Method OnDrawRibbon() As %Status
{
	// allow for manual refresh
	#dim tRefresh = $$$TextHTML("Refresh table")
	&html<
	<td nowrap style="padding-left:50px;">
	<image id="refreshTable" src="deepsee/loop_24.gif" class="icon" title="#(tRefresh)#" onclick="zenPage.refreshTable();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
	</td>
	<td style="width:5px;">&nbsp;</td>
	<td id='lastmodified'/>
	<td nowrap style="padding-left:5px;padding-right:50px;"></td>
	>
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	#dim tSC = ##Super()

	If $$$ISERR(tSC) Return tSC

	Do ..disableTabsIfDocDBDoesNotExist()

	Return tSC
}

Method disableTabsIfDocDBDoesNotExist() [ Internal, Private ]
{
	Try {

		#dim tTabGroup = ..%GetComponentById("tabGroup")

		#dim tNTabs = tTabGroup.children.Count()
		#dim tTab, tTabID,tTabNumber
		#dim tTablePaneID, tTablePane
		#dim tDocDBDoesNotExist = '$SYSTEM.DocDB.Exists(..#DOCDBNAME)
		For tTabNumber = 1:1:tNTabs {

			Set tTab = tTabGroup.children.GetAt(tTabNumber)
			Set tTabID = tTab.id
			Set tTablePaneID = $Piece(tTabID,"tab",2)
			Set tTablePane =  ..%GetComponentById(tTablePaneID)
			If tDocDBDoesNotExist {
				Set tTab.disabled = 1
				Set tTablePane.hidden = 1
			}

		}

	} Catch { }
}

Method DrawSelectOptions(pTable As %ZEN.Component.tablePane, pName As %String, pColinfo As %ZEN.Auxiliary.column) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	Try {
		#; Safeguard pName & pTable being modified before call
		#dim tEscapedName = ..escapeJSAndHTML(pName)
		#dim tEscapedTableComponentIndex = ..escapeJSAndHTML(pTable.index)
		#dim tFilterId = "filter1_"_tEscapedName_"_"_tEscapedTableComponentIndex
		#dim tOptionArray
		/*	Find the values used for the given column

			Record by passing true as 4th parameter:
				all from 'primary'
				and classification from 'advice'
				and mode from 'advice' translated to modeExtended

		*/
		If (pTable.id = "portTable") || ((pTable.id = "adviceTable") && ((tEscapedName = "classification") || (tEscapedName = "mode"))) {

			#dim tMappedEscapedName = tEscapedName

			If ((pTable.id = "adviceTable") && (tEscapedName = "mode")) Set tMappedEscapedName = ..escapeJSAndHTML("modeExtended")

			If ($property($this,tMappedEscapedName) = "") {

				Set tOptionArray = ..getColumnValues(tEscapedName, pTable.id, .tSC, 1)

			} Else {

				Set tOptionArray = [].%FromJSON($property($this,tMappedEscapedName))

			}

		} Else {

			Set tOptionArray = ..getColumnValues(tEscapedName, pTable.id, .tSC, 0)

		}

		#; Do not show filter selection if no data or same data
		If tOptionArray.%Size() < 1  Quit

		&html<<table class="tpFilterLayout" border="0" cellspacing="2" width="100%">>
		&html<<tbody><tr><td nowrap="1">>

		&html<<select class="tpFilter" id="#(tFilterId)#" onchange="zenPage.getComponent(#(tEscapedTableComponentIndex)#).filterChanged('#(tEscapedName)#',true);">>

		If pColinfo.filterValue = "" {

			&html<<option selected="true" value=""></option>>

		} Else {

			&html<<option value=""></option>>

		}

		#dim tOption
		#dim tOptionIterator = tOptionArray.%GetIterator()
		#dim tKey

		While tOptionIterator.%GetNext(.tKey,.tOption) {

			If tOption=pColinfo.filterValue {

				&html<<option selected="true" value="#($ZCVT(tOption,"O","HTML"))#">#($ZCVT(tOption,"O","HTML"))#</option>>

			} Else {

				&html<<option value="#($ZCVT(tOption,"O","HTML"))#">#($ZCVT(tOption,"O","HTML"))#</option>>

			}

		}

		&html<</select></td></tr></tbody></table>>

	} Catch {}

	Return $$$OK
}

Method getColumnValues(pColumn As %String, pTableName As %String = "", Output pSC As %Status = {$$$OK}, pCacheResults As %Boolean = 0) As %Library.DynamicArray
{
	#dim e As %Exception.AbstractException
	#dim tDynamicArray = []
	Try {

		#; Call validation
		If ",namespace,production,server,mirror,mode,instance,categories,classification,"'[(","_pColumn_",") Quit
		If ",portTable,reservationTable,adviceTable,conflictTable,availableTable," '[ (","_pTableName_",") QUit

		#; Flag to indicate if comma separated values in order to order using temp array
		#dim tMultipleValues = 0
		If pColumn = "categories" Set tMultipleValues = 1
		#dim tSQL = "SELECT DISTINCT %EXACT("_pColumn_") as Data from ISC_DM."_..#DOCDBNAME_" WHERE document = ?"
		If 'tMultipleValues Set tSQL = tSQL_" ORDER By Data"
		#dim tDocumentType = "primary"
		If pTableName '= "portTable" {
			Set tDocumentType = $Piece(pTableName,"Table")
		}
		#dim tResults =  ##class(%DocDB.Database).%ExecuteQuery(tSQL,tDocumentType)
		#dim tPosition
		#dim tData
		#dim tSeenData
		#dim tOneData

		While tResults.%Next() {
			Set tData = tResults.Data
			For tPosition = 1:1:$Length(tData,",") {
				Set tOneData = $ZSTRIP($Piece(tData,",",tPosition),"<>W")
				If tOneData'="" && '$Data(tSeenData(tOneData)) {
					Set tSeenData(tOneData) = ""
					If 'tMultipleValues Do tDynamicArray.%Push(tOneData)
				}
			}
		}

		If tMultipleValues {
			Set tOneData = $Order(tSeenData(""))
			While tOneData '= ""{
				Do tDynamicArray.%Push(tOneData)
				Set tOneData = $Order(tSeenData(tOneData))
			}
		}

		#; Add in custom classification values
		If (pTableName = "adviceTable") && (pColumn = "classification") {
			#dim tSuggestion
			For tSuggestion = "Reservation Boundary" {
				If '$Data(tSeenData(tSuggestion))#2 {
					Do tDynamicArray.%Push(tSuggestion)
				}
			}
		}

		If pCacheResults {

			#dim tPropertyName = pColumn

			If (pTableName = "adviceTable") && (pColumn = "mode") {

				Set tPropertyName = "modeExtended"

			}

			#; caller needs to ensure that pColumn is a property defined in the page
			Set $property($this, tPropertyName) = tDynamicArray.%ToJSON()

		}

	} Catch e {Set pSC = e.AsStatus()}

	Return tDynamicArray
}

Method DrawYesNo(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If %query(pName) { Write $$$TextHTML("Yes") } Else { Write $$$TextHTML("No")}
	Quit $$$OK
}

Method DrawInboundOutbound(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If %query(pName) { Write $$$TextHTML("Inbound") } Else { Write $$$TextHTML("Outbound")}
	Quit $$$OK
}

Method DrawPortFilters(pTable As %ZEN.Component.tablePane, pName As %String, pColinfo As %ZEN.Auxiliary.column) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	Try {

		#dim tStartPort=$Piece(pColinfo.filterValue,",")
		#dim tEndPort=$Piece(pColinfo.filterValue,",",2)
		If tEndPort = "" {
			If tStartPort '= "" {
				Set tEndPort = tStartPort
			}
		} ElseIf tEndPort < tStartPort {
			Set tEndPort = tStartPort
		}
		#dim tTableComponentIndex = pTable.index
		#dim tFilterId1 = "filter1_"_pName_"_"_tTableComponentIndex
		#dim tFilterId2 = "filter2_"_pName_"_"_tTableComponentIndex
		&html<<table class="tpFilterLayout" border="0" cellspacing="2" width="100%">>
		&html<<tbody><tr><td nowrap="1">>
		&html<<input type="text" size="8" class="tpFilter" id="#(tFilterId1)#" value="#(tStartPort)#" onchange="var sync=zenPage.setEndPort('#(tFilterId1)#','#(tFilterId2)#') ;"/>>
		&html<<label>&nbsp;to&nbsp;</label>>
		&html<<input type="text" size="8" class="tpFilter" id="#(tFilterId2)#" value="#(tEndPort)#"/>>
		&html<<button type="button" onclick="var sync=zenPage.setEndPort('#(tFilterId1)#','#(tFilterId2)#') ; zenPage.getComponent(#(tTableComponentIndex)#).filterChanged('#(pName)#',true);">Find</button>>
		&html<</td></tr></tbody></table>>

	} Catch {}

	Return $$$OK
}

Method getThisLocationData() As %String [ Internal, ZenMethod ]
{
	#dim tProduction = ""
	#dim tLocationArray = ""
	#dim thisLocationData = {}
	If ##class(Ens.Setting.Report.base).onGetProductionLocationData(tProduction, .tLocationArray) {
		#dim tValue
		#dim tKey = $Order(tLocationArray(""),1,tValue)
		While tKey '= "" {
			Do thisLocationData.%Set(..escapeJSAndHTML(tKey),..escapeJSAndHTML(tValue))
			Set tKey = $Order(tLocationArray(tKey),1,tValue)
		}
	}
	Do thisLocationData.%Set("username",..escapeJSAndHTML($username))
	Return thisLocationData.%ToJSON()
}

Method escapeJSAndHTML(pValue As %String) As %String [ Internal, Private ]
{
	Return $ZCONVERT($ZCONVERT(pValue,"O","JS"),"O","HTML")
}

Method setDocDBPortsAsJSON() As %String [ Internal, ZenMethod ]
{
	Return ..setDocDBAsJSONAndLastMod("reservation")
}

Method setDocDBAsJSONAndLastMod(pDocumentType As %String = "reservation") As %String [ Internal, Private ]
{
	/* Get the properties we are interested from the docDB and the last modified
		Used to find:
	 		ports not in use or reserved
		 	if already exist when importing reservation or advice to prevent duplicates
		 	This method is called for both reservation and advice. But for advice it is called only with pLastModOnly
		 	This method doubles up because original design was to use hash of data rather than last modified to identify if data stale
	*/
	#dim tDocDBResult = ..getDocuments(pDocumentType)
	#dim tResultData = ""
	#dim tLastModTS = ""

	#dim ex As %Exception.AbstractException

	Try {

		Set tLastModTS = ..setDocDBLastMod(pDocumentType)

		Set tResultData = tDocDBResult.%ToJSON()

		&js<zenPage.docDBAsJSON = #(..QuoteJS(tResultData))#;>

	} Catch ex {

		If (ex.Name = "<MAXSTRING>")||(ex.Name = "<STRINGSTACK>") {

			#dim tempStream = ##class(%Stream.TmpBinary).%New()
			Do tDocDBResult.%ToJSON(.tempStream)
			Set tResultData = ""
			Do tempStream.Rewind()
			While 'tempStream.AtEnd {
				Set tResultData = tempStream.Read()
				&js<zenPage.docDBAsJSON = zenPage.docDBAsJSON + #(..QuoteJS(tResultData))#;>
			}

		} Else {

			Throw ex

		}

	}

	Return tLastModTS
}

Method setDocDBLastMod(pDocumentType As %String = "reservation") As %String [ Internal, Private ]
{
	#dim tLastModTS = ""

	Set tLastModTS = ..getLastModified(pDocumentType)

	If (pDocumentType = "reservation") {

			&js<zenPage.lastModreservation = #(..QuoteJS(tLastModTS))#;>

	} Else {

			&js<zenPage.lastModadvice = #(..QuoteJS(tLastModTS))#;>
	}

	Return tLastModTS
}

Method getDocuments(pDocumentType As %String = "reservation") As %DynamicAbstractObject [ Internal, Private ]
{
	#; data retrieved to help a reservation does not include 'available'

	If (pDocumentType = "reservation") || (pDocumentType = "advice") {

		#dim tDocDB = $system.DocDB.GetDatabase(..#DOCDBNAME)

		#dim projection = ..getProjectionForFind(pDocumentType)

		#dim restriction = ..getRestrictionForFind(pDocumentType)

		Return tDocDB.%FindDocuments(restriction , projection, /*options*/)

	}

	Return []
}

Method getProjectionForFind(pDocumentType As %String = "reservation") As %DynamicAbstractObject [ Internal, Private ]
{
	#dim projection = []

	If (pDocumentType = "reservation") {

		#; Start required to find free range
		Do projection.%Push("document")
		Do projection.%Push("port")
		Do projection.%Push("interface")
		Do projection.%Push("startPort")
		Do projection.%Push("endPort")
		Do projection.%Push("classification")
		Do projection.%Push("server")
		Do projection.%Push("instance")
		Do projection.%Push("mirror")
		Do projection.%Push("production")
		Do projection.%Push("inbound")
		Do projection.%Push("mode")
		#; End required to find free range

		#; Start remainder for dupe reservation and advice not covered above
		Do projection.%Push("comment")
		Do projection.%Push("username")
		Do projection.%Push("partner")
		#; End remainder for dupe reservation and advice

		#; Start remainder for dupe reservation only not covered above
		Do projection.%Push("expiryDate")
		Do projection.%Push("itemName")
		Do projection.%Push("%DocumentId")
		#; End remainder for dupe reservation only

		#; Start remainder for dupe advice only not covered above
		#; End remainder for dupe advice only

	} ElseIf (pDocumentType = "advice") {

		Do projection.%Push("classification")
		Do projection.%Push("startPort")
		Do projection.%Push("endPort")
		Do projection.%Push("inbound")
		Do projection.%Push("comment")
		Do projection.%Push("username")
		Do projection.%Push("partner")
		Do projection.%Push("production")
		Do projection.%Push("server")
		Do projection.%Push("instance")
		Do projection.%Push("mirror")
		Do projection.%Push("mode")
		Do projection.%Push("%LastModified")
		Do projection.%Push("%DocumentId")

	}
	Return projection
}

Method getRestrictionForFind(pDocumentType As %String = "reservation") As %DynamicAbstractObject [ Internal, Private ]
{
	#; Do not retrieve 'available' documents.
	#; we can leave in conflict since not expected to be large
	#dim restriction = []

	If (pDocumentType = "reservation") {

		Do restriction.%Push("document")
		Do restriction.%Push("available")
		Do restriction.%Push("<>")

	} ElseIf (pDocumentType = "advice") {

		Do restriction.%Push("document")
		Do restriction.%Push("advice")
		Do restriction.%Push("=")
	}

	Return restriction
}

Method recordTableLastMod(pTableName As %String, pForce As %Boolean = 0) As %String [ Internal, ZenMethod ]
{
	If ",reservationTable,adviceTable," '[ (","_pTableName_",") Return ""

	#dim tDocumentType = $Piece(pTableName,"Table")
	#dim tLastModProperty = ..lastModPropertyName(tDocumentType)

	If pForce || ($Property($this,tLastModProperty) = "") {

		Do ..setDocDBLastMod(tDocumentType)

	}

	Return ""
}

Method lastModPropertyName(pDocumentType As %String) As %String [ Internal, Private ]
{
	Return "lastMod"_pDocumentType
}

Method getLastModified(pDocumentType As %String = "", Output pSC As %Status = {$$$OK}) As %String [ Internal, Private ]
{
	#dim e As %Exception.AbstractException

	Try {

		#dim tResults

		If pDocumentType = "advice" {

			Set tResults = ##class(%DocDB.Database).%ExecuteQuery("SELECT MAX(%LastModified) AS LASTMODIFIED from ISC_DM."_..#DOCDBNAME_" WHERE document = 'advice'")

		} ElseIf pDocumentType = "reservation" {

			Set tResults = ##class(%DocDB.Database).%ExecuteQuery("SELECT MAX(%LastModified) AS LASTMODIFIED from ISC_DM."_..#DOCDBNAME_" WHERE document = 'reservation' or document = 'primary'")

		} Else {

			Quit

		}

		If tResults.%Next() Return tResults.LASTMODIFIED

	} Catch e {Set pSC = e.AsStatus()}

	Return ""
}

Method SaveToServer(pJSON) As %String [ Internal, ZenMethod ]
{
	#; DocDB protection mechanism will also check required WRITE resource
	#dim e As %Exception.AbstractException
	#dim tMsg = $$$TextJS("Unable to save - check Event log for possible further information.")

	Try {
		#dim tObject = {}.%FromJSON(pJSON)
		#dim tTableName = tObject.%Get("$table")
		If ",reservationTable,adviceTable," '[ (","_tTableName_",") Quit
		#dim tDocumentType = $Piece(tTableName,"Table")

		#dim tCurrentLastMod = ..setDocDBLastMod(tDocumentType)
		#dim tLastModProperty = ..lastModPropertyName(tDocumentType)
		If $Property($this,tLastModProperty) '= tCurrentLastMod {
			Set tMsg = $$$TextJS("Server data has changed since you started editing and your changes could not be saved. Reloading the table.")
			Quit
		}
		Do tObject.%Remove("$table")
		Do tObject.%Remove("%LastModified")

		#dim tDirection = tObject.%Get("inbound")
		If ((tDirection'=0) && (tDirection'=1)) {
			If $ZCVT(tDirection,"l")="outbound" {
				Set tDirection = 0
			} Else {
				Set tDirection = 1
			}
			Do tObject.%Set("inbound",tDirection)
		}

		#dim tDocDB = $system.DocDB.GetDatabase(..#DOCDBNAME)
		#dim tDoc = ""
		#dim tID = ""
		#dim tObjectArray = tObject.%Get("$dataArray")
		#dim tPortRangeEnd = 0
		#dim tPortRange
		If (tObjectArray = "") {
			Set tID = tObject.%Get("%DocumentId")
			If (tObject.%IsDefined("$endPort")) {
				Set tPortRangeEnd = tObject.%Get("$endPort")
				Do tObject.%Remove("$endPort")
				If +tPortRangeEnd < tObject.%Get("port") Set tPortRangeEnd = tObject.%Get("port")
			}
			If tPortRangeEnd {
				For tPortRange = tObject.%Get("port"):1:tPortRangeEnd {
					Do tObject.%Set("port",tPortRange)
					Do tObject.%Set("document",tDocumentType)
					Set tDoc = tDocDB.%SaveDocument(tObject,tObject.%Get("%DocumentId"))
					#; remove first one if we are setting a range
					If tObject.%IsDefined("%DocumentId") Do tObject.%Remove("%DocumentId")
				}
			} Else {
				Do tObject.%Set("document",tDocumentType)
				Set tDoc = tDocDB.%SaveDocument(tObject,tID)
			}
		} Else {
			#dim tObjectIterator = tObjectArray.%GetIterator()
			#dim tKey, tOneObject, tInbound
			While (tObjectIterator.%GetNext(.tKey,.tOneObject)) {
				Set tID = tOneObject.%Get("%DocumentId")
				/* verify the document is in fact expected */
				If tOneObject.%IsDefined("ID") Do tOneObject.%Remove("ID")
				Do tOneObject.%Remove("%DocumentId")
				Do tOneObject.%Remove("%LastModified")
				Do tOneObject.%Set("document",tDocumentType)
				Set tInbound = tOneObject.%Get("inbound")
				If tInbound = "Inbound" {
					Do tOneObject.%Set("inbound",1)
				} ElseIf tInbound = "Outbound" {
					Do tOneObject.%Set("inbound",0)
				}
				#; inUse (only for reservation) will be re-computed by Server 
				If tOneObject.%IsDefined("inUse") {
					#dim tinUse = $zcvt(tOneObject.%Get("inUse"),"l")
					If (tinUse = "yes") {
						Do tOneObject.%Set("inUse",1)
					} ElseIf (tinUse = "no") {
						Do tOneObject.%Set("inUse",0)
					} ElseIf ((tinUse'=1) && (tinUse'=0)) {
						Do tOneObject.%Remove("inUse")
					}
				}

				If (tID '="") && $classmethod(tDocDB.ClassName, "%ExistsId", tID) {
					Set tDoc = tDocDB.%SaveDocument(tOneObject, tID)
				} Else {
					Set tDoc = tDocDB.%SaveDocument(tOneObject)
				}
				If '$IsObject(tDoc) Quit
			}
		}
		If $IsObject(tDoc) Set tMsg = ""
	} Catch e {
		// Log info in Event Log
		#dim tLogMessage = $$$FormatText($$$Text("Port Setting Report user entered data for %1. Failed to save: %2"), tDocumentType, e.DisplayString())
		$$$LOGINFO(tLogMessage)
	}
	Return tMsg
}

Method DeleteOnServer(pJSON) As %String [ Internal, ZenMethod ]
{
	#; DocDB protection mechanism will also check required WRITE resource
	#dim e As %Exception.AbstractException
	#dim tMsg = $$$TextJS("Unable to delete")

	Try {
		#dim tObject = {}.%FromJSON(pJSON)
		#dim tTableName = tObject.%Get("$table")
		If ",reservationTable,adviceTable," '[ (","_tTableName_",") QUit
		#dim tDocID =  tObject.%Get("%DocumentId")
		If tDocID '= "" {
			#dim tDocDB = $system.DocDB.GetDatabase(..#DOCDBNAME)
			#dim tDoc = tDocDB.%DeleteDocument(tDocID)
			If $IsObject(tDoc) Set tMsg = ""
		}
	} Catch e {}

	Return tMsg
}

ClassMethod hasAuxEditPrivileges() As %Boolean [ Internal ]
{
	Quit $system.Security.Check("%Ens_PortSettingsReport","WRITE")
}

/*
	Begin: UI, Data Edit, Deletem Add, Export and Import
*/
ClientMethod refreshTable() [ Language = javascript ]
{
	zenPage.executeTableQueryAndClearCache();
	return;
}

ClientMethod editEntry(tableId, rowId) [ Language = javascript ]
{
	if (!zenPage.checkEditAux()) { return false; }
	var table = zenPage.currentTable();
	if (!table) return;
	if (!tableId) tableId=table.id;
	if ((tableId !== 'reservationTable') && (tableId !== 'adviceTable')) return;
	var frmdiv = document.getElementById('add'+tableId+'Form');
	if (!frmdiv) return;
	var sync = zenPage.drawDataEntryForm(frmdiv,table,true);
	sync=zenPage.showDataEntry(table,true);
}

ClientMethod deleteEntry(tableId, rowId) [ Language = javascript ]
{
	if (!zenPage.checkEditAux()) { return false; }
	var table = zenPage.currentTable();
	if (!table) return;
	if (!tableId) tableId=table.id;
	if ((tableId !== 'reservationTable') && (tableId !== 'adviceTable')) return;
	var rowObject = table.getRenderedRowData(table.selectedIndex);
	if (!rowObject) return;
	rowObject['$table']=table.id
	var msg = zenPage.DeleteOnServer(JSON.stringify(rowObject));
	if (msg) {
		alert(msg);
	}
	zenPage.executeTableQueryAndClearCache(table);
	return '';
}

ClientMethod addEntry(tableId) [ Language = javascript ]
{
	if ((tableId !== 'reservationTable') && (tableId !== 'adviceTable')) return;
	var frmdiv = document.getElementById('add'+tableId+'Form');
	if (!frmdiv) return;
	var table = zen(tableId);
	if (!table) return;

	var sync = zenPage.drawDataEntryForm(frmdiv,table);
	sync=zenPage.showDataEntry(table,true);
}

ClientMethod currentPortspageExport() [ Language = javascript ]
{
	if (zenPage.editingOnThisTab(true)) {
		return;
	}
	var table =  zenPage.currentTable()
	if (!table) return;

	var numberRows = (table.rowCount > table.pageSize) ? table.pageSize : table.rowCount;
	if (!numberRows) return;

	var tableArray = [];
	for (var n = 0 ; (n<numberRows); n++) {
		tableArray.push(table.getRenderedRowData(n));
	}
	var csvData = zenPage.convertToCSV(tableArray);
	if (csvData) {
		var blob = new Blob([csvData], { type: 'text/csv' });
		var url = window.URL.createObjectURL(blob);
		var filename = 'Export'+table.id+'.csv';
		if ((window.navigator)&&(window.navigator.msSaveOrOpenBlob)) {
			window.navigator.msSaveBlob(blob, filename);
		} else {
			var a = document.createElement('a');
			a.href = url;
			a.download = filename;
			document.body.appendChild(a);
			a.click();
			document.body.removeChild(a);
		}
		window.URL.revokeObjectURL(url);
	}
}

ClientMethod convertToCSV(objArray) [ Language = javascript ]
{
	var rows = typeof objArray !== 'object' ? JSON.parse(objArray) : objArray;
	var str = '';
	var sep = '\t';

	if ((rows) && (rows.length)) {
		// Create label line from first row using json key not column headers
		for (var key in rows[0]) {
			str += key + sep;
	}
	str = str.slice(0, -1);
	str += '\r\n';
	// Add data rows
	for (var i = 0; i < rows.length; i++) {
		var line = '';
		for (var key in rows[i]) {
			if (line !== '') { line += sep; }
				line += rows[i][key];
			}
			str += (i > 0 ? '\r\n' : '') + line;
		}
	}
	return str;
}

ClientMethod importAuxData() [ Language = javascript ]
{
	if (!((zenPage.currentTab === 2) || (zenPage.currentTab === 3))) {
		alert(zenPage.msgCannotImportPortData);
		return;
	}

	if (zenPage.editingOnThisTab(true)) {
		return;
	}

	var table = zenPage.currentTable();

	var sync = zenPage.recordTableLastMod(table.id);

	var input = document.createElement('input');
	input.setAttribute('type', 'file');
	input.addEventListener('change', function(){
		input.addEventListener('click', function(){
			zenPage.getParseAndImportData();
			input.removeEventListener("click", function(){})
		}, false);
		input.click();
	}, false); 
	document.body.appendChild(input);
	input.click();
}

ClientMethod getParseAndImportData() [ Language = javascript ]
{
	var file = document.querySelector('input[type=file]').files[0];
	var reader = new FileReader();
	reader.addEventListener("load", function () {
		var sync = zenPage.parseAndImportData(reader.result);
		var input = document.querySelector('input[type=file]');
		document.body.removeChild(input);
	}, false);
	if (file) {
		reader.readAsText(file);
	}
}

ClientMethod parseAndImportData(csvOrJSON) [ Language = javascript ]
{
	if (!csvOrJSON) return;
	var jsonArray = [];
	var json = '';
	var err = '';
	try {
		json = JSON.parse(csvOrJSON);
		if (Array.isArray(json)) {
			jsonArray = json;
		} else {
			jsonArray.push(json);
		}
	} catch (err) {
		// Not JSON so need to parse as tab delimited csv
		jsonArray = zenPage.csvParse(csvOrJSON);
	}

	//Save jsonArray
	if ((jsonArray) && (Array.isArray(jsonArray)) && (jsonArray.length > 0)) {
		var table = zenPage.currentTable();
		var inputObject = {};
		inputObject['$table'] = table.id;
		inputObject['$dataArray'] = jsonArray;
		/* prevent unnecessary serialisation of potentially large JSON */
		zenPage.docDBAsJSON = '';
		var msg = zenPage.SaveToServer(JSON.stringify(inputObject));
		if (msg) {
			alert(msg);
		}
		zenPage.executeTableQueryAndClearCache(table);
	}

	return '';
}

ClientMethod csvParse(csvToParse) [ Language = javascript ]
{
	/*
		read tab delimited csv - first line are headers -> properties
		then read each line - tab delimited.
	*/
	var jsonArray = [];
	if (!csvToParse) return jsonArray;
	var lineSep = '\0';
	var csv = csvToParse.replace(/(\r\n|\n|\r)/gm, lineSep);;
	var jsonObject = {};
	var sep = '\t'
	var lines = csv.split(lineSep);
	var values;
	var valuesCount;
	for (var count = 0; count < lines.length; count++) {
		if (count === 0) {
			// Try tab delimited first then ,
			var keys = lines[0].split('\t');
			if (keys.length === 1) {
				sep = ','
				keys = lines[0].split(',');
				if (keys.length === 1) {
					// return empty json array since cannot determine delimiter
					return jsonArray;
				}
			}
		} else {
			if (lines[count] != '') {
				jsonObject = {};
				values = lines[count].split(sep);
				for (valuesCount = 0; valuesCount < values.length; valuesCount++) {
					jsonObject[keys[valuesCount]] = values[valuesCount];
				}
				jsonArray.push(jsonObject);
			}
		}
		
	}
	return jsonArray;
}

ClientMethod executeTableQueryAndClearCache(table) [ Language = javascript ]
{
	if (!table) var table = zenPage.currentTable();
	if (table) {
		var sync = table.executeQuery();
		/* availableTable not included in the docDBAsJSON cache */
		if (table.id !== 'availableTable') {
			zenPage.docDBAsJSON = '';
		}
		if (table.id === 'reservationTable') {
			zenPage.lastModreservation = '';
		} else if (table.id === 'adviceTable') { 		
			zenPage.lastModadvice ='';
		}
	}
	return;
}

/*
	End: Data Export and Import
*/

/*
	Begin: Data Entry Form
*/
ClientMethod showDataEntry(table, state) [ Language = javascript ]
{
	if ((!table) || (table !== zenPage.currentTable())) return; 
	var button = document.getElementById('add'+table.id+'Button');
	if (!button) return;
	var navbar = document.getElementById('nav'+table.id);
	if (!navbar) return;
	var tablePane = document.getElementById(table.id);
	if (!tablePane) return;
	var form = document.getElementById('add'+table.id);
	if (!form) return;
	navbar.hidden = state;
	tablePane.hidden = state;
	button.hidden = state;
	if (state) {
		form.style.display = "block";
	} else {
		form.style.display = "none";
	}
}

ClientMethod drawDataEntryForm(frmdiv, table, edit) [ Language = javascript ]
{
	while (frmdiv.firstChild) { frmdiv.removeChild(frmdiv.firstChild); }

	if ((table) && (table.navigator) && (table.navigator.tablePane) && (table.navigator.tablePane.columns) && (table.navigator.tablePane.columns.length)) {

		var sync = zenPage.recordTableLastMod(table.id);

		var locationData = {};

		try { locationData = JSON.parse(zenPage.getThisLocationData()); } catch (e) {}

		var dataEntryTable = zenPage.createTable();

		var dataEntryBody = document.createElement('tbody');

		var dataEntryRow = '';
		var dataEntryLabel = '';
		var dataEntryInput = '';
		var col = 0;
		var colObj = '';
		var input = '';
		var existingData = '';

		if (edit) { existingData = table.getRenderedRowData(table.selectedIndex); }

		var value = ''

		for (col=0; col < (table.navigator.tablePane.columns.length); col++) {

			colObj = table.navigator.tablePane.columns[col];

			if ((!colObj.hidden) && (!colObj.link) && (colObj.colName != '%LastModified') && (colObj.colName != 'inUse') ) {

				dataEntryRow = document.createElement('tr');

				// get value for input box
				if ((edit) && (existingData)) {
					value = existingData[colObj.colName];
				} else {
					value = zenPage.defaultForColumn(colObj, locationData);
				}

				// create input box
				input = zenPage.createInputBox(colObj);

				// change input object by adding value(s) to display
				zenPage.modifyinputWithvalue(input, value, colObj);

				// modify input with events
				zenPage.modifyinputWithEvents(input, colObj, table.id, edit);

				// Create label
				dataEntryLabel = zenPage.createLabel(colObj, table.id, edit);

				// Hide %DocumentId
				if (colObj.colName === '%DocumentId') {
					input.setAttribute('readonly','true');
					input.setAttribute('hidden','true');
					dataEntryLabel.setAttribute('hidden','true');
				}

				// Add label cell
				dataEntryRow.appendChild(dataEntryLabel);

				// Add input value cell
				dataEntryInput = document.createElement('td');
				input.setAttribute('id','frm_'+colObj.colName);
				dataEntryInput.appendChild(input);
				dataEntryRow.appendChild(dataEntryInput);

				// add row
				if ((table.id === 'reservationTable') && (colObj.colName === 'port') && (!edit)) {
					// indent Start Port
					var ex;
					try {dataEntryRow.childNodes[1].innerHTML = '&nbsp;&nbsp;' + dataEntryRow.childNodes[1].innerHTML;} catch (ex) {}
					zenPage.addConsecutive(dataEntryBody);
					dataEntryBody.appendChild(dataEntryRow);
					zenPage.addEndRange(dataEntryBody);
					var portRow = dataEntryRow;
				} else {
					dataEntryBody.appendChild(dataEntryRow);
				}

				// Add 'or' label
				if (colObj.colName === 'server') {
					zenPage.addLabelRow(dataEntryBody,'or');
				}

				// Add blank separator row
				if (colObj.colName === 'mirror') {
					zenPage.addLabelRow(dataEntryBody,'');
				}

			}
		}

		zenPage.addHelpButton(dataEntryBody);

		dataEntryTable.appendChild(dataEntryBody);
		frmdiv.appendChild(dataEntryTable);
		frmdiv.appendChild(document.createElement('br'));
	}
}

ClientMethod createTable() [ Language = javascript ]
{
	var dataEntryTable = document.createElement('table');
	dataEntryTable.className = 'tpTable';
	dataEntryTable.setAttribute('id','frmUserEdit');
	dataEntryTable.setAttribute('border',1);
	dataEntryTable.setAttribute('cellspacing',2);
	dataEntryTable.setAttribute('cellpadding',0);
	dataEntryTable.setAttribute('style','table-layout:auto');
	return dataEntryTable;
}

ClientMethod defaultForColumn(colObj, locationData) [ Language = javascript ]
{
	var value = '';
	if (colObj.colName === 'username') {
		value = locationData.username;
	} else {
		/* set expiryDate to 30 days from now and in local time*/
		if (colObj.colName === 'expiryDate') {
			try {
				var expiry = new Date(Date.now());
				expiry.setDate(expiry.getDate() + parseInt(zenPage.defaultExpiryLength) ) ;
				expiry.setMinutes(expiry.getMinutes() - expiry.getTimezoneOffset());
				value = expiry.toJSON().slice(0, 19).replace('T', ' ')
			} catch (e) {}
		} else if (colObj.colName === 'inbound') {
			value = 'Inbound';
		} else if (colObj.colName === 'mirror') {
			value = locationData.mirror;
		} else if (colObj.colName === 'server') {
			if (!locationData.mirror) value = locationData.server;
		}
	}
	return value;
}

ClientMethod createInputBox(colObj, value) [ Language = javascript ]
{
	if (colObj.filterType === 'enum') {
		input = document.createElement('select');
		input.setAttribute('class','selectorInput');
	} else if (colObj.colName == 'comment') {
		input = document.createElement('textarea');
		input.setAttribute('cols',50);
		input.setAttribute('rows',6);
	} else {
		input = document.createElement('input');
		if ((colObj.colName === 'server') || (colObj.colName === 'itemName')|| (colObj.colName === 'production')) {
			input.setAttribute('size',50);
		} else if ((colObj.colName === 'port') || (colObj.colName === 'startPort') || (colObj.colName === 'endPort')) {
			input.setAttribute('size',8);
			input.setAttribute('maxlength',5);
		}
	}
	return input;
}

ClientMethod modifyinputWithvalue(input, value, colObj) [ Language = javascript ]
{
	/*	Set the input value/display options
	 	Look to build options for the property based on actual data 
	*/
	var jsonOptions = '';
	var e = '';
	switch (colObj.colName){
		case 'production':
			try { if (zenPage.production) jsonOptions = JSON.parse(zenPage.production); } catch (e) {}
			break;
		case 'server':
			try { if (zenPage.server) jsonOptions = JSON.parse(zenPage.server); } catch (e) {}
			break;
		case 'instance':
			try { if (zenPage.instance) jsonOptions = JSON.parse(zenPage.instance); } catch (e) {}
			break;
		case 'mirror':
			try { if (zenPage.mirror) jsonOptions = JSON.parse(zenPage.mirror); } catch (e) {}
			break;
		case 'partner':
			try { if (zenPage.partner) jsonOptions = JSON.parse(zenPage.partner); } catch (e) {}
			break;
		case 'classification':
			try { if (zenPage.classification) jsonOptions = JSON.parse(zenPage.classification); } catch (e) {}
			break;
		case 'mode':
			try {
				if (zenPage.mode) var modeOptions = JSON.parse(zenPage.mode);
				if (zenPage.modeExtended) var extendedModeOptions = JSON.parse(zenPage.modeExtended);
				if (extendedModeOptions) {
					if (modeOptions) {
						jsonOptions = modeOptions.concat(extendedModeOptions);
					} else {
						jsonOptions = extendedModeOptions;
					}
					
				} else if (modeOptions) {
					jsonOptions = modeOptions;
				}
			} catch (e) {}
			break;
		default:
			break;
	}
	if (jsonOptions) {
		var option = '';
		var datalist = document.createElement('datalist');
		datalist.id = 'datalist'+ colObj.colName;
		jsonOptions.forEach(function(item) {
			option = document.createElement('option');
			option.value = item;
			datalist.appendChild(option);
		});
		input.setAttribute('list','datalist'+colObj.colName);
		input.setAttribute('class','selectorInput');
		input.appendChild(datalist);
		if (value) input.value = value;
	} else if (colObj.filterType === 'enum') {
		var filterEnum = colObj.filterEnum.split(',');
		var filterEnumDisplay = colObj.filterEnumDisplay.split(',');
		var option = '';
		for (var i = 0; i<filterEnum.length; i++) {
			option =  document.createElement('option');
			option.value = filterEnum[i];
			option.text = filterEnumDisplay[i];
			input.add(option);
		}
		input.selectedIndex = filterEnumDisplay.indexOf(value);
	} else {
		input.value = value;
	}
	return;
}

ClientMethod modifyinputWithEvents(input, colObj, tableid, edit) [ Language = javascript ]
{
	if (tableid === 'reservationTable') {
		if (colObj.colName === 'port') {
			if (!edit) {
				input.setAttribute('onblur','zenPage.portFieldonBlur("port",false);')
			} else {
				input.setAttribute('onblur','zenPage.portFieldonBlur("port",true);')
			}
		}
	} else if (tableid === 'adviceTable') {
		if (colObj.colName === 'startPort') {
			if (!edit) {
				input.setAttribute('onblur','zenPage.portFieldonBlur("startPort",false);')
			} else {
				input.setAttribute('onblur','zenPage.portFieldonBlur("startPort",true);')
			}
		} else if (colObj.colName === 'endPort') {
			if (!edit) {
				input.setAttribute('onblur','zenPage.portFieldonBlur("endPort",false);')
			} else {
				input.setAttribute('onblur','zenPage.portFieldonBlur("endPort",true);')
			}
		}
	}
}

ClientMethod createLabel(colObj, tableid, edit) [ Language = javascript ]
{
	var dataEntryLabel = document.createElement('td');

	if ((tableid === 'reservationTable') && (colObj.colName === 'port') && (!edit)) {
		dataEntryLabel.appendChild(document.createTextNode('Start Port'));
	} else {
		dataEntryLabel.appendChild(document.createTextNode(colObj.header))
	}

	return dataEntryLabel;
}

ClientMethod addConsecutive(dataEntryBody) [ Language = javascript ]
{
	/* use $ to indicate pseudo field. */

	var input = document.createElement('input');
	var value = '';
	input = document.createElement('input');
	input.setAttribute('value',value);
	input.setAttribute('id','frm_$rangeRequired');
	input.setAttribute('onblur','zenPage.portFieldonBlur("$rangeRequired",false);')
	input.setAttribute('size',4);
	input.setAttribute('maxlength',3);

	dataEntryRow = document.createElement('tr');
	dataEntryLabel = document.createElement('td');
	dataEntryLabel.appendChild(document.createTextNode('Number of Consecutive Ports'))
	dataEntryRow.appendChild(dataEntryLabel);

	dataEntryInput = document.createElement('td');
	dataEntryInput.appendChild(input);

	dataEntryRow.appendChild(dataEntryInput);
	dataEntryBody.appendChild(dataEntryRow);
	return;
}

ClientMethod addEndRange(dataEntryBody) [ Language = javascript ]
{
	/* use $ to indicate pseudo field. */

	var input = document.createElement('input');
	var value = '';
	input.setAttribute('value',value);
	input.setAttribute('id','frm_$endPort');
	input.setAttribute('onblur','zenPage.portFieldonBlur("$endPort",false);')
	input.setAttribute('size',8);
	input.setAttribute('maxlength',5);

	var dataEntryRow = document.createElement('tr');

	var dataEntryLabel = document.createElement('td');
	dataEntryLabel.appendChild(document.createTextNode('End Port'))
	dataEntryRow.appendChild(dataEntryLabel);

	var dataEntryInput = document.createElement('td');
	// indent End Port
	dataEntryInput.appendChild(document.createTextNode('\u00A0\u00A0'));
	dataEntryInput.appendChild(input);

	dataEntryRow.appendChild(dataEntryInput);
	dataEntryBody.appendChild(dataEntryRow);

	return;
}

ClientMethod portFieldonBlur(field, edit) As %String [ Language = javascript ]
{
	/*
		validate a port value
		identify if using field as range request and find a range
	*/
	var ex;
	try {

		// Remove leading and trailing spaces
		var portInput = document.getElementById('frm_'+field).value.replace(/^\s+|\s+$/g,'');
		document.getElementById('frm_'+field).value = portInput;
		if (!portInput) return true;

		/*
			reservation table has field 'port'
			advice table has fields startPort and endPort
		*/
		if ((edit) || (field === 'startPort') || (field === 'endPort') || (field === '$endPort') || ((portInput.charAt(0) !== '+') && (field === 'port'))) {
			if (!zenPage.validPort(portInput,true)) {
				zenPage.resetDataField(field);
			}
			if ((field === '$endPort') || (field === 'endPort')) {
				var error = zenPage.validEndPort(portInput, field);
				if (error) {
					alert(error);
					zenPage.resetDataField(field);
				}
			}
			return true;
		};

		/*
			From here on we are checking field frm_port or rangeRequired
			and its an add and hence start of range.
		*/

		/* check that requesting range for Inbound */
		if (document.getElementById('frm_inbound').value != 1) {
			alert($$$Text('Range requests valid for Inbound only'));
			zenPage.resetDataField(field);
			return true;
		}

		var rangeRequested = (field === '$rangeRequired') ? portInput : (portInput.substring(1)) ;
		if (!zenPage.validRangeRequest(rangeRequested,true)) {
			// clear End Port if left over
			document.getElementById('frm_$endPort').value = '';
			if (field === '$rangeRequired') document.getElementById('frm_port').value = '';
			zenPage.resetDataField(field);
			return false;
		}
		// request to find range
		var rangeRequestObject = zenPage.populateRangeRequestObject(rangeRequested);

		// see if boundary from advice and update rangeRequestObject
		if (!zenPage.findBoundary(rangeRequestObject)) {
			document.getElementById('frm_$endPort').value = '';
			if (field === '$rangeRequired') document.getElementById('frm_port').value = '';
			zenPage.resetDataField(field);
			return false;
		}

		if (!zenPage.findRange(rangeRequestObject)) {
			alert($$$Text('Unable to suggest a range'));
			document.getElementById('frm_$endPort').value = '';
			if (field === '$rangeRequired') document.getElementById('frm_port').value = '';
			zenPage.resetDataField(field);
			return false;
		}

		/* populate frm_port and frm_$endPort with findings in rangeRequestObject */
		if ((document.getElementById('frm_port')) && (rangeRequestObject.suggestedStart )) document.getElementById('frm_port').value = rangeRequestObject.suggestedStart;
		if ((document.getElementById('frm_$endPort')) && (rangeRequestObject.suggestedEnd )) document.getElementById('frm_$endPort').value = rangeRequestObject.suggestedEnd;

	} catch (ex) {
		alert($$$FormatText($$$Text("Error validating input : %1"),ex) );
		return false;
	}

	return true;
}

ClientMethod setEndPort(startPortID, endPortID) [ Language = javascript ]
{
	if (startPortID && endPortID) {
		var startPortCtl = document.getElementById(startPortID);
		var endPortCtl = document.getElementById(endPortID);
		if (startPortCtl && endPortCtl) {
			if ((endPortCtl.value == '')|| (parseInt(endPortCtl.value) < parseInt(startPortCtl.value))) {endPortCtl.value = startPortCtl.value;}
		}
	}
	return '';
}

ClientMethod resetDataField(field) [ Language = javascript ]
{
	document.getElementById('frm_'+field).value = '';
	window.setTimeout(function () {
		document.getElementById('frm_'+field).focus();
	}, 0);
	return true;
}

ClientMethod saveEntry(tableId) [ Language = javascript ]
{
	if ((tableId !== 'reservationTable') && (tableId !== 'adviceTable')) return;
	var frmdiv = document.getElementById('add'+tableId+'Form');
	if (!frmdiv) return;
	var table = zen(tableId);
	if (!table) return;
	var inputElement = '';
	var inputObject = {};

	var inputElements = frmdiv.querySelectorAll('input[id^=frm],textarea[id^=frm],select[id^=frm]');

	for (var i = 0; i < inputElements.length; i++) {
		inputElement = inputElements[i];
		// only set if value given
		if (inputElement.value) inputObject[inputElement.id.split("frm_")[1]]=inputElement.value;
	}

	var errors = zenPage.validDataToSave(tableId, inputObject)
	if (errors) {
		if (errors.charAt(0)!=='+') {
			alert(errors);
			return;
		} else {
			var msg = errors.split('+')[1]+'\n'+$$$Text('Press Cancel to abort Save. ');
			if (!(confirm(msg))) return;
		}
	}

	// Cleanup
	while (frmdiv.firstChild) {
		frmdiv.removeChild(frmdiv.firstChild);
	}
	/* prevent unnecessary serialisation of potentially large JSON */
	zenPage.docDBAsJSON = '';
	inputObject['$table'] = tableId;
	var msg = zenPage.SaveToServer(JSON.stringify(inputObject));
	if (msg) {
		alert(msg);
	}
	zenPage.executeTableQueryAndClearCache(table);

	var sync = zenPage.showDataEntry(table,false);
}

ClientMethod cancelsaveEntry(tableId) [ Language = javascript ]
{
	if ((tableId !== 'reservationTable') && (tableId !== 'adviceTable')) return;
	var table = zen(tableId);
	if (!table) return;
	var sync=zenPage.showDataEntry(table,false);
}

ClientMethod addHelpButton(dataEntryBody) [ Language = javascript ]
{
	var dataEntryRow = document.createElement('tr');
	var dataEntryCell = document.createElement('td');

	var dataEntryHelp = document.createElement('img');
	dataEntryHelp.setAttribute('src', 'deepsee/help_24.png');
	dataEntryHelp.setAttribute('title', 'help');
	dataEntryHelp.setAttribute('onclick', 'zenPage.showDataEntryHelp();');

	dataEntryCell.appendChild(dataEntryHelp);
	dataEntryRow.appendChild(dataEntryCell);
	dataEntryBody.appendChild(dataEntryRow);

	return;
}

ClientMethod addLabelRow(dataEntryBody, text) [ Language = javascript ]
{
	var orLabel = document.createElement('td');
	orLabel.appendChild(document.createTextNode('\u00A0 '+text));
	var dataEntryRow = document.createElement('tr');
	dataEntryRow.appendChild(orLabel);
	dataEntryBody.appendChild(dataEntryRow);
	return;
}

ClientMethod showDataEntryHelp() [ Language = javascript ]
{
	var table = zenPage.currentTable();
	var info = '';
	if (table) {
		var document = 'reservation';
		if (table.id === 'adviceTable') {
			info = $$$Text('Use this form to enter site specific port related advice.')
			info += '\n';
			info += '\n';
			info += $$$Text('The only fixed Classification is "Reservation Boundary" which helps identify boundary suggestions for inbound reservations.');
			info += '\n';
			info += $$$Text('Boundary identification is based on server or mirror and optional production, instance & mode fields.');
			info += '\n';
			info += $$$Text('The default used to bound an inbound reservation range request is 1074 to 65535');
			info += '\n';
			info += '\n';
			info += $$$Text('Other Classification entries are site specific and can be entered as required.');
		} else {
			info = $$$Text('Use this form to enter one or more port reservations.')
			info += '\n';
			info += '\n';
			info += $$$Text('The Server or Mirror field needs to be entered. For a Mirrored environment use the Mirror field.');
			info += '\n';
			info += '\n';
			info += $$$Text('The field "Number of Consecutive Ports" can be used to find consecutive inbound ports that are not in use or already reserved.');
			info += '\n';
			info += '\n';
			info += $$$Text('A "Reservation Boundary" entry in the advice table is used to bound the range searched - the default is 1074 to 65535');
			info += '\n';
			info += $$$Text('The boundary match is based on server or mirror and optional production, instance & mode fields.');
			info += '\n';
			info += '\n';
			info += $$$Text('It is possible to enter specific "Start Port" and optional "End Port"');
			info += '\n';
			info += '\n';
			info += $$$Text('An individual reservation table entry will be created for each port in the range.');
		}
		
		alert(info);
	}
}

/*
	End: Data Entry Form
*/

/*
	Begin: Data validation
*/
ClientMethod validNumber(data, type, warn) [ Language = javascript ]
{
	var ex;
	var max = (type === 'port') ? 65535 : 100;
	var min = 1;
	
	try {
		if (isNaN(data)||('' === data)||!(/^[0-9]+$/.test(data))) {
			if (warn) alert($$$Text("Value entered is not a positive integer."));
			return false;
		}
		if (data < min) {
			if (warn) alert($$$FormatText($$$Text("Value entered %1 is less than minimum allowed of %2"), data, min));
			return false;
		}
		if (data > max) {
			if (warn) alert($$$FormatText($$$Text("Value entered %1 is greater than maximum allowed of %2"), data, max));
			return false;
		}
		
	} catch (ex) {
			if (warn) alert($$$FormatText($$$Text("Error checking value: %1"),ex) );
			return false;
	}
	return true;
}

ClientMethod validPort(data, warn) [ Language = javascript ]
{
	var valid = zenPage.validNumber(data,'port',warn);
	return valid;
}

ClientMethod validRangeRequest(data, warn) [ Language = javascript ]
{
	var valid = zenPage.validNumber(data,'range',warn);
	return valid;
}

ClientMethod validEndPort(portInput, field) [ Language = javascript ]
{
	var startfield = (field === 'endPort') ? 'startPort' : 'port';
	var start = parseInt(document.getElementById('frm_'+startfield).value);
	var end = parseInt(portInput);

	if (!(start < (end+1))) return $$$Text('Resetting End Port to empty since greater than Start Port');
	if ((field === '$endPort') && ((start+100) < (end-1))) return $$$Text('Too many reservations requested in the range. Maximum is 100.');

	return '';
}

ClientMethod validDataToSave(tableId, inputObject) [ Language = javascript ]
{
	/* If errors found are not fatal then prepend with + */
	var errors = '';

	if (tableId === 'reservationTable') {

		var start = parseInt(inputObject['port']);
		var end = (inputObject['$endPort']) ? parseInt(inputObject['$endPort']) : start;

		// these ought to be checked in validEndPort()
		if (!(start < (end+1))) {
			return $$$Text('Invalid port range entered');
		}
		if ((start+100) < (end-1)) {
			return $$$Text('Too many reservations requested in the range. Maximum is 100.');
		}

		/* Check if the port(s) requested are not already reserved or in use for the Server/Mirror combination. */
		var inUseInfo = zenPage.findIfUsedOrReserved(inputObject);

		if ((inUseInfo) && inUseInfo['Port']) {
			var whereUsed = $$$Text('in use or reserved');
			var dupeInfo = '';
			if (inUseInfo['Details']) {
				if (inUseInfo['Details'].document) {
					if ((inUseInfo['Details'].document) === 'reservation') {
						whereUsed = $$$Text('reserved');
					} else {
						whereUsed = $$$Text('in use');
					}
					var dupeInfo =  JSON.stringify(inUseInfo['Details'],
										function(key, value){
											if (!value) return undefined;
											if (key === 'document') return undefined;
											if (key === '%DocumentId') return undefined;
											return value;
										},
										2);
				}			
			}
			errors = '+'+$$$FormatText($$$Text('Detected port %1 in your reservation request that is already %2 for %3: \n\n %4 \n'), inUseInfo['Port'], whereUsed, (inputObject['server'] ? inputObject['server'] : inputObject['mirror'] ), dupeInfo);
			return errors;
		}
		
	} else if (tableId === 'adviceTable') {

		if (inputObject['endPort']) {
			// these ought to be checked in validEndPort()
			var end = parseInt(inputObject['endPort']);
			var start = parseInt(inputObject['startPort']);
			if (!(start < (end+1))) {
				return $$$Text('Invalid port range entered');
			}
		}

	} else {

		errors = $$$Text('Invalid table being edited');

	}

	return errors;
}

/*
	End: Data validation
*/

/*
	Begin: Find free reservation ports
*/
ClientMethod findBoundary(rangeRequestObject) [ Language = javascript ]
{
	/* identify if server or mirror has values */
	if ((document.getElementById('frm_server').value === '') && (document.getElementById('frm_mirror').value === '')) {
		alert($$$Text('Server or Mirror value is needed to find a free range.'));
		return false;
	}
	var ex;

	try {

		if (!zenPage.docDBAsJSON) {
			var sync = zenPage.setDocDBPortsAsJSON()
		}
		var docDBData = [];
		if (zenPage.docDBAsJSON) {
			docDBData = JSON.parse(zenPage.docDBAsJSON);
			if (!docDBData.content) return false;
		} else {
			return false;
		}
		
		/* Filter Reservation Boundary first */ 

		var boundaryAdvice = docDBData.content.filter(function (row)
		{
			if ((row.document === 'advice') && (row.classification === 'Reservation Boundary')) {
				return true;
			}
			// skip this row
			return false;
		});
		/* filter further on instance, server or mirror, production
			count the number of matches.
			use reduce. pass in our boundary object and also information on request.
		*/
		if (boundaryAdvice) {
			// number of matches in last boundary match
			rangeRequestObject['boundaryMatches'] = 0;
			/* 
				walk boundaryAdvice[] looking at what matches against rangeRequestObject {} 
				updated boundaryStart and boundaryEnd if more matches than rangeRequestObject['boundaryMatches']
			*/
			var request = rangeRequestObject;
			rangeRequestObject = boundaryAdvice.reduce(function(request, advice)
			{
				var matches = 0;
				var openAdvice = !advice.server && !advice.mirror && !advice.production && !advice.instance;
				if (!openAdvice) {
					/* can only check fields defined in request and columns returned using getDocuments
						For bounday request fields populated in populateRangeRequestObject
					*/
					if (request.server) {
						if ((request.server === advice.server) || ((!advice.server) && (!advice.mirror))){
							matches++;
						} else {
							return request; //skip further match testing
						}
					} else {
						if ((request.mirror === advice.mirror) || ((!advice.server) && (!advice.mirror))) {
							matches++;
						} else {
							return request; //skip further match testing
						}
					}
					if (((request.production) && (request.production === advice.production)) || (!advice.production)) {
						if (advice.production) matches++;
					} else {
						return request; //skip further match testing
					}
					if (((request.instance) && (request.instance === advice.instance)) || (!advice.instance)) {
						if (advice.instance) matches++;
					} else {
						return request; //skip further match testing
					}
					if (((request.mode) && (request.mode === advice.mode)) || (!advice.mode)) {
						if (advice.mode) matches++;
					} else {
						return request; //skip further match testing
					}

				}
				// if more matches than before or no restrictions on the advice reset boundaries
				if ((matches > request['boundaryMatches']) || (openAdvice && !request['boundaryMatches'])){
					if (advice.startPort) request['boundaryStart'] = advice.startPort ;
					if (advice.endPort) request['boundaryEnd'] = advice.endPort;
					request['boundaryMatches'] = matches;
				}
				return request;
			}, request);

		}

	} catch (ex) {
		alert($$$FormatText($$$Text("Error finding boundary range : %1"),ex) );
		return false;
	}


	return true;
}

ClientMethod findRange(rangeRequestObject) [ Language = javascript ]
{
	var ex;
	var rangeFound = false;
	try {

		var filteredPortsInUseOrReserved = zenPage.filterPortsInUseOrReserved(rangeRequestObject);
		/* If no ports in use or reserved start at boundary	*/
		if ((!filteredPortsInUseOrReserved) || (!filteredPortsInUseOrReserved.length)){
			rangeRequestObject.suggestedStart = rangeRequestObject.boundaryStart;
			rangeRequestObject.suggestedEnd = parseInt(rangeRequestObject.boundaryStart) + parseInt(rangeRequestObject.range) -1;
			return true;
		}
		/* get ordered by port in use/reserved */
		var sortedPortsInUseOrReserved = zenPage.sortPortsFromFilteredDocuments(filteredPortsInUseOrReserved);

		/* Find the first gap that matches what we want */
		var result = {};
		rangeRequestObject['suggestedStart'] = parseInt(rangeRequestObject['boundaryStart']);

		rangeFound = sortedPortsInUseOrReserved.some(function(port)
		{
			if (!rangeRequestObject['suggestedStart']) {
				rangeRequestObject['suggestedStart'] = port+1;
				return false;
			}
			if ( ((rangeRequestObject['suggestedStart'] + rangeRequestObject['range'] - 1) < port ) ) {
				rangeRequestObject['suggestedEnd'] = (rangeRequestObject['suggestedStart'] + rangeRequestObject['range'] - 1);
				/* exit some() with rangeFound set to true */
				return true;
			} else {
				rangeRequestObject['suggestedStart'] = port+1;
				return false;
			}
		}, rangeRequestObject);
		if (!rangeFound) {
			if (rangeRequestObject['suggestedStart']) {
				rangeRequestObject['suggestedEnd'] = (rangeRequestObject['suggestedStart'] + rangeRequestObject['range'] - 1);
				rangeFound = true;
			}
		}

	} catch (ex) {
		alert($$$FormatText($$$Text("Error finding free range : %1"),ex) );
		return false;
	}

	return rangeFound;
}

ClientMethod populateRangeRequestObject(rangeRequested) [ Language = javascript ]
{
/*
	range reservation info:
		range - requested range length
		server - will need either this or mirror
		mirror
		production
		instance
		interface
		boundaryStart: 1074 and then updated if necessary from findBoundary from advice document
		boundaryEnd : 65535 and then updated if necessary from findBoundary from advice document
		suggestedStart - populated by findRange
		suggestedEnd - populated by findRange

*/
	var fields = ['server','mirror','production','instance','interface','mode'];
	var rangeRequestObject = fields.reduce(function (rangeRequest, field)
	{
		if (document.getElementById('frm_'+field)) {rangeRequest[field] = (document.getElementById('frm_'+field).value)}
		return rangeRequest;
	}, {});

	rangeRequestObject['range'] = parseInt(rangeRequested);
	rangeRequestObject['boundaryStart'] = 1074;
	rangeRequestObject['boundaryEnd'] = 65535;
	rangeRequestObject['suggestedStart'] = '';
	rangeRequestObject['suggestedEnd'] = '';

	return rangeRequestObject;
}

ClientMethod filterPortsInUseOrReserved(requestObject) [ Language = javascript ]
{
	/* called when looking for free range
		also called when looking for duplicates
	*/
	var ex;
	try {
		var filteredPortsInUseOrReserved = [];
		/* docDBAsJSON ought to have been set by findBoundary() */
		if (!zenPage.docDBAsJSON) {
			var sync = zenPage.setDocDBPortsAsJSON()
		}
		var docDBData = JSON.parse(zenPage.docDBAsJSON);
		/*
			filter the data by 
				document = reservation or document = primary
				server or mirror match request values
				if range request
					port = or > boundaryStart
					port = < boundaryEnd
				interface empty string or match request value
		*/
		filteredPortsInUseOrReserved = docDBData.content.filter(function(row)
		{
			/* skip if not primary or reservation */
			if ((row.document !== 'primary') && (row.document !== 'reservation')) return false;

			/* skip if this is an edit of existing document */
			if ((this['%DocumentId']) && (row['%DocumentId']) && ((this['%DocumentId']) == (row['%DocumentId']))) return false;

			/* skip if not same computer - this is requestObject */
			if (this.server) {
				if ((this.server) !== (row.server)) return false;
			} else if (this.mirror) {
				if ((this.mirror) !== (row.mirror)) return false;
			} else {
				/* need to specify at least server or mirror */
				return false ;
			}

			/* skip if not in our boundary and requestObject is a range request*/
			if ((this.boundaryStart) && (row.port < this.boundaryStart)) return false;
			if ((this.boundaryEnd) && (row.port > this.boundaryEnd)) return false;

			/* skip if different interfaces */
			if ((row.interface) && (this.interface) && (this.interface !== row.interface)) return false;

			/* include */
			return true;
		}, requestObject);
	} catch (ex) {
		alert($$$FormatText($$$Text("Error finding free range : %1"),ex) );
		return false;
	}
	return filteredPortsInUseOrReserved;
}

ClientMethod sortPortsFromFilteredDocuments(filteredPortsInUseOrReserved) [ Language = javascript ]
{
	var sortedPortsInUseOrReserved = filteredPortsInUseOrReserved.reduce(function(portArray, row)
	{
		var port = parseInt(row.port);
		if (portArray.indexOf(port) === -1) portArray.push(port);
		return portArray;
	}, []);
	sortedPortsInUseOrReserved.sort(function(a, b){return a-b});
	return sortedPortsInUseOrReserved;
}

ClientMethod findIfUsedOrReserved(inputObject) [ Language = javascript ]
{
	var inUseInfo = {}
	var inUsePort = '';
	var filteredPortsInUseOrReserved = zenPage.filterPortsInUseOrReserved(inputObject);
	if ((filteredPortsInUseOrReserved) && (filteredPortsInUseOrReserved.length)) {
		var start = parseInt(inputObject['port']);
		var end = (inputObject['$endPort']) ? parseInt(inputObject['$endPort']) : start;
		var sortedPortsInUseOrReserved = zenPage.sortPortsFromFilteredDocuments(filteredPortsInUseOrReserved);
		for (var port = start ; (port <= end); port++) {
			if (sortedPortsInUseOrReserved.indexOf(port) !== -1) {
				inUsePort = port;
				break;
			}
		}
	}
	inUseInfo['Port'] = inUsePort;
	inUseInfo['Details'] = '';
	if (inUsePort) {
		var gotInfo = filteredPortsInUseOrReserved.some(function(row)
		{
			if ( row.port === inUseInfo['Port']) {
				inUseInfo['Details'] = row ;
				/* exit some() with gotInfo set to true */
				return true;
			} else {
				return false;
			}
		}, inUseInfo);
	}

	return inUseInfo;
}

/*
	End: Find free reservation ports
*/

/*
	Begin: UI interactions
*/
ClientMethod onTabChange() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	if (tabGroup) zenPage.currentTab = tabGroup.getCurrTabNo();

	zenPage.indicateIfCanUseImportButton();
}

ClientMethod indicateIfCanUseImportButton() [ Language = javascript ]
{
	var btn = document.getElementById('command_importAuxButton');
	if (btn) {
		if ((!zenPage.canEditAuxTables) || (!((zenPage.currentTab === 2) || (zenPage.currentTab === 3)))) {
			btn.className = 'commandButtonDisabled';
			if (!zenPage.canEditAuxTables) {
				btn.onclick = '';
				btn.title = zenPage.msgEditingNotAllowed;
			}
		} else {
			btn.className = 'commandButton';
		}
	}
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	return;
}

ClientMethod checkEditAux() [ Language = javascript ]
{
	if (!zenPage.canEditAuxTables) {
		alert(zenPage.msgEditingNotAllowed);
	}
	return zenPage.canEditAuxTables;
}

ClientMethod currentTable() [ Language = javascript ]
{
	var table = ''
	/*
		use loose equality for 1 since we initialize on page load
		and is regarded as a string
		Afterwards we use tabGroup.getCurrTabNo() to set currentTab
	*/
	
	if (zenPage.currentTab == 1) {
		table = zen('portTable');
	} else if (zenPage.currentTab === 2) {
		table = zen('reservationTable');
	} else if (zenPage.currentTab === 3) {
		table = zen('adviceTable');
	} else if (zenPage.currentTab === 4) {
		table = zen('conflictTable');
	} else if (zenPage.currentTab === 5) {
		table = zen('availableTable');
	} 
	return table;
}

ClientMethod resetFilters() [ Language = javascript ]
{
	if (zenPage.editingOnThisTab(true)) {
		return;
	}
	var table = zenPage.currentTable();
	if (!table) return;
	table.resetColumnFilters();
	table.applyFilters();
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.invokeSuper('onloadHandler',[]);

	zenPage.indicateIfCanUseImportButton();
}

ClientMethod editingOnThisTab(showAlert) [ Language = javascript ]
{
	var editing = false;
	if ((zenPage.currentTab === 2) || (zenPage.currentTab === 3)) {
		var table = zenPage.currentTable(); 
		if (table) {
			var navbar = document.getElementById('nav'+table.id);
			if ((navbar) && (navbar.hidden)) {
				editing = true;
				if (showAlert) {
					alert('Disabled during editing');
				}
			}
		}
	}
	return editing;
}

/*
	End: UI interactions
*/
}
