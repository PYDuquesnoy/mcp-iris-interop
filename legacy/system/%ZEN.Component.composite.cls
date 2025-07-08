/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for composite components.
/// A composite component provides a way to pre-assemble a group of
/// components that can be used as a single item.
Class %ZEN.Component.composite Extends group [ Deprecated, System = 3 ]
{

/// Internal property.<br>
/// This property is used to keep track of whether the contents
/// of the composite element have been created or not.
Property childrenCreated As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// Constructor for composite components.
/// If you override this method, be sure to invoke this code as well using
/// ##super.
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; add this to list of composite elements within the page object
	#; this makes sure that the children of this composite will get created
	If $IsObject($G(%page)) {
		Set %page.%CompositeList(+$this) = $this
	}
	Else {
		#; our page is not defined yet; register this composite in a temp area
		Set %compositeList(+$this) = $this
	}
	Quit ##super($G(initvalue))
}

/// Server-side method
/// Find a child of this composite using its non-qualified (short) id name.
Method %GetChildById(pID As %String) As %ZEN.Component.object
{
	Quit:'$IsObject(%page)||(pID="") ""

	Set cid = $S(..id="":"id"_..index,1:..id)
	Quit %page.%GetComponentById(cid_"."_pID)
}

/// Client-side method
/// Find a child of this composite using its non-qualified (short) id name.
ClientMethod getChildById(id) [ Language = javascript ]
{
	var cid = (''==this.id) ? 'id'+this.index : this.id;
	return zenPage.getComponentById(cid+'.'+id);
}

/// This internal method creates the contents of the composite component.
Method %CreateComposite() As %Status [ CodeMode = objectgenerator, GenerateAfter = %OnAfterCreateComposite ]
{
	If (%class.Name = "%ZEN.Component.composite") {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Do %code.WriteLine(" Set tSC = $$$OK")

	// set up composite context
	Do %code.WriteLine(" New %composite")
	Do %code.WriteLine(" Set %composite = $this")

	// figure out if this page should provide automatic localization
	// For library (system) classes, localization occurs for %ZEN domain
	// For non-library classes, check for non-%ZEN domain
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
	}

	#; find XDATA block named Contents
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Contents")

	If (tIndex '= "") {
		#; get XDATA as stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()

		If (tStream.Size > 0) {

			#; render the stream into composite object (with children)
			Set tReader = ##class(%XML.Reader).%New()
			Set tSC = tReader.OpenStream(tStream) If $$$ISERR(tSC) Quit tSC
			Do tReader.Correlate("composite","%ZEN.Component.composite")
			
			#; there should only be one composite object defined
			Do tReader.Next(.tComposite,.tSC)
			If $$$ISERR(tSC) Quit tSC
			If '$IsObject(tComposite) Quit $$$ERROR($$$GeneralError,"No <composite> element defined in Contents block.")
	
			#; have composite object generate code to recreate itself at run-time
			Do tComposite.%GenerateCode(%code,tLocalize,.tURIList,"children",,"composite")
		}
	}

	#; set property to indicate that children have been created
	Do %code.WriteLine(" Set ..childrenCreated = 1")

	#; check for callback
	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnAfterCreateComposite",$$$cMETHrunnable)) {
		Do %code.WriteLine(" Set tSC=..%OnAfterCreateComposite()")
	}

	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// For composites that define panes, this method creates the object tree
/// for a given pane and adds it to the given group element.<br>
/// Every pane name and pane block is assumed to start with "pane".
ClassMethod %GetPaneContents(pGroup As %ZEN.Component.group, pPaneName As %String, Output pPaneExists As %Boolean) As %Status [ CodeMode = objectgenerator ]
{
	#; note there is a similar method in the abstractPage class
	#; that should be in sync with this one

	Do %code.WriteLine(" Set pPaneExists = 0")
	If (%class.Abstract || (%class.Name = "%ZEN.Component.composite")) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Set tSC = $$$OK

	Do %code.WriteLine(" Goto Dispatch")

	#; figure out if this page should provide automatic localization
	#; For library (system) classes, localization occurs for %ZEN domain
	#; For non-library classes, check for non-%ZEN domain
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
	}

	Do %code.WriteLine(" ")

	#; find every XData that contains a "pane" document
	#; Skip items in tSkip
	Set tSkip("Contents") = ""
	Set tSkip("Style") = ""

	Set tPanes = 0
	Set xdc = %compiledclass.XDatas.Count()
	For n = 1:1:xdc {
		Set xdata = %compiledclass.XDatas.GetAt(n)
		If ('$D(tSkip(xdata.Name))) {
			Set tName = xdata.Name

			#; get XDATA as stream
			Set tStream = xdata.Data

			#; generate object tree for pane
			If (tStream.Size > 0) {
				#; make sure block starts with "<pane"	

				Set tHasPane = 0
				Do tStream.Rewind()
				While ('tStream.AtEnd) {
					Set tLine = tStream.ReadLine()
					If (tLine [ "<") {
						If ($Find(tLine,"<pane")) {
							Set tHasPane = 1
						}
						Quit
					}
				}

				If (tHasPane) {
					Set tPanes = tPanes + 1
					Do tStream.Rewind()
					#; render the stream into page object (with children)
					Set tReader = ##class(%XML.Reader).%New()
					Set tSC = tReader.OpenStream(tStream)
					If $$$ISERR(tSC) Quit
					Do tReader.Correlate("pane","%ZEN.Component.group")
	
					#; there should only be one pane defined
					Do tReader.Next(.tPane,.tSC)
					If $$$ISERR(tSC) Quit
					If '$IsObject(tPane) {
						Set tSC = $$$ERROR($$$GeneralError,"No <pane> element defined in pane block: "_xdata.Name)
						Quit 
					}

					#; keep track of pane name
					Set tPaneNames(tName) = ""

					#; local label for pane (append "lbl"
					Do %code.WriteLine("lbl"_tName)

					#; generate code for pane
					Do tPane.%GenerateCode(%code,tLocalize,.tURIList,"children",1,"pane",,"pGroup")
					Do %code.WriteLine(" Set pPaneExists = 1")
					Do %code.WriteLine(" Goto Done")
				}
			}
		}
	}

	#; dispatcher
	Do %code.WriteLine("Dispatch")
	If $D(tPaneNames) {
		Do %code.Write(" Goto $Case(pPaneName")
		Set tName = $O(tPaneNames(""))
		While (tName'="") {
			Do %code.Write(","""_tName_""":lbl"_tName)
			Set tName = $O(tPaneNames(tName))
		}

		Do %code.WriteLine(",:Done)")
	}
	Do %code.WriteLine("Done")
	Do %code.WriteLine(" Quit $$$OK")

	Quit tSC
}

/// This callback is called after the children of this composite
/// component have been created.
Method %OnAfterCreateComposite() As %Status [ Abstract ]
{
	Quit $$$OK
}

/// This callback is called when a form defined on this composite is submitted.
/// <var>pSubmit</var> is a <class>%ZEN.Submit</class> object
/// containing details of the form submit.<br>
/// Subclasses override this method.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	#; this is overridden by subclasses
	Quit $$$OK
}

/// This is a local override of this method.
/// It makes sure that <var>%composite</var> is set.
Method %ReallyAddChild(pComponent As %ZEN.Component.object, pSibling As %ZEN.Component.object = "", pBefore As %Boolean = 0) As %Status [ GenerateAfter = %AddChild, Internal ]
{
	Set tSC = $$$OK
	
	New %composite
	Set %composite = $this

	#; if pSibling is provided, make sure it is in the list
	Set tIndex = 0
	If (pSibling '= "") {
		Set tIndex = ..%GetChildIndex(pSibling)
		Quit:(tIndex<1) $$$ERROR($$$GeneralError,"pSibling is not a member of this group.")
	}

	#; add component to page
	If $IsObject($G(%page)) {
		Set tSC = %page.%AddComponent(pComponent)
		#; if we failed to get added to page, set page error and quit
		If $$$ISERR(tSC) {
			Set %zenPageError = tSC
			Quit tSC
		}
	}

	#; add component to our list of children
	If (tIndex < 1) {
		Do ..children.Insert(pComponent)
	}
	Else {
		Do ..children.InsertAt(pComponent,$S(pBefore:tIndex,1:tIndex+1))
	}
	Set pComponent.parent = $this
	Set x = ..%OnMutateChildren(1)
	Quit tSC
}

}
