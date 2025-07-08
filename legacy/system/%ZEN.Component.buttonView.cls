/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This Zen component displays a set of text buttons displayed 
/// within a table. The number of columns is determined by the
/// <property>columns</property> property.<br/>
/// The contents of the <class>buttonView</class> are provided via the
/// user-defined <property>OnGetButtonInfo</property> callback.<br/>
/// This component is typically used to display progressive filter
/// buttons that allow a user to narrow down a search.
Class %ZEN.Component.buttonView Extends %ZEN.Component.component [ Deprecated, System = 3 ]
{

/// Number of columns of buttons to display.
Property columns As %ZEN.Datatype.integer(MINVAL = 1) [ InitialExpression = 4 ];

/// A string containing the current selected values.
/// This takes the form: "category:value;"
Property value As %ZEN.Datatype.string;

/// onselect event handler:
/// If defined, this event is fired when the user selects a new button.
/// The variable, <var>value</var> is passed to the event handler
/// and contains the current value of this component (same as
/// the <property>value</property> property).
Property onselect As %ZEN.Datatype.eventHandler;

/// Optional.
/// User-defined seed value. This is an optional parameter that
/// is passed on to the <method>OnGetButtonInfo</method> callback
/// method.<br>
Property seed As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Optional.
/// Name of Server-side callback method that provides the list of items to display
/// for this component.<br>
/// This method should return an array, indexed by button number, that
/// defines the category, caption, value, and (optional) tooltip for each button. You can
/// also provide an optional, disabled flag, which, it true will make
/// the button disabled in all cases.
/// The array takes the form:<br/>
/// <example>
/// Set pInfo(n) = $LB(category,caption,value,tooltip,disabled)
/// </example>
/// When the user selects a button, all other buttons of the same category
/// are disabled (unless category is ""). Pressing the Reset button restores
/// clears all the selections.<br/>
/// This must be the name of a server-only method in the page
/// class that contains this view component.
Property OnGetButtonInfo As %ZEN.Datatype.delegator(FORMALSPEC = "seed:%ZEN.Datatype.string,&pInfo", RETURNTYPE = "%Status");

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">

/* @doc="Table used to group buttons." */
.bvwTable {
	border: 1px solid black;
	font-family: lucida sans unicode, verdana, sans-serif;
	table-layout: fixed;
	width: 100%;
	background: #D0D0D0;
	font-size: 0.8em;
}

/* @doc="Item within buttonView." */
.bvwItem {
	border: 1px solid black;
	width: 125px;
	overflow: hidden;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Selected item within buttonView." */
.bvwItemSelected {
	border: 1px solid black;
	background: #000040;
	background-image: url(images/grad-blue-10x30.png);
	background-repeat: repeat-x;
	width: 125px;
	overflow: hidden;
}

/* @doc="Reset button within buttonView." */
.bvwItemReset {
	border: 1px solid black;
	background: #404000;
	background-image: url(images/grad-yellow-10x100.png);
	background-repeat: repeat-x;
	width: 125px;
	overflow: hidden;
	font-weight: bold;
}

/* @doc="Disabled item within buttonView." */
.bvwItemDisabled, .bvwItemDisabledAlways {
	border: 1px solid gray;
	width: 125px;
	overflow: hidden;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

.bvwTable a {
	text-align: center;
	display: block;
	padding: 2px;
	padding-left: 4px;
	padding-right: 4px;
}

.bvwItem a, .bvwItemReset a {
	color: black;
}

.bvwItemSelected a {
	color: white;
}

.bvwItemDisabled a, .bvwItemDisabledAlways a {
	color: #808080;
}

.bvwTable a:link, .bvwTable a:visited {
	text-decoration: none;
}

.bvwItem a:hover,.bvwItemReset a:hover {
	background: #FFEEAA;
	color: darkblue;
	height: 100%;
}

.bvwItemSelected a:hover {
	color: #FFEEAA;
}

</style>
}

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML()
{
	Set tInfo($I(tInfo)) = $LB("",$$$Text("Reset","%ZEN"),-1,$$$Text("Clear the current selections","%ZEN"))
	Set tSC = ..%GetButtonInfo(.tInfo)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
		Quit
	}

	Set tItemsPerRow = ..columns
	Set n = 0

	&html<<table class="bvwTable" cellspacing="4" border="0" cellpadding="0">>
	Set tKey = $O(tInfo(""))
	While (tKey '= "") {
		If (n#tItemsPerRow = 0) {
			&html<<tr>>
		}
		Set n = n + 1
		Set tGroup = $LG(tInfo(tKey),1)
		Set tName = $LG(tInfo(tKey),2)
		Set tValue = $LG(tInfo(tKey),3)
		Set tTitle = $LG(tInfo(tKey),4)
		Set tDisabled = $LG(tInfo(tKey),5,0) // 1:disabled (always),0:enabled
		Set tCls = $Case(tDisabled,1:"bvwItemDisabledAlways",:$S(n=1:"bvwItemDisabled",1:"bvwItem"))
		Set:tTitle'="" tTitle="title="""_tTitle_""""
		&html<<td class="#(tCls)#" id="#(..%MakeId("item_"_n))#" bvwGroup="#(tGroup)#" bvwValue="#(tValue)#"><a href="#" onclick="zenPage.getComponent(#(..index)#).itemClicked(#(n)#); return false;" #(tTitle)#>#(tName)#</a></td>>
		Set tKey = $O(tInfo(tKey))

		If (tKey="")||(n#tItemsPerRow = 0) {
			&html<</tr>>
		}
	}
	&html<</table>>
}

/// Invoke user method to get list of options to display.
Method %GetButtonInfo(ByRef pInfo) As %Status
{
	Set $ZT="Trap"
	Set tSC = $$$OK
	
	#; if user callback is defined, use that
	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnGetButtonInfo '= "")) {
		Set tSeed = $$$ZENVAL(..seed)
		Set tSC = $zobjmethod(tHost,..OnGetButtonInfo,tSeed,.pInfo)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// User clicked on item.
ClientMethod itemClicked(idx) [ Language = javascript ]
{
	var item = this.findElement('item_' + idx);
	if (item) {
		if ('bvwItemDisabled' == item.className) return;
		if ('bvwItemDisabledAlways' == item.className) return;

		var value = item.getAttribute('bvwValue');
		var group = item.getAttribute('bvwGroup');
		if ('bvwItemSelected' == item.className) {
			// unselect: enable everything in this group
			// rebuild value
			this.value = '';
			var n = 1;
			while (true) {
				n++;
				var el = this.findElement('item_' + n);
				if (!el) break;
				if (((''==group)||(group == el.getAttribute('bvwGroup')))) {
					if ('bvwItemDisabledAlways' != el.className) {
						el.className = 'bvwItem';
					}
				}
				else if (el.className == 'bvwItemSelected') {
					this.value += el.getAttribute('bvwGroup') + ':' +  el.getAttribute('bvwValue') + ';';
				}
			}
		}
		else {
			if (value == -1) {
				// reset button
				this.resetItems();
			}
			else {
				// disable others in this group
				var n = 1;
				while (true) {
					n++;
					var el = this.findElement('item_' + n);
					if (!el) break;
					if ((n != idx)&&((''==group)||(group == el.getAttribute('bvwGroup')))) {
						if ('bvwItemDisabledAlways' != el.className) {
							el.className = 'bvwItemDisabled';
						}
					}
				}
				item.className = 'bvwItemSelected';
				if ('' == group) {
					this.value = ':' +  value + ';';
				}
				else {
					this.value += group + ':' +  value + ';';
				}
			}
		}
	}

	// highlight reset
	var rst = this.findElement('item_1');
	if (rst) {
		if ('' != this.value) {
			rst.className = 'bvwItemReset';
		}
		else {
			rst.className = 'bvwItemDisabled';
		}
	}

	// notify user
	zenInvokeCallbackMethod(this.onselect,this,'onselect','value',this.value);
}

/// Reset state of buttons. 
ClientMethod resetItems() [ Language = javascript ]
{
	var rst = this.findElement('item_1');
	if (rst) {
		rst.className = 'bvwItemDisabled';
	}

	var n = 1;
	while (true) {
		n++;
		var item = this.findElement('item_' + n);
		if (null == item) break;
		if ('bvwItemDisabledAlways' != item.className) {
			item.className = 'bvwItem';
		}
	}
	this.value = '';
}

}
