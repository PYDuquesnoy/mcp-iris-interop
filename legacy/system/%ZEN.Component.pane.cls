/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The pane component is a specialized type of group that is useful for
/// defining a common layout (or template) in a base class and providing content within a subclass.
/// The <class>pane</class> component is used in two different ways:<br>
/// <ol>
/// <li>Within a template super class, <class>pane</class> components are used as
/// placeholders in which a subclass will inject components. Each pane is given a
/// unique name using its <property>paneName</property> property.</li>
/// <li>Each subclass of the template class defines XData blocks whose names
/// correspond to the name of the <class>pane</class> components. Each of these
/// XData blocks contains a set of components within an enclosing <class>pane</class>
/// element. When the subclass page is displayed, the contents of each <class>pane</class>
/// will be supplied via the various pane XData definitions.</li>
/// </ol>
/// Note that the default layout of a <class>pane</class> is "vertical".
Class %ZEN.Component.pane Extends group [ Deprecated, System = 3 ]
{

Parameter DEFAULTLAYOUT = "vertical";

/// Name of the pane definition that will provide the contents of 
/// this pane. This is the name of an XData block containing the
/// contents definition for the pane.
Property paneName As %ZEN.Datatype.string;

/// This callback is invoked when this pane element is added
/// to the set of page components.<br>
/// It asks the page to provide the contents of a pane. 
Method %OnAddToPageBefore() As %Status
{
	Set tSC = $$$OK
	Set tExists = 0

	Do {
		#; first check if page defines the pane
		Set tSC = %page.%GetPaneContents($this,..paneName,.tExists)
		If $$$ISERR(tSC) Quit
	
		#; if not found in page, check if we are within a composite
		If ('tExists&&$IsObject($G(%composite))) {
			Set tSC = %composite.%GetPaneContents($this,..paneName,.tExists)
			If $$$ISERR(tSC) Quit
		}
	} While(0)

	Quit tSC
}

}
