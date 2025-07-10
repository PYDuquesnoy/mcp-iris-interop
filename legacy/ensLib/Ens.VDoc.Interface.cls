/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %systemInclude)

/// Common interface used as a base class for all Virtual Document types
Class Ens.VDoc.Interface [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Compact descriptive name for this subclass of document
Parameter DOCCLASSNAME;

/// Full descriptive name for this subclass of document
Parameter DOCCLASSFULLNAME;

/// Reference to associated Schema Id
Property DocType As %String(MAXLEN = 128);

/// the category portion of the DocType
Property DocTypeCategory As %String [ Transient ];

/// Stored raw document type name ; the secondary type name portion of the DocType
Property DocTypeName As %String(MAXLEN = 50) [ ReadOnly, Transient ];

/// Raw type name of document as declared in document content
Property Name As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {Name}="subclass responsibility" }, SqlComputed, Transient ];

/// Raw type version of document if declared in document content
Property TypeVersion As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {TypeVersion}="" }, SqlComputed, Transient ];

/// Unique document identification string found in document content
Property Identifier As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {Identifier}="subclass responsibility" }, SqlComputed, Transient ];

/// The timestamp of when this Document object was first instantiated
Property TimeCreated As Ens.DataType.UTC [ InitialExpression = {$$$timeUTC} ];

/// Source of document (e.g. filename)
Property Source As %String(MAXLEN = 250, TRUNCATE = 1);

/// We clear this property to prevent saving or modifying of already-saved document objects
Property IsMutable As %Boolean [ InitialExpression = 1 ];

/* Note: if no Index OriginalDocId is declared on this property in your subclass, the Trace diagram will not display corresponding messages */
/// If this document is a response to another document of the same type, this property contains the Id of the original document
Property OriginalDocId As %String(COLLATION = "EXACT", MAXLEN = "");

/// An array of strings for storing user defined attribute values. Value key names beginning with % are reserved for InterSystems IRIS use.
Property UserValues As array Of %String(MAXLEN = "");

/// If provided, this parameter defines a comma-delimited, default list of
/// document types for a document class.<br>
/// This provides an alternate mechanism to overriding the
/// EnumerateDocTypes query
Parameter DOCTYPES As String;

/// Subclasses should override this if the version can be gotten from the document content
Method TypeVersionGet() As %String [ CodeMode = expression ]
{
""
}

Method IsMutableSet(pMutable As %Boolean) As %Status
{
	Quit:'..IsMutable&&pMutable $$$ERROR($$$EnsErrGeneral,"Cannot make immutable Object mutable again")
	Set i%IsMutable=''pMutable
	Quit $$$OK
}

Method PokeDocType(pDocType As %String) As %Status
{
	Set i%DocType=pDocType
	Quit $$$OK
}

/// Returns array of properties that make up the <i>contents</i>
/// of this object.<br>
/// This method in implemented within the document class.<br>
/// The content array is in the form:<br>
/// 	pContents(n,"type")="%String"<br>
/// 	pContents(n,"name")="Field"<br>
/// 	pContents(n,"alias")=alias code<br>
/// If pContents(n) is non-zero then the property is a composite type with<br>
/// sub-properties.  The sub-properties are indexed with a similar structure under<br>
///     pContents(n,m) where m is the index of the subtype property.<br>
ClassMethod GetContentArray(Output pContents, pMode As %String, pDocType As %String, pLevel As %Integer, pIncludeBase As %Boolean = 0) As %Status [ Abstract ]
{
	Quit $$$ERROR($$$EnsErrGeneral,("Subclass Responsibility"))
}

/// Returns a list of available DocTypes for the document class. <br/>
/// The DocType is returned as the first column in the result set. <br/>
/// The <var>Category</var> parameter can be used to restrict the list. <br/>
/// If <var>Category</var> is: <br/>
///  0 - return only DocTypes in standard categories <br/>
///  + - return only DocTypes in user-defined categories <br/>
///  empty - return DocTypes from all categories <br/>
///  a category name - return only DocTypes in the named category <br/>
///  a partial name suffixed with '%' - return only DocTypes in categories matching the partial category name <br/>
///  other - return nothing <br/>
/// If <var>IncludeBase</var> is: <br/>
///  0 - return only DocTypes defined in the current schema category itself <br/>
///  1 - return all DocTypes in the current schema category's base category in addition to those defined in the current category itself <br/>
/// This query can be overridden in a subclass.<br/>
/// This default implementation returns the type list specified by the
/// DOCTYPES parameter (or a dummy result containing 1 empty row).
Query EnumerateDocTypes(Category As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "Type:%String")
{
}

ClassMethod EnumerateDocTypesExecute(ByRef qHandle As %Binary, Category As %String, IncludeBase As %Boolean) As %Status
{
	Set qHandle=0
	Quit $$$OK
}

ClassMethod EnumerateDocTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateDocTypesExecute ]
{
	Set i=$I(qHandle)
	If qHandle>$L(..#DOCTYPES,",") Set Row="",AtEnd=1 Quit $$$OK
	Set Row=$LB($P(..#DOCTYPES,",",i))
	Quit $$$OK
}

ClassMethod EnumerateDocTypesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateDocTypesExecute ]
{
	Kill qHandle
	Quit $$$OK
}

/// Returns a list of document type schema categories for the document class.<br/>
/// The <var>Standard</var> parameter can be used to restrict the list.<br/>
/// If <var>Standard</var> is: <br/>
///  0 - return only standard categories <br/>
///  + - return only user-defined categories <br/>
///  empty - return all categories <br/>
///  a partial category name - return only categories starting with the given category name part<br/>
///  other - return nothing <br/>
/// This query can be overridden in a subclass.<br/>
/// This default implementation returns no rows.
Query EnumerateTypeCategories(Standard As %String = "") As %Query(CONTAINID = 0, ROWSPEC = "Category:%String,Description:%String,IsStandard:%Boolean,Base:%String")
{
}

ClassMethod EnumerateTypeCategoriesExecute(ByRef qHandle As %Binary, Standard As %String = "") As %Status
{
	Set qHandle=0
	Quit $$$OK
}

ClassMethod EnumerateTypeCategoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateTypeCategoriesExecute ]
{
	Set Row="",AtEnd=1 Quit $$$OK
}

ClassMethod EnumerateTypeCategoriesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateTypeCategoriesExecute ]
{
	Kill qHandle
	Quit $$$OK
}

/// Returns a list of VDoc classes that extend Ens.VDoc.Interface.<br/>
/// The <var>Persistent</var> and <var>Abstract</var> parameters can be used to restrict the list.<br/>
/// If <var>Persistent</var> is: <br/>
///  0 - return persistent and non-persistent subclasses <br/>
///  1 - return only persistent subclasses <br/>
/// If <var>Abstract</var> is: <br/>
///  0 - return only non-abstract subclasses <br/>
///  1 - return both abstract and non-abstract subclasses <br/>
/// Note that the default value for Persistent is 1.<br/>
Query EnumerateVDocs(Persistent As %Boolean = 1, Abstract As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "Name:%String,Persistent:%Boolean,Abstract:%Boolean")
{
}

ClassMethod EnumerateVDocsExecute(ByRef qHandle As %Binary, Persistent As %Boolean = 1, Abstract As %Boolean = 0) As %Status
{
	Kill qHandle
	Set qHandle=""
	Set tRS=##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute("Ens.VDoc.Interface")
	Quit:$$$ISERR(tSC) tSC
	While tRS.Next() {
		Set tName=tRS.Get("Name")
		Set tDef = ##class(%Dictionary.CompiledClass).%OpenId(tName)
		If tDef.Abstract Set tIsPersistent = 0, tAbstract = 1
		Else  Set tIsPersistent=$zobjclassmethod(tName,"%Extends","%Persistent"), tAbstract = 0
		; Comparisons to ensure we include non-persistent classes if Persistent=0, and Abstract classes if Abstract=1
		If (tIsPersistent >= Persistent) && (tAbstract <= Abstract) Set qHandle($i(qHandle))=$lb(tName,tIsPersistent,tAbstract)
	}
	Set qHandle=""
	Quit $$$OK
}

ClassMethod EnumerateVDocsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateVDocsExecute ]
{
	Set qHandle=$o(qHandle($g(qHandle)))
	If qHandle="" Set AtEnd=1 Quit $$$OK
	Set Row = $g(qHandle(qHandle))
	Quit $$$OK
}

ClassMethod EnumerateVDocsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateVDocsExecute ]
{
	Kill qHandle
	Quit $$$OK
}

/// Return the value of the designated virtual property.<br>
/// <var>pPropertyPath</var> contains a text expression representing the address within the document of the value of interest.<br>
/// <var>pFormat</var> contains additional context that may be used to influence the form of the result value<br>
/// If no value can be found matching <var>pPropertyPath</var> in the current document an empty string is returned and output argument <var>pStatus</var> returns status information explaining the failure<br>
/// <var>pTreatEmptyFieldAsNull</var> indicates whether repeating fields which have a separator but are empty should be considered to have a count of 1 (if false) or 0 (if true)
/// This is implemented by the document subclass.
Method GetValueAt(pPropertyPath As %String, pFormat As %String, Output pStatus As %Status, pTreatEmptyFieldAsNull As %Boolean = 0) As %String [ Abstract ]
{
	Set pStatus=$$$ERROR($$$EnsErrGeneral,("Subclass Responsibility"))
	Quit ""
}

/// Set the value of the designated virtual property.<br>
/// <var>pValue</var> contains the value to set.<br>
/// <var>pPropertyPath</var> contains a text expression representing the address within the document of the value of interest.<br>
/// <var>pKey</var> contains an optional key value or a set of comma-separated key values to be used as array indices where empty array index placeholders are present in <var>pPropertyPath</var>.<br>
/// <var>pAction</var> contains an action code: "set", "clear", "append", etc. <br>
Method SetValueAt(pValue As %String, pPropertyPath As %String, pAction As %String = "set", pKey As %String = "") As %Status [ Abstract ]
{
	Quit $$$ERROR($$$EnsErrGeneral,("Subclass Responsibility"))
}

/// Copy a whole set of values from source to target when iteration is implied between 2 VDocs
/// <var>pSourcePath</var> contains the property path to the source set<br>
/// <var>pTargetPath</var> contains the property path to the target set<br>
/// <var>pAction</var> contains an action code: "set", etc..<br>
/// <var>pKey</var> contains an optional key value or a set of comma-separated key values to be used as array indices where empty array index placeholders are present in <var>pPropertyPath</var>.<br>
Method CopyValues(pSource As Ens.VDoc.Interface, pSourcePath As %String, pTargetPath As %String, pAction As %String, pKey As %String) As %Status
{
	Quit $$$ERROR($$$EnsErrGeneral,("Subclass Responsibility"))
}

/// Return the next 
Method GetNextIndex(pPath As %String, pIndex As %String = "", ByRef pStatus As %Status = {$$$OK}) As %String
{
	Set pStatus=$$$ERROR($$$EnsErrGeneral,("Subclass Responsibility"))
	Quit ""
}

/// This method computes the Alias string for a property name, given the property's node in the Content Array.
ClassMethod GetAlias(pContentArrayName As %String, pArrayPos As %String) As %String
{
	Quit ""
}

Method Validate(pValidationSpec As %String) As %Status [ Abstract ]
{
	Quit $$$ERROR($$$EnsErrGeneral,("Subclass Responsibility"))
}

/// Override standard DrawHTMLForm method
/// Draw an HTML form for this form object.<BR>
/// <var>pObj</var> is an instance of the form object that
/// provides the initial values for the form.<BR>
/// <var>pActionURL</var> is the URL to submit this form to.<BR>
/// <var>pButtons</var> is an array of submit buttons to display for the form. If 
/// not provided, the default <I>Save</I> and <I>Cancel</I> buttons are shown.
/// <var>pButtons</var> is an integer-subscripted array of <class>FormButton</class> objects.
ClassMethod DrawHTMLForm(pObj As %RegisteredObject, ByRef pID As %String, pActionURL As %String = "", ByRef pButtons As %CSP.Util.FormButton, pTarget As %String = "") As %Status
{
	Set tSC = $$$OK
	
	// standard form header
	&html<<form action="#(pActionURL)#" method="POST" name="theForm" target="#(pTarget)#">
		<input type="hidden" name="$CLASS" value="#($classname())#">
		<input type="hidden" name="$FRAME" value="#(pTarget)#">>

	Set id = $O(pID(""))
	While (id '= "") {
		&html<<input type="hidden" name="$ID#(id)#" value="#(($ZCVT(pID(id),"O","HTML")))#">>
		Set id = $O(pID(id))
	}
	
	// loop over document contents
	Set tSC = ..DrawHTMLContentsForm(pObj,.pID)

	// standard form buttons
	&html<<br><table class="AutoForm">
		<tr><td class="AutoFormLabel">&nbsp;</td>
			<td class="AutoFormButton">>
	Do ..DrawFormButtons(.pButtons)
	&html<</td></tr></table>
		</form>>

	Quit tSC
}

/// Specialized HTML generation method to display the body of a form
/// to display/edit a document-style message.
ClassMethod DrawHTMLContentsForm(pObj As %RegisteredObject, ByRef pID As %String) As %Status
{
	// add code to display HTML here...
	Quit $$$OK
}

ClassMethod DrawFormButtons(ByRef pButtons As %CSP.Util.FormButton) As %Status
{
	Quit $$$OK
}

/// Returns an array of links to manager pages for this type of VDoc; item 0 is the family description
/// The output array is subscripted first by item number, and below that by "name","page" and "desc"
ClassMethod GetManagerLinks(Output pColumns) As %Boolean
{
	Quit 0 ; Subclass responsibility
}

/// Returns an array of links to manager pages for this type of VDoc; item 0 is the family description
/// The output array is subscripted first by item number, and below that by "name","page" and "desc"
ClassMethod GetNewManagerLinks(Output pColumns) As %Boolean
{
	Quit 0 ; Subclass responsibility
}

/// Return a suitable argument to pass to %New() to create a test object for the test described by the arguments.
/// Example: getTestNewArg("DTL","existing","Test.DTL.DTLExisting") as passed from the DTL test wizard.
ClassMethod getTestNewArg(pTestContext As %String, pTestOption As %String, pTestName As %String) As %String
{
	#; $List(3) is 'Source' for VDoc %OnNew() non-Object argument
	Quit $LB(,,"test "_pTestContext_$C(13,10)_pTestOption_$C(13,10)_pTestName)
}

}
