/// Created using the page template: Default
Class ZENMobile.ZenDoodle Extends %ZEN.Mobile.mobilePage
{

/// Turn off scroll and zoom defaults 
Parameter DEFAULTPREVENTGESTURES = 0;

/// Application this page belongs to.
Parameter APPLICATION = "ZENMobile.TestApplication";

Parameter PAGENAME = "Zen Doodle";

Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.scribbleArea {
	width:100%;
	height:100%;
	overflow:hidden;
	border:1px solid gray;
	background:#f5f5f5;
	color:#000044;
}

.button {
	font:bold 24px Arial;
	width:100%;
}

#TopBar {
	position:absolute;
	top:0px;
	left:0px;
	right:0px;
	height:40px;
}

#WorkArea {
	position:absolute;
	top:40px;
	left:0px;
	right:0px;
	bottom:40px;
}

#BottomBar {
	position:absolute;
	left:0px;
	right:0px;
	bottom:0px;
	height:40px;
}

</style>
}

Property v As %ZEN.Datatype.string;

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">
<group layout="none" id="TopBar" >
<text label="ID:" id="objId" value="7" size="4" onchange="zenPage.findObject();" 
labelStyle="position:absolute;top:0px;left:0px;font:bold 24px Arial;"
controlStyle="position:absolute;top:0px;left:25%;width:20%;font:bold 24px Arial;"
/>
<button caption="Load" onclick="zenPage.findObject();" enclosingStyle="position:absolute;top:0px;left:50%;width:50%;"/>
</group>

<group id="WorkArea" layout="none" >
<dataController id="scribbleData" modelClass="ZENMobile.ScribbleModel" modelId="1" />
<form controllerId="scribbleData" id="aForm" layout="none">
<text id="name" label="Title:" dataBinding="Name" value="untitled"
labelStyle="position:absolute;top:0px;left:0px;font:bold 24px Arial;"
controlStyle="position:absolute;top:0px;left:25%;width:70%;font:bold 24px Arial;"
/>
<scribbleArea id="masterpiece" culling="0" nib="2" smoothness="1" dataBinding="Art" enclosingStyle="position:absolute;top:40px;left:0px;right:0px;bottom:0px;"/>
</form>
</group>

<group id="BottomBar" layout="none">
<button caption="New" onclick="zenPage.newRecord();" enclosingStyle="position:absolute;top:0px;left:0%;width:33%;"/>
<button caption="Clear" onclick="zenPage.clearCanvas();" enclosingStyle="position:absolute;top:0px;left:33%;width:33%;"/>
<button caption="Save" onclick="zenPage.save();" enclosingStyle="position:absolute;top:0px;left:66%;width:33%;"/>
</group>

</page>
}

/// Find and load the object whose id is in the objid text box.
ClientMethod findObject() [ Language = javascript ]
{
	var ctrl = zenPage.getComponentById('objId');
	var id = ctrl.getValue();
	var controller = zenPage.getComponentById('scribbleData');
	controller.setModelId(id);
}

/* MVC STUFF */
ClientMethod newRecord() [ Language = javascript ]
{
	var controller = zen('scribbleData');
	controller.createNewObject();
}

ClientMethod save() [ Language = javascript ]
{
	var form = zen('aForm');
	form.save();
}

ClientMethod updateRecord() [ Language = javascript ]
{
	var controller = zen('scribbleData');
	controller.update();
}

/* END OF MVC STUFF */
ClientMethod clearCanvas() [ Language = javascript ]
{
	var s = this.getComponentById("masterpiece");
	s.clear();
}

ClientMethod export() [ Language = javascript ]
{
	var s = this.getComponentById("masterpiece");
	var b = s.Export("c:\\zout.dat","Just another test");
	alert(b);
}

ClientMethod getData() [ Language = javascript ]
{
	var s = this.getComponentById("masterpiece");
	var path = s.getValue();
//	var d = document.getElementById("dumpspace");
//	d.innerHTML = path;
}

ClientMethod autoRefresh() [ Language = javascript ]
{
	this.findObject();
	this.max--;
	if (this.max>0)setTimeout("zenPage.autoRefresh();",1000);
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	return;
	
	if (navigator.userAgent.indexOf("Mobile")>0) return;

	var ctrl = zenPage.getComponentById('objId');
	var id = ctrl.getValue();
	this.max = 600;
	if (id=="7") this.autoRefresh();
}

ClassMethod makeCRCTable() As %Library.ArrayOfDataTypes [ ZenMethod ]
{
	Set a = ##class(%Library.ArrayOfDataTypes).%New()
	For n=0:1:256 {
		Set c = n
		For k=0:1:8 {
			Set odd = $ZBOOLEAN(c,1,1)
			If (odd) {
				// c = -306674912 ^ ((c >> 1) & 0x7fffffff);
			}
			Else {
      			// c = (c >> 1) & 0x7fffffff;
			}
		}	
		Do a.SetAt(c,n)			
	}
	Quit a
}

}

