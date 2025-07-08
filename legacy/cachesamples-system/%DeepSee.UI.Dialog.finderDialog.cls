/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %products

/// DeepSee version of the Zen finder dialog.
/// Supports the following "modes":
/// <ul>
/// <li>"cubes" (only cubes)</li>
/// <li>"subjects" (only subjectAreas)</li>
/// <li>"subjectAreas" (cubes + subjectAreas as one list (for querying))</li>
/// <li>"models" (cubes + subjectAreas as separate lists (for modeling))</li>
/// <li>"modelsSA" (same as "models" but show subject areas by default)</li>
/// <li>"pivots"</li>
/// <li>"kpis"</li>
/// <li>"worksheets"</li>
/// <li>"dashboards"</li>
/// <li>"datasources" = "kpis"+"pivots"+"worksheets" (+metrics)</li>
/// <li>"sourceclasses" (for Architect: persistent,data connector, and collections)</li>
/// <li>"dataconnectors"</li>
/// <li>"termlists"</li>
/// <li>"qualityMeasures"</li>
/// <li>"pmmlModels"</li>
/// <li>"textClassifiers"</li>
/// <li>"listingGroups"</li>
/// <li>"ttModels"  (text transformation models)</li>
/// </ul> 
/// 
Class %DeepSee.UI.Dialog.finderDialog Extends %ZEN.Dialog.finderDialog [ System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

/// Provide the source data (as an array) that will drive the finder.
Method GetFinderArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	// assemble search parameters
	Set tParms("sort") = ..currSortMode
	Set tParms("search") = ..searchKey
	If (..mode = "cubes") {
		// + WAL078 -- set this when results should be ordered by captions instead of logical names,
		//             as in the cube open dialog in Architect
		Set tParms("orderByCaption") = 1
		// - WAL078
		Set tSC = ##class(%DeepSee.Utils).%GetCubeListArray(.tParms,.pMetaData,.pData,"cubes")
		Quit tSC
	}
	ElseIf (..mode = "subjects") {
		Set tParms("orderByCaption") = 1 // - WAL078
		Set tSC = ##class(%DeepSee.Utils).%GetCubeListArray(.tParms,.pMetaData,.pData,"subjectAreas")
		Quit tSC
	}
	ElseIf (..mode = "subjectAreas") {
		Set tParms("orderByCaption") = 1 // - WAL078
		// non-abstract items only
		Set tSC = ##class(%DeepSee.Utils).%GetCubeListArray(.tParms,.pMetaData,.pData,,1)
		Quit tSC
	}
	ElseIf ((..mode = "models")||(..mode = "modelsSA")) {
		Set tParms("orderByCaption") = 1 // - WAL078
		// cubes and subject areas
		If (..currCategory = "cubes") {
			Set tSC = ##class(%DeepSee.Utils).%GetCubeListArray(.tParms,.pMetaData,.pData,"cubes")
			Quit tSC
		}
		Set tSC = ##class(%DeepSee.Utils).%GetCubeListArray(.tParms,.pMetaData,.pData,"subjectAreas")
		
		Quit tSC
	}
	ElseIf (..mode = "kpis") {
		Set tSC = ##class(%DeepSee.Utils).%GetKPIListArray(.tParms,.pMetaData,.pData)
		Quit tSC
	}
	ElseIf (..mode = "worksheets") {
		Set tSC = ##class(%DeepSee.Utils).%GetWorksheetListArray(.tParms,.pMetaData,.pData)
		Quit tSC
	}
	ElseIf (..mode = "pivots") {
		Set tSC = ##class(%DeepSee.Utils).%GetPivotListArray(.tParms,.pMetaData,.pData)
		Quit tSC
	}
	ElseIf (..mode = "termlists") {
		Set tSC = ##class(%DeepSee.TermList).%GetTermListArray(.tParms,.pMetaData,.pData)
		Quit tSC
	}
	ElseIf (..mode = "qualityMeasures") {
		Set tSC = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasureArray(.tParms,.pMetaData,.pData)
		Quit tSC
	}
	ElseIf (..mode = "datasources") {
		// pivots and kpis
		If (..currCategory = "kpis") {
			Set tSC = ##class(%DeepSee.Utils).%GetKPIListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}
		ElseIf (..currCategory = "worksheets") {
			Set tSC = ##class(%DeepSee.Utils).%GetWorksheetListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}
		ElseIf (..currCategory = "metrics") {
			Set tSC = ##class(%DeepSee.Utils).%GetMetricListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}
		Else {
			Set tSC = ##class(%DeepSee.Utils).%GetPivotListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}
	}
	ElseIf (..mode = "dashboards") {
		Set tSC = ##class(%DeepSee.Utils).%GetDashboardListArray(.tParms,.pMetaData,.pData)
		Quit tSC
	}
	ElseIf (..mode = "dataconnectors") {
		If (..currCategory = "connectors") {
			Set tParms("super") = "%DeepSee.DataConnector"
			Set tSC = ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}
	}
	ElseIf (..mode = "sourceclasses") {
		If (..currCategory = "persistent") {
			Set tParms("persistent") = 1
			Set tParms("system") = 0
			Set tSC = ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}
		ElseIf (..currCategory = "connectors") {
			#; include all subclasses of this class, but not the class itself
			Set tParms("sub") = "%DeepSee.DataConnector"
			Set tSC = ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}
		ElseIf (..currCategory = "collections") {
			// First get list of persistent classes
			Set tParms("persistent") = 1
			Set tParms("system") = 0
			Set tSC = ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.tTempList)
			If $$$ISERR(tSC) Quit tSC
			
			Set tSC = ..%GetCollectionClasses(.tTempList,.pData)
			Quit tSC
		}
	}
	ElseIf (..mode="pmmlModels") {
		If (..currCategory = "pmmlModels") {
			Set tParms("sub") = "%DeepSee.PMML.Definition"
			Set tSC = ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}	
	}
	ElseIf (..mode="textClassifiers") {
		If (..currCategory = "textClassifiers") {
			Set tParms("sub") = "%iKnow.Classification.Classifier"
			Set tSC = ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.pData)
			Quit tSC
		}	
	}
	ElseIf (..mode="ttModels") {
		Set tParms("sub") = "%iKnow.TextTransformation.ModelData"
		Set tSC = ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms, .pMetaData, .pData)		
		Quit tSC	
	}
	ElseIf (..mode="listingGroups") {
		Set tSC = ##class(%DeepSee.ListingGroup).%GetListingGroupArray(.tParms,.pMetaData,.pData)
		Quit tSC
	}


	Quit ##super(.pParameters,.pMetaData,.pData)
}

/// For the set of persistent classes in pList, create a list of projected collection classes.
Method %GetCollectionClasses(ByRef pList, ByRef pData) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set k = $O(pList(""))
	While (k'="") {
		Set tNode = $G(pList(k))
		If (tNode'="") {
			// children?
			Kill tChildList,tChildData
			Merge tChildList = pList(k)
			If ($D(tChildList)>=10) {
				Set tSC = ..%GetCollectionClasses(.tChildList,.tChildData)
				If $D(tChildData) {
					Set pData(k) = tNode
					Merge pData(k) = tChildData
				}
			}
			Else {
				// see if this is a class with projected collections
				Set tClass = $LG(tNode,2)
				Kill tProjList
				Do ##class(%DeepSee.Utils).%GetCollectionProjections(tClass,.tProjList)
				If $D(tProjList) {
					Set pData(k) = tNode
					Set j = $O(tProjList(""))
					While (j'="") {
						Set tClass = tProjList(j)
						Set pData(k,tClass_".cls") = $LB(j,tClass,"cls",$LG(tNode,4),,"persistent")
						Set j = $O(tProjList(j))
					}
				}
			}
		}
		Set k = $O(pList(k))
	}
	Quit tSC
}

/// Return the icon for the item in "icons" mode.
ClientMethod getItemIcon(item) [ Language = javascript ]
{
	if (null == item.children) {
		var icon = this.getDeepSeeIcon(item);
		if (icon) {
			return icon;
		}
	}
	return this.invokeSuper('getItemIcon',arguments);
}

/// Return the icon for a DeepSee item or null if this is not a DeepSee item.
ClientMethod getDeepSeeIcon(item) [ Language = javascript ]
{
	var icon = null;
	switch(item.type) {
	case 'cube':
		return 'deepsee/cube_48.gif';
	case 'subjectArea':
		return 'deepsee/cube_fav_48.gif';
	case 'pivot':
		return 'deepsee/group_data_48.gif';
	case 'dashboard':
		return 'portal/pie_chart_48.gif';
	case 'kpi':
		return 'portal/3D_design_48.gif';
	case 'worksheet':
		return 'deepsee/summary_48.gif';
	}
	return icon;
}

/// Provide HTML for details on selected item in finder.
ClientMethod drawDetails(item, finder, index) [ Language = javascript ]
{
	zen('btnOK').setHidden(true);
	var html = new Array();
	var deepSee = false;

	switch (finder.viewType) {
	case 'columns':
		if (item && null == item.children) {
			var icon = this.getDeepSeeIcon(item);
			if (null == icon) {
				break;
			}

			deepSee = true;
			html[html.length] = '<div style="text-align:center; padding: 5px;">';
			var name = zenEscapeXML(item.translatedName? item.translatedName : (item.value ? item.value : item.name));
			if (name) {
				html[html.length] = '<div style="font-weight:bold;" title="'+name+'">' + name + '</div>';
				html[html.length] = '<hr/>';
			}

			if (null == item._info) {
				// get more info from server
				item._info = this.GetItemInfo(item.type,item.value);
				item.description = item._info.description;
				item.cubeType = item._info.cubeType;
			}

			// check for overload of icon
			icon = item.icon ? item.icon : icon;
		
			html[html.length] = '<img alt="" src="' + icon + '"/></b><br/>';
			if (item.date) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Last modified') + '</div>';
				html[html.length] = '<div style="color:#404040;font-size:11pt;">' + item.date + '</div><br/>';
			}

			if (item._info && ''!=item._info.generatedby) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Generated by') + '</div>';
				html[html.length] = '<div style="padding:5px;"><a href="#" title="'+$$$Text('Open this class') + '" onclick="zenPage.openSuper(\''+item._info.generatedby+'\');return false;">' + item._info.generatedby + '</a></div>';
				html[html.length] = '<br/>';
			}

			if (item._info && item._info.superclass) {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Extends') + '</div>';
				var t = item._info.superclass.split(',');
				for (var n = 0; n < t.length; n++) {
					html[html.length] = '<div style="padding:5px;"><a href="#" title="'+$$$Text('Open this class') + '" onclick="zenPage.openSuper(\''+t[n]+'\');return false;">' + t[n] + '</a></div>';
				}
				html[html.length] = '<br/>';
			}

			if (item.cubeType && item.cubeType != '') {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Type') + '</div>';
				html[html.length] = '<div style="text-align:center;color:#404040;font-size:11pt;">' + item.cubeType + '</div>';
				html[html.length] = '<br/>';
			}

			var desc = item.description ? item.description : '';
			if (desc != '') {
				html[html.length] = '<div style="color:#808080;font-weight:bold;">' + $$$Text('Description') + '</div>';
				html[html.length] = '<div style="text-align:left;overflow:auto;height:160px;font-size:10pt;color:#404040;">' + desc + '</div>';
			}

			// command
			html[html.length] = '<hr/>';
			html[html.length] = '<a class="commandButton" href="#" onclick="zenPage.dialogFinish();return false;">'+$$$Text('Go')+'</a>' + '<br/>';
			html[html.length] = '</div>';
		}
		break;
	}	
	if (deepSee) {
		return html.join('');
	}

	return this.invokeSuper('drawDetails',arguments);
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		/// if we are selecting a subject area and this is from Architect, then we will do a check for compound basecube.
		if ((this.currCategory == "subjectAreas") && ((this.mode == "models") || (this.mode == "modelsSA"))) {
			var value = this.getDialogValue();
			var compmsg = this.IsCompound(value);
			if (compmsg.length > 0) {
				var msg = compmsg + "\n" + $$$Text("Compound Cubes cannot be accessed via DeepSee Architect.") + "\n" + $$$Text("To access this Compound Cube definition, use Studio.");		
				//alert(msg);
				//return false;
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Add components to page.
Method %OnAfterCreatePage() As %Status
{
	// define set of category tabs to display in lookout menu
	Set tLookout = ..%GetComponentById("lookout")
	Set tDeepSee = 0

	// If superKey is defined, bypass MODE logic
	If (..superKey'="") {
		// some super classes are *built-in*
		Set tCaption = $P(..superKey,".",$L(..superKey,"."))
		Set tContent = $$$Text("Select a class from the options on the right")

		If (..superKey = "%DeepSee.CubeDefinition") {
			Set tCaption = $$$Text("DeepSee Cubes")
			Set tContent = $$$Text("Select a cube definition class from the options on the right")
		}

		Set tTab = ##class(%ZEN.Component.tab).%New()
		Set tTab.caption = tCaption
		Set tTab.layout = "none"
		Set tTab.title = ""
		Do tLookout.%AddChild(tTab)

		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.enclosingClass = "category"
		Set tHTML.content = tContent
		Do tTab.%AddChild(tHTML)

		Quit $$$OK
	}
	Set tProductName = $$$PRODUCT1
	// $LB(id,caption,help)
	If (..mode="cubes") {
		Set tCat(1) = $LB("cubes",tProductName,$$$Text("Display cubes"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="subjectAreas") {
		Set tCat(1) = $LB("subjectAreas",tProductName,$$$Text("Display Subject Areas"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="subjects") {
		Set tCat(1) = $LB("subjects",tProductName,$$$Text("Display Subject Area Definitions"))
		Set tDeepSee = 1
	}
	ElseIf ((..mode="models")||(..mode="modelsSA")) {
		Set tCat(1) = $LB("models",tProductName,$$$Text("Display Data Models"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="pivots") {
		Set tCat(1) = $LB("pivots",tProductName,$$$Text("Display saved pivots"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="termlists") {
		Set tCat(1) = $LB("termlists",tProductName,$$$Text("Display term lists"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="qualityMeasures") {
		Set tCat(1) = $LB("qualityMeasures",tProductName,$$$Text("Display Quality Measures"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="kpis") {
		Set tCat(1) = $LB("kpis",tProductName,$$$Text("Display KPIs"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="worksheets") {
		Set tCat(1) = $LB("worksheets",tProductName,$$$Text("Display Worksheets"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="datasources") {
		Set tCat(1) = $LB("datasources",tProductName,$$$Text("Display Data Sources"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="dashboards") {
		Set tCat(1) = $LB("dashboards",tProductName,$$$Text("Display Dashboards"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="sourceclasses") {
		Set tCat(1) = $LB("sourceclasses",$$$Text("Source Classes"),$$$Text("Display source classes"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="dataconnectors") {
		Set tCat(1) = $LB("dataconnectors",$$$Text("Data Connectors"),$$$Text("Display Data Connectors"))
		Set tDeepSee = 1
	}
	ElseIf (..mode="pmmlModels") {
		set tCat(1) = $lb("pmmlModels",$$$Text("PMML"),$$$Text("Display PMML models"))
		set tDeepSee = 1
	}
	ElseIf (..mode="textClassifiers") {
		set tCat(1) = $lb("textClassifiers",$$$Text("Text Classifiers"),$$$Text("Display Text Classifiers"))
		set tDeepSee = 1
	}
	ElseIf (..mode="ttModels") {
		set tCat(1) = $lb("ttModels",$$$PRODUCT5,$$$FormatText($$$Text("Display %1 Text Transformation Models"),$$$PRODUCT5))
		set tDeepSee = 1
	}
	ElseIf (..mode="listingGroups") {
		Set tCat(1) = $LB("listingGroups",tProductName,$$$Text("Display listing groups"))
		Set tDeepSee = 1
	}

	// initial category to show
	If ((..mode="cubes")) {
		Set ..currCategory = "cubes"
	}
	ElseIf ((..mode="subjectAreas")) {
		Set ..currCategory = "subjectAreas"
	}
	ElseIf ((..mode="subjects")) {
		Set ..currCategory = "subjects"
	}
	ElseIf ((..mode="models")) {
		Set ..currCategory = "cubes"
	}
	ElseIf ((..mode="modelsSA")) {
		Set ..currCategory = "subjectAreas"
	}
	ElseIf ((..mode="pivots")) {
		Set ..currCategory = "pivots"
	}
	ElseIf ((..mode="termlists")) {
		Set ..currCategory = "termlists"
	}
	ElseIf ((..mode="qualityMeasures")) {
		Set ..currCategory = "qualityMeasures"
	}
	ElseIf ((..mode="kpis")) {
		Set ..currCategory = "kpis"
	}
	ElseIf ((..mode="worksheets")) {
		Set ..currCategory = "worksheets"
	}
	ElseIf ((..mode="datasources")) {
		Set ..currCategory = "pivots"
	}
	ElseIf ((..mode="dashboards")) {
		Set ..currCategory = "dashboards"
	}
	ElseIf ((..mode="sourceclasses")) {
		Set ..currCategory = "persistent"
	}
	ElseIf ((..mode="dataconnectors")) {
		Set ..currCategory = "connectors"
	}
	ElseIf ((..mode="pmmlModels")) {
		Set ..currCategory = "pmmlModels"
	}
	ElseIf ((..mode="textClassifiers")) {
		Set ..currCategory = "textClassifiers"
	}
	ElseIf ((..mode="listingGroups")) {
		Set ..currCategory = "listingGroups"
	}

	If (tDeepSee) {
		Set k = $O(tCat(""))
		While (k'="") {
			Set tTab = ##class(%ZEN.Component.tab).%New()
			Set tTab.caption = $LG(tCat(k),2)
			Set tTab.layout = "none"
			Set tTab.title = $LG(tCat(k),3)
			Do tLookout.%AddChild(tTab)

			Set tHTML = ##class(%ZEN.Component.html).%New()
			Set tHTML.enclosingClass = "category"
			Set tHTML.OnDrawContent = "DrawCategories"
			Set tHTML.seed = $LG(tCat(k),1) // passed to DrawCategories method
			Do tTab.%AddChild(tHTML)
			Set k = $O(tCat(k))
		}
		Quit $$$OK
	}

	Quit ##super()
}

/// Get information to display in the category box.
Method OnGetCategoryInfo(pCategory As %String, Output pDisplay As %Boolean, Output pIcons As %List) As %Status
{
	Set pDisplay = 1
	If (pCategory = "cubes") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("cubes",$$$Text("Cubes"),$$$Text("Show DeepSee Cube Definitions"),"deepsee/cube_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "subjectAreas") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("subjectAreas",$$$Text("Subject Areas"),$$$Text("Show DeepSee Subject Areas"),"deepsee/cube_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "subjects") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("subjects",$$$Text("Subject Areas"),$$$Text("Show DeepSee Subject Area Definitions"),"deepsee/cube_fav_48.gif")
		Quit $$$OK
	}
	ElseIf ((pCategory = "models")||(pCategory = "modelsSA")) {
		Set pIcons(1) = $LB("cubes",$$$Text("Cubes"),$$$Text("Show DeepSee Cubes"),"deepsee/cube_48.gif")
		Set pIcons(2) = $LB("subjectAreas",$$$Text("Subject Areas"),$$$Text("Show DeepSee Subject Areas"),"deepsee/cube_fav_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "pivots") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("pivots",$$$Text("Pivots"),$$$Text("Show DeepSee Pivots"),"deepsee/group_data_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "termlists") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("termlists",$$$Text("Term lists"),$$$Text("Show DeepSee Term Lists"),"deepsee/comparison_chart_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "qualityMeasures") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("qualityMeasures",$$$Text("Quality Measures"),$$$Text("Show DeepSee Quality Measures"),"deepsee/comparison_chart_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "kpis") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("kpis",$$$Text("KPIs"),$$$Text("Show DeepSee KPIs"),"portal/3D_design_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "worksheets") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("worksheets",$$$Text("Worksheets"),$$$Text("Show DeepSee Worksheets"),"deepsee/summary_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "datasources") {
		Set pIcons(1) = $LB("pivots",$$$Text("Pivots"),$$$Text("Show DeepSee Pivots"),"deepsee/group_data_48.gif")
		Set pIcons(2) = $LB("kpis",$$$Text("KPIs"),$$$Text("Show DeepSee KPIs"),"portal/3D_design_48.gif")
		Set pIcons(3) = $LB("worksheets",$$$Text("Worksheets"),$$$Text("Show DeepSee Worksheets"),"deepsee/summary_48.gif")
		If (($System.Version.GetMajor()>=2011)&&(##class(%Library.EnsembleMgr).IsEnsembleNamespace())) {
			Set pIcons(4) = $LB("metrics",$$$Text("Business Metrics"),$$$Text("Show Ensemble Business Metrics"),"deepsee/gauge_48.gif")
		}
		Quit $$$OK
	}
	ElseIf (pCategory = "dashboards") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("dashboards",$$$Text("Dashboards"),$$$Text("Show DeepSee Dashboards"),"deepsee/pie_chart_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "sourceclasses") {
		Set pIcons(1) = $LB("persistent",$$$Text("Persistent"),$$$Text("Show Persistent classes"),"portal/table_48.gif")
		Set pIcons(2) = $LB("connectors",$$$Text("Data Connectors"),$$$Text("Show Data Connector classes"),"portal/3D_design_48.gif")
		Set pIcons(3) = $LB("collections",$$$Text("Collections"),$$$Text("Classes projected for child-table collections"),"portal/table_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "dataconnectors") {
		Set pIcons(1) = $LB("connectors",$$$Text("Data Connectors"),$$$Text("Show Data Connector classes"),"portal/3D_design_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "pmmlModels") {
		Set pIcons(1) = $LB("pmmlModels",$$$Text("PMML Models"),$$$Text("Show PMML Models"),"portal/binocular_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "textClassifiers") {
		Set pIcons(1) = $LB("textClassifiers",$$$Text("Text Classifiers"),$$$Text("Show Text Classifiers"),"portal/osi_model_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "listingGroups") {
		// id,caption,tooltip,icon
		Set pIcons(1) = $LB("listingGroups",$$$Text("Listing Groups"),$$$Text("Show DeepSee Listing Groups"),"deepsee/comparison_chart_48.gif")
		Quit $$$OK
	}
	ElseIf (pCategory = "ttModels") {
		Set pIcons(1) = $LB("models",$$$Text("Models"),$$$Text("Display iKnow Text Transformation Models"),"deepsee/cube_48.gif")
	}
	
	Quit ##super(pCategory, .pDisplay, .pIcons)
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = $$$Text("Finder")

	Set pViewIcons(1) = $LB("columns",$$$Text("Show columns view"),"portal/view_box_columns.png")
	Set pViewIcons(2) = $LB("list",$$$Text("Show list view"),"portal/view_box_list.png")

	Set pSortOptions(1) = $LB("name",$$$Text("Name"),$$$Text("Sort items by name"))
	Set pSortOptions(2) = $LB("date",$$$Text("Date"),$$$Text("Sort items by last modified date"))

	Quit $$$OK
}

/// Zen page notification of an HTTP request.
ClassMethod %OnPreHTTP() As %Boolean [ Internal, ServerOnly = 1 ]
{
	// test if user has resources
	Set tPriv = 0
	Set tMode = $G(%request.Data("MODE",1))

	If ((tMode="cubes")||
		(tMode="subjects")||
		(tMode="subjectAreas")||
		(tMode="pivots")||
		(tMode="datasources")||
		(tMode="kpis")||
		(tMode="worksheets")||
		(tMode="dashboards")||
		(tMode="pmmlModels")||
		(tMode="textClassifiers")) {
		Set tPriv = 1
	}

	If ('tPriv) {
		Set tPriv = ##super()
	}
	If ('tPriv) {
		// test DeepSee resources
		If ($System.Security.Check("%DeepSee_Architect","USE")||
			$System.Security.Check("%DeepSee_ArchitectEdit","USE")||
			$System.Security.Check("%DeepSee_Analyzer","USE")||
			$System.Security.Check("%DeepSee_AnalyzerEdit","USE")||
			$System.Security.Check("%DeepSee_Portal","USE")||
			$System.Security.Check("%DeepSee_PortalEdit","USE")
			) {
		Set tPriv = 1
		}
	}

	If ('tPriv) {
		Set %response.Redirect = ##class(%DeepSee.Utils).%GetErrorPageURL("Privilege")
	}
	Quit tPriv
}

/// This method evaluates whether the subjectArea user selected has a compound baseCube.<br>
/// Returns message if it is a compound base cube. Otherwise return null.
ClassMethod IsCompound(subjectAreaFullName) As %String [ ZenMethod ]
{
	Set $ZT="Error"	
	Set tName = $P(subjectAreaFullName,".",1,$L(subjectAreaFullName,".")-1)
	Set tModel = ##class(%DeepSee.Utils).%GetSubjectAreaModel(tName,.tSC)
	If $$$ISERR(tSC) Quit ""
	Set tBaseCube = tModel.baseCube
	If $L(tBaseCube,",") = 1 Quit ""
	Set tMsg = $$$FormatText($$$Text("The [%1] Subject Area is a Compound Cube."),tName)
	Quit $TR($TR(tMsg,"[",""""""),"]","""""")
Error	///
	Quit ""
}

/// Look up additional information for a given item.
ClassMethod GetItemInfo(pMode As %String, pItemName As %String, pItemCategory As %String = "") As %ZEN.proxyObject [ Internal, ZenMethod ]
{
	Set tInfo = ##class(%ZEN.proxyObject).%New()

	If ((pMode = "cube")||(pMode = "subjectArea")) {
		Set tInfo.generatedby = ""
		Set tInfo.superClass = ""
		Set tInfo.cubeType = $S(pMode="subjectArea":"Subject Area",1:"Cube")
		Set tInfo.description = ##class(%DeepSee.Utils).%GetCubeDescription(pItemName)
		Quit tInfo
	}
	ElseIf ((pMode = "kpi")) {
		Set tInfo.generatedby = ""
		Set tInfo.superClass = ""
		Set tInfo.cubeType = ""
		Set tInfo.description = ##class(%DeepSee.Utils).%GetKPIDescription(pItemName)
		Quit tInfo
	}
	ElseIf ((pMode = "pivot")||(pMode = "worksheet")||(pMode = "dashboard")) {
		Set tInfo.generatedby = ""
		Set tInfo.superClass = ""
		Set tInfo.cubeType = ""
		Set tInfo.description = ""
		// assume mode is same as extension!
		Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pItemName_"."_pMode)
		If ($IsObject(tItem)) {
			Set tInfo.description = $S($E(tItem.description,1,3)="$$$": ##class(%DeepSee.UserPortal.Utils).%ResolveName(tItem.description), 1:tItem.description)
		}
		Quit tInfo
	}
	Else {
		Set tInfo = ##super(pMode,pItemName,pItemCategory)
	}
	Quit tInfo
}

}
