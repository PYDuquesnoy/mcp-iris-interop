/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized DeepSee Dashboard widget that displays a visual meter (such as a speedometer).
/// There may be multiple meters displayed within the widget, each corresponding to a dataProperty
/// in the widget definition's dataProperty list.
Class %DeepSee.Component.Widget.meter Extends %DeepSee.Component.Widget.widget [ System = 4 ]
{

/// Number of meters displayed in this widget (set automatically).
Property meterCount As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon,ranking)
	Set pInfo = $LB(..%ClassName(0),$$$Text("Meter","%DeepSee"),..%ClassName(1),"deepsee/gauge_48.gif",3)

	// $LB(name,caption,,icon)
	Set pSubtypeList($I(n)) = $LB("speedometer",$$$Text("Speedometer","%DeepSee"),,"deepsee/speedo_48.gif")
	Set pSubtypeList($I(n)) = $LB("fuelGauge",$$$Text("Fuel Gauge","%DeepSee"),,"deepsee/fuel_48.gif")
	Set pSubtypeList($I(n)) = $LB("textMeter",$$$Text("Text Meter","%DeepSee"),,"deepsee/text_box_48.gif")
	Set pSubtypeList($I(n)) = $LB("trafficLight",$$$Text("Traffic Light","%DeepSee"),,"deepsee/caution_48.gif")
	Set pSubtypeList($I(n)) = $LB("lightBar",$$$Text("Light Bar","%DeepSee"),,"deepsee/lightbar_48.gif")
	Set pSubtypeList($I(n)) = $LB("smiley",$$$Text("Smiley Face","%DeepSee"),,"deepsee/smiley_48.gif")
	Quit $$$OK
}

/// Return information on additional "properties" supported by this widget for the given subtype.
ClassMethod %GetWidgetPropertyInfo(pSubtype As %String, Output pInfo As %List) As %Status
{
	Kill pInfo
	// $LB(name,value,type,caption,title,hidden,displayList)

	// DTB250 - Move Analyzer to the top and add print
	Set pInfo($I(pInfo)) = $LB("analyzer",0,"%Boolean",$$$Text("Analyzer","%DeepSee"),$$$Text("Enable Analyzer dialog for this meter","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("print",0,"%Boolean",$$$Text("Print","%DeepSee"),$$$Text("Enable printing for this meter","%DeepSee"))

	If ((pSubtype="textMeter")||(pSubtype="speedometer")||(pSubtype="fuelGauge")) {
		Set pInfo($I(pInfo)) = $LB("format","#,#","Format",$$$Text("Format","%DeepSee"),$$$Text("Default numeric format string for meter","%DeepSee"))
	}

	// JMD1170
	Set pInfo($I(pInfo)) = $LB("highRangeColor","","ColorSVG",$$$Text("High value color","%DeepSee"),$$$Text("Color used to indicate values above the upper threshold","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("lowRangeColor","","ColorSVG",$$$Text("Low value color","%DeepSee"),$$$Text("Color used to indicate values below the lower threshold","%DeepSee"))

	// Set pInfo($I(pInfo)) = $LB("labelStyle","","Style",$$$Text("Label style","%DeepSee"),$$$Text("Style for meter labels","%DeepSee"),1)

	Set pInfo($I(pInfo)) = $LB("backgroundColor","","ColorSVG",$$$Text("Background color","%DeepSee"),$$$Text("Background color for widget","%DeepSee"))
	
	Set pInfo($I(pInfo)) = $LB("opacity","","Opacity",$$$Text("Background opacity","%DeepSee"),$$$Text("Background opacity for widget","%DeepSee")) // JSL4483

	// !!!
	// Set pInfo($I(pInfo)) = $LB("freeForm",0,"%Boolean",$$$Text("Freeform","%DeepSee"),$$$Text("Allow free form layout for widgets","%DeepSee"))
	Quit $$$OK
}

/// This callback is responsible for creating the contents of the widget.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Set tSC = $$$OK
	Try {
		// DTB565 - required by excel/PDF export
		Set ..sessionCookie = %session.CSPSessionCookie
		
		// get default values for widget properties
		Do ..%GetWidgetPropertyInfo(..subtype,.tList)
		Set n = $O(tList(""))
		While (n'="") {
			Set tName = $LG(tList(n),1)
			//Set tPValue(tName) = ..%definition.properties.GetAt(tName)
			Set tPValue(tName) = $S(..%definition.properties.%IsA("%Collection.AbstractArray"):..%definition.properties.GetAt(tName),1:"")
			Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
			Set n = $O(tList(n))
		}

		Set tMsg = ""
		// see if we have a data source
		Set tPivotDef = ""
		Set tPivotTable = ""
		Set tKPIClass = ""
		Set tDataSource = ..dataSource
		Set tExt = $P(tDataSource,".",$L(tDataSource,"."))
		If (tExt = "kpi") {
			Set tName = $P(tDataSource,".",1,$L(tDataSource,".")-1)
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
		}
		ElseIf (tExt = "metric") {
			Set tKPIClass = "Ens.BusinessMetricKPI"
		}
		ElseIf (tExt = "worksheet") {
			Set tKPIClass = "%DeepSee.KPIWorksheet"
		}

		Set tController = ""
		If (tKPIClass'="") {
			// add data controller to the widget
			Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
			Set tController.id = ..%MakeWidgetId("controller")
			Set tController.modelClass = tKPIClass
			If (tExt = "metric") {
				Set tController.modelId = ..dataSource
			}
			ElseIf (tExt = "worksheet") {
				Set tController.modelId = ..dataSource
			}
			Set tSC = pGroup.%AddChild(tController)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tExt="pivot") {
			// saved pivot
			// create a hidden pivotTable and use it as the controller
			Set tPivotDef = ""
			If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..dataSource)) {
				// DTB580 - Only set the folder item if we know it exists
				Set tPivotDef = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..dataSource,.tSC)
				If $$$ISERR(tSC) Quit
			}
			If '$IsObject(tPivotDef) Quit 
			
			Set tPivotTable = ##class(%DeepSee.Component.pivotTable).%New()
			Set tPivotTable.id = ..%MakeWidgetId("controller")
			Set tPivotTable.hidden = 1
			Set tSC = pGroup.%AddChild(tPivotTable)
			If $$$ISERR(tSC) Quit

			// copy information from the saved item to the graphical pivot
			Set tSC = tPivotDef.%CopyToComponent(tPivotTable)
			If $$$ISERR(tSC) Quit

			Set tController = tPivotTable
		}
		Else {
			Set tMsg = $$$Text("Meter is not connected to a valid data source","%DeepSee")_" <br/><i>"_tDataSource_"</i>"
		}

		// add an SVG frame to the widget
		Set tFrame = ##class(%ZEN.SVGComponent.svgFrame).%New()
		Set tFrame.id = ..%MakeWidgetId("svgFrame")
		Set tFrame.onselectItem = "zenPage.getComponent("_..index_").meterSelected(item);"

		Set:$G(tPValue("backgroundColor"))'="" tFrame.backgroundStyle = "fill:"_$G(tPValue("backgroundColor"))_";"
		Set:$G(tPValue("opacity"))'="" tFrame.backgroundStyle = tFrame.backgroundStyle_"fill-opacity:"_$G(tPValue("opacity"))_";"
		Set ..opacity = $G(tPValue("opacity"))

		// !!! not supported at this time
		Set tFreeForm = +$G(tPValue("freeForm"),0)
		If ('tFreeForm) {
			Set tFrame.layout = "flow"
			Set tFrame.editMode = ""
		}
		Else {
			Set tFrame.layout = ""
			Set tFrame.editMode = "drag"
		}
		Set tSC = pGroup.%AddChild(tFrame)
		If $$$ISERR(tSC) Quit

		// place meter(s) within the frame
		// 1 per data property
		Set ..meterCount = 0
		Set tMCount = ..%definition.dataProperties.Count()
		If (tMCount=0) {
			// place one default meter as a place holder
			Set tMeterClass = ..%SubTypeToClass(..subtype)
			Set:tMeterClass="" tMeterClass = "%ZEN.SVGComponent.speedometer"
			Set tMeter = $classmethod(tMeterClass,"%New")
			Set tMeter.id = ..%MakeWidgetId("svgMeter"_1)
			Set tMeter.label = $$$Text("No Meters Defined","%DeepSee")

			Do tFrame.%AddChild(tMeter)
			Set ..meterCount = ..meterCount + 1
		}
		Else {
			For m=1:1:tMCount {
				Set tDataPropertyDef = ..%definition.dataProperties.GetAt(m)
				Set tPropertyName = tDataPropertyDef.dataValue

				// meter may define its own subtype
				If (tDataPropertyDef.subtype'="") {
					Set tMeterClass = ..%SubTypeToClass(tDataPropertyDef.subtype)
				}
				Else {
					Set tMeterClass = ..%SubTypeToClass(..subtype)
				}
			
				// check for meter override; test theme as well
				Set tMeterOverride = ""
				Set tMeterJSON = ""
				Set tMeterShortName = $P(tMeterClass,".",$L(tMeterClass,"."))
				If (..%definition.themeOverrides.%IsA("%Collection.AbstractArray")) {
					Set:tMeterShortName'="" tMeterJSON = ..%definition.themeOverrides.GetAt(tMeterShortName)
				}
				Else {
					// JSON provider
					Set:tMeterShortName'="" tMeterJSON = $property(..%definition.themeOverrides,tMeterShortName)
				}

				Set:tDataPropertyDef.override'="" tMeterJSON = tDataPropertyDef.override
				If (tMeterJSON'="") {
					Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(tMeterJSON,,.tMeterOverride)
					If $$$ISERR(tSC) Quit

					If ($IsObject(tMeterOverride)&&(tMeterOverride."_type"'="")) {
						Set tMeterClass = "%ZEN.SVGComponent." _ tMeterOverride."_type"
					}
					If ($IsObject(tMeterOverride)&&(tMeterOverride.dataValue'="")) {
						Set tPropertyName = tMeterOverride.dataValue
					}
				}

				If (tPropertyName '= "") {
					Set tPropertyCaption = tDataPropertyDef.label
					// JMD997
					If (tPropertyCaption="$auto") {
						// use display name as a label
						// this is done on the client
						Set tPropertyCaption = "$auto"
					}
				}
				Else {
					Set tPropertyCaption = tDataPropertyDef.label
					// Set tPropertyCaption = $$$Text("Not Connected","%DeepSee")
				}

				Set tMeter = $classmethod(tMeterClass,"%New")
				Set tMeter.label = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tPropertyCaption)
				Set tMeter.showConditionally = (tDataPropertyDef.showAs = "conditional")

				If (""'=$G(tPValue("labelStyle"))) {
					Set tMeter.labelStyle = ..%definition.properties.GetAt("labelStyle")
				}

				// JMD1493 apply overrides *before* widget properties
				If ($IsObject(tMeterOverride)) {
					// apply override properties
					Kill tOverArray
					Do tMeterOverride.%CopyToArray(.tOverArray)
					Set p = $O(tOverArray(""))
					While (p'="") {
						If ($IsObject(tOverArray(p))) {
						}
						ElseIf ($E(p)'="_") {
							Set $Property(tMeter,p) = tOverArray(p)
						}
						Set p = $O(tOverArray(p))
					}
				}

				// apply additional widget properties
				If (tMeter.%IsA("%ZEN.SVGComponent.textMeter")) {
					If (""'=$G(tPValue("format"))) {
						// default for all meters on widget
						Set tMeter.format = ..%definition.properties.GetAt("format")
					}
					If (tDataPropertyDef.format'="") {
						// local override
						Set tMeter.format = tDataPropertyDef.format
					}
					If (tDataPropertyDef.style'="") {
						Set tMeter.normalStyle = tDataPropertyDef.style
					}
				}
				ElseIf (tMeter.%IsA("%ZEN.SVGComponent.speedometer")) {
					If (""'=$G(tPValue("highRangeColor"))) {
						Set tColor = tPValue("highRangeColor")
						Set tMeter.highRangeStyle = "fill:"_tColor_";"
						Set tMeter.highLampColor = tColor
					}
					If (""'=$G(tPValue("lowRangeColor"))) {
						Set tColor = tPValue("lowRangeColor")
						Set tMeter.lowRangeStyle = "fill:"_tColor_";"
						Set tMeter.lowLampColor = tColor
					}
					If (""'=$G(tPValue("format"))) {
						// default for all meters on widget
						Set tMeter.odometerFormat = ..%definition.properties.GetAt("format")
					}
					If (tDataPropertyDef.format'="") {
						// local override
						Set tMeter.odometerFormat = tDataPropertyDef.format
					}
				}
				ElseIf (tMeter.%IsA("%ZEN.SVGComponent.fuelGauge")) {
					If (""'=$G(tPValue("highRangeColor"))) {
						Set tColor = tPValue("highRangeColor")
						Set tMeter.highLampColor = tColor
					}
					If (""'=$G(tPValue("lowRangeColor"))) {
						Set tColor = tPValue("lowRangeColor")
						Set tMeter.lowLampColor = tColor
					}
					If (""'=$G(tPValue("format"))) {
						// default for all meters on widget
						Set tMeter.format = ..%definition.properties.GetAt("format")
					}
					If (tDataPropertyDef.format'="") {
						// local override
						Set tMeter.format = tDataPropertyDef.format
					}
				}
				ElseIf (tMeter.%IsA("%ZEN.SVGComponent.smiley")) {
					If (""'=$G(tPValue("persona"))) {
						Set tMeter.persona = ..%definition.properties.GetAt("persona")
					}
				}

				// apply these last
				Set tMeter.id = ..%MakeWidgetId("svgMeter"_m)
				Set tMeter.dataBinding = tPropertyName
				Set tMeter.targetValue = tDataPropertyDef.targetValue
				Set tMeter.rangeLower = tDataPropertyDef.rangeLower
				Set tMeter.rangeUpper = tDataPropertyDef.rangeUpper
				Set tMeter.thresholdLower = tDataPropertyDef.thresholdLower
				Set tMeter.thresholdUpper = tDataPropertyDef.thresholdUpper
				If $IsObject(tController) {
					Set tMeter.controllerId = tController.id
				}

				Do tFrame.%AddChild(tMeter)
				Set ..meterCount = ..meterCount + 1
			}
		}

		If (tMsg '= "") {
			Set tFrame.hidden = 1
			Set tFrame.width = 0
			Set tFrame.height = 0
			Set tLabel = ##class(%ZEN.Component.html).%New()
			Set tLabel.enclosingStyle = "border: 1px solid black; margin:5px; line-height:150%; padding:5px; background: white; color: #D04040;"
			Set tLabel.content = tMsg
			Set tSC = pGroup.%AddChild(tLabel)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Translate a subtype into a Meter class name.
Method %SubTypeToClass(pSubtype As %String) As %String [ Private ]
{
	If (pSubtype = "") {
		Set tClassName = "%ZEN.SVGComponent.speedometer"
	}
	Else {
		Set tClassName = "%ZEN.SVGComponent." _ pSubtype
	}
	Quit tClassName
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var svg = this.findComponent('svgFrame');
	if (!svg) return;

	var adjW = 2;
	var adjH = 2;

	var svgDiv = svg.getEnclosingDiv();
	svgDiv.style.width = width + 'px';
	svgDiv.style.height = height + 'px';

	// adjust size of svg frame
	var svgWid = width - adjW;
	var svgHgt = height - adjH;
	svg.setProperty("width",svgWid+'px');
	svg.setProperty("height",svgHgt+'px');

	// adjust meter(s)
	if (svgHgt <= 0 || svgWid <= 0) {
		return;
	}

	// count number of non-hidden meters
	var meterCount = this.getMeterCount();
	var mCount = 0;
	for (var n = 0; n < meterCount; n++) {
		meter = this.findComponent('svgMeter' + (n+1));
		if (meter && !meter.hidden) {
			mCount++;
		}
	}

	if (mCount > 0) {
		var xw = Math.round((svgWid-10) / mCount);
		var mh = (xw > svgHgt) ? svgHgt : xw;

		while (mh < (svgHgt*0.35) && (xw < svgWid)) {
			xw = Math.round(xw * 1.05);
			xw = (xw > svgWid) ? svgWid : xw;
			mh = (xw > svgHgt) ? svgHgt : xw;
		}

		for (var n = 0; n < meterCount; n++) {
			meter = this.findComponent('svgMeter' + (n+1));
			if (meter && !meter.hidden) {
				var aspect = (meter.viewBoxHeight>0) ? meter.viewBoxWidth / meter.viewBoxHeight : 1;
				if (aspect > 1) {
					var mw = xw;
					mh = mw / aspect;
				}
				else {
					var mw = mh * aspect;
				}
				meter.setProperty("width",mw);
				meter.setProperty("height",mh);
			}
		}
	}
}

/// If this widget contains a data controller, return it.
/// This allows for generic capabilities in this base class.
ClientMethod getDataController() [ Language = javascript ]
{
	return this.findComponent('controller');
}

/// Return the given meter object within this widget.
ClientMethod getMeter(n) [ Language = javascript ]
{
	n = zenGet(n,0);
	return this.findComponent('svgMeter' + (n+1));
}

/// If this widget contains a data controller, return it.
Method %GetDataController() As %ZEN.Auxiliary.abstractController
{
	Quit ..%FindComponent("controller")
}

/// Return an object describing what to display for this level within the navigator.
/// Invoked from dashboard viewer.
ClientMethod navGetContentForLevel(level, key, value) [ Internal, Language = javascript ]
{
	var content = { title: $$$Text('Settings','%DeepSee'), items:[] };
	var navigator = zenPage.getNavigator();
	var title = '';

	// key may take the form key:no
	var ckey = key; // local copy
	var keyNo = '';
	if (ckey.toString().indexOf(':')>0) {
		var t = ckey.split(':');
		ckey = t[0];
		keyNo = parseInt(t[1]);
	}

	switch (ckey) {
	case 'WidgetSettings':
		// get common content
		content = this.invokeSuper('navGetContentForLevel',arguments);

		content.items[content.items.length] = {display:'section', caption:$$$Text('Meter Settings','%DeepSee') };
		content.items[content.items.length] = {display:'image-caption-hz', image:'deepsee/ds2_dashboard_44.png', caption:$$$Text('Meters','%DeepSee'), action:'drill', key:'widget-meter-List'};
		break;

	case 'widget-meter-List':
		content.title = $$$Text('Meters','%DeepSee');

		// "add meter" button
		content.headerButtons = [ 
			{key:'meter-meterAdd', caption:$$$Text('Add Meter','%DeepSee'), image:'deepsee/ds2_plus_44_w.png'}
		];

		// list of data properties within this widget
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef && widgetDef.dataProperties && widgetDef.dataProperties.length) {
			for (var n = 0; n < widgetDef.dataProperties.length; n++) {
				var dataProp = widgetDef.dataProperties[n];
				if (dataProp) {
					var caption = dataProp.label ? dataProp.label : dataProp.dataValue;
					var meter = this.getMeter(n);
					caption = (caption=='$auto' && meter) ? meter.getLabelText() : caption;
					caption = caption ? caption : ('Meter ' + (n+1));
					content.items[content.items.length] = {display:'image-caption-hz', image:'deepsee/ds2_dashboard_44.png', caption:caption, action:'drill', key:'widget-meter-Settings:'+n, canDrag:false, closeButton:true};
				}
			}
		}
		else {
			content.items[content.items.length] = {display:'info', caption:$$$Text('Widget has no meters','%DeepSee'), value:'Press the Add button to add a Meter', captionStyle:'color:darkred;white-space: normal;width:260px;', style:'height:150px;' };
		}
		break;

		// settings for "specific" meter in the widget.
	case 'widget-meter-Settings':
		content.title = $$$Text('Meter Settings','%DeepSee');
		// get settings from data prop
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef && widgetDef.dataProperties[keyNo]) {
			var dataProp = widgetDef.dataProperties[keyNo];

			// use selected meter
			var meter = this._selectedMeter;
			if (!meter) {
				content.html = '<div style="padding:10px;font-size:20px;color:#804040;font-style:italic;">' + $$$Text('Please select a meter') + '</div>';
			}
			else {
				// select item
				var svg = this.findComponent('svgFrame');
				if (!(window.navigator.userAgent.indexOf('Edge')>0)&&(!zenIsIE)) {
					// DTB625 - This causes problems for IE, and Edge no longer passes the zenIsIE test!
					svg.selectItem(meter);
				}

				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Type','%DeepSee'),value:zenGet(meter._type), action:'drill', key:'widget-meter-MeterType:'+keyNo};

				content.items[content.items.length] = {display:'section', caption:$$$Text('Data and Range','%DeepSee')};

				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Data Property','%DeepSee'),value:zenGet(dataProp.dataValue), edit:'string', action:'drill', key:'widget-meter-dataValue:'+keyNo};

				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label','%DeepSee'),value:zenGet(dataProp.label), edit:'string', action:'drill', key:'widget-meter-label:'+keyNo};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Style','%DeepSee'),value:zenGet(meter.labelStyle), action:'drill', key:'widget-meter-labelStyle:'+keyNo, text:''};

				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Upper Range','%DeepSee'),value:zenGet(dataProp.rangeUpper), edit:'string', action:'drill',key:'widget-meter-rangeUpper:'+keyNo};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lower Range','%DeepSee'),value:zenGet(dataProp.rangeLower), edit:'string', action:'drill',key:'widget-meter-rangeLower:'+keyNo};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Upper Threshold','%DeepSee'),value:zenGet(dataProp.thresholdUpper), edit:'string', action:'drill',key:'widget-meter-thresholdUpper:'+keyNo};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lower Threshold','%DeepSee'),value:zenGet(dataProp.thresholdLower), edit:'string', action:'drill',key:'widget-meter-thresholdLower:'+keyNo};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Target Value','%DeepSee'),value:zenGet(dataProp.targetValue), edit:'string', action:'drill',key:'widget-meter-targetValue:'+keyNo};

				content.items[content.items.length] = {display:'section', caption:$$$Text('Styles','%DeepSee')};
				content.items[content.items.length] = {display:'caption', caption:$$$Text('Apply Style to All Meters','%DeepSee'), action:'select', key:'widget-meter-ApplyStyle:'+keyNo, style:'color:darkblue;'};

				// meter specific settings
				switch(meter && meter._type) {
				case 'trafficLight':
				case 'lightBar':
				case 'fuelGauge':
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Body Style','%DeepSee'),value:zenGet(meter.outerBodyStyle), action:'drill', key:'widget-meter-outerBodyStyle:'+keyNo, text:''};
					break;
				case 'speedometer':
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Outer Circle','%DeepSee'),value:zenGet(meter.outerCircleStyle), action:'drill', key:'widget-meter-outerCircleStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Middle Circle','%DeepSee'),value:zenGet(meter.midCircleStyle), action:'drill', key:'widget-meter-midCircleStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Ring','%DeepSee'),value:zenGet(meter.ringStyle), action:'drill', key:'widget-meter-ringStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Inner Circle','%DeepSee'),value:zenGet(meter.innerCircleStyle), action:'drill', key:'widget-meter-innerCircleStyle:'+keyNo, text:''};

					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Nub','%DeepSee'),value:zenGet(meter.nubStyle), action:'drill', key:'widget-meter-nubStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Needle','%DeepSee'),value:zenGet(meter.needleStyle), action:'drill', key:'widget-meter-needleStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Separators','%DeepSee'),value:zenGet(meter.separatorStyle), action:'drill', key:'widget-meter-separatorStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Thin Needle','%DeepSee'),value:zenGet(meter.thinNeedle), edit:'switch', key:'widget-meter-thinNeedle:'+keyNo};

					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Odometer Box','%DeepSee'),value:zenGet(meter.odometerBoxStyle), action:'drill', key:'widget-meter-odometerBoxStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Odometer Style','%DeepSee'),value:zenGet(meter.odometerTextStyle), action:'drill', key:'widget-meter-odometerTextStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Labels','%DeepSee'),value:zenGet(meter.valueLabelStyle), action:'drill', key:'widget-meter-valueLabelStyle:'+keyNo, text:''};

					break;
				case 'smiley':
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Persona','%DeepSee'),value:zenGet(meter.persona), edit:'choice', key:'widget-meter-persona:'+keyNo, valueList:'classic,alien,pirate',displayList:'Classic,Alien,Pirate'};
					break;
				case 'textMeter':
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'),value:zenGet(meter.backgroundStyle), action:'drill', key:'widget-meter-backgroundStyle:'+keyNo, text:''};
					//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'),value:zenGet(meter.opacity), action:'drill', key:'widget-meter-opacity:'+keyNo, text:''}; // JSL4483
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Style','%DeepSee'),value:zenGet(meter.normalStyle), action:'drill', key:'widget-meter-normalStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Low Style','%DeepSee'),value:zenGet(meter.lowStyle), action:'drill', key:'widget-meter-lowStyle:'+keyNo, text:''};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('High Style','%DeepSee'),value:zenGet(meter.highStyle), action:'drill', key:'widget-meter-highStyle:'+keyNo, text:''};
					break;
				}
			}

			if (ckey == 'widget-meter-General') {
				content.title = $$$Text('General Meter Settings','%DeepSee');
				// break out list of meters
				content.items[content.items.length] = {display:'image-caption-hz', image:'deepsee/ds2_dashboard_44.png', caption:$$$Text('Meters','%DeepSee'), action:'drill', key:'widget-meter-List'};
			}
		}
		break;

	case 'widget-meter-label':
		// label for meter
		content.title = $$$Text('Label','%DeepSee');
		var meter = this._selectedMeter;

		var list = [
			{ caption:$$$Text('Auto','%DeepSee'), value:'$auto',hint:$$$Text('Select a default label automatically','%DeepSee')},
		];

		content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(meter.label),$$$Text('Label','%DeepSee'),$$$Text('Select a label for this data property','%DeepSee'));
		break;

	case 'widget-meter-dataValue':
	case 'widget-meter-rangeUpper':
	case 'widget-meter-rangeLower':
	case 'widget-meter-thresholdUpper':
	case 'widget-meter-thresholdLower':
	case 'widget-meter-targetValue':
		// list of possible data values
		content.title = $$$Text('Properties','%DeepSee');
		/*

		var list = [];

		// get list of properties from our controller
		var controller = this.getDataController();		
		var pcount  = controller.getDimSize(2);
		for (var n = 0; n < pcount; n++) {
			list[list.length] = {value:controller.getLabel(n,2)};
		}
		content.html = navigator.getChooserListHTML(list,key,value);
		*/

		// get data property list
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var options = zenPage.fetchOptionList('widget-property',widgetDef.dataSource);
		if (options && options.children) {
			var list = options.children;
			content.html = navigator.getChooserListHTML(list,key,value);
		}
		break;

		// svg styles
	case 'widget-meter-outerBodyStyle':
	case 'widget-meter-outerCircleStyle':
	case 'widget-meter-midCircleStyle':
	case 'widget-meter-ringStyle':
	case 'widget-meter-innerCircleStyle':
	case 'widget-meter-nubStyle':
	case 'widget-meter-separatorStyle':
	case 'widget-meter-odometerBoxStyle':
	case 'widget-meter-needleStyle':
	case 'widget-meter-backgroundStyle':
		// pull apart style
		var attr = ckey.toString().split('-')[2];
		title = $$$Text('Style','%DeepSee');

		var meter = this._selectedMeter;
		if (!meter) { 
			break;
		}
		var style = zenGet(meter[attr]);
		var info = navigator.parseStyleSVG(style);

		var fill = info['fill'] ? info['fill'] : 'transparent';
		var stroke = info['stroke'] ? info['stroke'] : 'none';
		var strokeWidth = zenGet(info['stroke-width']);
		var opacity = zenGet(info['opacity']);
		var strokeDashArray = info['stroke-dasharray'];
		switch (strokeDashArray) {
		case '1,6':
			strokeDashArray = 'dotted';
			break;
		case '10,10':
			strokeDashArray = 'dashed';
			break;
		default:
			strokeDashArray = 'solid';
			break;
		}

		opacity = opacity==='' ? 1.0 : opacity;

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Fill','%DeepSee'), action:'drill', value:fill,	key:ckey+'-fill:'+keyNo, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fill+';', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:opacity,	key:ckey+'-opacity:'+keyNo};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line','%DeepSee'), action:'drill', value:'',	key:ckey+'-stroke:'+keyNo, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+stroke+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Width','%DeepSee'), edit:'slider-toggle', value:strokeWidth,	key:ckey+'-stroke-width:'+keyNo, minValue:0, maxValue:25, stepSize:0.25};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Style','%DeepSee'), edit:'choice', value:strokeDashArray,	key:ckey+'-stroke-dasharray:'+keyNo, valueList:'solid,dashed,dotted', displayList:'solid,dashed,dotted'};
		break;

		// text styles
	case 'widget-meter-labelStyle':
	case 'widget-meter-normalStyle':
	case 'widget-meter-lowStyle':
	case 'widget-meter-highStyle':
	case 'widget-meter-valueLabelStyle':
	case 'widget-meter-odometerTextStyle':
		var attr = ckey.toString().split('-')[2];
		title = $$$Text('Style','%DeepSee');

		var meter = this._selectedMeter;
		if (!meter) { 
			break;
		}
		var style = zenGet(meter[attr]);

		// pull apart style from incoming value
		var info = navigator.parseStyleSVG(style);

		var fill = info['fill'] ? info['fill'] : 'transparent';
		var stroke = info['stroke'] ? info['stroke'] : 'none';
		var strokeWidth = zenGet(info['stroke-width']);

		var fontFamily = zenGet(info['font-family']);
		var fontSize = zenGet(info['font-size']);
		fontSize = fontSize ? parseFloat(fontSize) : fontSize;
		var opacity = zenGet(info['opacity']);
		opacity = opacity==='' ? 1.0 : opacity;

		// webkit only for now!
		var shadow = zenGet(info['text-shadow']);
		shadow = shadow ? true : false;

		var bold = zenGet(info['font-weight']);
		bold = bold ? true : false;

		var italic = zenGet(info['font-style']);
		italic = italic ? true : false;

		var fs = [];
		if (bold) { fs[fs.length] = 'bold'; }
		if (italic) { fs[fs.length] = 'italic'; }
		if (shadow) { fs[fs.length] = 'shadow'; }
		var fontStyle = fs.join(',');

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color','%DeepSee'), action:'drill', value:fill,	key:ckey+'-fill:'+keyNo, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fill+';', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stroke','%DeepSee'), action:'drill', value:stroke,	key:ckey+'-stroke:'+keyNo, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+stroke+';', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stroke Width','%DeepSee'), edit:'slider-toggle', value:strokeWidth,	key:ckey+'-stroke-width:'+keyNo, minValue:0, maxValue:5, stepSize:0.05};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:opacity,	key:ckey+'-opacity:'+keyNo};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%DeepSee'), action:'drill', value:fontFamily,	key:ckey+'-font-family:'+keyNo, style:'font-family:'+fontFamily+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Size','%DeepSee'), edit:'slider-toggle', value:fontSize,	key:ckey+'-font-size:'+keyNo, minValue:4, maxValue:50, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style','%DeepSee'), edit:'choice-multi', value:fontStyle,	key:ckey+'-textStyle:'+keyNo, valueList:'bold,italic,shadow', displayList:'B,I,S', valueStyle:'font-size:12px;font-family:times new roman;', choiceStyles:'font-weight:900;^font-style:italic;^text-shadow:1px 1px 2px #F0F0F0;'};
		break;

	case 'widget-meter-labelStyle-fill':
	case 'widget-meter-labelStyle-stroke':

	case 'widget-meter-valueLabelStyle-fill':
	case 'widget-meter-valueLabelStyle-stroke':
	case 'widget-meter-odometerTextStyle-fill':
	case 'widget-meter-odometerTextStyle-stroke':

	case 'widget-meter-normalStyle-fill':
	case 'widget-meter-normalStyle-stroke':
	case 'widget-meter-lowStyle-fill':
	case 'widget-meter-lowStyle-stroke':
	case 'widget-meter-highStyle-fill':
	case 'widget-meter-highStyle-stroke':
	case 'widget-meter-backgroundStyle-fill':
	case 'widget-meter-backgroundStyle-stroke':
	case 'widget-meter-odometerBoxStyle-fill':
	case 'widget-meter-odometerBoxStyle-stroke':
	case 'widget-meter-separatorStyle-fill':
	case 'widget-meter-separatorStyle-stroke':
	case 'widget-meter-nubStyle-fill':
	case 'widget-meter-nubStyle-stroke':
	case 'widget-meter-needleStyle-fill':
	case 'widget-meter-needleStyle-stroke':
	case 'widget-meter-outerCircleStyle-fill':
	case 'widget-meter-outerCircleStyle-stroke':
	case 'widget-meter-innerCircleStyle-fill':
	case 'widget-meter-innerCircleStyle-stroke':
	case 'widget-meter-midCircleStyle-fill':
	case 'widget-meter-midCircleStyle-stroke':
	case 'widget-meter-ringStyle-fill':
	case 'widget-meter-ringStyle-stroke':
	case 'widget-meter-outerBodyStyle-fill':
	case 'widget-meter-outerBodyStyle-stroke':
		var attr = ckey.toString().split('-')[2];
		title = $$$Text('Style','%DeepSee');
		var k2 = (keyNo === '') ? '' : ':' + keyNo;

		// choose a color
		content.html = navigator.getColorChooserHTML(attr+k2,value,'svg');
		break;

	case 'widget-meter-valueLabelStyle-font-family':
	case 'widget-meter-odometerTextStyle-font-family':
	case 'widget-meter-labelStyle-font-family':
	case 'widget-meter-normalStyle-font-family':
	case 'widget-meter-lowStyle-font-family':
	case 'widget-meter-highStyle-font-family':
		var attr = ckey.toString().split('-')[2];
		title = $$$Text('Font','%DeepSee');
		var k2 = (keyNo === '') ? '' : ':' + keyNo;
		content.html = navigator.getFontChooserHTML(attr+k2,value);
		break;

	case 'widget-meter-MeterType':
		content.title = $$$Text('Meter Type','%DeepSee');
		var meter = this._selectedMeter;
		if (!meter) { 
			break;
		}

		// 158x158 -> 64X64
		var list = [
			{ image:'', value:'', caption:$$$Text('Default','%DeepSee')},
			{ image:'deepsee/speedo_48.gif', value:'speedometer', caption:$$$Text('Speedometer','%DeepSee')},
			{ image:'deepsee/fuel_48.gif', value:'fuelGauge', caption:$$$Text('Fuel Gauge','%DeepSee')},
			{ image:'deepsee/text_box_48.gif', value:'textMeter', caption:$$$Text('Text Meter','%DeepSee')},
			{ image:'deepsee/caution_48.gif', value:'trafficLight', caption:$$$Text('Traffic Light','%DeepSee')},
			{ image:'deepsee/lightbar_48.gif', value:'lightBar', caption:$$$Text('Light Bar','%DeepSee')},
			{ image:'deepsee/smiley_48.gif', value:'smiley', caption:$$$Text('Smiley','%DeepSee')},
		];
		content.html = navigator.getIconListHTML(list,key,zenGet(meter._type));
		break;

	default:
		// pull key apart; dispatch on second piece
		var kt = ckey.toString().split('-');
		switch(kt[1]) {
		case 'common':
			// dispatch to super class
			content = this.invokeSuper('navGetContentForLevel',arguments);
			break;
		}
		break;
	}

	return content;
}

/// Select of item in navigator.
ClientMethod navSelectItem(key, value, which) [ Language = javascript ]
{
	var ckey = key;
	var keyNo = '';
	if (ckey.toString().indexOf(':')>0) {
		var t = ckey.split(':');
		ckey = t[0];
		keyNo = parseInt(t[1]);
	}

	var kt = ckey.toString().split('-');
	var target = kt[1];

	switch(target) {
	case 'meter':
		if (which == 'drill') {
			switch(ckey) {
			case 'widget-meter-Settings':
				// select the meter
				this._selectedMeter = this.getMeter(keyNo);
				break;
			}
		}
		else if (which == 'select') {
			switch(ckey) {
			case 'widget-meter-ApplyStyle':
				// copy style to all other data properties
				var widgetDef = this.getDefinition(zenPage.currWidgetKey);
				var masterMeter = this.getMeter(keyNo);
				var masterMeter = this._selectedMeter;
				if (!masterMeter) { 
					break;
				}
				for (var n = 0; n < widgetDef.dataProperties.length; n++) {
					if (n!=keyNo) {
						var meter = this.getMeter(n);
						if (meter._type == masterMeter._type) {
							widgetDef.dataProperties[n].override = widgetDef.dataProperties[keyNo].override;
						}
					}
				}
				zenPage.setModified(true);
				if (zenPage.recreateWidget) {
					zenPage.recreateWidget(this.widgetKey);
				}
				var nav = zenPage.getNavigator();
				if (nav) {
					nav.refreshTopSheet();
				}
				break;
			}
		}
		break;
	default:
		// send to super
		this.invokeSuper('navSelectItem',arguments);
		break;
	}
}

/// Click on header button in navigator.
ClientMethod navHeaderButtonClick(key) [ Language = javascript ]
{
	var ckey = key;
	var keyNo = '';
	if (ckey.toString().indexOf(':')>0) {
		var t = ckey.split(':');
		ckey = t[0];
		keyNo = parseInt(t[1]);
	}

	var kt = ckey.toString().split('-');
	var target = kt[0];

	switch(target) {
	case 'meter':
		switch(ckey) {
		case 'meter-meterAdd':
			// add a new "data property"
			var widgetDef = this.getDefinition(zenPage.currWidgetKey);
			var dp = this.newDataProperty();
			widgetDef.dataProperties[widgetDef.dataProperties.length] = dp;
			zenPage.setModified(true);
			if (zenPage.recreateWidget) {
				zenPage.recreateWidget(this.widgetKey);
			}
			var nav = zenPage.getNavigator();
			if (nav) {
				nav.refreshTopSheet();
			}
			break;
		}
		break;
	default:
		// send to super
		this.invokeSuper('navHeaderButtonClick',arguments);
		break;
	}
}

/// Click on close button in navigator.
ClientMethod navCloseButtonClick(key) [ Language = javascript ]
{
	// key may take the form key:no
	var ckey = key;
	var keyNo = '';
	if (ckey.toString().indexOf(':')>0) {
		var t = ckey.split(':');
		ckey = t[0];
		keyNo = parseInt(t[1]);
	}

	switch(ckey) {
	case 'widget-meter-Settings':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef) {
			if (confirm('Do you wish to delete this meter?')) {
				widgetDef.dataProperties.splice(keyNo,1);
				zenPage.setModified(true);
				zenPage.recreateWidget(zenPage.currWidgetKey);
				var nav = zenPage.getNavigator();
				if (nav) {
					nav.refreshTopSheet();
				}
			}
		}
		break;
	default:
		// send to super
		this.invokeSuper('navCloseButtonClick',arguments);
		break;
	}
}

/// Change of data value in navigator.
ClientMethod navDataChange(key, value, final) [ Language = javascript ]
{
	// JMD1206: make copy of key!
	var ckey = key;
	var navigator = zenPage.getNavigator();
	var legend = this.findComponent('chartLegend');
	var title = '';

	var keyNo = '';
	if (ckey.toString().indexOf(':')>0) {
		var t = key.split(':');
		ckey = t[0];
		keyNo = parseInt(t[1]);
	}

	// pull 'widget-' off of key
	var kt = ckey.toString().split('-');
	kt.splice(0,1);
	var k2 = kt.join('-');
	var target = kt[0];

	// now test 2nd piece of key
	switch (target) {
	case 'common':
		this.invokeSuper('navDataChange',arguments);
		break;

	case 'meter':
		var attr = k2.toString().split('-')[1];
		var widgetDef = this.getDefinition();
		var dataProp = widgetDef.dataProperties[keyNo];
		var meter = this._selectedMeter;
		if (!meter) {
			break;
		}

		var isOverride = false;
		var recreate = false;

		// apply change to dataProperty and/or meter based on type
		switch (attr) {
		case 'labelStyle':
		case 'normalStyle':
		case 'valueLabelStyle':
		case 'odometerTextStyle':
		case 'lowStyle':
		case 'highStyle':
		case 'backgroundStyle':
		case 'odometerBoxStyle':
		case 'nubStyle':
		case 'separatorStyle':
		case 'needleStyle':
		case 'outerCircleStyle':
		case 'innerCircleStyle':
		case 'midCircleStyle':
		case 'ringStyle':
		case 'outerBodyStyle':
			isOverride = true;
			t = k2.toString().split('-');
			t.splice(0,2);
			var styleProp = t.join('-');
			title = styleProp;

			// fold attr into style
			var styleValues = {};
			if (styleProp && styleProp.length) {
				switch(styleProp) {
				case 'textStyle':
					var cv = value.toString().split(',');
					for (var n = 0; n < cv.length; n++) {
						styleValues[cv[n]] = true;
					}
					styleProp = null;
					break;
				case 'opacity':
					value = value >=1 ? '' : value;
					this.setOpacity(value);  // JSL4483
					break;
				case 'font-size':
					// *some* svg requires units
					value = (value==='') ? value : (parseFloat(value) + 'px');
					break;
				case 'stroke-dasharray':
					switch (value) {
					case 'dotted':
						value = '1,6';
						break;
					case 'dashed':
						value = '10,10';
						break;
					case 'solid':
					default:
						value = '';
						break;
					}
					break;
				}

				var style = meter.getProperty(attr);
				var info = navigator.parseStyleSVG(style);
				if (styleProp) {
					info[styleProp] = value;
				}
				if (styleValues.bold) {
					info['font-weight'] = 'bold';
				}
				else {
					delete info['font-weight'];
				}
				if (styleValues.italic) {
					info['font-style'] = 'italic';
				}
				else {
					delete info['font-style'];
				}
				if (styleValues.shadow) {
					info['text-shadow'] = '1px 1px 1px #808080';
				}
				else {
					delete info['text-shadow'];
				}
				style = navigator.convertCSSToText(info);
				meter.setProperty(attr,style);

				// make sure navigator shows current value
				var spec = navigator.getParentSpec();
				spec.value = style;
			}
			break;
		case 'label':
		case 'rangeUpper':
		case 'rangeLower':
		case 'thresholdUpper':
		case 'thresholdLower':
		case 'targetValue':
			isOverride = true;
			dataProp[attr] = value;
			meter.setProperty(attr,value);
			break;
		case 'dataValue':
			isOverride = true;
			dataProp[attr] = value;
			recreate = true;
			break;
		case 'persona':
			isOverride = true;
			meter.setProperty(attr,value);
			break;
		case 'thinNeedle':
			isOverride = true;
			meter.setProperty(attr,value?true:false);
			break;

		case 'MeterType':
			// cache old meter type so that we can restore it
			if (!zenPage._oldMeterType) {
				zenPage._oldMeterType = meter._type;
			}
			var svg = this.findComponent('svgFrame');
			this.setMeterType(svg,meter,value);
			isOverride = true;
			break;

		default:
			alert('Unhandled attr ' + attr);
			break;
		}

		// update overrides
		if (final) {
			if (ckey == 'widget-meter-MeterType') {
				delete zenPage._oldMeterType;
			}
			zenPage.setModified(true);
			var widgetDef = this.getDefinition();
			if (widgetDef && (isOverride||recreate)) {
				var dataProp = widgetDef.dataProperties[keyNo];

				// ignore properties in the skip list
				var skip = {
					parent:true, window:true, controller:true, controllerId:true, 
					superClass:true, seriesSize:true, seriesCount:true,
					odometerFormat:true,
					label:true
				}
				var jsonOver = this.componentToJSON(meter,0,skip);

				dataProp.subtype = meter._type;
				if (zenGet(widgetDef.themeOverrides[meter._type])!=jsonOver) {
					dataProp.override = jsonOver;
				}
				else {
					dataProp.override = '';
				}

				if (recreate) {
					if (zenPage.recreateWidget) {
						zenPage.recreateWidget(this.widgetKey);
					}
				}
			}
		}
		break;
	default:
		break;
	}
}

/// Test if there are any style overrides for this widget.
ClientMethod hasOverrides() [ Language = javascript ]
{
	var result = false;
	var widgetDef = this.getDefinition();
	if (widgetDef) {
		// check every dataProperty
		for (var n = 0; n < widgetDef.dataProperties.length; n++) { 
			var dataProp = widgetDef.dataProperties[n];
			if (dataProp.override) {
				result = true;
				break;
			}
		}
	}
	return result;
}

/// Reset any style overrides for this widget.
ClientMethod resetOverrides(themeOnly) [ Language = javascript ]
{
	var widgetDef = this.getDefinition();
	if (widgetDef) {
		// check every dataProperty
		for (var n = 0; n < widgetDef.dataProperties.length; n++) { 
			var dataProp = widgetDef.dataProperties[n];
			if (dataProp.override) {
				zenPage.setModified(true);
				dataProp.override = '';
			}
		}
		if (zenPage.recreateWidget) {
			zenPage.recreateWidget(this.widgetKey);
		}
	}
}

/// Return an array of current style overrides for this widget.
/// Used to save to a theme.
ClientMethod getOverrides() [ Language = javascript ]
{
	var overrides = {};
	var widgetDef = this.getDefinition();
	if (widgetDef) {
		// check every dataProperty
		for (var n = 0; n < widgetDef.dataProperties.length; n++) { 
			var dataProp = widgetDef.dataProperties[n];
			if (dataProp.override) {
				var meter = this.getMeter(n);
				if (meter) {
					if (widgetDef.themeOverrides && widgetDef.themeOverrides[meter._type]) {
						overrides[meter._type] = widgetDef.themeOverrides[meter._type];
					}
					if (dataProp.override) {
						overrides[meter._type] = dataProp.override;
					}
				}
			}
		}
	}
	return overrides;
}

/// Return the number of meters displayed within this widget.
ClientMethod getMeterCount() [ Language = javascript ]
{
	return parseInt(this.meterCount);
}

ClientMethod newDataProperty() [ Language = javascript ]
{
	return {
"_class":"%DeepSee.Dashboard.DataProperty",
"align":"",
"baseValue":"",
"dataValue":"",
"display":"value",
"format":"",
"label":"$auto",
"name":"",
"override":"",
"rangeLower":"",
"rangeUpper":"",
"showAs":"value",
"style":"",
"subtype":"",
"summary":"",
"summaryValue":"",
"targetValue":"",
"thresholdLower":"",
"thresholdUpper":"",
"valueColumn":false,
"width":""
}
}

/// Set the type of the given meter.
ClientMethod setMeterType(svg, meter, type) [ Language = javascript ]
{
	if (''==type) {
		if ('undefined' != typeof zenPage._oldMeterType) {
			// restore to cached type
			type = zenPage._oldMeterType;
		}
		else {
			return;
		}
	}
	if (null==meter) return;

	var newType = type;
	if (newType != meter._type) {
		var newMeter = zenPage.createComponent(newType);
		newMeter.setProperty('controllerId',meter.controllerId);
		newMeter.setProperty('width',meter.width * (newMeter.viewBoxWidth/meter.viewBoxWidth));
		newMeter.setProperty('height',meter.height * (newMeter.viewBoxHeight/meter.viewBoxHeight));

		// copy over other settings
		newMeter.label = meter.label;
		newMeter.labelStyle = meter.labelStyle;
		newMeter.targetValue = meter.targetValue;
		newMeter.rangeUpper = meter.rangeUpper;
		newMeter.rangeLower = meter.rangeLower;
		newMeter.thresholdUpper = meter.thresholdUpper;
		newMeter.thresholdLower = meter.thresholdLower;
		newMeter.scaleFactor = meter.scaleFactor;
		newMeter.animate = meter.animate;
		newMeter.disabled = meter.disabled;
		newMeter.dataBinding = meter.dataBinding;
		newMeter.showConditionally = meter.showConditionally;

		// find ordinal position of old meter
		var idx = 0;
		for (var n = 0; n < svg.children.length; n++) {
			if (svg.children[n].id == meter.id) {
				idx = n;
				break;
			}
		}
		meter.unrender();
		// svg.addChild(newMeter);
		// insert child at specific position
		svg.children.splice(idx,0,newMeter);
		newMeter.parent = svg;
	
		// render the new component (if we are rendered)
		if (svg.document && svg.svgGroup) {
			newMeter.renderSVG(svg.document,svg.svgGroup);
		}

		svg.removeChild(meter);
		newMeter.setProperty('id',meter.id);
		if (this._selectedMeter==meter) {
			this._selectedMeter = newMeter;
		}
		meter = newMeter;
		svg.layoutChildren();
	}
}

/// Notification that this widget is selected / unselected.
ClientMethod onSetHighlight(flag) [ Internal, Language = javascript ]
{
	var svg = this.findComponent('svgFrame');
	if (svg) {
		svg.setProperty('editMode',flag?'select':'none');
	}
}

/// Notification that a meter is selected.
ClientMethod meterSelected(meter) [ Internal, Language = javascript ]
{
	if (this._selectedMeter != meter) {
		this._selectedMeter = meter;
		var nav = zenPage.getNavigator();
		if (nav) {
			nav.refreshTopSheet();
		}
	}
}

/// PDF export for SVG using the svgImageProvider
ClientMethod exportPDF(printMultiple, preserveTempFiles) [ Language = javascript ]
{
	// Method added by DTB250
	var parms = {};
	var table = this.getDataController();
	// pull print settings from widgetDef.properties;
	var widgetDef = this.getDefinition();
	
	printMultiple = (printMultiple) ? printMultiple : false;				// DTB251 - For multi-tab browser display
	preserveTempFiles = (preserveTempFiles) ? preserveTempFiles : false;	// DTB251 - For merging into a single PDF
	
	// Find filter values and names from the data source
	var filterNames = [];
	var filterValues = [];

	if (''!==table.kpi) {
		if (table&&table.filters) {
			// get filter values
			for (var n = 0; n < table.filters.length; n++) {
				var filter = table.filters[n];
				if (filter.text!='') {
					filterNames[filterNames.length] = filter.spec;
					var val = filter.text.toString();
					// unquote
					if ('&'==val.charAt(0)) {
						val = val.substring(2,val.length-1);
					}
					filterValues[filterValues.length] = val;
				}
			}
		}
		else {
			// Try to print filters from the widget state
			for (var filter in this.filterText) {
				var filterValue = this.filterText[filter]
				if (filterValue) {
					filterNames[filterNames.length] = filter;
					filterValues[filterValues.length] = filterValue;
				}
			}	
		}
		
		// Try to add pivot variables
		for (prop in table.pivotVariables) {
			filterNames[filterNames.length]= prop;
			filterValues[filterValues.length] = table.pivotVariables[prop];
		}
	}
	else if ((''!=table.cubeName) && (''!=table.queryKey)) {
		table.getFilterInfo(filterNames, filterValues);
	}
	
	// Convert the filters into a single table that can be printed
	var util = zenPage.getComponentById("svgUtil");
	
 	parms.title = widgetDef.title;
 	parms.filterTable = util.prepareFilterTable(filterNames,filterValues);
 	parms.preserveTempFiles = preserveTempFiles;		// DTB251 - Add option to preserve temp files
 	parms.printMultiple = printMultiple;				// DTB251 - Communicate multiple widget print to the printer
	
	this.prepareSvgPrintParameters(parms);				// DTB565 - Normalize the printing parameters
	
	this.printSVGContent(this.id+'/svgFrame',parms);
}

/// This callback is called just before controls are added to the top of the widget.
/// <var>pGroup</var> is the header in which new Zen control can be added.
Method %OnCreateControls(pGroup As %ZEN.Component.group) As %Status
{
	// get default values for widget properties
	Do ..%GetWidgetPropertyInfo(..subtype,.tList)
	Set n = $O(tList(""))
	While (n'="") {
		Set tName = $LG(tList(n),1)
		Set tPValue(tName) = ..%definition.properties.GetAt(tName)
		Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
		Set n = $O(tList(n))
	}
	
		// pdf export
	If (+$G(tPValue("print"))) {
		Set tButton = ##class(%ZEN.Component.image).%New()
		Set tButton.src = "deepsee/ds2_printer_22.png"
		Set tButton.title = $$$Text("Create PDF from this scorecard","%DeepSee")
		If (..previewMode) {
			Set tButton.disabled = 1
		}
		Else {
			Set tButton.onclick = "zenPage.getComponent("_..index_").exportPDF();"
		}
		Do pGroup.%AddChild(tButton)
	}
	
	Quit $$$OK
}

}
