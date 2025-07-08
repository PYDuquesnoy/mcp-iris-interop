/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized searchBox control for DeepSee searches.
/// This is designed for use within DeepSee components and not as a stand-alone control.
Class %DeepSee.Component.searchBox Extends %ZEN.Component.abstractComboBox [ System = 3 ]
{

Parameter JSINCLUDES = "zenCSLM.js,zenESVG.js,DeepSee.js";

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

Parameter ICONAPPLY = "deepsee/ds2_checkmark_16.png";

Parameter ICONCANCEL = "deepsee/ds2_circlex_22.png";

Parameter ICONSEARCH = "deepsee/ds2_magnify_18.png";

/// Localization domain
Parameter DOMAIN = "%DeepSee";

/// Localized "loading" message displayed by control.<br>
/// This message is temporarily displayed while a server-side query is running.
Property loadingMessage As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Loading...","%ZEN")} ];

/// Name of the DeepSee dataSource driving this dropdown.
Property dataSourceName As %ZEN.Datatype.string;

/// Logical name of the filter supplying the values.
Property filterName As %ZEN.Datatype.string;

/// Maximum number of items to show.
Property maxRows As %ZEN.Datatype.integer [ InitialExpression = 500 ];

/// List of current selected item values.
Property listOfValues As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// List of current selected item text values.
Property listOfText As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// List of item text values from prior searches.
Property priorText As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// List of item values from prior searches.
Property priorValues As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// List of filter specs from other filter controls.
/// This is used to restrict the set of members displayed by this searchBox.
Property relatedFilterSpecs As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// List of filter key values from other filter controls.
/// This is used to restrict the set of members displayed by this searchBox.
Property relatedFilterKeys As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Selection mode: "","not" or "range"
Property selectMode As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// If true, allow selection of multiple items.
Property multiSelect As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, require at least one selected item.
Property valueRequired As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// The type of level that provides data for this control.
Property selectType As %ZEN.Datatype.string;

/// The calendar being used for a time level.
Property calendar As %ZEN.Datatype.string;

/// If defined, name of description property for a level.
Property descriptionProperty As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Display mode.
/// Controls what is displayed in the drop down area.
Property displayMode As %ZEN.Datatype.string(VALUELIST = "list,calendar,custom,measure", XMLPROJECTION = "none") [ InitialExpression = "list" ];

/// If true, use typed in text as a search key. This is set internally.
Property useSearch As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// If true, add any pivot variables associated with the data source. This is ignored if the data source
/// is itself a pivot variable.
Property appendPivotVariables As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// onshowdropdown event handler:
/// This event is fired just as the dropdown is about to be rendered.
Property onshowdropdown As %ZEN.Datatype.eventHandler;

/// List of calculated member values (used for calendar dropdown).
Property listOfCMbrValues As list Of %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// List of calculated member captions (used for calendar dropdown).
Property listOfCMbrText As list Of %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// Value in search box. This is set internally.
Property searchText As %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// If true, then render in preview mode.
Property previewMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Apply icon.
Property iconApply As %ZEN.Datatype.string [ InitialExpression = {..#ICONAPPLY} ];

/// Cancel icon.
Property iconCancel As %ZEN.Datatype.string [ InitialExpression = {..#ICONCANCEL} ];

/// Search icon.
Property iconSearch As %ZEN.Datatype.string [ InitialExpression = {..#ICONSEARCH} ];

/// Optional date format to apply (using DeepSee date format).
Property dateFormat As %ZEN.Datatype.string [ InitialExpression = "mmm d, y" ];

/// Number indicating the first day of the week in the displayed calendar. 0 = Sunday, 6 = Saturday.
Property firstDayOfWeek As %ZEN.Datatype.integer;

/// Optional csv-list of values to use for dropdown
Property valueList As %ZEN.Datatype.csv;

/// Optional csv-list of captions to use for dropdown
Property displayList As %ZEN.Datatype.csv;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

.searchBoxCaption {
	color: gray;
	font-size: 8pt;
	text-align: center;
}

.searchBoxSearchBox {
	font-size: 8pt;
}

.searchBoxDescription {
	font-size: 12px;
	color: #606060;
}

table td.searchBoxTextCellRO {
	color: #404040;
	font-size: 9pt;
	font-weight: bold;
	padding-left: 2px;
}

table td.searchBoxTextCell {
	color: #404040;
	background: white;
	font-size: 9pt;
	font-weight: bold;
	padding-left: 2px;
	border-top: 1px solid #D0D0D0;
	border-left: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
}

table td.searchBoxBtn {
	background: white;
	border-top: 1px solid #D0D0D0;
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	vertical-align: bottom;
}

table td.searchBoxBtn img {
	padding-top: 2px;
	padding-right: 2px;
	padding-left: 2px;
	height: 12px;
}

/* header in dropdown */
table.searchBoxHeader {
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	border-bottom: 1px solid darkgray; 
	height: 30px;
}

/* List within dropdown */
div.searchBoxList {
	height: 190px;
	width: 350px;
	overflow-y: auto;
	overflow-x: hidden;
	background: #F0F0F0;
}

table.searchBoxTable {
	width: 100%;
	border-bottom: 1px solid #D0D0D0;
}

div.searchBoxItemBarDiv {
	height: 20px;
	background: rgb(183,183,204);
	border-bottom: 1px solid #909090;
	padding: 3px;
	font-size: 13px;
	box-shadow: 0px 2px 10px #808080;
}

table tr.searchBoxItemBar {
	background: rgb(183,183,204);
}

table tr.searchBoxItemBar td {
	color: #606060;
	font-weight: bold;
	font-size: 12px;
}

table tr.searchBoxItemOdd,
table tr.searchBoxItemEven {
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.3s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.3s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0.3s;
	transition-timing-function: ease;
	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

table tr.searchBoxItemOdd {
}

table tr.searchBoxItemEven {
	background: white;
}

table tr.searchBoxItemOdd:hover,
table tr.searchBoxItemEven:hover {
	background: #FFEEAA;
}

table.searchBoxTable td.cb {
}

table.searchBoxTable td {
	color: #404040;
	font-family: arial;
	font-size: 14px;
	padding: 4px;
	padding-left: 2px;
	padding-right: 2px;
}

.searchBoxCustomItemEven, 
.searchBoxCustomItemOdd {
	font-size: 14px;
	padding: 5px;
	padding-left: 10px;
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.3s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.3s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0.3s;
	transition-timing-function: ease;
	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

.searchBoxCustomItemEven {
	background: #F8F8F8;
}

.searchBoxCustomItemOdd {
	background: white;
}

.searchBoxCustomItemEven:hover,
.searchBoxCustomItemOdd:hover {
	background: #FFEEAA;
}

.searchBoxCustomItemEven:active,
.searchBoxCustomItemOdd:active {
	background: #404040;
	color: #F0F0F0;
}

#offsetNow1[disabled],
#offsetNow2[disabled] {
	visibility: hidden;
}

</style>
}

/// Draw contents of search box.
Method %DrawHTML()
{
	Set tType = ""
	If (..filterName'="") {
		// JMD1276 show error
		// find type of filter dimension; "" is default
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMemberDimensionType(..dataSourceName,..filterName,.tType,.tMemberClass,.tMbrInfo)		// DTB181 - Return timeFunction class
		If $$$ISERR(tSC) {
			Write $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
			Quit
		}
	}

	Set ..selectType = tType									// DTB121 - store the dimension type
	Set ..calendar = ##class(%DeepSee.Utils).%GetTimeLevelCalendar($G(tMemberClass)) // + WAL142 -- use Dan's utility
	
	// DTB246 - Determine setting for local first day of the week for calendar display
	Set tMondayDayOfWeek = $system.SQL.DAYOFWEEK(62997)		// Use a known Monday for reference
	Set ..firstDayOfWeek = ( -(tMondayDayOfWeek-1)#7 + 1 )#7		
	
	// JMD1475
	Set ..descriptionProperty = $G(tMbrInfo("descriptionProperty"))

	Set tDisplay = ""
	Set tRangeMode = (..selectMode="range")

	// JMD1317 - find type of pivot variable
	If ((tType="$PIVOTVARIABLE")&&(..dataSourceName'="")) {
		// what kind of data source is in play?
		Set tDataSource = ..dataSourceName
		Set tExt = $P(tDataSource,".",$L(tDataSource,"."))
		If ((tExt = "pivot")||(tExt = "cube")) {
			If (tExt = "pivot") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDataSource,.tSC)
				If '$IsObject(tPivot) Quit
				Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			}
			Else {
				Set tCubeName = $$$UPPER($P(tDataSource,".",1,$L(tDataSource,".")-1))
			}
		}

		Set tPVarName = $P(..filterName,".",2)
		If ((tCubeName'="")&&(tPVarName'="")) {
			Kill tVInfo
			Set tSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(tCubeName,tPVarName,.tVInfo)
		}
		Set tVarType = $G(tVInfo("type"))
		Set tVSourceType = $G(tVInfo("sourceType"))
		Set tVValueList = $G(tVInfo("valueList"))
		If ((tVSourceType="manual")&&(tVarType="day")&&(tVValueList="")) {
			Set tType = "day"
		}
		// + WAL139 -- handle display name lookup
		ElseIf (..value'="") {
			If (($G(tVInfo("displayList"))'="")&&($G(tVInfo("valueList"))'="")) {
				For i=1:1:$L(tVInfo("valueList"),",") {
					If ($Piece(tVInfo("valueList"),",",i) = ..value) {
						If ($Piece(tVInfo("displayList"),",",i)'="") {
							Set tDisplay = $Piece(tVInfo("displayList"),",",i)
							Quit	
						}
					}	
				}	
			}
		}
		// - WAL139
		
		// DTB557 - Set the selectType and calendar of pivot variables to expected values
		If (tType="day") {
			Set ..selectType = "day"
			Set ..calendar = "gregorian"
		}
		Else {
			Set ..selectType = ""
		}
	}

	// JMD1263
	Set ..dateFormat = $G(tMbrInfo("dateFormat"))

	If (tType="day")&&(..calendar'["hijri") {		// DTB181 - There is no hijri calendar component!
		Set ..displayMode = "calendar"

		// get list of calculated members, if any
		// tFilters(n) = $LB(text,value)
		Kill tFilters
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(..dataSourceName,..filterName,.tFilters,.tDefaultFilterValue,"",.tRelatedFilters,1,tRangeMode)
		If $$$ISERR(tSC) Quit

		Do ..listOfCMbrValues.Clear()
		Do ..listOfCMbrText.Clear()

		Set n = $O(tFilters(""))
		While (n'="") {
			Do ..listOfCMbrValues.Insert($LG(tFilters(n),2))
			Do ..listOfCMbrText.Insert($LG(tFilters(n),1))

			Set n = $O(tFilters(n))
		}
	}
	ElseIf (tType="text") {
		Set ..displayMode = "custom"
	}
	ElseIf (tType="measure") {
		Set ..displayMode = "measure"
		Set tSC = ..%ParseMeasureExpression(..dataSourceName,$$$ZENVAL(..value),.tOp,.tParm)
		If $$$ISERR(tSC) {
			Quit
		}
		Set tDisplay = tOp _ " " _ tParm
	}
	ElseIf (tType="mdx") {
		// mdx computed dimension
		// show search box;
		// do not allow NOT, range, or multiSelect
		Set ..displayMode = "list"
		Set ..useSearch = 1
		Set ..multiSelect = 0
	}
	Else {
		Set ..displayMode = "list"
	}
	Set ..dropdownWidth = 250

	// text-only
	If (tDisplay="") {
		Set tVal(1) = $$$ZENVAL(..value)
		Set tVal(2) = ""

		If (tVal(1)'="") {
			// JMD1335 find display value
			If ($L(tVal(1),"]:&[")=2) {
				// range
				Set tVal(2) = "&["_$P(tVal(1),"]:&[",2)
				Set tVal(1) = $P(tVal(1),"]:&[",1)_"]"
				// JMD1335 force range mode
				Set ..selectMode = "range"		
			}
			If ($E(tVal(1),1,2)="&[") {
				// unescape
				Set tVal(1) = $E(tVal(1),3,*-1)
			}
			If (tType="day") {
				// best guess for NOW
				If (tVal(1)["NOW") {
					// JMD1335: show original NOW text
					//Set tOff = -$P(tVal(1),"-",2) + $P(tVal(1),"+",2)
					//Set tVal(1) = $ZDT($H+tOff,3)
				}
				Else {
					// DTB148 - Do not convert time level values
					//Set:($L(tVal(1))=5) tVal(1) = $ZDT(tVal(1),3)
				}
			}
			If ($E(tVal(2),1,2)="&[") {
				Set tVal(2) = $E(tVal(2),3,*-1)
			}
			If (tType="day") {
				If (tVal(2)["NOW") {
					// JMD1335: show original NOW text
					//Set tOff = -$P(tVal(2),"-",2) + $P(tVal(2),"+",2)
					//Set tVal(2) = $ZDT($H+tOff,3)
				}
				Else {
					// DTB148 - Do not convert time level values
					//Set:($L(tVal(2))=5) tVal(2) = $ZDT(tVal(2),3)
				}
			}

			If ("day"=tType)||("month"=tType)||("year"=tType) {
				// DTB121 - These are special cases where the tooltip displays the internal "NOW+offset"
				// The searchBox text always resolves to a real time member 
				Set tDisplay = ..%GetDisplayValue(tVal(1),tType)		// DTB551
				If ($E(tVal(1),1,3)="NOW") {
					// Localize the NOW word in the tooltip
					Set tTitle = $$$Text("NOW") _ $E(tVal(1),4,*)
				}
				Else {
					Set tTitle = tDisplay
				}

				// JMD1407
				If (tVal(2)'="") {
					Set tDisplay = tDisplay _ ":" _ ..%GetDisplayValue(tVal(2),tType)		// DTB551
					If ($E(tVal(2),1,3)="NOW") {
						Set tTitle = tTitle _ ":" _ $$$Text("NOW") _ $E(tVal(2),4,*)
					} 
					Else {
						Set tTitle = tTitle _ ":" _ ..%GetDisplayValue(tVal(2),tType)		// DTB551
					}
				}
			}
			Else {
				Set tDisplay = ..%GetDisplayValue(tVal(1))
				// JMD1407
				If (tVal(2)'="") {
					Set tDisplay = tDisplay _ ":"_..%GetDisplayValue(tVal(2))
				}
				Set tTitle = tDisplay		// DTB121 - Tooltip and display match in this case
			}
		}
	}

	// try to let text wrap
	Set tDisplay = $Replace(tDisplay,"+","+ ")

	// JMD1335
	If (..text="") {
		Set ..text = tDisplay
	}
	Set tSize = ..size
	If (..size="") {
		Set tSize = "100%"
	}
	Else {
		Set tSize = ..size_"em"
	}

	&html<<input type="hidden" id="#(..%MakeId("hidden"))#" #(..%Name())# #(..%Attr("value",..value))#/>>
	#; do not add this to set of events
	Set tIgnore("onkeypress")=""
	Set tIgnore("onchange")=""
	Set tIgnore("onblur")=""

	&html<<table border="0" cellspacing="0" cellpadding="0">>
	Set tButtonCaption = $S(..buttonCaption="":$$$Text("Search","%ZEN"),1:..buttonCaption)
	Set tButtonTitle = $S(..buttonTitle="":"",1:"title="""_$ZCVT(..buttonTitle,"O","HTML")_"""")
	Set tImage = ..iconSearch
	If $G(tTitle)="" {
		// DTB121 - make sure a tooltip is consistently displayed
		Set tTitle = tDisplay
	} 

	// n.b. word-break is ie-only
	Set tROS = $S(..readOnly:"RO",1:"")
	&html<<tr><td valign="bottom" id="#(..%MakeId("input"))#" class="searchBoxTextCell#(tROS)#" title="#($zconvert(tTitle,"O","HTML"))#" style="word-wrap:break-all;width:#(tSize)#;">#($ZCVT(tDisplay,"O","HTML"))#&nbsp;</td>>
	If ('..readOnly) {
		If (..previewMode) {
			&html<
			<td valign="bottom" class="searchBoxBtn">
			<img src="#(tImage)#" id="#(..%MakeId("btn"))#"/>
			</td>>
		}
		Else {
			&html<
			<td valign="bottom" class="searchBoxBtn" onclick="zenPage.getComponent(#(..index)#).showDropdown();" onmouseover="this.style.background='#FFEEAA';" onmouseout="this.style.background='white';">
			<img src="#(tImage)#" id="#(..%MakeId("btn"))#" #(tButtonTitle)#/>
			</td>>
		}
	}
	&html<</tr>>
	&html<</table>>

	If (+..#USECACHEDIV) {
		#; extra div to cache dropdown contents
		&html<<div style="display: none;" id="#(..%MakeId("cache"))#">>
		Do ..%OnDrawCacheDiv()
		&html<</div>>
	}
}

/// Internal method.<br>
/// Create contents of drop down box using DHTML.
/// If <var>loadOnly</var> is defined and true, then
/// load the contents into the cached div, but do not show.
ClientMethod renderDropdown() [ Internal, Language = javascript ]
{
	this.searchText = '';

	// JMD1366: remember starting values (moved from loadDropDown)
	this.rememberValues();

	// JMD1366: clear priors
	this.priorValues.length = 0;
	this.priorText.length = 0;

	var value = '';
	this.loadDropdown(value,true);
}

/// Internal method.<br>
/// Create contents of drop down box using DHTML.
/// <var>value</var> is used as search filter.
/// If <var>show</var> is false, then
/// load the contents into the cached div, but do not show.
ClientMethod loadDropdown(value, show) [ Internal, Language = javascript ]
{
	try {
		// value is value from input control
		// our *actual* value is in this.value
		zenFireEvent(this.index, this.onshowdropdown, 'onshowdropdown');

		var actualValue = this.value;

		value = (null == value) ? '' : value.toString();
		// DTB140 - use the same tooltips as with non-calendar searchBox for Apply and Cancel buttons
		//var hlpApply = $$$Text('Apply the current selection');
		//var hlpCancel = $$$Text('Cancel');
		var hlpApply = $$$Text("Use new values for this filter","%DeepSee")
		var hlpCancel = $$$Text("Do not change this filter value","%DeepSee")

		if (('calendar' != this.displayMode)&&('measure' != this.displayMode)) {
			// do not use *actual* value as search key
			value = this.searchText;

			// trim value
			if (this.searchKeyLen >= 0) {
				value = ('string'==typeof value) ? value.substr(0,this.searchKeyLen) : value;
			}
		}
		else {
			value = actualValue;
		}

		this.dataLoaded = false;
		this.lastValue = value;

		var needToLoad = true;

		// can user select a range of dates?
		var rangeSelect = this.selectMode == 'range';

		if (show) { 
			// register that we used the modal div!
			zenPage.lastModalIndex = this.index;

			var div = this.getDropDownDiv();

			if ('calendar' != this.displayMode) {
				div.innerHTML = '<span class="comboboxLoading">' + this.loadingMessage + '</span>';
			}
			else {
				needToLoad = false;
				div.innerHTML = '<span class="comboboxLoading">' + this.loadingMessage + '</span>';

				var v1 = '';
				var v2 = '';
				var nowInfo1 = {};
				var nowInfo2 = {};

				// show drop down calendar
				var cal = zenPage.createComponent('calendar');
				cal.setProperty('id','cal');
				cal.setProperty('startYear',1900);
				cal.setProperty('firstDayOfWeek',this.firstDayOfWeek);		// DTB246
				if (rangeSelect) {
					cal.setProperty('onchange','zenPage.getComponent('+this.index+').dateRangeChange(1);');
					cal.setProperty('multiSelect',false);
					cal.setProperty('rangeSelect',false);
				}
				else {
					cal.setProperty('onchange','zenPage.getComponent('+this.index+').dateChange(zenThis,true);');
					cal.setProperty('multiSelect',true);
					cal.setProperty('rangeSelect',true);
				}

				if (rangeSelect) {
					var cal2 = zenPage.createComponent('calendar');
					cal2.setProperty('id','cal2');
					cal2.setProperty('startYear',1900);
					cal2.setProperty('onchange','zenPage.getComponent('+this.index+').dateRangeChange(2);');
					cal2.setProperty('multiSelect',false);
					cal2.setProperty('rangeSelect',false);
				}

				// get and set value *after* applying parms
				if (rangeSelect) {
					// get date range
					if (''!=actualValue) {
						var t = actualValue.toString().split(']:&[');
						if (t.length < 2) {
							v1 = t[0].substring(2,t[0].length-1);
							v2 = '';
						}
						else {
							v1 = t[0].substring(2);
							v2 = t[1].substring(0,t[1].length-1);
						}
						
						// JMD1335: push NOW processing into dateFromHorolog
						cal.setValue(this.dateFromHorolog(v1,nowInfo1));
						cal2.setValue(this.dateFromHorolog(v2,nowInfo2));
					}
					else {
						cal.setValue('');
						cal2.setValue('');
					}
					// this.dateRangeChange(1);
				}
				else {
					if (''!==value) {
						// look for %NOT
						if ('%NOT ' == value.substring(0,5)) {
							this.selectMode = 'not';
							value = value.substring(5);
						}

						// there may be multiple dates {a,b} or a range (:)
						var isRange = false;
						cal.listOfValues.length = 0;
						var vlist;

						if (value.charAt(0)=='{') {
							// list
							value = value.substring(1,value.length-1);
							vlist = value.split(',');
						}
						else if (value.split(':').length == 2) {
							isRange = true;
							vlist = value.split(':');
						}
						else {
							vlist = [value];
						}

						for (var n = 0; n < vlist.length; n++) {
							var v = vlist[n].toString();
							// remove &[]
							v = v==''?'':v.substring(2,v.length-1);

							value = this.dateFromHorolog(v);
							cal.listOfValues[cal.listOfValues.length] = value;
							if (n==0) {
								// calendar expects a string
								value = ('string' == typeof value) ? value : '';
								cal.setProperty('value',value);
							}
						}
						cal.isRange = isRange;
						this.dateChange(cal,true);
					}
					else {
						cal.isRange = false;
						cal.setProperty('value','');
						this.dateChange(cal,true);
					}
				}

				var html = new Array();
				html[html.length] = '<table class="searchBoxHeader" cellpadding="0" border="0"><tr>';
				html[html.length] = '<td width="99%" nowrap="1">&nbsp;</td>';
				html[html.length] = '<td><img title="'+hlpApply+'" class="dsptIcon" src="'+this.iconApply+'" onclick="zenPage.getComponent('+this.index+').applyCalendar();" /></td>';
				html[html.length] = '<td><img title="'+hlpCancel+'" class="dsptIcon" src="'+this.iconCancel+'" onclick="zenPage.getComponent('+this.index+').cancelChanges();"/></td>';
				html[html.length] = '</tr></table>';

				/* place all and not options above calendar */
				var selAll = (""==actualValue)&&(""==this.selectMode) ? 'checked="1"' : '';
				var selNOT = ("not"==this.selectMode) ? 'checked="1"' : '';
				var selRange = ("range"==this.selectMode) ? 'checked="1"' : '';

				var selNow1 = (nowInfo1.now) ? 'checked="1"' : '';
				var selNow2 = (nowInfo2.now) ? 'checked="1"' : '';
				var disNow1 = (!selNow1) ? 'disabled="disabled"' : '';
				var disNow2 = (!selNow2) ? 'disabled="disabled"' : '';

				// +DTB140 - add help messages
				var msgAll = $$$Text("All","%DeepSee")
				var msgValRequired = $$$Text("Required","%DeepSee")
				var msgNOT = $$$Text("Exclude","%DeepSee")
				var msgRange = $$$Text("Range","%DeepSee")
				
				var hlpAll = $$$Text("Show all members within this category","%DeepSee")
				var hlpValRequired = $$$Text("At least one member must be selected in this category","%DeepSee")
				var hlpNOT = $$$Text("Exclude the selected items","%DeepSee")
				var hlpRange = $$$Text("Show everything that is between the start and end values","%DeepSee")
				// -DTB140
				
				html[html.length] = '<table class="searchBoxTable" width="100%" border="0" cellspacing="0"><tr class="searchBoxItemBar">';	
				
				// +DTB140 - don't add an All check box if a value is required
				if (!this.valueRequired) {		
					html[html.length] = '<td align="left" nowrap="1">';
					html[html.length] = '<input type="checkbox" '+selAll+' id="'+this.makeId('cball')+'" onclick="zenPage.getComponent('+this.index+').itemClick(event,\'\',true);"/>';
					html[html.length] = '<span onclick="zenPage.getComponent('+this.index+').itemClick(event,\'\',false);" title="'+hlpAll+'">';
					html[html.length] = msgAll;
					html[html.length] = '</span>';
				}
				else {
					// Provide a visual cue that this is required
					html[html.length] = '<td align="left" nowrap="1">';
					html[html.length] = '<span onclick="zenPage.getComponent('+this.index+').itemClick(event,\'\',false);" title="'+hlpValRequired+'">';
					html[html.length] = msgValRequired;
					html[html.length] = '</span>';
				}
				// -DTB140

				
				html[html.length] = '</td>';
				html[html.length] = '<td align="right" nowrap="1">';
				html[html.length] = '<input type="checkbox" '+selNOT+' id="'+this.makeId('cbNOT')+'" onclick="zenPage.getComponent('+this.index+').notClick(true);"/>';
				html[html.length] = '<span onclick="zenPage.getComponent('+this.index+').notClick(false);" title="'+hlpNOT+'">';
				html[html.length] = msgNOT;
				html[html.length] = '</span></td>';

				html[html.length] = '<td align="right" nowrap="1">';
				html[html.length] = '<input type="checkbox" '+selRange+' id="'+this.makeId('cbRange')+'" onclick="zenPage.getComponent('+this.index+').rangeClick(true);"/>';
				html[html.length] = '<span onclick="zenPage.getComponent('+this.index+').rangeClick(false);" title="'+hlpRange+'">';
				html[html.length] = msgRange;
				html[html.length] = '</span></td>';

				if (rangeSelect) {
					// eat up space
					html[html.length] = '<td width="90%">&nbsp;</td>';
				}

				html[html.length] = '</tr></table>';

				// if there are calculated members, render them here
				if (!rangeSelect) {
					html[html.length] = '<table style="background:#F0F0F0;" class="searchBoxTable" cellpadding="0" border="0" cellspacing="0">';
					for (var n = 0; n < this.listOfCMbrValues.length; n++) {
						var cls = (n%2) ? 'Even':'Odd';
						var clr = (n%2) ? 'white':'';
						var val = this.listOfCMbrValues[n];
						var txt = this.listOfCMbrText[n];
						var sel = (val == actualValue);

						html[html.length] = '<tr id="'+this.makeId('item_'+(n+1))+'" zenValue="'+zenEscapeXML(val)+'" zenText="'+zenEscapeXML(txt)+'" class="searchBoxItem'+cls+'"><td>';
						html[html.length] = '<input '+(sel?'checked="true" ':'')+'id="'+this.makeId('cb_'+(n+1))+'" type="checkbox" onclick="zenPage.getComponent('+this.index+').itemClick(event,'+(n+1)+',true);" />';
						html[html.length] = '</td><td nowrap="1" width="99%" onclick="zenPage.getComponent('+this.index+').itemClick(event,'+(n+1)+',false);">'+zenEscapeXML(txt) + '</td></tr>';
					}
					html[html.length] = '</table>';
				}

				if (rangeSelect) {
					// place 2 calendars in a table
					html[html.length] = '<table style=""><tr><td><span style="font-size:8pt;color:#606060;">'+$$$Text('From')+'</span>';
				}

				// div for calendar
				var divid = ('' == cal.id) ? 'zen'+cal.index : cal.id;
				html[html.length] = '<div id="'+divid+'" style="background:#F0F0F0;"></div>';

				if (rangeSelect) {
					// JMD1335: display NOW offset
					html[html.length] = '<input id="cbNow1" '+selNow1+' type="checkbox" onclick="zenPage.getComponent('+this.index+').cbNowClick(true,1);"/><span onclick="zenPage.getComponent('+this.index+').cbNowClick(false,1);" style="font-size:10pt;color:#404040;padding:2px;">'+$$$Text('NOW')+'</span>';
					html[html.length] = '&nbsp;<input id="offsetNow1" '+disNow1+' value="'+zenGet(nowInfo1.offset)+'" type="input" placeHolder="&#177;'+$$$Text('days')+'" size="3" onchange="zenPage.getComponent('+this.index+').offsetNowChange(1);" />';
					html[html.length] = '</td><td><span style="font-size:8pt;color:#606060;">'+$$$Text('To')+'</span>';
					var divid2 = ('' == cal2.id) ? 'zen'+cal2.index : cal2.id;
					html[html.length] = '<div id="'+divid2+'" style="background:#F0F0F0;"></div>';
					html[html.length] = '<input id="cbNow2" '+selNow2+' type="checkbox" onclick="zenPage.getComponent('+this.index+').cbNowClick(true,2);"/><span onclick="zenPage.getComponent('+this.index+').cbNowClick(false,2);" style="font-size:10pt;color:#404040;padding:2px;">'+$$$Text('NOW')+'</span>';
					html[html.length] = '&nbsp;<input id="offsetNow2" '+disNow2+' value="'+zenGet(nowInfo2.offset)+'" type="input" placeHolder="&#177;'+$$$Text('days')+'" size="3" onchange="zenPage.getComponent('+this.index+').offsetNowChange(2);" />';
					html[html.length] = '</td></tr></table>';
				}
				div.innerHTML = html.join('');

				// draw calendar(s) into div
				cal.renderContents();
				if (rangeSelect) {
					cal2.renderContents();
				}

				var calDiv = cal.getEnclosingDiv();

				div.style.overflow = 'hidden';
				
				// JMD: auto width does not work!
				var cw = 222 * (rangeSelect?2.1:1);
				div.style.width = cw+'px';
				div.style.height = 'auto';
				div.style.boxShadow = '5px 5px 5px #808080';

				// NOW
				if (cal && nowInfo1.now) {
					cal.setDisabled(true);
				}
				if (cal2 && nowInfo2.now) {
					cal2.setDisabled(true);
				}
			}
			zenPage.correctIELayering(this.getDropDownDiv());
		}
		// call server method
		if (needToLoad) {
			this.LoadDropDownContents(value,show?0:1);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in loadDropdown');
	}
}

/// Internal method.<br>
/// Server-side method to load contents of the drop down box
/// by executing query associated with this control.
/// If <var>cached</var>, load contents into cache div
Method LoadDropDownContents(searchParm As %String, cached As %Boolean = 0) [ Internal, ZenMethod ]
{
	#; stop progress bar
	&js<zenPage.getComponent(#(..index)#).stopProgressBar();>

	Set cached = 0

	#; invoke method to draw dropdown contents
	#; find div to hold content
	If ('cached) {
		&js<var div = zenPage.getComponent(#(..index)#).getDropDownDiv();>
	}
	Else {
		&js<var div = zenPage.getComponent(#(..index)#).getCacheDiv();>
	}
	&js<zenASSERT(div,"Unable to find drop down div element.",arguments);>

	#; execute our %DrawDropDownContents method and capture it as JavaScript
	Write "var html = '"

	#; use JS output to properly escape HTML for JS
	Set io = ##class(%ZEN.Controller).%BeginJSTranslation()
	If (..displayMode="custom") {
		Set tSC = ..%DrawCustomDropDownContents(searchParm,.tCount)
	}
	ElseIf (..displayMode="measure") {
		Set tSC = ..%DrawMeasureDropDownContents(searchParm,.tCount)
	}
	Else {
		Set tSC = ..%DrawDropDownContents(searchParm,.tCount)
	}
	Do ##class(%ZEN.Controller).%EndJSTranslation(io)
	Write "';",!

	Write "div.innerHTML = html;",!
	Write "html=null;",!

	// Turn off outer scroll bar
	Write "div.style.overflow = 'hidden';",!

	Write "div.style.border = '3px solid #D0D0D0';",!
	Write "div.style.borderRadius = '3px';",!

	// add shadow
	Write "div.style.boxShadow = '4px 4px 4px gray';",!

	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
		&js<zenPage.endModal();>
		Quit
	}

	#; update client focus, flags, & item count
	&js<
		var xcb = zenPage.getComponent(#(..index)#);
		xcb.adjustDropDownWidth();
		xcb.adjustDropdownPosition(); // JSL4502
		xcb.selectedIndex = -1;
		xcb.dataLoaded = true;
		xcb.itemCount = #(tCount)#;
		if (zenPage.correctIELayering) {
			zenPage.correctIELayering(xcb.getDropDownDiv());
		}
	>
	If ('cached) {
		&js<
			var input = xcb.findElement(xcb.displayMode=='measure'?'msrParm':'search');
			if (input) {
				try {
					input.focus();
					if (xcb.displayMode=='measure') {
						input.select();
					}
				}
				catch(ex) {}
			}
			xcb.isDropdownVisible = true;
			xcb.findSelectedItem();
		>
	}
	Else {
		&js<
			xcb._hasCache = true;
		>
	}
}

/// Server-side method to provide contents of the list box.
/// This is called from the client.
Method %DrawDropDownContents(searchParm As %String, Output pCount As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tRS = ""
		Set tHasDisplay = 0
		Set tMaxRows = ..maxRows
		Set tCount = 0
		Set tType = ..selectType		// DTB121

		// options
		Set tHasNot = ..multiSelect // these are tied together
		Set tMultiSelect = ..multiSelect

		#; do we have a searchParm
		Set tSearchKey = searchParm
		If ('..useSearch) {
			//Set tSearchKey = ""
		}

		// JMD1253 test for namedFilters
		Set tNamedFilter = 0
		If (..filterName="$NAMEDFILTER") {
			Set tNamedFilter = 1
			Set tHasNot = 0
		}

		// JMD1276 test for pivot variables
		Set tPivotVariable = 0
		If ($$$LOWER($E(..filterName,1,10))="$variable.") {
			Set tPivotVariable = 1
			Set tHasNot = 0
		}

		#; pick up related filter specs
		Kill tRelatedFilters
		For n = 1:1:..relatedFilterSpecs.Count() {
			Set tSpec = ..relatedFilterSpecs.GetAt(n)
			Set tKey = ..relatedFilterKeys.GetAt(n)
			If ((tSpec'="")&&($L(tSpec)<200)) {
				// if list is too long, don't bother
				Set tRelatedFilters(tSpec) = tKey
			}
		}

		// test for range support
		Set tHasRange = 0
		If ('tNamedFilter && 'tPivotVariable) {
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%DoesFilterSupportRange(..dataSourceName,..filterName,.tHasRange)
			If $$$ISERR(tSC) Quit
		}

		// JMD1475: test for description
		Set tHasDesc = 0
		If ('tNamedFilter && 'tPivotVariable) {
			Set tHasDesc = (..descriptionProperty'="")
		}

		Set tRangeMode = tHasRange && (..selectMode="range")

		// pull apart current values for search box
		// JMD1253
		If (tNamedFilter) {
			Set tValue = ..value
			// !!! if tValue starts with { we have to pull apart the pieces !!!
			Set:tValue'="" tValueList(tValue) = ""
		}
		ElseIf (tPivotVariable) {
			Set tValue = ..value
			If ($E(tValue,1)="{") {
				// list of values {a,b,c} -- pull them apart
				Set tValue = $E(tValue,2,$L(tValue)-1)
				For x = 1:1:$L(tValue,",") {
					Set v = $P(tValue,",",x)
					Set tValueList(v) = ""
				}
			}
			ElseIf (tValue'="") {
				Set tValueList(tValue) = ""
			}
		}
		Else {
			If ($E(..value,1,5)="%NOT ") {
				Set ..selectMode = "not"
				Set tValue = $E(..value,6,$L(..value))
			}
			Else {
				Set tValue = ..value
			}

			If ($E(tValue,1,2)="&[") {
				// test for range
				If (tValue["]:&[") {
					Set ..selectMode = "range"
					Set tRangeVal(1) = $P(tValue,"]:&[",1)_"]"
					Set tRangeVal(2) = "&["_$P(tValue,"]:&[",2)

					// JMD1321: try to find values for NOW
					// +DTB121 - this is failing to find correct values, and display values are handled elsewhere
					/*
					If (tRangeVal(1)["&[NOW") {
						Set tDisplay = ..%GetDisplayValue($$$ZENVAL(..value))
						Set tRangeVal(1) = "&["_$P(tDisplay,":",1)_"]"
					}
					If (tRangeVal(2)["&[NOW") {
						Set tDisplay = ..%GetDisplayValue($$$ZENVAL(..value))
						Set tRangeVal(2) = "&["_$P(tDisplay,":",2)_"]"
					}
					*/
					// -DTB121
					
					Set tValueList(tRangeVal(1)) = ""
				}
				ElseIf (tRangeMode) {
					// DTB121 - case where the range mode has been turned on via check box, 
					// but the selection has not been changed yet. Set both dropdowns to the same value
					Set tRangeVal(1) = tValue
					Set tRangeVal(2) = tValue
					
					Set tValueList(tRangeVal(1)) = ""
				}
				Else {
					Set tValueList(tValue) = ""
				}
			}
			ElseIf ($E(tValue,1)="{") {
				// list of values {a,b,c} -- pull them apart
				Set tValue = $E(tValue,2,$L(tValue)-1)
				Set tItemCount = $L(tValue,"],&[")
				For x = 1:1:tItemCount {
					Set v = $P(tValue,"],&[",x)
					// DP-408166 - Complete the quoted keys according to position in the list to 
					// account for $Piece on "],&["
					Set:(x>1) v = "&["_v
					Set:(x<tItemCount) v = v_"]"
					
					Set tValueList(v) = ""
				}
			}
			ElseIf(tValue'="") {
				Set tValueList(tValue) = ""
			}
		}

		// Get members of the given filter
		// tFilters(n) = $LB(text,value)
		Kill tFilters
		If (..valueList'="") {
			Set n = 0
			// DTB525 - Temporarily replace the escaped comma with a stand-in character so the lists can be correctly $Pieced
			Set tValueList = $Replace(..valueList,"\,",$C(1))
			Set tDisplayList = $Replace(..displayList,"\,",$C(1))
			Set:tDisplayList="" tDisplayList = ..valueList
			
			For p=1:1:$L(tValueList,",") {
				Set tFVal = $P(tValueList,",",p)
				If (tFVal'="") {
					Set tCaption = $Replace($P(tDisplayList,",",p),$C(1),",")		// DTB525 - Translate the stand-in back to a comma
					Set tFVal = $Replace(tFVal,$C(1),",")
					Set tFilters($I(n)) = $LB(tCaption,tFVal)
				}
			}
		}
		Else {
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(..dataSourceName,..filterName,.tFilters,.tDefaultFilterValue,tSearchKey,.tRelatedFilters,0,tRangeMode,.tValueList)
			If $$$ISERR(tSC) Quit
			
			// DTB837 - Append pivot variables if the switch is on and the current datasource is not itself a variable
			If ..appendPivotVariables && '($$$LOWER($E(..filterName,1,10))="$variable.") {
				Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetPivotVariablesForDataSource(..dataSourceName,.tVariables)
				If $$$ISERR(tSC) Quit
				
				Set n = $O(tFilters(""),-1)
				Set k = $O(tVariables(""))
				While (k'="") {
					// use logical value!
					Set tFilters($I(n)) = $LB("$variable."_$LG(tVariables(k),1),"$variable."_$LG(tVariables(k),1))
					Set k = $O(tVariables(k))
				}
			}
		}

		Set tLabel = ""

		Set msgAll = $$$TextHTML("All","%DeepSee")
		Set msgValRequired = $$$TextHTML("Required","%DeepSee")		// DTB140
		Set msgNOT = $$$TextHTML("Exclude","%DeepSee")
		Set msgRange = $$$TextHTML("Range","%DeepSee")

		Set msgApply = $$$TextHTML("Use new values for this filter","%DeepSee")
		Set msgCancel = $$$TextHTML("Do not change this filter value","%DeepSee")
		Set hlpAll = $$$Text("Show all members within this category","%DeepSee")
		Set hlpValRequired = $$$Text("At least one member must be selected in this category","%DeepSee")		// DTB140
		If (tMultiSelect) {
			Set hlpCheckbox = $$$Text("Filter results using this value. Use the CTRL key to select multiple items","%DeepSee")
		}
		Else {
			Set hlpCheckbox = $$$Text("Filter results using this value.","%DeepSee")
		}
		Set hlpNOT = $$$Text("Exclude the selected items","%DeepSee")
		Set hlpRange = $$$Text("Show everything that is between the start and end values","%DeepSee")

		// header
		If (..searchText'="") {
			Set tSearch = ..searchText
			Set tStyle = ""
			Set tSearchMode = 1
		}
		Else {
			Set tSearch = $$$Text("Search","%DeepSee")
			Set tStyle = "color: #D0D0D0;"
			Set tSearchMode = 0
		}

		&html<
		<table class="searchBoxHeader" cellpadding="0" border="0"><tr>
		<td width="99%" nowrap="1"><input id="#(..%MakeId("search"))#" class="searchBoxSearchBox" type="search" size="12" value="#($ZCVT(tSearch,"O","HTML"))#" style="#(tStyle)#" onchange="return zenPage.getComponent(#(..index)#).doSearch();" onkeydown="return zenPage.getComponent(#(..index)#).searchKeyPress(event);" onclick="zenPage.getComponent(#(..index)#).searchKeyPress(event);"/>&nbsp;</td>
		<td><img class="dsptIcon" title="#(msgApply)#" src="#(..iconApply)#" onclick="zenPage.getComponent(#(..index)#).applyChange();" /></td>
		<td><img class="dsptIcon" title="#(msgCancel)#" src="#(..iconCancel)#" onclick="zenPage.getComponent(#(..index)#).cancelChanges();"/></td>
		</tr></table>>

		Set tFilterKey = ""

		// list

		// item bar
		&html<<div class="searchBoxItemBarDiv">>
		Set colSpan = 1

		Set selAll = $S((""=..value)&&(""=..selectMode):"checked=""1""",1:"")
		Set selNOT = $S(("not"=..selectMode):"checked=""1""",1:"")
		Set selRange = $S(("range"=..selectMode):"checked=""1""",1:"")
		If (..selectMode'="range") {
			If (..valueRequired) {
				// DTB140 - remove All option if a value is required
				&html<<span nowrap="1" title="#(hlpValRequired)#" onclick="zenPage.getComponent(#(..index)#).itemClick(event,'',false);">
				#(msgValRequired)#
				</span>>
			}
			Else {
				// Display All option
				&html<<input id="#(..%MakeId("cball"))#" title="#(hlpAll)#" type="checkbox" #(selAll)# value="" filterValue="" onclick="zenPage.getComponent(#(..index)#).itemClick(event,'',true);"/>
				<span nowrap="1" title="#(hlpAll)#" onclick="zenPage.getComponent(#(..index)#).itemClick(event,'',false);">
				#(msgAll)#
				</span>>
			}
		}

		If (tHasNot && (..selectMode'="range")) {
			&html<&nbsp;<input id="#(..%MakeId("cbNOT"))#" title="#(hlpNOT)#" type="checkbox" #(selNOT)# value="" onclick="zenPage.getComponent(#(..index)#).notClick(true);"/>
			<span nowrap="1" title="#(hlpNOT)#" onclick="zenPage.getComponent(#(..index)#).notClick(false);">#(msgNOT)#</span>>
		}

		If (tHasRange) {
			&html<&nbsp;<input id="#(..%MakeId("cbRange"))#" title="#(hlpRange)#" type="checkbox" #(selRange)# value="" onclick="zenPage.getComponent(#(..index)#).rangeClick(true);"/>
			<span nowrap="1" title="#(hlpRange)#"  onclick="zenPage.getComponent(#(..index)#).rangeClick(false);">#(msgRange)#</span>>
		}
		&html<</div>>

		// once again, tables must be used instead of div!
		&html<<div class="searchBoxList" id="#(..%MakeId("list"))#">>
		&html<<table class="searchBoxTable" id="#(..%MakeId("table"))#" cellpadding="0" border="0" cellspacing="0">>

		If ((..selectMode="range")) {
			// show start / end combos

			// remove missing items!
			Set k = $O(tFilters(""))
			While (k'="") {
				Set tFVal = $LG(tFilters(k),2)
				If (tFVal="&[<null>]") {
					Kill tFilters(k)
				}
				Set k = $O(tFilters(k))
			}

			If '$D(tFilters) {
				Set tNoRange = $$$Text("There are no values available for range selection")
				&html<<tr><td colspan="#(colSpan)#" style="padding-left:5px;padding-top:10px;color:#404040;">#(tNoRange)#</td></tr>>
			}
			Else {
				For nx = 1:1:2 {
					Set tWhich = $Case(nx,1:$$$Text("From:"),2:$$$Text("To:"))
					&html<<tr><td nowrap="1" colspan="#(colSpan)#" style="padding-left:5px;padding-top:10px;color:#404040;">#(tWhich)#</td></tr>>

					&html<<tr><td nowrap="1" colspan="#(colSpan)#" style="padding-left:5px;color:#404040;"><select id="#(..%MakeId("range"_nx))#" onchange="zenPage.getComponent(#(..index)#).rangeChange(#(nx)#);">>
					Set k = $O(tFilters(""))
					While (k'="") {
						Set tFTxt = $LG(tFilters(k),1)
						Set tFVal = $LG(tFilters(k),2)
						If (tFVal'="&[<null>]") {
							Set sel = $S(tFVal="":"",tFVal=$G(tRangeVal(nx)):"selected=""1""",1:"")
							If (tFVal="NOW")&&(tRangeVal(nx)["NOW") {
								// DTB121 - the value is NOW+offset, mark NOW as the selected option
								set sel = "selected=""1"""
							}
							Set tCount = tCount + 1
							Set tCls = $S(tCount#2:"Odd",1:"Even")
							Set tValAttr = "value="""_$ZCVT(tFVal,"O","HTML")_""""
							Set tTextAttr = $ZCVT(tFTxt,"O","HTML")
							&html<<option id="#(..%MakeId("item_"_tCount))#" #(sel)# #(tValAttr)# >#(tTextAttr)#</option>">
						}
						Set k = $O(tFilters(k))
					}
					
					// +DTB121 - add an offset input for levels that accept NOW
					&html<</select></td>>
					Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMemberDimensionType(..dataSourceName,..filterName,.tType,,.tMbrInfo)
					If (tType'="")&&(("month"=tType)||("year"=tType)||(("day"=tType)&&(..calendar["hijri"))) {		// DTB181 - Add an offset box to hijri date ranges
						Set tCurrentRangeVal = $G(tRangeVal(nx))
						Set offSetID = "offsetNow"_nx
						Set tPlaceholder = $C(177) _ $S(
								tType="month":$$$Text("months"),
								tType="year":$$$Text("years"),
								1:"")
						Set tDisabled = $S(((tCurrentRangeVal["&[NOW")||(tCurrentRangeVal="")):"",1:"disabled=""true""")
						
						Set tDefault = ""
						If (tCurrentRangeVal["&[NOW") {
							Set tOffset = $Translate(tCurrentRangeVal,"&[NOW]","")
							Set tDefault = $S((tOffset'=""):"value="""_tOffset_"""",1:"")
						}

						&html<<td nowrap="1" style="padding-left:5px;color:#404040;"><input id="#(offSetID)#" type="input" size="3" placeHolder="#(tPlaceholder)#" onchange="zenPage.getComponent(#(..index)#).offsetNowChange(#(nx)#);" #(tDisabled)# #(tDefault)#/></td></tr>>
					} 
					Else {
						&html<</tr>>
					}
					// -DTB121
				}
			}
		}
		Else {
			// show list of  items
			Set k = $O(tFilters(""))
			While (k'="") {
				Set tFTxt = $LG(tFilters(k),1)
				Set tFVal = $LG(tFilters(k),2)
				Set tFDesc = $LG(tFilters(k),3)
				Set sel = $S(tFVal="":"",$D(tValueList(tFVal)):"checked=""1""",1:"")
				Set tCount = tCount + 1
				Set tCls = $S(tCount#2:"Odd",1:"Even")
				Set tColor = $S(tCount#2:"",1:"white")
				Set tValAttr = "zenValue="""_$ZCVT(tFVal,"O","HTML")_""""
				Set tTextAttr = "zenText="""_$ZCVT(tFTxt,"O","HTML")_""""
				&html<<tr id="#(..%MakeId("item_"_tCount))#" #(tValAttr)# #(tTextAttr)# class="searchBoxItem#(tCls)#">>
				
				If (tFVal'="$msg") {
					&html<<td class="cb"><input id="#(..%MakeId("cb_"_tCount))#" title="#(hlpCheckbox)#" type="checkbox" #(sel)# onclick="zenPage.getComponent(#(..index)#).itemClick(event,#(tCount)#,true);" /></td>
					<td colspan="#(colSpan)#" width="99%" title="#($ZCVT(tFTxt,"O","HTML"))#" onclick="zenPage.getComponent(#(..index)#).itemClick(event,#(tCount)#,false);" #($S((sel="")||(tHasDesc):"",1:"style=""font-weight:bold;"""))#>#($ZCVT(tFTxt,"O","HTML"))#&nbsp;>
				}
				Else {
					&html<<td class="cb"></td>
					<td class="comboboxLoading" colspan="#(colSpan)#" width="99%" title="#($ZCVT(tFDesc,"O","HTML"))#">#($ZCVT(tFTxt,"O","HTML"))#&nbsp;>
				}
				
				If ((tHasDesc||(tFVal="$msg"))&&(tFDesc'="")) {
					&html<<br/><div class="searchBoxDescription">#($ZCVT(tFDesc,"O","HTML"))#</div>>
				}
				&html<
				</td>
				</tr>>
				Set k = $O(tFilters(k))
			}
		}
		&html<</table></div>>
		&html<</div>>

		Set pCount = tCount
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw contents of drop down in "custom" mode.
Method %DrawCustomDropDownContents(searchParm As %String, Output pCount As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tRS = ""
		Set tHasDisplay = 0
		Set tMaxRows = ..maxRows
		Set tCount = 0
		Set pCount = 0

		#; do we have a searchParm
		Set tSearchKey = searchParm
		If ('..useSearch) {
			Set tSearchKey = ""
		}
		
		#; pick up related filter specs
		Kill tRelatedFilters
		For n = 1:1:..relatedFilterSpecs.Count() {
			Set tSpec = ..relatedFilterSpecs.GetAt(n)
			Set tKey = ..relatedFilterKeys.GetAt(n)
			If (tSpec'="") {
				Set tRelatedFilters(tSpec) = tKey
			}
		}

		// Get possible members that match the given search
		// tFilters(n) = $LB(text,value)
		Kill tFilters
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(..dataSourceName,..filterName,.tFilters,.tDefaultFilterValue,tSearchKey,.tRelatedFilters)
		If $$$ISERR(tSC) Quit

		Set tLabel = ""
		Set msgApply = $$$TextHTML("Use new values for this filter","%DeepSee")
		Set msgCancel = $$$TextHTML("Do not change this filter value","%DeepSee")

		Set tFilterKey = ""

		// pull apart current values for search box
		Set tValue = ..value

		// list
		&html<<div class="searchBoxList" id="#(..%MakeId("list"))#" style="height:250px;">>
		
		// reset
		Set tReset = $$$Text("Reset","%DeepSee")
		&html<<div class="searchBoxCustomItemEven" onclick="zenPage.getComponent(#(..index)#).selectCustomItem('','');" style="font-weight:bold;color:#606060;font-style:italic;">#(tReset)#&nbsp;</div>>
		Set tCount = tCount + 1

		// list of items
		Set k = $O(tFilters(""))
		While (k'="") {
			Set tFTxt = $LG(tFilters(k),1)
			Set tFVal = $LG(tFilters(k),2)
			Set tCount = tCount + 1
			Set tCls = $S(tCount#2:"searchBoxCustomItemEven",1:"searchBoxCustomItemOdd")
			Set tStyle = $S(tValue=tFVal:"font-weight:bold;background:rgb(53,107,141);color:white;",1:"")
			&html<<div class="#(tCls)#" style="#(tStyle)#" onclick="zenPage.getComponent(#(..index)#).selectCustomItem('#($ZCVT(tFTxt,"O","JS"))#','#($ZCVT(tFVal,"O","JS"))#');">#($ZCVT(tFTxt,"O","HTML"))#&nbsp;</div>>
			Set k = $O(tFilters(k))
		}
		&html<</div>>

		Set pCount = tCount
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw contents of drop down in "measure" mode.
Method %DrawMeasureDropDownContents(searchParm As %String, Output pCount As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pCount = 0
		Set tDataSourceName = ..dataSourceName

		// parse incoming value
		// this should be something like:
		// %SEARCH.&[[Measures].[Units Sold]>1]
		Set tSC = ..%ParseMeasureExpression(tDataSourceName,..value,.tOp,.tParm)
		If $$$ISERR(tSC) {
			Quit
		}

		Set tLabel = ""
		Set msgAll = $$$TextHTML("All","%DeepSee")
		Set msgNOT = $$$TextHTML("Exclude","%DeepSee")
		Set msgRange = $$$TextHTML("Range","%DeepSee")

		Set msgApply = $$$TextHTML("Use new values for this filter","%DeepSee")
		Set msgCancel = $$$TextHTML("Do not change this filter value","%DeepSee")
		Set hlpAll = $$$Text("Show all members within this category","%DeepSee")
		Set hlpCheckbox = $$$Text("Filter results using this value. Use the CTRL key to select multiple items","%DeepSee")
		Set hlpNOT = $$$Text("Exclude the selected items","%DeepSee")
		Set hlpRange = $$$Text("Show everything that is between the start and end values","%DeepSee")

		// header
		&html<
		<table class="searchBoxHeader" cellpadding="0" border="0"><tr>
		<td width="99%" nowrap="1"><b>#($ZCVT(tLabel,"O","HTML"))#&nbsp;</b></td>
		<td><img class="dsptIcon" title="#(msgApply)#" src="#(..iconApply)#" onclick="zenPage.getComponent(#(..index)#).applyMeasure();" /></td>
		<td><img class="dsptIcon" title="#(msgCancel)#" src="#(..iconCancel)#" onclick="zenPage.getComponent(#(..index)#).cancelChanges();"/></td>
		</tr></table>>

		// checkbox(es)
		&html<
		<table class="searchBoxTable" cellpadding="0" border="0" width="100%"><tr>
		<td align="left" nowrap="1">
		<input type="checkbox" id="#(..%MakeId("cball"))#" #($S((tOp="")||(tParm=""):"checked=""1""",1:""))# onclick="zenPage.getComponent(#(..index)#).msrAllClick(event,true);" />
		<span onclick="zenPage.getComponent(#(..index)#).msrAllClick(event,false);">#(msgAll)#</span></td>
		</tr></table>>

		// show expression
		Set tMsrName = ""
 		If (tDataSourceName'="") {
	 		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetCaptionForTargetProperty(tDataSourceName,..filterName,.tMsrName)
			If $$$ISERR(tSC) Quit
 		}

		&html<<div style="padding:2px;text-align:center;background:#F0F0F0;height:100%;color:#404040;">>
		&html<<div style="padding:10px;">#($ZCVT(tMsrName,"O","HTML"))#</div>>
		&html<<select id="#(..%MakeId("msrOp"))#" onchange="zenPage.getComponent(#(..index)#).msrChange();">>
		Set tOpList = $LB("","=","<>",">",">=","<","<=")
		For n=1:1:$LL(tOpList) {
			Set tOpItem = $LG(tOpList,n)
			&html<<option value="#(tOpItem)#" #($S(tOp=tOpItem:"selected=""1""",1:""))#>#(tOpItem)#</option>>
		}
		&html<</select>>
		&html<<input id="#(..%MakeId("msrParm"))#" size="8" type="text" value="#($ZCVT(tParm,"O","HTML"))#" onchange="zenPage.getComponent(#(..index)#).msrChange();" onkeypress="return zenPage.getComponent(#(..index)#).msrKeyPress(event);"/>>
		&html<<div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse a measure expression:<br/>
/// E.g, %SEARCH.&[[Measures].[Units Sold]>1]
Method %ParseMeasureExpression(pDataSourceName As %String, pValue As %String, Output pOp As %Integer, Output pParm As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pOp = ""
		Set pParm = ""

		// parse incoming value
		// this should be something like:
		// %SEARCH.&[[Measures].[Units Sold]>1]
		If ((pValue="")||($$$UPPER($E(pValue,1,8))'="%SEARCH.")) {
		}
		Else {
			// parse (use logic from advanced filter)

			// what kind of data source is in play?
			Set tDataSourceName = pDataSourceName
			If (tDataSourceName'="") {
				If (tDataSourceName'[".") {
		  			Set tDataSourceName=tDataSourceName_".cube"
		  		}
				Set tExt = $P(tDataSourceName,".",$L(tDataSourceName,"."))

				If ((tExt = "pivot")||(tExt = "cube")) {
					If (tExt = "pivot") {
						Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDataSourceName,.tSC)
						If $IsObject(tPivot) {
							Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
						}
					}
					Else {
						Set tCubeName = $$$UPPER($P(tDataSourceName,".",1,$L(tDataSourceName,".")-1))
					}
				}
			}
			If (tCubeName'="") {
				// strip off %SEARCH.&[   ]
				Set tExpr = $E(pValue,11,$L(pValue)-1)

				New %tree
				Set tSC = ##class(%DeepSee.UI.Dialog.AdvancedFilter).%ConvertSearchKeyToGraph("%tree(1)",tCubeName,tExpr)
				If $$$ISERR(tSC) Quit

				Set tOpNode = $G(%tree(1))
				Set tParmNode = $G(%tree(1,2))
				If ($LG(tOpNode,1)="measureOperator") {
					Set pOp = $LG(tOpNode,2)
				}
				If ($LG(tParmNode,1)="literal") {
					Set pParm = $LG(tParmNode,2)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// User click on NOT (exclude members) option within dropdown.
ClientMethod notClick(iscb) [ Language = javascript ]
{
	var ctrlAll = this.findElement('cball');
	var ctrlNOT = this.findElement('cbNOT');
	var ctrlRange = this.findElement('cbRange');
	var wasRange = false;

	if (!iscb) {
		// toggle checkbox
		ctrlNOT.checked = !ctrlNOT.checked;
	}

	if (ctrlNOT.checked) {
		this.selectMode = 'not';
		if (ctrlAll) {		// DTB140 - this may not have been added
			ctrlAll.checked = false;
		}
		if (ctrlRange) {
			wasRange = ctrlRange.checked;
			ctrlRange.checked = false;
		}
	}
	else {
		this.itemClick('','',false);
	}

	if ('calendar' == this.displayMode) {
		// not is not allowed
		if (this.isAnyItemSelected()) {
			ctrlNOT.checked = false;
			this.selectMode = '';
		}

		// special handling for calendar
		var cal = zenPage.getComponentById('cal');
		this.dateChange(cal,false);
		if (wasRange) {
			// hide 2nd calendar
			this.renderDropdown();
		}
	}
	this.updateInput();
}

/// Change of range combo.
ClientMethod rangeChange(which) [ Language = javascript ]
{
	// try to avoid nonsense ranges
	var ctrlR1 = this.findElement('range1');
	var ctrlR2 = this.findElement('range2');
	
	// +DTB121 - control display of offset inputs
	var offset1 = self.document.getElementById('offsetNow1');
	var offset2 = self.document.getElementById('offsetNow2');
	
	if (offset1) {
		offset1.disabled=('&[NOW]'!=ctrlR1.value);
	}
	if (offset2) {
		offset2.disabled=('&[NOW]'!=ctrlR2.value);
	}
	// -DTB121

	// disable for now!
	if (ctrlR1&&ctrlR2&&false) {
		// leave NOW alone!
		if (('&[NOW]'!=ctrlR1.value) && ('&[NOW]'!=ctrlR2.value)) {
			if (which==1) {
				if (ctrlR1.selectedIndex>ctrlR2.selectedIndex) {
					ctrlR2.selectedIndex = ctrlR1.selectedIndex;
				}
			}
			else {
				if (ctrlR1.selectedIndex>ctrlR2.selectedIndex) {
					ctrlR1.selectedIndex = ctrlR2.selectedIndex;
				}
			}
		}
	}
	this.updateInput();
}

/// User click on Range option within dropdown.
ClientMethod rangeClick(iscb) [ Language = javascript ]
{
	var ctrlAll = this.findElement('cball');
	var ctrlNOT = this.findElement('cbNOT');
	var ctrlRange = this.findElement('cbRange');

	if (!iscb) {
		// toggle checkbox
		ctrlRange.checked = !ctrlRange.checked;
	}
	if (ctrlRange.checked) {
		this.selectMode = 'range';
		if (ctrlAll) {
			ctrlAll.checked = false;
		}
		if (ctrlNOT) {
			ctrlNOT.checked = false;
		}
	}
	else {
		this.itemClick('','',false);
	}
	this.renderDropdown();
}

/// User click on all checkbox within measure dropdown.
/// <var>iscb</var> is true if this is a click from the checkbox.
ClientMethod msrAllClick(evt, iscb) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	isall = false;
	var ctrlAll = this.findElement('cball');

	if (!iscb) {
		// toggle checkbox
		ctrlAll.checked = !ctrlAll.checked;
	}

	if (ctrlAll.checked) {
		var ctrlOp = this.findElement('msrOp');
		var ctrlParm = this.findElement('msrParm');
		ctrlOp.value = '';
		ctrlParm.value = '';
	}
}

/// User change value within measure expression dropdown.
ClientMethod msrChange() [ Language = javascript ]
{
	var ctrlAll = this.findElement('cball');
	var ctrlOp = this.findElement('msrOp');
	var ctrlParm = this.findElement('msrParm');

	// toggle checkbox
	ctrlAll.checked = (ctrlOp.value=='')||(ctrlParm.value=='');
}

/// User key press in measure value control.
ClientMethod msrKeyPress(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	switch(evt.keyCode) {
	case zenESC:
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		this.cancelChanges();
		return false;

	case zenENTER:
		this.applyMeasure();
		break;
	}
	return true;
}

/// User click on item within dropdown.
/// <var>iscb</var> is true if this is a click from the checkbox.
ClientMethod itemClick(evt, idx, iscb) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	isall = false;

	var removeItem = false; // + WAL181
	var ctrlAll = this.findElement('cball');
	var ctrlNOT = this.findElement('cbNOT');
	var wasRange = false;

	if (''==idx) {
		var ctrl = ctrlAll;
		isall = true;
		this.selectMode = '';
		if (ctrlNOT) {
			ctrlNOT.checked = false;
		}
		var ctrlRange = this.findElement('cbRange');
		if (ctrlRange) {
			wasRange = ctrlRange.checked;
			ctrlRange.checked = false;
		}
	}
	else {
		var ctrl = this.findElement('cb_'+idx);
		// + WAL181
		if ((ctrl.checked == false) && ('calendar' != this.displayMode) && ('range' != this.selectMode) && (iscb)) { // WAL214 -- only set flag if checkbox
			removeItem = true;
		}
		// - WAL181
	}

	if (!iscb && ctrl) {
		// click on label: toggle checkbox
		ctrl.checked = !ctrl.checked;
	}

	if ('calendar' == this.displayMode) {
		// special handling for calendar
		var cal = zenPage.getComponentById('cal');
		cal.setValue('');
		this.dateChange(cal,false);

		if (''==idx) {
			if (ctrlAll) {
				ctrlAll.checked = true;
			}
			this.resetItems();
		}
		else {
			// not is not allowed for now
			if (ctrlNOT) {
				ctrlNOT.checked = false;
				this.selectMode = '';
			}
			if (ctrlAll) {
				ctrlAll.checked = false;
			}
			this.resetItems(idx);
		}
		this.updateInput();
		if (wasRange) {
			// hide 2nd calendar
			this.renderDropdown();
		}
		return;
	}

	// if true, don't require ctrl key to multi select
	var multi = iscb;

	// behavior:
	// 	click on label is radio button (unless ctrl is down)
	//  click on check box adds the choice
	if (ctrl && ctrl.checked && isall) {
		// turn off all others
		this.resetItems();
	}
	else if (ctrl && ctrl.checked && !isall) {
		if (ctrlAll) {		// DTB140 - this may not have been added
			ctrlAll.checked = false;
		}
		if (!this.multiSelect || (!evt.ctrlKey && !multi)) {
			// ctrl not pressed; reset all other items
			this.resetItems(idx);
		}
	}
	else if (ctrl && !ctrl.checked) {
		// if nothing checked, turn all box on
		var any = this.isAnyItemSelected();
		if (!any) {
			if (ctrlAll) {		// DTB140 - this may not have been added
				ctrlAll.checked = true;
			}
			if (ctrlNOT) {
				// PFS025 - Uncheck EXCLUDE when nothing is selected
				ctrlNOT.checked = false;
			}
		}
	}
	
	// PFS102 - Always update input (this fixes initial load issues)
	this.updateInput();
	
	if (removeItem) {
		 this.removeItem(idx);
	}
}

ClientMethod removeItem(idx) [ Language = javascript ]
{
	var removeValue = '';
	var cb = this.findElement('cb_'+idx);
	if (!cb) return;
	// find wrapper tr element to get values for this item
	var tr = this.findElement('item_'+idx);
	if (tr) {
		removeValue = tr.getAttribute('zenValue');
	}
	for (var n = 0; n < this.listOfValues.length; n++) {
		if (this.listOfValues[n]==removeValue) {
			this.listOfValues.splice(n,1);
			this.listOfText.splice(n,1);
		}
	}
	// + WAL231 -- remove this item from the prior values lists so that
	//             updateInput doesn't add it back into to filter
	for (var n = 0; n < this.priorValues.length; n++) {
		if (this.priorValues[n]==removeValue) {
			this.priorValues.splice(n,1);
			this.priorText.splice(n,1);
		}
	}
	// - WAL231
	this.text = this.listOfText[0] ? zenEscapeXML(this.listOfText[0]) : '';
	this.value = this.listOfValues.join(',');
	if (this.listOfValues.length>1) {
		this.value = '{' + this.value + '}';
		this.text = zenEscapeXML(this.listOfText.join('+ '));
	}

	if (this.selectMode=='not' && '' != this.value) {
		// use special NOT value to be replaced later
		this.value = '%NOT ' + this.value;
		this.text = 'NOT&nbsp;' + this.text;
	}
	this.title = this.text;
	var hidden = this.findElement('hidden');
	hidden.value = this.value;

	var td = this.findElement('input');
	if (td) {
		td.innerHTML = this.text + '&nbsp;';
	}
	this.updateTooltip();
}

/// Unselect all options in the dropdown list.
/// If <var>skip</var> is provided, do not reset it.
ClientMethod resetItems(skip) [ Language = javascript ]
{
	skip = ('undefined' == typeof skip) ? -1 : skip;
	for (n=1;;n++) {
		var cb = this.findElement('cb_'+n);
		if (!cb) break;
		if (skip==-1 || n!=skip) {
			cb.checked = false;
		}
	}
	if (skip==-1) {
		// JMD1366 clear prior
		this.priorValues.length = 0;
		this.priorText.length = 0;
	}
}

/// Test if any checkbox is selected in the dropdown list.
ClientMethod isAnyItemSelected() [ Language = javascript ]
{
	var any = false;
	if (this.priorValues.length>0) {
		// JMD1366
		any = true;
	}
	else {
		for (n=1;;n++) {
			var cb = this.findElement('cb_'+n);
			if (!cb) break;
			if (cb.checked) {
				any = true;
				break;
			}
		}
	}
	return any;
}

/// Display new values in input control.
ClientMethod updateInput() [ Language = javascript ]
{
	// clear current selections
	this.listOfValues.length = 0;
	this.listOfText.length = 0;

	// get value(s)
	if ('range' == this.selectMode) {
		// DTB551 - Moved to specific case
		this.value = '';
		this.text = '';
		this.title = '';
		
		var ctrlR1 = this.findElement('range1');
		var ctrlR2 = this.findElement('range2');
		
		// +DTB121 - use offsets to find the value in the case where NOW is selected
		var offset1 = self.document.getElementById('offsetNow1');
		var offset2 = self.document.getElementById('offsetNow2')
		var usesOffset = false;
		
		// clear bad offset value
		// !!! we could allow expressions -10y etc...
		var nowOffset1 = '';
		var nowOffset2 = '';
		if (offset1) {
			usesOffset = true;
			offset1.value = (!offset1.value||isNaN(parseInt(offset1.value,10))) ? '' : parseInt(offset1.value,10);
			offset1.value = offset1.value>0 ? ('+'+offset1.value) : offset1.value;
			offset1.value = offset1.value==0 ? '' : offset1.value;
			nowOffset1 = offset1.value;
		}
		if (offset2) {
			usesOffset = true;
			offset2.value = (!offset2.value||isNaN(parseInt(offset2.value,10))) ? '' : parseInt(offset2.value,10);
			offset2.value = offset2.value>0 ? ('+'+offset2.value) : offset2.value;
			offset2.value = offset2.value==0 ? '' : offset2.value;
			nowOffset2 = offset2.value;
		}
		
		if ((usesOffset)&&(ctrlR1&&ctrlR2)) {
			// DTB121 - at least one NOW with an offset is in play
			var format = this.dateFormat;
			
			var c1text = !offset1.disabled ? this.resolveNowOffset(nowOffset1,this.selectType) : ctrlR1.options[ctrlR1.selectedIndex].text;
			var c2text = !offset2.disabled ? this.resolveNowOffset(nowOffset2,this.selectType) : ctrlR2.options[ctrlR2.selectedIndex].text;
			
			var c1value = !offset1.disabled ? ('&[NOW'+nowOffset1+']') : c1text=="" ? "" : ctrlR1.value;
			var c2value = !offset2.disabled ? ('&[NOW'+nowOffset2+']') : c2text=="" ? "" : ctrlR2.value;

			// Set the title explicitly in this case. The display will not show NOW but the tooltip will show the display version of the actual key
			var c1title = !offset1.disabled ? ($$$Text('NOW')+nowOffset1) : ctrlR1.options[ctrlR1.selectedIndex].text;
			var c2title = !offset2.disabled ? ($$$Text('NOW')+nowOffset2) : ctrlR2.options[ctrlR2.selectedIndex].text;
			
			if (!offset1.disabled&&!offset2.disabled&&(nowOffset1==nowOffset2)) {
				// avoid range between same values
				c2text = '';
				c2value = '';
			}
			this.text = c1text + ((c1text!=''&&c2text!='')?':':'') + c2text;
			this.value = c1value + ((c1value!=''&&c2value!='')?':':'') + c2value;
			this.title = c1title + ((c1title!=''&&c2title!='')?':':'') + c2title;
		}		
		else if (ctrlR1&&ctrlR2) {
			// DTB121 - range between two concrete members
			this.text = ctrlR1.options[ctrlR1.selectedIndex].text +":"+ ctrlR2.options[ctrlR2.selectedIndex].text;
			this.value = ctrlR1.value +":"+ ctrlR2.value;
			this.title = this.text;
		}
		// -DTB121
	}
	else if (('not'==this.selectMode)&&('calendar'==this.displayMode)) {
		// DTB551 - Do nothing in this case, the calendar has already handled it
	}
	else {
		// DTB551 - Moved to specific case
		this.value = '';
		this.text = '';
		this.title = '';
		
		var ctrlAll = this.findElement('cball');
		if (!ctrlAll || !ctrlAll.checked) {
			// visit each cb
			for (n=1;;n++) {
				var cb = this.findElement('cb_'+n);
				if (!cb) break;
				if (cb.checked) {
					// find wrapper tr element to get values for this item
					var tr = this.findElement('item_'+n);
					if (tr) {
						this.listOfValues[this.listOfValues.length] = tr.getAttribute('zenValue');
						this.listOfText[this.listOfText.length] = tr.getAttribute('zenText');
					}
				}
			}
			
			// JMD1366 fold in prior list
			// prevent duplicates
			var vlist = {};
			for (var n = 0; n < this.listOfValues.length; n++) {
				if (this.listOfValues[n]) {
					vlist[this.listOfValues[n]] = true;
				}
			}
			for (var n = 0; n < this.priorValues.length; n++) {
				// PFS072 - Skip folding prior list if multiSelect is disabled
				if ((this.priorValues[n])&&!vlist[this.priorValues[n]]&&this.multiSelect) {
					this.listOfValues.push(this.priorValues[n]);
					this.listOfText.push(this.priorText[n]);
					vlist[this.priorValues[n]] = true;
				}
			}

			this.text = this.listOfText[0] ? zenEscapeXML(this.listOfText[0]) : '';
			this.value = this.listOfValues.join(',');
			if (this.listOfValues.length>1) {
				this.value = '{' + this.value + '}';
				this.text = zenEscapeXML(this.listOfText.join('+ '));
			}

			if (this.selectMode=='not' && '' != this.value) {
				// use special NOT value to be replaced later
				this.value = '%NOT ' + this.value;
				this.text = 'NOT&nbsp;' + this.text;
			}
		}
		this.title = this.text;		// DTB121 
	}

	var hidden = this.findElement('hidden');
	hidden.value = this.value;

	var td = this.findElement('input');
	if (td) {
		td.innerHTML = this.text + '&nbsp;';
	}
	this.updateTooltip();
}

/// User click on ok icon.
ClientMethod applyChange() [ Language = javascript ]
{
	// WAL181 - if (updateInput) this.updateInput();
	
	// DTB140 - enforce valueRequired
	if ( (''==this.value) && this.valueRequired ) {
		alert($$$Text('A value is required for this control.'));
	}
	else {
		// notify
		this.onchangeHandler();

		// otherwise endModal assumes cancel
		this._applied = true;
		zenPage.endModal();
		delete this._applied;
	}
}

/// User click on ok icon in calendar mode.
ClientMethod applyCalendar() [ Language = javascript ]
{
	// DTB140 - enforce valueRequired
	if ( (''==this.value) && this.valueRequired ) {
		alert($$$Text('A value is required for this control.'));
	}
	else {
		// notify
		this.onchangeHandler();
		this._applied = true;
		zenPage.endModal();
		delete this._applied;
	}
}

/// User click on ok icon in measure mode.
ClientMethod applyMeasure() [ Language = javascript ]
{
	this.listOfValues.length = 0;
	this.listOfText.length = 0;

	var msrOp = this.findElement('msrOp').value;
	var msrParm = this.findElement('msrParm').value;
	if (msrParm=='') {
		var val = '';
		var text = '';
	}
	else {
		var val = '%SEARCH.&['+this.filterName+msrOp+msrParm+']';
		var text = msrOp+msrParm;
	}

	this.value = val;
	this.text = text;

	this.listOfValues[this.listOfValues.length] = val;
	this.listOfText[this.listOfText.length] = text;

	var td = this.findElement('input');
	if (td) {
		td.innerHTML = this.text + '&nbsp;';
		td.title = this.text;
	}

	var hidden = this.findElement('hidden');
	hidden.value = this.value;
	this.updateTooltip();

	// notify
	this.onchangeHandler();
	this._applied = true;
	zenPage.endModal();
	delete this._applied;
}

/// Cancel user changes.
ClientMethod cancelChanges(close) [ Language = javascript ]
{
	close = ('undefined' == typeof close ? true : close);

	this.value = this._value;
	this.text = this._text;
	this.listOfValues = this._listOfValues.slice(0);
	this.listOfText = this._listOfText.slice(0);

	var hidden = this.findElement('hidden');
	hidden.value = this.value;
	var td = this.findElement('input');
	if (td) {
		td.innerHTML = this.text + '&nbsp;';
		td.title = this.text;
	}
	if (close) {
		if ( (''==this.value) && this.valueRequired ) {
			// DTB140 - prevent closing if a value is not set
			alert($$$Text('A value is required for this control.'));
		}
		else {
			zenPage.endModal()
		};
	}
}

/// Remember current values.
ClientMethod rememberValues() [ Language = javascript ]
{
	// make copies
	this._value = this.value;
	this._text = this.text;
	this._listOfValues = this.listOfValues.slice(0);
	this._listOfText = this.listOfText.slice(0);
}

/// Convert value to a display value.
ClientMethod findDisplayValue(value) [ Language = javascript ]
{
	if ('' === value) {
		return '';
	}
	var text = value;

	if ((null!=zenPage._sourceControl)&&('undefined'!=typeof zenPage._sourceControl.text)) {
		// copy over text value of source
		text = zenPage._sourceControl.text;
	}
	return text;
}

/// User selected a value in the custom drop down.
ClientMethod selectCustomItem(text, val) [ Language = javascript ]
{
	this.listOfValues.length = 0;
	this.listOfText.length = 0;
	this.value = val;
	this.text = text;

	var td = this.findElement('input');
	if (td) {
		td.innerHTML = this.text + '&nbsp;';
		td.title = this.text;
	}

	var hidden = this.findElement('hidden');
	hidden.value = this.value;
	this.onchangeHandler();

	this._applied = true;
	zenPage.endModal();
}

/// Notification that this component is about to stop being modal.
ClientMethod onEndModalHandler(zindex) [ Language = javascript ]
{
	if (!this._applied) {
		this.cancelChanges(false);
	}
	this.invokeSuper('onEndModalHandler',arguments);
}

/// User selected a new date in the calendar.
ClientMethod dateChange(ctrl, clear) [ Language = javascript ]
{
	this.listOfValues.length = 0;
	this.listOfText.length = 0;

	// clear checkboxes (if any)
	if (clear) {
		this.resetItems();
	}

	for (var n = 0; n < ctrl.listOfValues.length; n++) {
		var val = ctrl.listOfValues[n];
		if (''!==val) {
			var text = val;

			// convert to horolog
			var h = this.dateToHorolog(val);
			val = '&['+h+']';
			this.listOfValues[this.listOfValues.length] = val;
			this.listOfText[this.listOfText.length] = this.dateFormat ? zenFormatDate(text,this.dateFormat) : text;
		}
	}

	this.text = this.listOfText[0] ? this.listOfText[0] : '';
	this.value = this.listOfValues.join(',');
	if (ctrl.isRange && this.listOfValues.length==2) {
		this.value = this.listOfValues.join(':');
		this.text = this.listOfText.join(':');
	}
	else if (this.listOfValues.length>1) {
		this.value = '{' + this.value + '}';
		this.text = this.listOfText.join('+ ');
	}

	if (this.selectMode=='not' && ''!==this.value) {
		// use special NOT value to be replaced later
		this.value = '%NOT ' + this.value;
		this.text = 'NOT&nbsp;' + this.text;
	}

	if (''!=this.value) {
		var ctrlAll = this.findElement('cball');
		if (ctrlAll) {
			ctrlAll.checked = false;
		}
	}

	var hidden = this.findElement('hidden');
	hidden.value = this.value;
	var td = this.findElement('input');
	if (td) {
		td.innerHTML = this.text + '&nbsp;';
		td.title = this.text;
	}
	this.updateTooltip();
}

/// Convert a yyyy-mm-dd date to $h.
ClientMethod dateToHorolog(val) [ Language = javascript ]
{
	if (''!==val && val!='NOW') {
		var text = val;
		var t = val.toString().split('-');
		var year = parseInt(t[0],10);
		var month = parseInt(t[1],10)-1;
		var day = parseInt(t[2],10);
		var date = new Date(Date.UTC(year,month,day));
		
		// convert to horolog
		val = Math.round(((date.getTime()) / 1000) / 86400) + 47117;
	}
	return val;
}

/// Convert NOW-offset to a readable date value given the type. If an unsupported type is entered, the function
/// will return a localized 'NOW'+offset.<br>
/// Supported types: day, month, year
ClientMethod resolveNowOffset(offset, type) [ Language = javascript ]
{
	// Method added by DTB121
	offset = Number(offset);		// Supports offset coming in as a string, eg: '+5'
 	var val = '';
 	date = new Date();
 	if ('gregorian'==this.calendar) {		// DTB181 - Each calendar must be processed differently
		if ('day'==type) {
			var dateODBC = date.getFullYear() + '-' + (date.getMonth()+1) + '-' + date.getDate();
			var offsetDateHoro = this.dateToHorolog(dateODBC) + offset;
			
			val = zenFormatDate(this.dateFromHorolog(offsetDateHoro),this.dateFormat);
		}
		else if ('month'==type) {
			// need to calculate month offset here!
			var monthNumber = date.getFullYear()*12 + date.getMonth() + 1 + offset;
			var offsetYear = Math.floor(monthNumber/12);
			var offsetMonth = monthNumber%12;
			
			// DTB148 - Use user-defined dateFormat for months if it is defined.
			if (''!=this.dateFormat) {
				val = zenFormatDate(offsetYear + '-' + offsetMonth,this.dateFormat);
			}
			else {
				val = zenFormatDate(offsetYear + '-' + offsetMonth,'mmm-y');
			}
		}
		else if ('year'==type) {
			val = date.getFullYear() + offset;
		}
 	}
	
	if (''==val) {
		// Missing the information to resolve the NOW, so display it with its offset
		val = $$$Text('NOW') + (offset>0 ? ('+'+offset) : (offset<0 ? offset : '') )  ;		// DTB181 - Do not add anything if offset is 0
	}

	return val;
}

/// Convert a $H to yyyy-mm-dd date.
ClientMethod dateFromHorolog(val, nowInfo) [ Language = javascript ]
{
	// JMD1335: test for NOW
	var date = null;
	if (nowInfo) {
		nowInfo.now = false;
		nowInfo.offset = '';
	}
	if (val.toString().indexOf('NOW')>=0) {
		// assume offset is in days
		var date = new Date();
		// PFS096 - Cast as int so later expressions are addition instead of string concat
		var tMinus = parseInt(val.split('-')[1]);
		var tPlus = parseInt(val.split('+')[1]);
		if (tMinus) {
			date.setDate(date.getDate() - tMinus);
			if (nowInfo) {
				nowInfo.offset = '-'+tMinus;
			}
		}
		else if (tPlus) {
			date.setDate(date.getDate() + tPlus);
			if (nowInfo) {
				nowInfo.offset = '+'+tPlus;
			}
		}
		if (nowInfo) {
			nowInfo.now = true;
		}
	}
	else if (''!==val && !isNaN(val)) {
		var days1970 = parseInt(val,10) - 47117;
		var date = new Date((days1970 * 24 * 3600 * 1000));
	}
	if (date) {
		var mon = date.getUTCMonth();
		mon = (mon<9?'0':'') + (mon+1);
		var day = date.getUTCDate();
		day = (day<10?'0':'') + (day);
		var yr = date.getUTCFullYear();
		val = yr+'-'+mon+'-'+day;
	}
	
	return val;
}

/// User click on NOW checkbox.
ClientMethod cbNowClick(isCB, which) [ Language = javascript ]
{
	var cb1 = self.document.getElementById('cbNow1');
	var cb2 = self.document.getElementById('cbNow2');
	var offset1 = self.document.getElementById('offsetNow1');
	var offset2 = self.document.getElementById('offsetNow2');

	if (!isCB) {
		if (which==1 && cb1) {
			cb1.checked = !cb1.checked;
		}
		else if (which==2 && cb2) {
			cb2.checked = !cb2.checked;
		}
	}

	var cal1 = zen('cal');
	if (cb1 && cb1.checked) {
		cal1.setDisabled(true);
		offset1.disabled = false;
	}
	else {
		cal1.setDisabled(false);
		offset1.disabled = true;
	}

	var cal2 = zen('cal2');
	if (cb2 && cb2.checked) {
		cal2.setDisabled(true);
		offset2.disabled = false;
	}
	else {
		cal2.setDisabled(false);
		offset2.disabled = true;
	}
	this.dateRangeChange(which);
}

/// User change on NOW offset input
ClientMethod offsetNowChange(which) [ Language = javascript ]
{
	// DTB121 - calendars are used only for days, dropdown range pickers for all other time levels
	if (this.selectType=='day') {
		this.dateRangeChange(which);
	}
	else {
		this.rangeChange(which);
	}
}

/// User selected a new date range in the calendar(s).
ClientMethod dateRangeChange(which) [ Language = javascript ]
{
	var cal1 = zen('cal');
	var cal2 = zen('cal2');
	var cb1 = self.document.getElementById('cbNow1');
	var cb2 = self.document.getElementById('cbNow2');
	var now1 = (cb1 && cb1.checked);
	var now2 = (cb2 && cb2.checked);
	var offset1 = self.document.getElementById('offsetNow1');
	var offset2 = self.document.getElementById('offsetNow2');

	// clear bad offset value
	// !!! we could allow expressions -10y etc...
	var nowOffset1 = '';
	var nowOffset2 = '';
	if (offset1) {
		offset1.value = (!offset1.value||isNaN(parseInt(offset1.value,10))) ? '' : parseInt(offset1.value,10);
		offset1.value = offset1.value>0 ? ('+'+offset1.value) : offset1.value;
		offset1.value = offset1.value==0 ? '' : offset1.value;
		nowOffset1 = offset1.value;
	}
	if (offset2) {
		offset2.value = (!offset2.value||isNaN(parseInt(offset2.value,10))) ? '' : parseInt(offset2.value,10);
		offset2.value = offset2.value>0 ? ('+'+offset2.value) : offset2.value;
		offset2.value = offset2.value==0 ? '' : offset2.value;
		nowOffset2 = offset2.value;
	}

	this.listOfValues.length = 0;
	this.listOfText.length = 0;

	// try to avoid bad ranges
	if (!now1 && !now2 && (cal1.getValue()!='')&&(cal2.getValue()!='')) {
		if (which == 1) {
			if (cal1.getValue()>cal2.getValue()) {
				cal2.setValue(cal1.getValue());
			}
		}
		else if (which == 2) {
			if (cal1.getValue()>cal2.getValue()) {
				cal1.setValue(cal2.getValue());
			}
		}
	}
	var format = this.dateFormat;
	// DTB121 - always show a human-readable time member
	var c1text = now1 ? this.resolveNowOffset(nowOffset1,this.selectType) : (format?zenFormatDate(cal1.getValue(),format):cal1.getValue());
	var c2text = now2 ? this.resolveNowOffset(nowOffset2,this.selectType) : (format?zenFormatDate(cal2.getValue(),format):cal2.getValue());
	
	var c1value = now1 ? ('&[NOW'+nowOffset1+']') : c1text=="" ? "" : '&[' + this.dateToHorolog(cal1.getValue()) + ']';		// DTB148 - use original value, not calculated text.
	var c2value = now2 ? ('&[NOW'+nowOffset2+']') : c2text=="" ? "" : '&[' + this.dateToHorolog(cal2.getValue()) + ']';		// DTB148

	// DTB121 - title will hold the NOW values if they are used
	var c1title = now1 ? ($$$Text('NOW')+nowOffset1) : (format?zenFormatDate(cal1.getValue(),format):cal1.getValue());
	var c2title = now2 ? ($$$Text('NOW')+nowOffset2) : (format?zenFormatDate(cal2.getValue(),format):cal2.getValue());

	if (now1 && now2 && (nowOffset1==nowOffset2)) {
		// avoid range between same values
		c2text = '';
		c2value = '';
		c2title = '';		// DTB121
	}

	this.value = c1value + ((c1value!=''&&c2value!='')?':':'') + c2value;
	this.text = c1text + ((c1text!=''&&c2text!='')?':':'') + c2text;
	this.title = c1title + ((c1title!=''&&c2title!='')?':':'') + c2title;

	var hidden = this.findElement('hidden');
	hidden.value = this.value;
	var td = this.findElement('input');
	if (td) {
		td.innerHTML = this.text + '&nbsp;';
	}
	this.updateTooltip();
}

/// Change the tooltip for the input control.
ClientMethod updateTooltip() [ Language = javascript ]
{
	var input = this.findElement('input');		// DTB121 - use 'input' not 'search'!
	if (input) {
		if (''==this.title) {
			input.title = this.text.replace(/&#160;/g,' ');		// DTB551 - Text might have an escaped space
		}
		else {
			// DTB121 - title may contain different information than text
			input.title = this.title;
		}
	}
}

/// Intercept default behavior.
/// Keydown within input control.
ClientMethod inputKeyHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var idx = parseInt(this.selectedIndex,10);

	// trap keys
	if (this.isDropdownVisible) {
		switch(evt.keyCode) {
		case zenESC:
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			this.cancelChanges();
			return false;

		case zenENTER:
			if (this.keyMode) {
				// show drop down
				this.clearTimer();
				this.keyMode = true;
				this.showDropdown();
			}
			else {
				this.applyChange();
			}
			return false;
		default:
			this.keyMode = true;
			break;
		}
	}
	else {
		switch(evt.keyCode) {
		case zenESC:
			if (zenPage.modalStack.length>0) {
				this.cancelChanges();
			}
			return false;

		case zenDOWN:
		case zenENTER:
			// show drop down
			this.clearTimer();
			this.keyMode = true;
			this.showDropdown();
			return false;
		default:
			this.startTimer();
			this.useSearch = true;
			break;
		}
	}

	// invoke callback, if present
	return zenInvokeCallbackMethod(this.onkeydown,this,'onkeydown');
}

/// Lookup up the display value for the combobox given a logical value.<br/>
Method %GetDisplayValue(pValue As %String, pType As %String = "") As %String
{
	Set tText = pValue
	Set tType = $G(pType)		// DTB551
	Try {
		Set tCubeName = ""

		// +DTB551 - Add support for more possible values of the raw filter
		Set tHasNot = 0
		If ($E(pValue,1,4)="%NOT") {
			Set tHasNot = 1
			Set pValue = $ZSTRIP($E(pValue,5,*),"<>W")		// DTB
			
			// Parse the incoming key. A single key will get isolated, 
			// a set or exclude key will remain as-is.
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pValue,.tInfo)
			If $$$ISERR(tSC) Quit
			Set pValue = tInfo(1)
		}
		// -DTB551

		// what kind of data source is in play?
		If (..dataSourceName'="") {
			Set tDataSourceName = ..dataSourceName
			If (tDataSourceName'[".") {
	  			Set tDataSourceName=tDataSourceName_".cube"
	  		}
			Set tExt = $P(tDataSourceName,".",$L(tDataSourceName,"."))

			If ((tExt = "pivot")||(tExt = "cube")) {
				If (tExt = "pivot") {
					Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDataSourceName,.tSC)
					If $IsObject(tPivot) {
						Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
					}
				}
				Else {
					Set tCubeName = $$$UPPER($P(tDataSourceName,".",1,$L(tDataSourceName,".")-1))
				}
			}
			ElseIf ((tExt="kpi")||(tExt="metric")||(tExt="worksheet")) {
				If (tExt="kpi") {
					Set tName = $P(tDataSourceName,".",1,$L(tDataSourceName,".")-1)
					Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
				}
				ElseIf (tExt="worksheet") {
					Set tKPIClass = "%DeepSee.KPIWorksheet"
				}
				Else {
					Set tKPIClass = "Ens.BusinessMetricKPI"
				}
				If (tKPIClass'="") {
					Set tText = pValue		// DTB609
					// + WAL209 -- format the values, if they are in key format
					//             Values will be in key format if this is an MDX-based KPI that makes
					//             use of %GetMembersForFilter, as in:
					//                 do ..%GetMembersForFilter("Patients.cube",pFilter,.pMembers)
					Set tParsedText=""
					Set tSC = ##class(%DeepSee.Utils).%ParseKeyForDisplay(pValue,.tParsedText,tKPIClass,..filterName)		// DTB609
					If $$$ISERR(tSC) Quit
					Set:(tParsedText'="") tText = tParsedText
					// - WAL209
				}
				Else {
					Set tText = $ZSTRIP(pValue,"<>W")
					If ($E(tText,1,2)="&[") {
						Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pValue,.tInfo)		// DTB551 - Use the parser
						Set tText = tInfo(1)
					}
				}
			}
		}

		If (tCubeName'="") {
			// value could be a range
			Set tText = ""
			If (..filterName="$NAMEDFILTER") {
				// DTB516 - For named fiters, attempt to match the spec with the definition
				Set tSC = ##class(%DeepSee.Utils).%GetNamedFilters(tCubeName,.tNamedFilters)
				If $$$ISERR(tSC) Quit
				
				Set tFilterNo = $O(tNamedFilters(""),1,tFilterInfo)
				While tFilterNo'="" {
					If ($LG(tFilterInfo,3)=pValue) {
						Set tText = $LG(tFilterInfo,1)
						Quit
					}

					Set tFilterNo = $O(tNamedFilters(tFilterNo),1,tFilterInfo)
				}
			}
			ElseIf (..filterName["$variable") {
				// DTB551 - Handle pivot variables by type
				If (tType="day") {
					Set tText = ##class(%DeepSee.Time.DayMonthYear).%KeyToValue(pValue)
				}
			}
			Else {
				For q=1:1:$L(pValue,":") {
					Set tSC = ##class(%DeepSee.Utils).%GetLevelNameForKey(tCubeName,..filterName,$P(pValue,":",q),.tText2)
					If (tText2="") {
						// JMD1407: this is not a range; this is a name with a ":" in it
						Set tText = pValue
						Quit
					}
					If $$$ISOK(tSC) {
						Set tText = $S(q>1:tText_":"_tText2,1:tText2)
					}
					Quit:q>=2
				}
			}
		}
		
		If tHasNot {
			// DTB551 - Prepend with NOT if the value was passed in an exclude key
			Set tText = $$$Text("NOT") _ " " _ tText
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tText = $System.Status.GetOneErrorText(tSC)
	}
	
	If (tText="") {
		// DTB551 - Always return something if the inpuut couldn't be converted!
		Set tText = pValue
	}

	Quit tText
}

/// Adjust the placement and size of the dropdown box based on
/// current screen geometry and scrolling conditions.
ClientMethod adjustDropdownPosition() [ Language = javascript ]
{
	this.invokeSuper('adjustDropdownPosition',arguments);
	var div = this.getDropDownDiv();

	// don't let drop down go off right edge
	var left = zenGetLeft(div);
	var ww = zenGetWindowWidth();
	if ((left + div.offsetWidth) > ww) {
		div.style.left = (ww-div.offsetWidth)+'px';
	}
}

/// Keypress in search box control.
ClientMethod searchKeyPress(evt) [ Language = javascript ]
{
	evt = evt ? evt : event;
	var ctrl = this.findElement('search');
	if (ctrl.style.color != '') {
		ctrl.style.color = '';
		ctrl.value = '';
	}

	switch(evt.keyCode) {
	case zenENTER:
		this.doSearch();
		break;
	case zenESC:
		this.cancelChanges();
		break;
	}
	return true;
}

/// Perform search on drop down contents.
ClientMethod doSearch() [ Language = javascript ]
{
	// PFS102 - Call updateInput to save the state before searching
	this.updateInput();
	
	// refresh dropdown
	var ctrl = this.findElement('search');
	this.searchText = ctrl.value;

	// JMD1366 remember current items
	for (var n = 0; n < this.listOfValues.length; n++) {
		this.priorValues.push(this.listOfValues[n]);
		this.priorText.push(this.listOfText[n]);
	}
	this.loadDropdown(ctrl.value,true);
}

/// Explicitly set text value of this control.
ClientMethod setTextValue(text) [ Internal, Language = javascript ]
{
	this.text = text;
	var td = this.findElement('input');
	if (td) {
		td.innerHTML = this.text + '&nbsp;';
		td.title = this.text;
	}
}

/// Adjust the width of the dropdown.
ClientMethod adjustDropDownWidth() [ Internal, Language = javascript ]
{
	var div = this.getDropDownDiv();
	var list = this.findElement('list');
	if (list) {
		div.style.width = list.offsetWidth + 'px'; // JSL4502 this original code makes searchbox too wide?
	}
}

}
