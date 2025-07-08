/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents the definition of a visual widget (such as a chart) within a user-defined DeepSee dashboard.
/// This is what is saved to disk, not the actual visual component.
Class %DeepSee.Dashboard.Widget Extends (%SerialObject, %XML.Adaptor) [ Final, System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "widget";

Parameter XMLIGNORENULL = 1;

/// Identifying name for this widget. This is used to logically identify the widget within
/// a dashboard (such as for sending filter events to it).
Property name As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Internal key used to track this widget instance.
Property key As %String(MAXLEN = 255, XMLPROJECTION = "none") [ Internal ];

/// Which type of widget to display.
/// This is the class name of a widget. If no class package is provided, then
/// "%DeepSee.Component.Widget" is used.
Property type As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Widget subtype.
/// This is used by widgets that support various subtypes (such as a meter).
Property subtype As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Widget subtype class.
/// If the user overrides the subtype class (such as in a chart or meter), this
/// holds the actual type.
Property subtypeClass As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Title to display for the widget.<br/>
/// Long titles may not display well.
Property title As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Name of the data source for the widget.
/// This is the name of the data source originally defined for this widget.
/// It may be the case that the widget is using a local override of the data source
/// (such as when a user uses the "analyze" button on a pivot widget).
Property dataSource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Name of local datasource, if the user has made a local modification to its datasource.
/// This is stored in the dashboard settings global.
Property localDataSource As %String(MAXLEN = 255, XMLPROJECTION = "none") [ Transient ];

/// Indicates that the user-specific localDataSource for this widget should be cleared when this widget is saved.
Property resetDataSource As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Transient ];

/// If defined, this the name of a widget on the dashboard that provides the data for this widget.
/// This overrides <property>dataSource</property> if present.
Property dataLink As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Name of the drill down data source for the widget.
/// This is the name of a data source used when the user performs a "drill down" operation
/// (if supported) on the widget. (This is a dashboard to display when the user drills down on
/// a cell within a pivot widget).
Property drillDownDataSource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Top position of the widget.
Property top As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Left position of the widget.
Property left As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Width of the widget.
Property width As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Height of the widget.
Property height As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// HTML content of sidebar.
Property sidebarContent As %ZEN.Datatype.html(XMLPROJECTION = "attribute");

/// Specify whether to display a sidebar.
Property showSidebar As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Width of sidebar area.
Property sidebarWidth As %ZEN.Datatype.length(XMLPROJECTION = "attribute");

/// Set of controls displayed within this widget.
Property controls As list Of Control(XMLNAME = "control", XMLPROJECTION = "element");

/// Set of dataProperties displayed within this widget.
/// (Interpretation of this is dependent on the type of widget in use).
Property dataProperties As list Of DataProperty(XMLNAME = "dataProperty", XMLPROJECTION = "element");

/// Array of additional property values to apply to the widget.
Property properties As array Of %String(MAXLEN = 5000, XMLKEYNAME = "name", XMLNAME = "property", XMLPROJECTION = "ELEMENT");

/// Set of data series used displayed within this widget.
Property dataSeries As list Of ChartDataSeries(XMLNAME = "dataSeries", XMLPROJECTION = "element");

/// Array of filter states for the widget.
/// Each name is of the form: [DIM].[HIER].[LEVEL]<br/>
/// Each value is an MDX key value.
Property filterState As array Of %String(MAXLEN = 5000, XMLKEYNAME = "name", XMLNAME = "filterState", XMLPROJECTION = "ELEMENT");

/// Array of additional override values (such as chart state) to apply to the widget.
Property overrides As array Of %String(MAXLEN = 30000, XMLKEYNAME = "name", XMLNAME = "override", XMLPROJECTION = "ELEMENT");

/// If true, this widget should be maximized when first displayed.
Property maximized As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// homeRow position (landscape) of the widget (if in snap grid mode).
Property homeRowL As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// homeCol position (landscape) of the widge (if in snap grid mode)t.
Property homeColL As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// colSpan (landscape) of the widget (if in snap grid mode).
Property colSpanL As %Integer(MINVAL = 1, XMLPROJECTION = "attribute");

/// rowSpan (landscape) of the widget (if in snap grid mode).
Property rowSpanL As %Integer(MINVAL = 1, XMLPROJECTION = "attribute");

/// homeRow position (portrait) of the widget (if in snap grid mode).
Property homeRowP As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// homeCol position (portrait) of the widge (if in snap grid mode)t.
Property homeColP As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// colSpan (portrait) of the widget (if in snap grid mode).
Property colSpanP As %Integer(MINVAL = 1, XMLPROJECTION = "attribute");

/// rowSpan (portrait) of the widget (if in snap grid mode).
Property rowSpanP As %Integer(MINVAL = 1, XMLPROJECTION = "attribute");

/// Specify whether to display a toolbar.
Property showToolbar As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Specify whether to display the separator between the toolbar and widget content
Property showToolbarBottomBorder As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Specify whether to display a toolbar.
Property showToolbarOnlyWhenMaximized As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Specify color of toolbar
Property colorToolbar As %ZEN.Datatype.color(XMLPROJECTION = "attribute") [ InitialExpression = "#F0F0F0" ];

/// Specify opacity of toolbar
Property opacityToolbar As %ZEN.Datatype.float(XMLPROJECTION = "attribute") [ InitialExpression = 1.0 ];

/// JSL4483 color of widget background
Property backgroundColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute") [ InitialExpression = "#F0F0F0" ];

/// JSL4483 opacity of widget background
Property opacity As %ZEN.Datatype.float(XMLPROJECTION = "attribute") [ InitialExpression = 1.0 ];

/// If defined, this the name of a theme provides the styles for this widget.
Property theme As %String(MAXLEN = 512, XMLPROJECTION = "attribute");

/// Transient array of additional override values that come from the theme for this widget.
Property themeOverrides As array Of %String(MAXLEN = 30000, XMLPROJECTION = "NONE") [ Transient ];

/// Optional. Name of termlist (with or without extension) that supplies data-driven colors
/// for chart series.
Property dataColorList As %ZEN.Datatype.string(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Return the name of the data source for this widget.
/// If there is a local override, return it.
Method %GetDataSource() As %String
{
	Quit $S(..localDataSource'="":..localDataSource,1:..dataSource)
}

/// Create a visual widget component using this definition.<br/>
/// <var>pURLSettings</var> is an array of settings values pulled out of the URL.
Method %CreateVisualWidget(Output pWidget As %DeepSee.Component.Widget.widget, ByRef pURLSettings As %String, pPreviewMode As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pWidget = ""
		Set tClassName = ""
		If (..type '= "") {
			Set tClassName = ..type
			If (tClassName '[ ".") {
				Set tClassName = "%DeepSee.Component.Widget." _ tClassName
			}
		}
		
		If (tClassName = "") {
			Quit
		}

		Set pWidget = $classmethod(tClassName,"%New")
		Set pWidget.previewMode = pPreviewMode
		Set pWidget.%definition = ##this // make def available to widget
		Set pWidget.subtype = ..subtype
		Set pWidget.name = ..name
		Set ..key = $ZCRC(..name,7)		// DTB436 - Use a stable key linked to the widget name
		Set pWidget.widgetKey = ..key
		// JMD1118
		Set pWidget.header = ##class(%DeepSee.UserPortal.Utils).%ResolveText(..title)
		Set pWidget.sidebarContent = ..sidebarContent
		Set pWidget.showSidebar = ..showSidebar
		Set pWidget.sidebarWidth = ..sidebarWidth		// DTB122
		Set pWidget.showToolbar = $S(..showToolbar="":1,1:..showToolbar)
		Set pWidget.showToolbarBottomBorder = ..showToolbarBottomBorder		// DTB171
		Set pWidget.showToolbarOnlyWhenMaximized = ..showToolbarOnlyWhenMaximized // WAL105
		Set pWidget.colorToolbar = ..colorToolbar // JSL4483
		Set pWidget.opacityToolbar = ..opacityToolbar // JSL4483
		Set pWidget.opacity = $S(..opacity="":1,1:..opacity) // JSL4483
		Set pWidget.backgroundColor = ..backgroundColor // JSL4483

		// copy settings into the visual widget
		// settings for *all* items
		Set n = $O(pURLSettings("*",""))
		While (n'="") {
			Do pWidget.settings.SetAt(pURLSettings("*",n),n)
			Set n = $O(pURLSettings("*",n))
		}
		If (..name'="") {
			// settings for *this* item
			Set n = $O(pURLSettings(..name,""))
			While (n'="") {
				Do pWidget.settings.SetAt(pURLSettings(..name,n),n)
				Set n = $O(pURLSettings(..name,n))
			}
		}

		// see if there is a theme;
		// if so, copy overides into local collection
		Do ..themeOverrides.Clear()
		If (..theme'="") {
			Set tTheme = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..theme)
			If $IsObject(tTheme) {
				Set key = tTheme.overrides.Next("")
				While (key'="") {
					Set value = tTheme.overrides.GetAt(key)
					Do ..themeOverrides.SetAt(value,key)
					Set key = tTheme.overrides.Next(key)
				}
			}
		}

		// apply property overrides (???)
		Set key = ..properties.Next("")
		While (key'="") {
			Set value = ..properties.GetAt(key)
			Set key = ..properties.Next(key)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set pWidget = ""
	}
	Quit tSC
}

/// Copy contents of this widget to <var>pTarget</var>.
Method %CopyTo(ByRef pTarget) As %Status
{
	Set tSC = $$$OK
	Try {
		If pTarget.%IsA("%DeepSee.Dashboard.Widget") {
			// Dispatch to the widget copy
			Set tSC = ..%CopyToDef(.pTarget)
		}
		Else {
			// Dispatch to the Dao copy
			Set tSC = ..%CopyToDao(.pTarget)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %CopyToDef(ByRef pTarget As %DeepSee.Dashboard.Widget) As %Status
{
	Set tSC = $$$OK

	Try {
		Set pTarget.name = ..name
		Set pTarget.type = ..type
		Set pTarget.subtype = ..subtype
		Set pTarget.title = ..title
		Set pTarget.dataSource = ..dataSource
		Set pTarget.localDataSource = ..localDataSource
		Set pTarget.drillDownDataSource = ..drillDownDataSource
		Set pTarget.width = ..width
		Set pTarget.height = ..height
		Set pTarget.sidebarContent = ..sidebarContent
		Set pTarget.showSidebar = ..showSidebar
		Set pTarget.sidebarWidth = ..sidebarWidth
		Set pTarget.showToolbar = ..showToolbar
		Set pTarget.showToolbarBottomBorder = ..showToolbarBottomBorder		// DTB171
		Set pTarget.showToolbarOnlyWhenMaximized = ..showToolbarOnlyWhenMaximized  // WAL105
		Set pTarget.colorToolbar = ..colorToolbar // JSL4483
		Set pTarget.opacityToolbar = ..opacityToolbar // JSL4483
		Set pTarget.opacity = ..opacity // JSL4483
		Set pTarget.backgroundColor = ..backgroundColor // JSL4483
		set pTarget.theme = ..theme // JSL4453 - theme was missing
		// JMD1170 (make sure add from catalog picks up override)
		Set pTarget.subtypeClass = ..subtypeClass
		Do pTarget.controls.Clear()
		For n=1:1:..controls.Count() {
			Set tControl = ..controls.GetAt(n)
			Set tTargetControl = ##class(Control).%New()
			Set tSC = tControl.%CopyTo(tTargetControl)
			If $$$ISERR(tSC) Quit

			Do pTarget.controls.Insert(tTargetControl)
		}
		If $$$ISERR(tSC) Quit

		Do pTarget.properties.Clear()
		Set key = ..properties.Next("")
		While (key'="") {
			Set value = ..properties.GetAt(key)
			Do pTarget.properties.SetAt(value,key)
			Set key = ..properties.Next(key)
		}

		Do pTarget.dataProperties.Clear()
		For n=1:1:..dataProperties.Count() {
			Set tDataProp = ..dataProperties.GetAt(n)
			Set tTargetProp = ##class(DataProperty).%New()
			Set tSC = tDataProp.%CopyTo(tTargetProp)
			If $$$ISERR(tSC) Quit
			Do pTarget.dataProperties.Insert(tTargetProp)
		}
		If $$$ISERR(tSC) Quit

		// JMD1128
		Do pTarget.overrides.Clear()
		Set key = ..overrides.Next("")
		While (key'="") {
			Set value = ..overrides.GetAt(key)
			Do pTarget.overrides.SetAt(value,key)
			Set key = ..overrides.Next(key)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Copy the contents of this definition to an Dao.
Method %CopyToDao(ByRef pTarget As %DynamicObject = {$$$NULLOREF}) As %Status
{
	Set tSC = $$$OK

	Try {
		// DP-427658 - Initialize a new dynamic object if no object is provided
		Set:('$IsObject(pTarget)) pTarget = {}
 
		Set pTarget.name = ..name
		Set pTarget.type = ..type
		Set pTarget.subtype = ..subtype
		Set pTarget.title = ..title
		Set pTarget.dataSource = ..dataSource
		Set pTarget.localDataSource = ..localDataSource
		Set pTarget.drillDownDataSource = ..drillDownDataSource
		Set pTarget.width = ..width
		Set pTarget.height = ..height
		Set pTarget.sidebarContent = ..sidebarContent
		Set pTarget.showSidebar = ..showSidebar
		Set pTarget.sidebarWidth = ..sidebarWidth
		Set pTarget.showToolbar = ..showToolbar
		Set pTarget.showToolbarBottomBorder = ..showToolbarBottomBorder		// DTB171
		Set pTarget.showToolbarOnlyWhenMaximized = ..showToolbarOnlyWhenMaximized  // WAL105
		Set pTarget.colorToolbar = ..colorToolbar // JSL4483
		Set pTarget.opacityToolbar = ..opacityToolbar // JSL4483
		Set pTarget.opacity = ..opacity // JSL4483
		Set pTarget.backgroundColor = ..backgroundColor // JSL4483
		Set pTarget.theme = ..theme // JSL4453 - theme was missing
		// JMD1170 (make sure add from catalog picks up override)
		Set pTarget.subtypeClass = ..subtypeClass

		If ($P(..dataSource,".",*)="pivot") {
			Set pTarget.baseMDX = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..dataSource).%GetBaseMDX()
		}

		Set tCount = ..controls.Count()
		If tCount {
			Set pTarget.controls = []

			For n=1:1:tCount {
				Set tTargetControl = {}
				Set tSC = ..controls.GetAt(n).%CopyToDao(.tTargetControl)
				If $$$ISERR(tSC) Quit

				Do pTarget.controls.%Push(tTargetControl)
			}
			If $$$ISERR(tSC) Quit
		}

		Set tCount = ..properties.Count()
		If tCount {
			Set pTarget.properties = {}

			Set key = ..properties.Next("")
			While (key'="") {
				Set $PROPERTY(pTarget.properties,key) = ..properties.GetAt(key)
				Set key = ..properties.Next(key)
			}
		}

		Set tCount = ..dataProperties.Count()
		If tCount {
			Set pTarget.dataProperties = []

			For n=1:1:tCount {
				Set tTargetProp = {}
				Set tSC = ..dataProperties.GetAt(n).%CopyToDao(.tTargetProp)
				If $$$ISERR(tSC) Quit

				Do pTarget.dataProperties.%Push(tTargetProp)
			}
			If $$$ISERR(tSC) Quit
		}
		
		Set tCount = ..overrides.Count()
		If tCount {
			Set pTarget.overrides = {}

			Set key = ..overrides.Next("")
			While (key'="") {
				Set $PROPERTY(pTarget.overrides,key) = ..overrides.GetAt(key)
				Set key = ..overrides.Next(key)
			}
		}

	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return a list of all folder items that this widget depends upon.
/// Returns a list of the form:<br/>
/// pList(ITEMNAME) = itemName<br/>
Method %GetDependencies(pList As %String) As %Status
{
	If (..dataSource'="") {
		If '$D(pList($$$UPPER(..dataSource))) {
			Set pList($$$UPPER(..dataSource)) = ..dataSource
			// dispatch
		}
	}

	If (..drillDownDataSource'="") {
		If '$D(pList($$$UPPER(..drillDownDataSource))) {
			Set pList($$$UPPER(..drillDownDataSource)) = ..drillDownDataSource
			// dispatch
		}
	}
	Quit $$$OK
}

/// Diagnostic method: display contents of this widget definition to the console.
Method %Dump() As %Status
{
	Set tSC = $$$OK

	Write ?5,"---------------------------------------------------------",!
	Write ?5,"Widget:",?25,##this,!
	Write ?5,"Name:",?25,..name,!
	Write ?5,"Title:",?25,..title,!
	Write ?5,"Type:",?25,..type,!
	Write ?5,"Subtype:",?25,..subtype,!
	Write ?5,"DataSource:",?25,..dataSource,!
	Write ?5,"Local DataSource:",?25,..localDataSource,!
	Write ?5,"Drill down:",?25,..drillDownDataSource,!

	Write ?5,"Controls:",?25,..controls.Count(),!
	For n=1:1:..controls.Count() {
		Set tControl = ..controls.GetAt(n)
		Write ?10,"----------------------------------------------------",!
		Write ?10,"Control:",?25,tControl,!
		Write ?10,"Control Key:",?25,tControl.controlKey,!
		Write ?10,"Action:",?25,tControl.action,!
		Write ?10,"Target:",?25,tControl.target,!
		Write ?10,"Target Prop:",?25,tControl.targetProperty,!
		Write ?10,"Label:",?25,tControl.label,!
		Write ?10,"Location:",?25,tControl.location,!
		Write ?10,"Type:",?25,tControl.type,!
		Write ?10,"Value:",?25,tControl.value,!
	}


	Quit tSC
}

Storage Default
{
<Data name="WidgetState">
<Value name="1">
<Value>name</Value>
</Value>
<Value name="2">
<Value>type</Value>
</Value>
<Value name="3">
<Value>subtype</Value>
</Value>
<Value name="4">
<Value>title</Value>
</Value>
<Value name="5">
<Value>width</Value>
</Value>
<Value name="6">
<Value>height</Value>
</Value>
<Value name="7">
<Value>top</Value>
</Value>
<Value name="8">
<Value>left</Value>
</Value>
<Value name="9">
<Value>properties</Value>
</Value>
<Value name="10">
<Value>sidebarContent</Value>
</Value>
<Value name="11">
<Value>showSidebar</Value>
</Value>
<Value name="12">
<Value>sidebarWidth</Value>
</Value>
<Value name="13">
<Value>filters</Value>
</Value>
<Value name="14">
<Value>datatype</Value>
</Value>
<Value name="15">
<Value>dataSource</Value>
</Value>
<Value name="16">
<Value>controls</Value>
</Value>
<Value name="17">
<Value>key</Value>
</Value>
<Value name="18">
<Value>dataProperty</Value>
</Value>
<Value name="19">
<Value>dataProperties</Value>
</Value>
<Value name="20">
<Value>autoLink</Value>
</Value>
<Value name="21">
<Value>dataLink</Value>
</Value>
<Value name="22">
<Value>localDataSource</Value>
</Value>
<Value name="23">
<Value>filterState</Value>
</Value>
<Value name="24">
<Value>drillDownDataSource</Value>
</Value>
<Value name="25">
<Value>maximized</Value>
</Value>
<Value name="26">
<Value>dataSeries</Value>
</Value>
<Value name="27">
<Value>homeRowL</Value>
</Value>
<Value name="28">
<Value>homeColL</Value>
</Value>
<Value name="29">
<Value>colSpanL</Value>
</Value>
<Value name="30">
<Value>rowSpanL</Value>
</Value>
<Value name="31">
<Value>homeRowP</Value>
</Value>
<Value name="32">
<Value>homeColP</Value>
</Value>
<Value name="33">
<Value>colSpanP</Value>
</Value>
<Value name="34">
<Value>rowSpanP</Value>
</Value>
<Value name="35">
<Value>overrides</Value>
</Value>
<Value name="36">
<Value>showToolbar</Value>
</Value>
<Value name="37">
<Value>theme</Value>
</Value>
<Value name="38">
<Value>subtypeClass</Value>
</Value>
<Value name="39">
<Value>dataColorList</Value>
</Value>
<Value name="40">
<Value>colorToolbar</Value>
</Value>
<Value name="41">
<Value>opacityToolbar</Value>
</Value>
<Value name="42">
<Value>backgroundColor</Value>
</Value>
<Value name="43">
<Value>opacity</Value>
</Value>
<Value name="44">
<Value>showToolbarOnlyWhenMaximized</Value>
</Value>
<Value name="45">
<Value>showToolbarBottomBorder</Value>
</Value>
</Data>
<State>WidgetState</State>
<StreamLocation>^%DeepSee.Dashboard.WidgetS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
