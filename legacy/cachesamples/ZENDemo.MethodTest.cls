/// Zen Demo page for methods.
/// This page demonstrates the various ways in which Zen pages can invoke
/// methods.
Class ZENDemo.MethodTest Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

Parameter PAGENAME = "Method Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENDEMO";

/// This property is here to make sure client page includes
/// definition of customClass.
Property customClass As ZENTest.customClass;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#menuTitleBox {
	color: white;
	background: #000040;
	background-image: url(images/grad-blue-10x100.png);
	background-repeat: repeat-x;
}

#menu {
	height: 500px;
	width: 400px;
	overflow-y: auto;
	overflow-x: hidden;
	border: 1px solid black;
}


</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Method Test Page">
<demo:demoTitle id="title" title="Zen Method Test Page" category="Zen Test Suite" />
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Method Test" title="Method Test Page" href="ZENDemo.MethodTest.cls"/>
</locatorBar>
<hgroup>
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates the following features:">
<demo:bullet text="Calling client-side methods in response to client events" />
<demo:bullet text="Calling server-side methods in response to events" />
<demo:bullet text="Calling server-side methods asynchronously and synchronously" />
<demo:bullet text="Dynamically creating components on a page" />
</demo:sidebar>
</vgroup>

<spacer width="50" />
<vgroup valign="top">
<spacer height="25" />
 <menu	id="menu" layout="vertical" cellVAlign="top">
<titleBox	title="Methods" 
	id="menuTitleBox"
			subtitle="Demonstration of invoking methods"
 />

<menuItem   caption="Client Instance Method" 
					onclick="zenPage.clientMethod();"
					help="Invoke an instance method of the client page object."
					/>

<menuItem   caption="Client Method: Objects created" 
					onclick="zenPage.clientMethodCreate();"
					help="Invoke an instance method that creates a component dynamically."
					/>

<menuItem   caption="Client Assertion Test" 
					onclick="zenPage.assertionTest();"
					help="Test the zenASSERT function."
					/>

<menuItem   caption="isOfType Method Test" 
					id="typeMenu"
					onclick="zenPage.isOfTypeTest();"
					help="Test the isOfType method."
					/>

<menuItem   caption="Server Instance Method" 
					onclick="zenPage.serverInstanceMethod();"
					help="Invoke server instance method."
					/>

<menuItem   caption="Server Instance Method with Arguments" 
					onclick="zenPage.serverInstanceMethodArgs(zenPage.getComponentById('title'),1,'hello');"
					help="Invoke server instance method with args."
					/>

<menuItem   caption="Server Instance Method with Return Value" 
					onclick="alert(zenPage.serverInstanceMethodRet());"
					help="Invoke server instance method that returns a value."
					/>

<menuItem   caption="Server Class Method" 
					onclick="zenPage.serverClassMethod();"
					help="Invoke server class method."
					/>

<menuItem   caption="Server Class Method with Arguments" 
					onclick="zenPage.serverClassMethodArgs(zenPage.getComponentById('title'),1,'hello');"
					help="Invoke server class method."
					/>

<menuItem   caption="Server Instance Method: Objects Created" 
					onclick="zenPage.serverInstanceMethodCreate();"
					help="Invoke server instance method that adds objects to the object model."
					/>

<menuItem   caption="Server Instance Method: Objects Modified" 
					onclick="zenPage.serverInstanceMethodMod();"
					help="Invoke server instance method that modifies the object model."
					/>

<menuItem   caption="Server Instance Method: Objects Deleted" 
					onclick="zenPage.serverInstanceMethodDelete();"
					help="Invoke server instance method that deletes objects."
					/>

<menuItem   caption="Server Class Method With Error" 
					onclick="zenPage.serverClassMethodWithError();"
					help="Invoke server class method that has an error in it."
					/>

<menuItem   caption="Create Custom Object" 
					onclick="zenPage.createCustomObject();"
					help="Create an instance of a custom JS class."
					/>

<menuItem   caption="Synch and Asynch Methods" 
					onclick="zenPage.methodMixed();"
					help="Invoke multiple server methods both synchronously and asynchronously."
					/>

<menuItem   caption="Refresh HTML Element" 
					onclick="zenPage.refreshHTML();"
					help="Invoke server method to refresh html element."
					/>

<menuItem   caption="Run Background Task"
					id="menuBGTask" 
					onclick="zenPage.RunBackgroundTask();"
					help="Run a server method in the background."
					/>
<menuSeparator />
<html id="html">This is an HTML element.</html>
<menuSeparator />
<html id="taskStatus"> </html>
<menuSeparator />
<menuItem   caption="Modal Group: Calendar"
					onclick="zenPage.modalGroupCal();"
					help="Create a calendar modal group."
					/>
<menuItem   caption="Modal Group: MsgBox"
					onclick="zenPage.modalGroupMsg();"
					help="Create a Message Box modal group."
					/>
<menuItem   caption="Modal Group: Dynamic" 
					onclick="zenPage.modalGroupDynamic();"
					help="Create a dynamic modal group."
					/>

<menuItem   caption="Modal Group: Static"
					onclick="zenPage.modalGroupStatic();"
					help="Display a modal group using a static definition within the page definition."
					/>
<menuSeparator />
<hgroup>
<checkbox caption="Trace JavaScript Calls" 
		title="Show JavaScript calls invoked from the server."
		onclick="zenPage.toggleDebugMode(zenThis,'js');"/>

<checkbox caption="Trace Events" 
		title="Trace client-side events."
		onclick="zenPage.toggleDebugMode(zenThis,'events');"/>

<checkbox caption="Trace Serialization" 
		title="Show serial state for each request."
		onclick="zenPage.toggleDebugMode(zenThis,'serialize');"/>
</hgroup>
</menu>

</vgroup>
<spacer width="100"/>
<group id="group">
<html id="out"/>
</group>
</hgroup>
<modalGroup id="mgStatic" groupTitle="Popup">
<text id="mgText" label="Value:" />
<button id="mgButton" caption="OK" onclick="zenPage.mgBtnClick();"/>
</modalGroup>
</page>
}

/// Client method
ClientMethod clientMethod() [ Language = javascript ]
{
	alert('This is a client method.');
	return true;
}

/// A client-method that creates a component dynamically
ClientMethod clientMethodCreate() [ Language = javascript ]
{
	var group = this.getComponentById('group');

	// create a button
	var btn = this.createComponent('button');
	btn.setProperty('caption','button: ' + btn.index);
	
	// Add event handler-- note order of quotation marks
	btn.setProperty('onclick',"alert('This is a button!');");

	// add the button to the group
	group.addChild(btn);

	// refresh the contents of the group
	// true flag forces synchronous refresh.
	// (sync is not required, it is used here as a demonstration)
	group.refreshContents(true);
}

/// ASSERT test method
ClientMethod assertionTest() [ Language = javascript ]
{
	zenASSERT(false,"This is an ASSERT",arguments);
}

/// test the isOfType method
ClientMethod isOfTypeTest() [ Language = javascript ]
{
	var item = zenPage.getComponentById('typeMenu');
	zenASSERT(item,"Unable to find typeMenu component",arguments);
	
	alert(item._type + ' is object: ' + item.isOfType('object'));
	alert(item._type + ' is component: ' + item.isOfType('component'));
	alert(item._type + ' is menuItem: ' + item.isOfType('menuItem'));
	alert(item._type + ' is form: ' + item.isOfType('form'));
}

/// Server instance method
Method serverInstanceMethod() [ ZenMethod ]
{
	#; The server returns the following JavaScript statements to client
	#; for execution.
	&js<
	alert('Server instance method');
	alert('page: #(%page)#');
	alert('child 1: #(%page.children.GetAt(1))#');
	alert('title by id: #(%page.%GetComponentById("title"))#');
	alert('menu by id: #(%page.%GetComponentById("menu"))#');
	>
}

/// Server instance method
Method serverInstanceMethodArgs(p1 As %ZEN.Component.object, p2 As %Integer, p3 As %String) [ ZenMethod ]
{
	#; The server returns the following JavaScript statements to client
	#; for execution.
	&js<
	alert('Server instance method (args)');
	alert('page: #(%page.nextIndex)#');
	alert('arg1: #(p1)#');
	alert('arg2: #(p2)#');
	alert('arg3: #(p3)#');
	alert('child 1: #(%page.children.GetAt(1))#');
	alert('title by id: #(%page.%GetComponentById("title"))#');
	alert('menu by id: #(%page.%GetComponentById("menu"))#');
	>
}

/// Server instance method
Method serverInstanceMethodRet() As %String [ ZenMethod ]
{
	&js<alert('Server instance method');>
	Quit "This value is from the server: " _ $ZDT($H,3)
}

/// Server instance method with server modifications
Method serverInstanceMethodMod() [ ZenMethod ]
{
	#; update
	Set html = %page.%GetComponentById("out")
	Set html.content = "This is an update from the server: " _ $ZH

	Set btn = %page.%GetComponentById("NewBtn1")
	If $IsObject(btn) {
		Set btn.caption = "Hey " _ ($ZH\1)
		Set btn.onclick = "alert('Don\'t tread on me!');"
	}
	Else {
		&js<alert('Unable to find button. Call Create first!');>	
	}
}

/// Server instance method with server modifications
Method serverInstanceMethodCreate() [ ZenMethod ]
{
	#; create
	Set group = %page.%GetComponentById("group")
	If '$IsObject(group) {
		&js<alert('Unable to find group.');>
		Quit
	}
	Set count = group.children.Count()

	Set cal = ##class(%ZEN.Component.calendar).%New()
	Set cal.id = "NewCal"_count
	Do group.%AddChild(cal)

	Set btn = ##class(%ZEN.Component.button).%New()
	Set btn.id = "NewBtn"_count
	Set btn.caption = "New Button"
	Do group.%AddChild(btn)

	Set btn = ##class(%ZEN.Component.text).%New()
	Set btn.label = "Hey"
	Do group.%AddChild(btn)
}

/// Server instance method with server modifications
Method serverInstanceMethodDelete() [ ZenMethod ]
{
	#; if there is a calendar, delete it!
	Set cal = %page.%GetComponentById("NewCal1")
	If $IsObject(cal) {
		#; remove object from its parent
		Do cal.parent.%RemoveChild(cal)
	}
	Else {
		#; this logic will only work if create is called once!
		&js<alert('No calendar component found to delete.');>
	}
}

/// Server class method
ClassMethod serverClassMethod() [ ZenMethod ]
{
	&js<alert('Server class method');>
	&js<alert('page: #($G(%page,"missing"))# (should be missing!)');>
}

/// Server class method with an error to demonstrate
/// error handling.
ClassMethod serverClassMethodWithError() [ ZenMethod ]
{
	Set x = 1 / 0
}

/// Server instance method
ClassMethod serverClassMethodArgs(p1 As %ZEN.Component.object, p2 As %Integer, p3 As %String) [ ZenMethod ]
{
	#; The server returns the following JavaScript statements to client
	#; for execution.
	&js<
	alert('Server class method (args)');
	alert('page: #(%page.nextIndex)#');
	alert('application: #(%application)#');
	alert('arg1: #(p1)#');
	alert('arg2: #(p2)#');
	alert('arg3: #(p3)#');
	alert('child 1: #(%page.children.GetAt(1))#');
	alert('title by id: #(%page.%GetComponentById("title"))#');
	alert('menu by id: #(%page.%GetComponentById("menu"))#');
	>
}

/// Create an instance of the customClass class.
ClientMethod createCustomObject() [ Language = javascript ]
{
	try {
		var custom = zenPage.createComponentNS('http://www.intersystems.com/zentest','customClass');
		custom.test();
	}
	catch(ex) {
		alert("ERROR: " + ex);
	}
}

/// User click on debug mode checkbox.
ClientMethod toggleDebugMode(cb, name) [ Language = javascript ]
{
	var flag = cb.getValue()==1 ? true : false;
	zenPage.setTraceOption(name,flag);
}

/// Refresh contents of html element.
ClientMethod refreshHTML() [ Language = javascript ]
{
	var html = zenPage.getComponentById('html');
	zenASSERT(html,"Unable to find html element",arguments);

	// call server to refresh html
	// NOTE: this is for testing; an application would simply
	// call html.setProperty('content','...');
	html.content = "This text was sent to the server and back!"
	html.refreshContents();
}

/// display a modalGroup calendar
ClientMethod modalGroupCal() [ Language = javascript ]
{
	// create a modal group
	var group = zenPage.createComponent('modalGroup');
	group.setProperty('onaction','zenPage.calendarAction(group);');
	group.show('Select a date:','calendar','2005/12/12');
}

/// User action handler for calendar flaotingGroup.
ClientMethod calendarAction(group) [ Language = javascript ]
{
	alert("You selected: " + group.getValue());
}

/// display a modalGroup msgBox
ClientMethod modalGroupMsg() [ Language = javascript ]
{
	// create a modal group
	var group = this.createComponent('modalGroup');
	group.show('Message','msgBox','This is a message!<br>It can contain <span style="color: red; font-weight: bold;">HTML</span>!');
}

/// display a dynamic modalGroup
ClientMethod modalGroupDynamic() [ Language = javascript ]
{
	// create a modal group
	var group = this.createComponent('modalGroup');

	// add components dynamically
	var cal = this.createComponent('calendar');
	group.addChild(cal);
	cal.setProperty('onchange','zenPage.endModal();');

	var btn = this.createComponent('button');
	group.addChild(btn);
	btn.setProperty('caption','My Button');

	// Show the group in "dynamic" mode.
	group.show('Dynamic','dynamic');
}

/// Display the static modalGroup.
ClientMethod modalGroupStatic() [ Language = javascript ]
{
	// Find the group and show it
	var mg = this.getComponentById('mgStatic');
	mg.show();
}

/// OK button pressed within static modalGroup.
ClientMethod mgBtnClick() [ Language = javascript ]
{
	var ctrl = zenPage.getComponentById('mgText');

	// write user value into HTML component
	var html = zenPage.getComponentById('html');
	html.setProperty('content','User entered: ' + ctrl.getValue());
	
	// hide the modal group
	zenPage.endModal();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	//alert('This method is called when the page is loaded.');
}

/// Run a method in the background.
ClassMethod RunBackgroundTask() [ ZenMethod ]
{
	#; Run method BackgroundTask in a background job.
	Do ..%RunBackgroundMethod("BackgroundTask")
}

/// This is an example of a task that is run in the background.
ClassMethod BackgroundTask()
{
	Do ..%SetBackgroundMethodStatus("Started",0)

	#; simulated background task
	For n = 1:1:10 {
		Do ..%SetBackgroundMethodStatus("Running",n*10)
		Hang 1
	}
	Do ..%EndBackgroundMethod()
}

/// This server-side callback method is called whenever the client
/// calls to monitor the current background task.
/// Typically a subclass uses this to send back JavaScript to update
/// a progress bar.
ClassMethod %OnMonitorBackgroundTask(pTaskID As %String, pStatus As %String, pPercentComplete As %Float)
{
	#; write status into HTML component
	Set pMsg = pStatus _ ": " _ +pPercentComplete _ "%"
	&js<
	var html = zenPage.getComponentById('taskStatus');
	html.setProperty('content','#(pMsg)#');
	>
}

/// This server-side callback method is called whenever the client
/// calls to monitor the current background task and the task is complete.
/// Typically a subclass uses this to send back JavaScript to update
/// the page.
ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
	#; Clear HTML component
	&js<
	var html = zenPage.getComponentById('taskStatus');
	html.setProperty('content','');
	>
}

/// Client-side callback to update task status.<br>
/// <var>taskInfo</var> is an associative array (object) containing
/// task status indexed by taskid.
ClientMethod ontaskHandler(taskInfo) [ Language = javascript ]
{
	var html = zenPage.getComponentById('taskStatus');
	if (null == taskInfo) {
		// no tasks
		html.setProperty('content','');
	}
	else {
		// get task info
		var msg = '';
		for (task in taskInfo) {
			msg += 'Task: ' + task + ': ' + taskInfo[task] + '<br>';
		}
		html.setProperty('content',msg);
	}
}

/// Test of intermixed Synch and Asynch methods
ClientMethod methodMixed() [ Language = javascript ]
{
	this.ServerAsynch(1);
	this.ServerAsynch(2);
	alert(this.ServerSynch(1));
	this.ServerAsynch(3);
	this.ServerAsynch(4);
}

/// test
Method ServerAsynch(x As %Integer) [ ZenMethod ]
{
	&js<alert('This is an asynchronous method: #(x)#');>
}

/// test
Method ServerSynch(x As %Integer) As %String [ ZenMethod ]
{
	Quit "This is a synchronous method: " _ x
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

}

