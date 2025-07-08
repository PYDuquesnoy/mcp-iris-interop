/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides validation and dispatch for version 2 of the DeepSee REST services
/// 
/// For /Command calls, required arguments are expected in the request body. Every request is treated as a POST request (including those 
/// that only fetch values) This is to prevent running into the error where the number of characters in the URL exceeds the limit.
/// 
/// For /Data and /Info calls, required arguments are expected in the URL. The exceptions to this rule are /Data/MDXExecute and
/// /Data/PivotExecute, which require an argument POSTed to the the body of the request.
/// For some services, the client may POST additional parameters
/// in the body of the request. The description for each service outlines the parameters accepted for that particular service.
/// In all services, unknown parameters that are included in the request body are ignored.<br><br>
/// <b>Example:</b> Execute an MDX query using an HTTP POST request, sent to a web application with Dispatch class <b>%DeepSee.REST.v2</b>.
/// <example language="javascript">		var request = {};
/// 		var mdx = 'SELECT ' +
/// 			  '  NON EMPTY [Product].[P1].[Product Category].Members ON 0,' +
/// 			  '  NON EMPTY [Outlet].[H1].[Region].Members ON 1 ' +
/// 			  'FROM [HoleFoods]'
/// 		request.method = 'POST';
/// 		request.user = 'user';
/// 		request.passwd = 'pass';
/// 		request.acceptType = 'JSON';
/// 		request.contentType = 'JSON';
/// 		request.body = '{"MDX":"' + mdx + '"}';
/// 		request.callback = custom.queryCallBack
/// 		request.async = true;
/// 		request.url = 'http://host/port/restApplication/v2/Data/MDX';
/// 
/// 		// run the query
/// 		var xhr = new XMLHttpRequest();
/// 		xhr.open(request.method,request.url,request.async);
/// 
/// 		// kick off the request
/// 		xhr.send(contents);</example>
/// Requests may be sent to the following services:<br> <ul>
///     <li>/Data/TestConnection or /Info/TestConnection - get test info to confirm connection to the server.</li> 
///     <li>/Data/MDXExecute - get result in JSON format for MDX query. POST the query in the required property "MDX". The server will assume
/// 			the client wishes to wait for complete results before sending a response. The default timeout for this wait
/// 			is 2 seconds less than the session's timeout setting. This can be set using the TIMEOUT property in the 
/// 			request. <br>The client can optionally instruct the server to send partial results by POSTing "WAIT":0. 
/// 		<example language="javascript"> request.body = '{ "MDX": "SELECT FROM PATIENTS",' +
/// 		'  "FILTERS": [' +
/// 		'   "[HomeD].[H1].[ZIP].&[32006]",' +
/// 		'   "%OR({[PatGrpD].[H1].[Patient Group].&[Group A],[PatGrpD].[H1].[Patient Group].&[Group B]})"' +
/// 		'  ]' +
/// 		'  "WAIT":1' +
/// 		'  "TIMEOUT":30' +
/// 		'};'</example></li>
///     <li>/Data/PivotExecute - get result in JSON format for a stored pivot table. POST the full name (Folder/SubFolder/Name) of the 
/// 				table in the required property "PIVOT". Filters may be 
/// 			optionally be POSTed in the FILTERS property of the request. These filters take the identical
/// 			form as described in /Data/MDXExecute. This service also supports the WAIT and TIMEOUT options. A pivot
/// 			table that supports pivot variables may have those variables set using the VARIABLES array in the request.
/// 		<example language="javascript"> request.body = '{ "PIVOT":"Pivot Variables/Commission Calculator",' +
/// 		'  "VARIABLES": [' +
/// 		'   "name":"commissionpercentage",' +
/// 		'   "value":15' +
/// 		'  ]' +
/// 		'};'</example></li>
/// 	<li>/Data/KPIExecute - execute a KPI. POST the logical name of KPI in "KPI". Filters may be added as an array of
/// 			objects in "FILTER". Each of the filter objects must provide a "name" and a "value" property.
/// 		<example language="javascript"> request.body = '{ "KPI": "DemoMDX",' +
/// 		'  "FILTERS": [ {' +
/// 		'    "name" : "[aged].[h1].[age group]",' +
/// 		'    "value" : "&[0 to 29]" }' +
/// 		'  ]' +
/// 		'};'</example></li>
///     <li>/Data/MDXDrillthrough - execute a detail listing on the cube's source class. POST the query in "MDX".
/// 			DRILLTHROUGH requests will support a list of RETURN fields in the request, or a choice of LISTING. 
/// 			Attempting to post both will result in an error.
/// 		<example language="javascript"> request.body = '{ "MDX": "DRILLTHROUGH SELECT FROM [PATIENTS]",' +
/// 		'  "LISTING":"Doctor details"' +
/// 		'};'</example>
/// 		<example language="javascript"> request.body = '{ "MDX": "DRILLTHROUGH SELECT FROM [PATIENTS]",' +
/// 		'  "RETURN":"Age,BirthDate"' +
/// 		'};'</example></li>
/// 	<li>/Data/MDXCancelQuery/:queryID - if a previous query has not completed, it can be canceled.</li>
/// 	<li>/Data/MDXUpdateResults/:queryID - given a previous query response with ResultsComplete = 0, the client can request an update to the results
/// 			using the cubeKey and queryKey.</li>
/// 
/// 	<li>/Info/Filters/:dataSource - to get a list of filters available for a particular cube.</li>
/// 	<li>/Info/FilterMembers/:dataSource/:filterSpec/ - get a list of values for a particular filter. Supported dataSources 
/// 				are cubes and KPIs.
/// 			Values can be limited by POSTing values of other filters or a search key in the request.<br>
/// 		<example language="javascript"> request.body = '{ "RELATED": [' +
/// 		'    {' +
/// 		'      "spec": "[DateOfSale].[Actual].[YearSold]",' +
/// 		'      "value": "&[2013]:&[2016]"' +
/// 		'    }' +
/// 		'  ],' +
/// 		'  "SEARCHKEY":"Jan"' +
/// 		'}';</example></li>
/// 	<li>/Info/Cubes/ - get a list of cubes available in the namespace.</li>
/// 	<li>/Info/Pivots/ - get a list of pivots available. The listing can be limited
/// 			to pivots based on a particular cube by POST to the BASECUBE property in the request.
/// 		<example language="javascript">request.body = '{"BASECUBE":"HOLEFOODS"}'</example></li>
/// 	<li>/Info/Dashboards/ - get a list of available dashboards.</li>
/// 	<li>/Info/Listings/:cube - get a list of available listings for a particular cube.</li>
/// 	<li>/Info/Measures/:cube - get a list of measures available for a particular cube.</li>
/// 	<li>/Info/ListingFields/:cube - get the list of listing fields defined for a particular cube,
/// 			for user-defined custom listings.</li>
/// 	<li>/Info/NamedFilters/:cube - get a list of named filters defined for a cube.</li>
/// 	<li>/Info/PivotVariables/:cube - get a list of pivot variables defined a cube.</li>
/// 	<li>/Info/PivotVariableDetails/:cube/:variable - get the details for a single pivot variable.</li>
/// 	<li>/Info/QualityMeasures/:cube - get a list of quality measures available for the cube.</li>
/// 
/// 	<li>/Command/BuildCube - A wrapper for <method>%DeepSee.Utils.%BuildCube</method> which records cube event 
/// 			information when building the cube. </li>
/// 	<li>/Command/RepairBuild - This method provides a means of doing an unscheduled repair build
/// 			of a registered cube. </li>
/// 	<li>/Command/BuildAllRegisteredGroups -  This is a utility method which executes a complete 
/// 			build of all currently registered cubes in the current cube registry.</li>
/// 	<li>/Command/BuildOneRegisteredGroup - This is a utility method which executes a complete build of one 
/// 			registered cube group in the current cube registry.</li>
/// 	<li>/Command/SynchronizeCube -  A wrapper for <method>%DeepSee.Utils.%SynchronizeCube</method> which records 
/// 		cube event information when building the cube.</li>
/// 	<li>/Command/GetLastUpdate -  Retrieves the timestamp of the the last registered data update for the cube. Updates 
/// 		performed outside of the Cube Manager will not be recognized in this check. </li>
/// 	<li>/Command/GetActiveRegistry -  Retrieve the name of the Cube Registry currently marked Active</li>
/// 	<li>/Command/SetActiveRegistry -  Change which Cube Registry is currently active. The Active Registry is the 
/// 		only one that is visible to the updater tasks. </li>
/// 	<li>/Command/BuildRegistryMap -  Retrieve the map that describes the current state of the Cube Registry and 
/// 			all other unregistered cubes on the system.
///          For the lookup variable in the output JSON, for each array in the "cubes" object, the first value corresponds  
/// 		     to that the GroupIdx value and the second the CubeIdx value for that cube. The Cube can then be retrieved as follows:
/// 		     Set Cube = Map.Groups.GetAt(GroupIdx).Cubes.GetAt(CubeIdx)
/// 			Currently GroupIdx and CubeIdx are 1-indexed. Subtract 1 from GroupIdx asnd CubeIdx to make them work for a 0-indexed system</li>
/// 	<li>/Command/WriteToRegistry -  Walk through a CubeManager.RegistryMap object and register the cubes.</li>
/// 	<li>/Command/ScheduleUpdaterTasks -  Schedule the build and synch tasks according to the settings in a 
/// 			CubeManager.RegistryMap object.</li>
/// 	<li>/Command/GetSynchScheduleParameters - Convenience method -- takes the number of seconds between synchs
/// 			and sets the parameters for the call to ##class(%DeepSee.CubeManager.Task.Synch).Schedule</li>
/// 	<li>/Command/GetCubeSize -  Given the logical name, <var>pCubeName</var> of a DeepSee cube, return the number
/// 			of rows within its fact table.</li>
/// 	<li>/Command/IsValidGroup -  Boolean test which returns 1 if the group supplied as the argument is no 
/// 			less than the union of the natural groups of each of its members.</li>
/// 	<li>/Command/IsValidCubeSchedule -  Validation for the current cube settings.</li>
/// </ul>
Class %DeepSee.REST.v2 Extends %DeepSee.REST.REST
{

XData UrlMap
{
<Routes>
   <!-- Send objects in this format: {"MDX":"QUERY"} HTTP method: POST -->
   <Map Prefix="/Command" Forward="%DeepSee.REST.v2.CommandServer"/>
   <Map Prefix="/Data" Forward="%DeepSee.REST.v2.DataServer"/>
   <Map Prefix="/Info" Forward="%DeepSee.REST.v2.InfoServer"/>
</Routes>
}

/// Verfies required Converts request body 
ClassMethod %ValidateRequest(pUrl As %String, pMethod As %String) As %Status
{
	#dim %request As %CSP.Request
	#dim obj As %DynamicObject
	
	Set tSC = $$$OK
	
	// DTB210 - Refactor using Try/Catch
	Try {
		If (pMethod'="POST") {
			Set tSC = $$$OK
			Quit
		}
		
		// Convert request body into UTF8 proxyObject
		If $IsObject(%request.Content) {
			Set tContent = %request.Content.Read($$$MaxStringLength)
		}
		Else {
			// DTB224 - Create an empty JSON object if none is posted
			Set tContent = "{}"
		}

		Set tContent = $ZCVT(tContent,"I","UTF8")
	
		// DTB261 - Object is built straight from the incoming JSON content
		Set tJSONObj = ##class(%DynamicAbstractObject).%FromJSON(tContent)
		If '$IsObject(tJSONObj) {
			Set tSC = $$$ERROR($$$GeneralError,"Failure to parse posted JSON content")
			Quit
		}
		
		If '$IsObject(tJSONObj) {
			Set tSC = $$$ERROR($$$ArgumentIsNotAnObject,pUrl_":"_pMethod)
			Quit
		}
		
		Set %request.Content = tJSONObj // tJSONObj here is a valid UTF8 proxyObject with required property
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
