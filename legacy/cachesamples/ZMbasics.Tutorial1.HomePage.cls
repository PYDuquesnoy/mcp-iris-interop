/// Sample Zen Mojo tutorial page, with one &lt;mojo:documentView>, which is a general container. 
/// <p>To specify the appearance of the &lt;mojo:documentView>, this sample uses 
/// the ongetlayout callback attribute. 
/// This returns a JSON string that describes the contents of the component,
/// in terms of a set of layout objects defined by the plugins used in this &;lt;documentView.
/// This callback is defined as follows:
/// <p>ongetlayout="return zenPage.getContent('mainViewLayout',key,criteria);"
/// <p>The method <method>getContent</method> is a built-in page method that you can use to retrieve
/// a content object, in this case a layout graph. This method:
/// <ol>
/// <li>Calls the onGetContent() method of the associated template class. If that method
/// returns content for the given key, ZM uses that content.</li>
/// <li>Otherwise, ZM calls the %OnGetJSONContent() method of the same template class (not demonstrated here).
/// </li> 
/// </ol>
/// <p>Within &lt;mojo:documentView>, the developerMode="true" option adds a toggle button that you can 
/// use to see the JSON data and layout strings available to the component.
/// <p>This ZM page class uses the template class <class>ZMbasics.Tutorial1.Template</class>.
/// <p>Next tutorial in the series: <class>ZMbasics.Tutorial2.HomePage</class>.
Class ZMbasics.Tutorial1.HomePage Extends %ZEN.Mojo.basePage
{

/// Name of the default template class that this page uses.
Parameter TEMPLATECLASS = "ZMbasics.Tutorial1.Template";

/// Localization domain; best practice is to always specify this
Parameter DOMAIN = "Zen Mojo Demo";

/// This XML block defines the contents of the pageContents pane.
XData pageContents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
xmlns:mojo="http://www.intersystems.com/zen/mojo" layout="none">
<mojo:documentView id="mainView" 
developerMode="true"
ongetlayout  ="return zenPage.getContent('mainViewLayout',key,criteria);">
<mojo:mojoDefaultPageManager>
<mojo:HTML5Helper/>
</mojo:mojoDefaultPageManager>
</mojo:documentView>

</pane>
}

/// Implementation for this page. This method adjusts the size of the documentView components 
/// within the content area based on the current width and height of the screen. 
/// In this case there is only one documentView.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
    // This method should have an if{} block for each component. 
    
    var mainView = zen('mainView');
    if (mainView) {
        mainView.setSize(width, height);
        var mainDiv = mainView.getEnclosingDiv();
        mainDiv.style.top =  '0px';
        mainDiv.style.left = '0px';
    }
}

/// Method override for this page. This method defines the application name,
/// which controls the name shown on the browser tab.
Method %GetAppSettings(pPage As %String = "", pMode As %String = "") As %ZEN.proxyObject
{
    //get most settings from the superclass
    set tInfo = ##super()

    // then override the nameApplication setting -- this affects the browser tab name
    set tInfo.nameApplication = "ZM Tutorial 1"

    quit tInfo
}

XData Style
{
<style type="text/css">

* {
  	font-family: arial;
	margin: 0;
	padding: 0;
}

body {
	position: relative;
	font-family: arial;
	font-size: 12pt;
	background: #F8F8F1;
	overflow: auto;
}

#zMojoHeaderPane {
}

#zMojoForegroundGroup {
	position: relative;
	top: 0px;
	left: 0px;
	border: 1px;
	overflow: hidden;
	padding: 0px;
}

#zMojoFooterGroup {
}


</style>
}

/// This implementation erases the default contents of the header area.
Method ZMojoDrawQuickLinks(pSeed As %String) As %Status [ ZenMethod ]
{
	Quit $$$OK
}

}

