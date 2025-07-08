/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee, %products)

IncludeGenerator (%occUtility, %DeepSee)

/// This is a common base class to different types of KPI.
Class %DeepSee.AbstractKPI Extends (%CSP.Page, %ZEN.DataModel.ObjectDataModel, %DeepSee.QuerySource) [ Abstract, System = 4 ]
{

/// KPI cannot be modified from a client (part of DataModel API).
Parameter READONLYMODEL = 1;

/// If true, this KPI is available for public use within dashboard (subject also
/// to the RESOURCE parameter).<br/>
/// If false  it is not listed as an available KPI within the dashboard tools, but it
/// can be used within pivot tables and may be visible within the Analyzer.
Parameter PUBLIC As BOOL = 1;

/// The resource needed to use this KPI:<br/>
/// If defined and the current user holds the USE privilege on this resource, then
/// the user may view (run queries against) this item.<br/>
Parameter RESOURCE As STRING;

/// If true, always recompute the value of this KPI when used within an MDX query.<br/>
/// Typically a KPI (especially a plug-in) used within an MDX query does not need to be 
/// recalculated unless the class defining the KPI is recompiled. For KPIs that depend on
/// external data, it may be convenient to always recompute the KPI value.
/// Setting this parameter to true has the same effect as recompiling the KPI class before
/// each use.
Parameter FORCECOMPUTE As BOOL = 0;

/// Lower threshold value for any meters connected to this KPI.
Property %thresholdLower As %Double(ZENHIDDEN = 1);

/// Upper threshold value for any meters connected to this KPI.
Property %thresholdUpper As %Double(ZENHIDDEN = 1);

/// Lower range value for any meters connected to this KPI.
Property %rangeLower As %Double(ZENHIDDEN = 1);

/// Upper range value for any meters connected to this KPI.
Property %rangeUpper As %Double(ZENHIDDEN = 1);

/// Message to be displayed by dashboard widget.
Property %message As %String(ZENHIDDEN = 1);

/// Proxy object containing filter values from the client.
Property %filterValues As %ZEN.proxyObject(ZENHIDDEN = 1);

/// Set true if the current results are from the cache.
Property %fromCache As %String(ZENHIDDEN = 1) [ InitialExpression = 0 ];

/// Cache key used for this query.
Property %cacheKey As %String(ZENHIDDEN = 1) [ Internal ];

/// Internal property that holds the current cube name used by this KPI (if any).
/// Used for caching.
Property %cubeName As %String(ZENHIDDEN = 1) [ Internal ];

/// Internal property that holds the current MDX query key used by this KPI (if any).
/// Used for caching.
Property %queryKey As %String(ZENHIDDEN = 1) [ Internal ];

/// Internal property that holds the current cell context when this KPI is invoked from
/// within an MDX statement.<br/>
/// (Note: type is an object to prevent MVC code generation).
Property %cellContext As %ZEN.proxyObject(ZENHIDDEN = 1) [ Internal, MultiDimensional ];

/// Return true if this KPI is public.
ClassMethod %IsPublic() As %Boolean
{
	Quit +..#PUBLIC
}

/// Draw the test page.
ClassMethod OnPage() As %Status
{
	Set tSC = $$$OK
	Try {
		New %dsKPIError
		Set %dsKPIError = $$$OK
		
		If ((..%ClassName(1)="%DeepSee.AbstractKPI")||(..%ClassName(1)="%DeepSee.KPI")) {
			Quit
		}

		If '$System.Security.Check("%Development","U") {
			Quit
		}
		
		// DTB592 - Move after security checks
		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			If $$$ISERR(tSC) {
				Set tErrorMsg = $$$FormatText($$$Text("Error creating %1 session.","%DeepSee"),$$$PRODUCT1)
			}
			Set tSession = $G($$$DeepSeeSession)
		}
		Set tIcon = $$$ICON1
		&html<<html>
		<head>>

		&html<<link rel="shortcut icon" href="#(tIcon)#">>

		&html<<script language="javascript">
function updateFilters(name,value,list)
{
	// reset dependents
	var t = list.toString().split(',');
	for (var n = 0; n < t.length; n++) {
		var ctrl = self.document.getElementById('select_'+t[n]);
		if (ctrl) {
			ctrl.value = '';
		}
	}

	// submit to recompute filter values
	var form = self.document.getElementById('theForm');
	form.submit();
}
		</script>>

	
		&html<<style>

body {
	margin: 0px;
	background: #FAFAFA;
	font-family: arial;
	color: #404040;
}

.query {
	margin-left: 20px;
	width: 800px;
	border: 1px solid #606060;
	background: white;
	padding: 3px;
	line-height: 150%;
	font-family: courier new;
	overflow: auto;
	box-shadow: 2px 2px 2px #808080;
}

.title {
	color: #F0F0F0;
	padding: 6px;
	padding-left: 20px;
	font-size: 24px;
}

.title,table.tableValue th {
background: rgb(167,207,223); /* Old browsers */
background: -moz-linear-gradient(top,  rgba(167,207,223,1) 0%, rgba(35,83,138,1) 100%); /* FF3.6+ */
background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(167,207,223,1)), color-stop(100%,rgba(35,83,138,1))); /* Chrome,Safari4+ */
background: -webkit-linear-gradient(top,  rgba(167,207,223,1) 0%,rgba(35,83,138,1) 100%); /* Chrome10+,Safari5.1+ */
background: -o-linear-gradient(top,  rgba(167,207,223,1) 0%,rgba(35,83,138,1) 100%); /* Opera 11.10+ */
background: -ms-linear-gradient(top,  rgba(167,207,223,1) 0%,rgba(35,83,138,1) 100%); /* IE10+ */
background: linear-gradient(top,  rgba(167,207,223,1) 0%,rgba(35,83,138,1) 100%); /* W3C */
filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#a7cfdf', endColorstr='#23538a',GradientType=0 ); /* IE6-9 */
}

.tableTitle {
	font-weight: bold;
	width: 100%;
	text-align: left;
	color: #404040;
	padding-left: 20px;
	padding-top: 20px;
	padding-bottom: 2px;
}

table.tableKPI {
	margin-left: 20px;
	background: white;
	border: 1px solid #606060;
}

table.tableKPI td {
	text-align: left;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 3px;
}

table.tableValue {
	margin-left: 20px;
	background: white;
	border: 1px solid #606060;
	font-size: 12px;
}

table.tableValue th {
	color: white;
	border-bottom: 1px solid #606060;
	border-right: 1px solid gray;
	text-align: left;
	padding: 3px;
}

table.tableValue td {
	text-align: left;
	border-right: 1px solid gray;
	padding: 3px;
}

		</style>>

		&html<</head>
		<body>>

		If (+$$$comClassKeyGet(..%ClassName(1),$$$cCLASSabstract)) {
			Write "Abstract class"
			&html<</body></html>>
			Quit
		}
	
		If '$System.Security.Check("%Development","U") {
			Write "You must hold development privileges to view this page"
			&html<</body></html>>
			Quit
		}

		If ($G(%request.Data("clear",1))) {
			Do ..%ClearKPICache()
			&html<<div style="margin:20px;">>
			Write "KPI Cache cleared."
			&html<<br/><a href="#($ZCVT(..%ClassName(1),"O","URL")_".cls")#">Reload</a>>
			&html<<div>>
			&html<</body></html>>
			Quit
		}

		Set tTitle = $$$FormatText($$$Text("%1 KPI Test Page","%DeepSee"),$$$PRODUCT1)
		Set tKPIName = ..%GetKPIName()
		Set tKPICaption = ..%GetKPICaption()

		Set hlpCaption = $$$TextHTML("Return value of %GetKPICaption","%DeepSee")

		Set tSC = ..%GetFilterList(.tFilters)
		If $$$ISERR(tSC) Quit
		Set tLogo = $$$LOGO2
		&html<<div class="title">
		<table border="0" cellspacing="0">
		<tr><td><image width="36" src="#(tLogo)#"/></td>
		<td style="color:#F0F0F0;font-size:18pt;text-shadow:2px 2px 1px #808080;">#(tTitle)#</td></tr></table>
		</div>>

		&html<<div class="tableTitle">#($$$TextHTML("KPI","%DeepSee"))#</div>>
		&html<<table border="0" cellspacing="0" class="tableKPI">>
		&html<<tr><td><b>#($$$TextHTML("Class","%DeepSee"))#</b></td><td>#($ZCVT(..%ClassName(1),"O","HTML"))#</td></tr>>
		&html<<tr><td><b>#($$$TextHTML("Name","%DeepSee"))#</b></td><td>#($ZCVT(tKPIName,"O","HTML"))#</td></tr>>
		&html<<tr><td title="#(hlpCaption)#"><b>#($$$TextHTML("Caption","%DeepSee"))#</b></td><td>#($ZCVT(tKPICaption,"O","HTML"))#</td></tr>>
		&html<</table>>

		// use a dataController to drive the KPI
		New %datacontroller
		Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
		Set %datacontroller = tController
		Set tController.modelClass = ..%ClassName(1)
		// this lets us pass in a worksheet name
		Set tController.modelId = $G(%request.Data("ID",1))

		Set tController.criteria = ##class(%ZEN.proxyObject).%New()
		Set tCriteria = tController.criteria

		Set tFilterCount = 0
		Set f = $O(tFilters(""))
		While (f'="") {
			Set tFilterCount = tFilterCount + 1
			Set tDependsOn = $LG(tFilters(f),5)
			If (tDependsOn'="") {
				Set tName = $LG(tFilters(f),1)
				Set tFilterDepends(tName,tDependsOn) = ""
				Set tFilterMasters(tDependsOn,tName) = ""
			}
			Set f = $O(tFilters(f))
		}
		Set tFiltersMsg = $$$FormatText($$$Text("%1 filter(s)","%DeepSee"),tFilterCount)

		&html<<div class="tableTitle">#($$$TextHTML("Filters","%DeepSee"))#&nbsp;&nbsp;&nbsp;<span style="color:#606060; font-size:0.8em;">#(tFiltersMsg)#</span></div>>
		&html<<form id="theForm">>
		&html<<table border="0" cellspacing="0" class="tableValue">>
		&html<<tr>>
		Set f = $O(tFilters(""))
		While (f'="") {
			Set tCaption = $LG(tFilters(f),2)
			Set:tCaption="" tCaption = $LG(tFilters(f),1)
			&html<<td><b>#($ZCVT(tCaption,"O","HTML"))#&nbsp;&nbsp;<b></td>>
			Set f = $O(tFilters(f))
		}
		&html<</tr>>
		&html<<tr>>

		// get list of current filter values
		Kill tFilterValues
		Set f = $O(tFilters(""))
		While (f'="") {
			Set tFilterName = $LG(tFilters(f),1)
			Set tValue = $G(%request.Data(tFilterName,1))
			Set tFilterValues(tFilterName) = tValue
			Set f = $O(tFilters(f))
		}

		// draw filter controls
		// JMD1390: use combo if there is a list, otherwise text
		Set fc = 0
		Set f = $O(tFilters(""))
		While (f'="") {
			Set fc = fc + 1
			Set tFilterName = $LG(tFilters(f),1)
			Set tSC = ..%GetFilterMembers(tFilterName,.tMembers,.tDefaultValue,,,.tFilterValues)
			If $$$ISERR(tSC) Quit

			Set tChange = ""
			If $D(tFilterMasters(tFilterName)) {
				Set tList = ""
				Set k = $O(tFilterMasters(tFilterName,""))
				While (k'="") {
					If (k'=tFilterName) {
						Set tList = tList _ $S(tList="":"",1:",") _ k
					}
					Set k = $O(tFilterMasters(tFilterName,k))
				}
				Set tChange = "onchange=""updateFilters('"_$ZCVT(tFilterName,"O","JS")_"',this.value,'"_$ZCVT(tList,"O","JS")_"');"""
			}
			
			// JMD1390
			&html<<td>>
			Set tValue = $G(%request.Data(tFilterName,1))
			Set:tValue="" tValue = tDefaultValue
			Set $zobjproperty(tCriteria,tFilterName) = tValue
			If ('$D(tMembers)) {
				// text box
				&html<#(tChange)#<input type="search" id="select_#(tFilterName)#" value="#($ZCVT(tValue,"O","HTML"))#" name="#(tFilterName)#" #(tChange)# size="8"/>>
			}
			Else {
				// combo
				&html<<select id="select_#(tFilterName)#" name="#(tFilterName)#" #(tChange)#>>
				If (tDefaultValue="") {
					&html<<option/>>
				}
				Set m = $O(tMembers(""))
				While (m'="") {
					Set tMemberName = $LG(tMembers(m),1)
					Set tMemberValue = $LG(tMembers(m),2)
					&html<<option #($S(tValue=tMemberValue:"selected=""1""",1:""))# value="#($ZCVT(tMemberValue,"O","HTML"))#">#($ZCVT(tMemberName,"O","HTML"))#</option>>
					Set m = $O(tMembers(m))
				}
				&html<</select>>
			}
			&html<</td>>
			Set f = $O(tFilters(f))
		}
		&html<<tr><td style="border-top: 1px solid gray;" colspan="#(fc)#"><input type="submit"/></td></tr>>
		&html<</table>>
		&html<</form>>
		If $$$ISERR(tSC) Quit
		
		// aquire data from KPI
		Set tSC = tController.%AcquireData()
		If $$$ISERR(tSC) Quit

		If (tController.modelError'="") {
			&html<<div style="padding:5px;">Error getting data from KPI:</div>>
			&html<<div style="padding:5px;color:darkred;">#($ZCVT(tController.modelError,"O","HTML"))#</div>>
		}

		Set tModel = tController.%model

		Set tSC = tController.%GetModelPropertyInfo(.tPropInfo)
		If $$$ISERR(tSC) Quit

		// sort prop info; remove % properties
		Set tProp = $O(tPropInfo(""))
		While (tProp'="") {
			If (tProp '[ "%") {
				Set tInfo(tPropInfo(tProp)) = tProp
			}
			Set tProp = $O(tPropInfo(tProp))
		}
		&html<</tr>>

		// get query used for KPI
		Set tQuery = ""
		Set tSourceType = tModel.%GetSourceType()
		If (tSourceType="mdx") {
			Set tSC = tModel.%GetMDX(.tQuery)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tSourceType="sql") {
			Set tSC = tModel.%GetSQL(.tQuery)
			If $$$ISERR(tSC) Quit
		}
		Else {
			// try each type
			Set tSC = tModel.%GetMDX(.tQuery)
			If $$$ISERR(tSC) Quit
			If (tQuery = "") {
				Set tSC = tModel.%GetSQL(.tQuery)
				If $$$ISERR(tSC) Quit
			}
		}

		If (tQuery'="") {
			&html<<div class="tableTitle">#($$$TextHTML("Query","%DeepSee"))#: <span style="color:#404080;">#(tSourceType)#</span></div>>
			&html<<div class="query">#($ZCVT(tQuery,"O","HTML"))#</div>>
		}
		If (tModel.%fromCache) {
			&html<<div style="color:#606060;font-size:10px;margin-left:20px;">Results served from KPI cache.</div>>
		}

		/// JMD900
		If (tModel.%IsCacheable()) {
			&html<<form style="margin:20px;"><input type="hidden" name="clear" value="1"/><input type="submit" Value="Clear KPI Cache"/></form>>

			// take a peek at the cache
			Set tClass = $$$UPPER(tModel.%ClassName(1))
			Set tCacheKey = tModel.%cacheKey
			If ((tClass'="")&&(tCacheKey'="")) {
				Set tPctComplete = $G($$$DeepSeeKPIGLVN(tClass,tCacheKey,"pctComplete"))
				If (tPctComplete<100) {
					Write "<div style=""margin:20px;color:darkblue;"">Computing... ",$FNumber(tPctComplete,",",2),"% Complete</div>",!
					Write "<script language=""javascript"">window.setTimeout('self.document.location.reload();',1000);</script>",!
				}
			}
		}

		Set tSeriesCount = tController.dataBag.seriesCount
		Set tSCMsg = $$$FormatText($$$Text("%1 series","%DeepSee"),tSeriesCount)

		&html<<div class="tableTitle">#($$$TextHTML("KPI Values","%DeepSee"))#&nbsp;&nbsp;&nbsp;<span style="color:#606060; font-size:0.8em;">#(tSCMsg)#</span></div>>
		&html<<table border="0" cellspacing="0" class="tableValue">>
		&html<<tr>>
		&html<<th>#($$$TextHTML("Series","%DeepSee"))#</th>>
		Set tProp = $O(tInfo(""))
		While (tProp'="") {
			&html<<th>#($ZCVT(tInfo(tProp),"O","HTML"))#</th>>
			Set tProp = $O(tInfo(tProp))
		}
		&html<</tr>>

		Set tSeriesNames = ""
		For r=1:1:tSeriesCount {
			&html<<tr style="background:#($S(r#2:"#F0F0F0;",1:"white"))#;">>
			Set tName = $G(tModel.%seriesNames(r))
			&html<<td>#($ZCVT(tName,"O","HTML"))#</td>>
			Set tProp = $O(tInfo(""))
			While (tProp'="") {
				Set tValue = tController.dataBag.%GetValue(tInfo(tProp),r)
				If (tValue=$$$ZENMISSING) {
					Set tValue = "<null>"
				}
				Set tDisp = $E(tValue,1,50)_$S($L(tValue)>50:"...",1:"")
				&html<<td title="#($ZCVT(tValue,"O","HTML"))#" #($S($IsValidNum(tValue):"style=""text-align:right;""",1:""))#>#($ZCVT(tDisp,"O","HTML"))#&nbsp;</td>>
				Set tProp = $O(tInfo(tProp))
			}
			&html<</tr>>
		}
		&html<</table>>
		&html<<br/>>
		&html<</body>
		</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the current user has access to this KPI.
ClassMethod %CheckResource() As %Boolean
{
	Quit $S(..#RESOURCE="":1,1:$System.Security.Check(..#RESOURCE,"U"))
}

/// Return the logical name in its original form for this KPI.
/// <var>pName</var> is the canonic form of the name.
ClassMethod %GetKPIName(pName As %String = "") As %String
{
	Quit ""
}

/// Return the caption as defined in the XML for this KPI.
ClassMethod %GetKPICaptionName(pName As %String = "") As %String
{
	Quit ..%GetKPIName(pName)
}

/// Return the caption for this KPI.<br/>
/// This is either: (a) the value returned by <method>%OnGetKPICaption</method>,
/// (b) the value of the caption attribute in the KPI definition, or (c) the name of the KPI,
/// in that order.
ClassMethod %GetKPICaption() As %String [ Final ]
{
	Set tCaption = ..%OnGetKPICaption()
	If (tCaption="") {
		Set tCaption = ..%GetKPICaptionName()
	}
	If (tCaption="") {
		Set tCaption = ..%GetKPIName()
	}
	Quit tCaption
}

/// This callback can return the (localized) caption for this KPI.
ClassMethod %OnGetKPICaption() As %String
{
	Quit ""
}

/// This callback, if implemented, returns the text of an SQL query used to provide
/// a "detail listing" for this KPI.<br/>
/// <var>pFilters</var> is an array of current filter values: pFilters(name)=value.<br/>
/// <var>pSelection</var> is an array containing information about the current selected items in the pivot.
/// It contains 2 values:<br/>
/// pSelection("selectedRange") contains the current selected cells in the pivot as a string in the form
/// "startRow,startCol,endRow,endCol" (1-based). "" if no cells are selected.<br/>
/// pSelection("rowValues") contains a csv-list of "row" values for the selected rows in the pivot (similar
/// to the $$$VALUELIST value used for OpenWindow URLs. This may contain "\," for "," within the data values.<br/>
/// <var>pListingName</var> is the name of the listing to display. This is reserved for future use.<br/>
/// This method is simply a convenient alternative to the <method>%OnGetListingResultSet</method> method.
/// It takes precedence over the <method>%OnGetListingResultSet</method> method.
ClassMethod %OnGetListingSQL(ByRef pFilters As %String, ByRef pSelection As %String, pListingName As %String = "") As %String
{
	Quit ""
}

/// This callback, if implemented, can prepare and execute
/// a listing query used to provide a "detail listing" for this KPI.
/// <var>pFilters</var> is an array of current filter values.<br/>
/// <var>pListingName</var> is the name of the listing to display. This is reserved for future use.<br/>
ClassMethod %OnGetListingResultSet(ByRef pFilters As %String, ByRef pSelection As %String, pListingName As %String = "", Output pRS As %SQL.StatementResult) As %Status
{
	Set pRS = ""
	Quit $$$OK
}

/// Return the sourceType for this KPI
ClassMethod %GetSourceType() As %String
{
	Quit "manual"
}

/// Apply property defaults from the KPI model.
Method %ApplyDefaults()
{
	Quit $$$OK
}

/// This callback method does the actual work of loading values from the source object.
Method %OnLoadModel(pSource As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		If ($IsObject($G(%dataController))&&$IsObject(%dataController.criteria)) {
			Set ..%filterValues = %dataController.criteria
		}
		Else {
			// point to empty object as a convenience
			Set ..%filterValues = ##class(%ZEN.proxyObject).%New()
		}
		Do ..%ApplyDefaults()

		// pick up cell context if present
		Kill ..%cellContext
		Merge ..%cellContext = %dsCellContext

		// manual
		Set tSC = ..%OnExecute()
		If $$$ISERR(tSC) Quit

		// notify
		Set tSC = ..%OnLoadKPI()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Notify subclass that KPI is has just be executed.
/// This is a good place to override properties, such as range and threshold.
Method %OnLoadKPI() As %Status
{
	Quit $$$OK
}

/// Return the display name for a property within this KPI.
ClassMethod %GetKPIPropertyCaption(pProperty As %String) As %String
{
	Set tCaption = pProperty
	Set tSC = ..%GetKPIPropertyInfo(.tListProperty)
	Set k = $O(tListProperty(""))
	While (k'="") {
		If ($$$UPPER(pProperty)=$$$UPPER(tListProperty(k))) {
			Set tCaption = $G(tListProperty(k,"caption"),tCaption)
			Quit
		}
		Set k = $O(tListProperty(k))
	}
	Quit tCaption
}

/// Return list of properties. This is part of the DataModel API; this version returns the set of properties
/// defined by this KPI.
ClassMethod %OnGetPropertyInfo(pIndex As %Integer, ByRef pList As %String, pExtended As %Boolean = 0, pModelId As %String = "") As %Status [ Final ]
{
	Try {
		Set tSC = ..%GetKPIPropertyInfo(.tList,pModelId)
		If $$$ISERR(tSC) Quit

		// convert KPI list to DataModel list
		Set k = $O(tList(""))
		While (k'="") {
			Set tName = $G(tList(k))
			If (tName'="") {
				Set pList(tName) = $I(pIndex)
				// JMD997 pick up caption if present
				Set:$G(tList(k,"caption"))'="" pList(tName,"label") = tList(k,"caption")
			}
			Set k = $O(tList(k))
		}
	}
	Catch(ex) {
		Set ^%err = $ZE
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return information on properties defined in the KPI block.
/// This takes the form:<br/>
/// pList(n) = name<br/>
/// pList(n,"caption") = displayed caption<br/>
/// pList(n,"defaultValue") = value<br/>
/// pList(n,"columnNo") = #<br/>
ClassMethod %GetKPIPropertyInfo(Output pList As %String, pModelId As %String = "") As %Status [ Internal ]
{
	Quit ..%OnGetKPIPropertyInfo(.pList,1,pModelId)
}

/// Add additional properties beyond those defined in the KPI block.
/// This takes the form:<br/>
/// pList(n) = name<br/>
/// pList(n,"defaultValue") = value<br/>
/// pList(n,"columnNo") = #<br/>
/// <var>pPropNo</var> is the number of next open slot in the list.
ClassMethod %OnGetKPIPropertyInfo(ByRef pList As %String, pPropNo As %Integer, pModelId As %String = "") As %Status
{
	Quit $$$OK
}

/// Get data for this KPI manually.
/// This is implemented by subclasses that provide manual data.
Method %OnExecute() As %Status
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of possible filters for this KPI.
/// This drives the list of filter selections for widget connected to this KPI.
/// This takes the form:<br/>
/// pFilters(n)=$LB(name,caption,filterProperty,multiSelect,dependsOn)<br/>
ClassMethod %GetFilterList(Output pFilters As %List, pDataSourceName As %String = "") As %Status [ Internal ]
{
	Kill pFilters
	Quit ..%OnGetFilterList(.pFilters,pDataSourceName)
}

/// Callback to get additional possible filters for this KPI.
/// This drives the list of filter selections for widget connected to this KPI.
/// This takes the form:<br/>
/// pFilters($I(pFilters))=$LB(name,caption,value,multiSelect,dependsOn)<br/>
ClassMethod %OnGetFilterList(Output pFilters As %List, pDataSourceName As %String = "") As %Status
{
	Quit $$$OK
}

/// Return a list of possible filter values for a given filter.
/// This takes the form:<br/>
/// pMembers(n)=$LB(text,value)<br/>
ClassMethod %GetFilterMembers(pFilter As %String, Output pMembers As %List, Output pDefaultValue As %String, pSearchKey As %String = "", pDataSourceName As %String = "", ByRef pFilterValues As %String) As %Status [ Internal ]
{
	Kill pMembers
	Quit ..%OnGetFilterMembers(pFilter,.pMembers,pSearchKey,pDataSourceName,.pFilterValues)
}

/// Callback to get additional members for a KPI filter.
/// This takes the form:<br/>
/// pMembers($I(pMembers))=$LB(text,value)<br/>
/// <var>pSearchKey</var> is the search key entered by the user, if applicable.<br/>
/// <var>pFilterValues</var> is an array of all current filter values.<br/>
ClassMethod %OnGetFilterMembers(pFilter As %String, Output pMembers As %List, pSearchKey As %String = "", pDataSourceName As %String = "", ByRef pFilterValues As %String) As %Status
{
	Quit $$$OK
}

/// Given a filter and its logical value, return its display value.
ClassMethod %GetFilterDisplayValue(pFilter As %String, pValue As %String, pDataSourceName As %String = "") As %String
{
	Set tText = pValue
	If (pValue'="") {
		Do ..%GetFilterMembers(pFilter,.tMembers,,,pDataSourceName)
		Set k = $O(tMembers(""))
		While (k'="") {
			If ($LG(tMembers(k),2)=pValue) {
				Set tText = $LG(tMembers(k),1)
				Quit
			}
			Set k = $O(tMembers(k))
		}
	}

	Quit tText
}

/// Given a filter and its display value (<var>pText</var>), return its logical value.
/// If there is not a one-to-one correspondence for logic and display values, then the result
/// of this call is indeterminate.
ClassMethod %GetFilterLogicalValue(pFilter As %String, pText As %String, pDataSourceName As %String = "", ByRef pFilterValues) As %String
{
	Set tValue = pText
	If (pText'="") {
		// JMD1124: special case for [%cube] && [%measure]
		// to avoid double conversion
		If ((pFilter="%cube")&&($E(pText,1)="[")&&($E(pText,*)="]")) {
			Quit pText
		}
		ElseIf ((pFilter="%measure")&&($E(pText,1)="[")&&($E(pText,*)="]")) {
			Quit pText
		}

		Set pText = $$$UPPER(pText)
		Do ..%GetFilterMembers(pFilter,.tMembers,,,pDataSourceName,.pFilterValues)
		Set k = $O(tMembers(""))
		While (k'="") {
			If ($$$UPPER($LG(tMembers(k),1))=pText) {
				Set tValue = $LG(tMembers(k),2)
				Quit
			}
			Set k = $O(tMembers(k))
		}
	}
	Quit tValue
}

/// Return list of possible actions for this KPI.
/// This drives the list of action selections for widget connected to this KPI.
/// This takes the form:<br/>
/// pActions(n)=$LB(name,caption)<br/>
ClassMethod %GetActionList(ByRef pActions As %List, pDataSourceName As %String = "") As %Status [ Internal ]
{
	// n.b., pActions may already have items in it!
	Quit ..%OnGetActionList(.pActions, pDataSourceName)
}

/// Callback to get additional actions for a KPI.
/// This takes the form:<br/>
/// pActions($I(pActions))=$LB(name,caption)<br/>
ClassMethod %OnGetActionList(ByRef pActions As %List, pDataSourceName As %String = "") As %Status
{
	Quit $$$OK
}

/// Internal method that gets invoked from a client dashboard and dispatches to a user callback.
ClassMethod %InvokeDashboardAction(pAction As %String, pContext As %ZEN.proxyObject, pDataSourceName As %String = "") As %Status [ Internal ]
{
	Quit ..%OnDashboardAction(pAction,pContext,pDataSourceName)
}

/// This callback is invoked from a dashboard when an action defined by this dashboard is invoked.<br/>
/// <var>pAction</var> is the logical name of the action.<br/>
/// <var>pContext</var> is a proxy object that contains various information about the action and
/// provides a way for the method to return information to the client.
ClassMethod %OnDashboardAction(pAction As %String, pContext As %ZEN.proxyObject, pDataSourceName As %String = "") As %Status
{
	Quit $$$OK
}

/// Return true if this kpi should be computed asynchronously (for plug-ins).
ClassMethod %IsAsync() As %Boolean
{
	Quit 0
}

/// Return the cube this KPI is based on.
ClassMethod %IsCacheable() As %String
{
	Quit 0
}

/// Get a specific value from this KPI.<br/>
/// This is best used with simple KPIs implemented in manual mode as it can be expensive otherwise.<br/>
/// On return, <var>pPctComplete</var> indicates whether this value is completely computed (100) or
/// in progress (that is, it is being computed by a background agent).<br/>
/// <var>pCacheKey</var> is the cache key associated with this request in the case of an
/// asynchronous KPI. This is returned by reference.<br/>
/// <var>pFilters</var> is an array of filters and their (display) values.<br/>
/// <var>pCellContext</var> is the cell context passed in by the %KPI function.<br/>
ClassMethod %GetKPIValue(pKPIName As %String, Output pValue As %String, pKPIProperty As %String = "", pSeries As %String = "", ByRef pFilters As %String, pCellContext As %String = "", ByRef pCacheKey As %String, Output pPctComplete As %Integer, pParentQueryKey As %String = "", Output pKPIStatus As %Status) As %Status
{
	Set tSC = $$$OK
	Try {
		New %dsKPIError
		Set %dsKPIError = $$$OK

		// JMD900: add % complete
		Set pPctComplete = 100
		Set pValue = ""
		// + WAL068
		If ($G(pCacheKey)="") { 
			Set pCacheKey = ""
			Set tCacheKeyNotInitialized = 1
		}
		// - WAL068
		If (pKPIProperty = "") {
			Quit
		}

		// If we are given a cache key, use it to test for % complete
		If (pCacheKey'="") {
			Set tClass = $$$UPPER(..%ClassName(1))
			If ((tClass'="")&&(pCacheKey'="")) {
				Set pPctComplete = $G($$$DeepSeeKPIGLVN(tClass,pCacheKey,"pctComplete"),100)

				// JMD1390 - is someone else working on this?
				If $D($$$DeepSeeKPIGLVN(tClass,pCacheKey,"zprocessingkpi")) {
					Set pValue = "@Computing "_$FN(pPctComplete,",",2)_"%"
					Quit
				}
			}
		}

		If (pPctComplete >= 100) {
			// JMD1124 make sure %cube is passed along
			Set:$D(pFilters("%cube")) tFilterValues("%cube") = pFilters("%cube")

			// convert filter display values to logical
			Kill tFilters
			Set k = $O(pFilters(""))
			While (k'="") {
				Set tFilters(k) = ..%GetFilterLogicalValue(k,pFilters(k),,.tFilterValues)
				Set k = $O(pFilters(k))
			}

			// create a data controller to drive the KPI
			Set tSC = ..%CreateKPIController(.tController,pKPIName,.tFilters,pCellContext,pParentQueryKey)
			If $$$ISERR(tSC) Quit

			Set tModel = $S($IsObject(tController):tController.%model,1:"")
			
			// Find series number
			Set tSeriesNo = $S(pSeries="":1,1:+pSeries)
			If (pSeries'="") {
				Set tName = $$$UPPER(pSeries)
				// test for series with name of pSeries
				If $IsObject(tModel) {
					Set k = $O(tModel.%seriesNames(""))
					While (k'="") {
						If (tName=$$$UPPER(tModel.%seriesNames(k))) {
							Set tSeriesNo = k
							Quit
						}
						Set k = $O(tModel.%seriesNames(k))
					}
				}
			}

			// Test for async value not yet computed
			If ($IsObject(tModel) && tModel.%IsCacheable()) {
				// take a peek at the cache
				Set tClass = $$$UPPER(tModel.%ClassName(1))
				Set tCacheKey = tModel.%cacheKey
				If ((tClass'="")&&(tCacheKey'="")) {
					Set pPctComplete = $G($$$DeepSeeKPIGLVN(tClass,tCacheKey,"pctComplete"),100)
					Set pCacheKey = tCacheKey
				}
			}
		}

		// get value
		If (pPctComplete >= 100) {
			Set pValue = tController.dataBag.%GetValue(pKPIProperty,tSeriesNo)
			If (pValue=$$$ZENMISSING) {
				// + WAL068 -- if we queued the kpi task don't trust this value
				If ($G(tModel) && $IsObject(tModel) && tModel.%IsCacheable() && tModel.%IsAsync() && $G(tCacheKeyNotInitialized)) {
					Set pValue = "@Computing "_$FN(pPctComplete,",",2)_"%"
				}
				Else {
					Set pValue = ""
				}
				// - WAL068
			}
		}
		Else {
			Set pValue = "@Computing "_$FN(pPctComplete,",",2)_"%"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Set pKPIStatus = %dsKPIError		// DTB524 - Return direct status
	
	// Return error as value
	If $$$ISERR(%dsKPIError) {
		Set pValue = $System.Status.GetErrorText(%dsKPIError)
		Set tSC = $$$OK
	}

	// Return error as value
	If $$$ISERR(tSC) {
		Set pValue = $System.Status.GetErrorText(tSC)
		Set tSC = $$$OK
	}
	Quit tSC
}

/// Get the value of the given KPI property and print it to the console.<br/>
/// This is provided as a diagnostic aid for KPIs.
/// The KPI is forced to execute in the foreground, even if it is defined to be asynchronous,
/// unless <var>pAsync</var> is set to true (1).
ClassMethod %PrintValue(pKPIProperty As %String = "", pSeries As %String = "", ByRef pFilters As %String, pAsync As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	New %dsKPISync
	Set %dsKPISync = 'pAsync
	Set tValue = ""
	If (pKPIProperty="") {
		// Use all
		Do ..%GetKPIPropertyInfo(.tList)
	}
	Else {
		Set tList(1) = pKPIProperty
	}
	Set k = $O(tList(""))
	While (k'="") {
		Set tSC = ..%GetKPIValue(..%GetKPIName(),.tValue,tList(k),pSeries,.pFilters)
		Write tList(k),?25,tValue,!
		If $$$ISERR(tSC) Quit
		Set k = $O(tList(k))
	}
	Quit tSC
}

/// Set up the context for and execute this KPI.
/// Return the instance of data controller used to drive the KPI.
ClassMethod %CreateKPIController(Output pController As %ZEN.Auxiliary.dataController, pKPIName As %String, ByRef pFilters As %String, pCellContext As %String = "", pParentQueryKey As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set pController = ""
		
		// use a dataController to drive the KPI
		New %datacontroller
		New %page		// prevent temp components from being added to page!

		// pass cell context along, if needed
		New %dsCellContext
		If (pCellContext'="") {
			// split context by ";", unescape
			Set tContext = $Replace(pCellContext,";;",$C(0))
			For p=1:1:$L(tContext,";") {
				Set tSpec = $Replace($P(tContext,";",p),$C(0),";")
				Set:tSpec'="" %dsCellContext(p) = tSpec
			}
		}

		Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
				
		Set %datacontroller = tController
		Set tController.modelClass = ..%ClassName(1)
		Set tController.modelId = ""
		
		// + WAL203
		New %parentQueryKey
		Set %parentQueryKey = pParentQueryKey
		// - WAL203

		// Return controller
		Set pController = tController

		Set tExt = $P(pKPIName,".",$L(pKPIName,"."))
		If ((tExt'="kpi")) {
			Set tController.modelId = pKPIName
		}

		// apply filter values
		If ($D(pFilters)) {
			Set tController.criteria = ##class(%ZEN.proxyObject).%New()
			Set tCriteria = tController.criteria

			Set tFilterName = $O(pFilters(""))
			While (tFilterName'="") {
				Set $zobjproperty(tCriteria,tFilterName) = $G(pFilters(tFilterName))
				Set tFilterName = $O(pFilters(tFilterName))
			}
		}

		// aquire data from KPI
		// this will lead to %OnLoadModel being called
		Set tSC = tController.%AcquireData()
		If ($$$ISERR(tSC)||(tController.modelError'="")) {
			// return error to caller
			If (tController.modelError'="") {
				Set pValue = tController.modelError
				Set tSC = $$$OK
			}
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Get an array of values from this KPI.<br/>
/// <var>pPropertyList</var> is a $List of property names: $LB(prop1,prop2).
/// On return, <var>pValues</var> contains an array of values of the properties listed in <var>pPropertyList</var>:
/// pValues(n) = $LB(prop1,prop2)<br/>
/// Use "%series" in property list to get the series name<br/>.
ClassMethod %GetKPIValueArray(pKPIName As %String, Output pValues As %String, pPropertyList As %List, ByRef pFilters As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pValues
		If (pPropertyList = "") {
			Quit
		}
		Set tPropCount = $LL(pPropertyList)
		If (tPropCount = 0) {
			Quit
		}

		// create a data controller to drive the KPI
		Set tCellContext = ""
		Set tSC = ..%CreateKPIController(.tController,pKPIName,.pFilters,tCellContext)
		If $$$ISERR(tSC) Quit

		// aquire data from KPI
		Set tSC = tController.%AcquireData()
		If $$$ISERR(tSC) Quit

		Set tModel = tController.%model
		If $IsObject(tModel) {
			Set tCount = 0
			// loop over series;
			Set k = $O(tModel.%seriesNames(""))
			While (k'="") {
				Set tItem = ""
				Set tCount = tCount + 1
				// get property values for this series
				For n=1:1:tPropCount {
					Set tPropName = $LG(pPropertyList,n)
					If ($$$LOWER(tPropName)="%series") {
						// JMD1276
						Set tValue = $G(tModel.%seriesNames(k))
					}
					Else {
						Set tValue = tController.dataBag.%GetValue(tPropName,tCount)
						If (tValue=$$$ZENMISSING) {
							Set tValue = ""
						}
					}
					Set $List(tItem,n) = tValue
				}
				Set pValues(tCount) = tItem

				Set k = $O(tModel.%seriesNames(k))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an MDX statement to provide the KPI data.
Method %GetMDX(Output pMDX As %String) As %Status [ Internal ]
{
	Quit ""
}

/// Return an MDX statement to provide the KPI data.
Method %GetSQL(Output pSQL As %String) As %Status [ Internal ]
{
	Quit ""
}

/// Utility method.
/// Clear all KPI cache entries for this KPI.
ClassMethod %ClearKPICache() As %Status
{
	Kill $$$DeepSeeKPIGLVN($$$UPPER(..%ClassName(1)))
	Quit $$$OK
}

/// Utility method.
/// Compute a hash code based on the current filter values for this KPI.
/// This is used for caching KPI results.
Method %GetFilterKey() As %String
{
	Set tFilterKey = ""

	If $IsObject(..%filterValues) {
		Do ..%filterValues.%CopyToArray(.tValues)
		Set tText = ""
		Set k = $O(tValues(""))
		While (k'="") {
			If ($G(tValues(k))'="") {
				Set tText = tText_k_":"_tValues(k)_";"
			}
			Set k = $O(tValues(k))
		}

		Set:tText'="" tFilterKey = $ZCRC(tText,7)
	}

	Quit tFilterKey
}

/// Utility method.
/// Create a local instance of data controller to drive the KPI.
/// This is used to get values from a KPI on the server.
ClassMethod %CreateLocalController(Output pController As %ZEN.Auxiliary.dataController, pModelClass As %String, pModelId As %String, pCriteria As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill %objlasterror
		Set pController = ##class(%ZEN.Auxiliary.dataController).%New()
		Set pController.modelClass = pModelClass
		Set pController.modelId = pModelId
		Set pController.criteria = pCriteria

		// aquire data from KPI
		Set tSC = pController.%AcquireData()
		If $$$ISERR(tSC) Quit

		If $$$ISERR($G(%objlasterror,$$$OK)) {
			Set tSC = %objlasterror
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the last modified date for this KPI class.
ClassMethod %GetKPIClassTimeStamp() As %String
{
	// JMD1495
	If (+..#FORCECOMPUTE) {
		Quit ""
	}
	// JMD945: Use mod date as class timestamp
	Quit $$$defClassKeyGet(..%ClassName(1),$$$cCLASStimechanged)
}

}
