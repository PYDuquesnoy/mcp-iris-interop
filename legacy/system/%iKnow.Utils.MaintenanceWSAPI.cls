/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Utils.MaintenanceAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Utils.MaintenanceAPI</class> for more information.</p>
Class %iKnow.Utils.MaintenanceWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
{

///  Adds an existing entity (by ID) to a SkipList.
/// For cross-domain SkipLists, use <method>AddStringToSkipList</method>
ClassMethod AddEntityToSkipList(domainId As %Integer, skipListId As %Integer, entUniId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).AddEntityToSkipList(domainId, skipListId, entUniId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  Adds a string to a SkipList, adding it as an entity if it didn't exist in the domain before.
ClassMethod AddStringToSkipList(domainId As %Integer, skipListId As %Integer, string As %String) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).AddStringToSkipList(domainId, skipListId, string)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  <p>Adds a single entry to a User Dictionary at <var>position</var>. If <var>position</var> <= 0 (default),
///  it is added at the bottom of the list, otherwise at the requested position, shifting
///  existing entries down if it was already taken.</p>
///  <p><b>Deprecated</b>: please use AddEntry() in <class>%iKnow.UserDictionary</class></p>
ClassMethod AddUserDictionaryEntry(userDictId As %Integer, rewriteFrom As %String, rewriteTo As %String, position As %Integer = 0) As %Boolean [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set position = $s($g(position)="":0, 1:position)

	set sc = ##class(%iKnow.Utils.MaintenanceAPI).AddUserDictionaryEntry(userDictId, rewriteFrom, rewriteTo, .position)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// Clears the contents of a single SkipList.
ClassMethod ClearSkipList(pDomainId As %Integer, pSkipListId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).ClearSkipList(pDomainId, pSkipListId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  <p>Create a new SkipList with the given name and description</p>
ClassMethod CreateSkipList(domainId As %Integer, name As %String, description As %String = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).CreateSkipList(domainId, name, description, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>This method creates a User Dictionary with a given <var>name</var> and optional <var>description</var> and
///  returns the created user dictionary ID afterwards. This method will return -1 if an error occurred,
///  which is passed by reference as <var>sc</var>.</p>
///  <p><b>Deprecated</b>: please use %New() in <class>%iKnow.UserDictionary</class></p>
ClassMethod CreateUserDictionary(name As %String, description As %String = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).CreateUserDictionary(name, description, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Drops a SkipList (entities part of the list will not be deleted from the domain)
ClassMethod DropSkipList(domainId As %Integer, skipListId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).DropSkipList(domainId, skipListId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  This method drops the User Dictionary identified by the supplied <var>userDictId</var>,
///  including all its entries.
///  <p><b>Deprecated</b>: please use %DeleteId() in <class>%iKnow.UserDictionary</class></p>
ClassMethod DropUserDictionary(userDictId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).DropUserDictionary(userDictId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  Retrieves a list of all the strings in the specified SkipList
ClassMethod GetSkipListElements(domainId As %Integer, skipListId As %Integer) As %XML.DataSet [ WebMethod ]
{
	set data = ##class(%XML.DataSet).%New("%iKnow.Utils.MaintenanceQAPI:GetSkipListElements")
	set tSC = data.Execute(domainId, skipListId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  Finds the SkipList ID corresponding to the supplied name.
ClassMethod GetSkipListId(domainId As %Integer, name As %String) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(domainId, name, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Retrieves a list of all the SkipLists registered in this domain.
ClassMethod GetSkipLists(domainId As %Integer, pIncludeCrossDomain As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pIncludeCrossDomain = $s($g(pIncludeCrossDomain)="":0, 1:pIncludeCrossDomain)

	set data = ##class(%XML.DataSet).%New("%iKnow.Utils.MaintenanceQAPI:GetSkipLists")
	set tSC = data.Execute(domainId, pIncludeCrossDomain)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  Returns a list of all the User Dictionaries in this namespace.
///  <p><b>Deprecated</b>: please use <class>%iKnow.UserDictionary</class></p>
ClassMethod GetUserDictionaries() As %XML.DataSet [ WebMethod ]
{
	set data = ##class(%XML.DataSet).%New("%iKnow.Utils.MaintenanceQAPI:GetUserDictionaries")
	set tSC = data.Execute()
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Returns the contents of a User Dictionary.</p>
///  <p><b>Deprecated</b>: please use GetEntries() in <class>%iKnow.UserDictionary</class></p>
ClassMethod GetUserDictionaryEntries(userDictId As %Integer) As %XML.DataSet [ WebMethod ]
{
	set data = ##class(%XML.DataSet).%New("%iKnow.Utils.MaintenanceQAPI:GetUserDictionaryEntries")
	set tSC = data.Execute(userDictId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  Returns the ID corresponding to the supplied User Dictionary <var>name</var>.
///  <p><b>Deprecated</b>: please use NameIndexOpen() <class>%iKnow.UserDictionary</class></p>
ClassMethod GetUserDictionaryId(name As %String) As %Library.Integer [ WebMethod ]
{
	quit ##class(%iKnow.Utils.MaintenanceAPI).GetUserDictionaryId(name)
}

/// Returns whether or not there are any SkipLists in the domain
ClassMethod HasSkipLists(pDomainId As %Integer) As %Library.Boolean [ WebMethod ]
{
	quit ##class(%iKnow.Utils.MaintenanceAPI).HasSkipLists(pDomainId)
}

///  Removes an entity (by ID) from a SkipList (but not from the domain)
/// For cross-domain SkipLists, use <method>RemoveStringFromSkipList</method>
ClassMethod RemoveEntityFromSkipList(domainId As %Integer, skipListId As %Integer, entUniId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).RemoveEntityFromSkipList(domainId, skipListId, entUniId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  Removes a string from a SkipList (but not from the domain)
ClassMethod RemoveStringFromSkipList(domainId As %Integer, skipListId As %Integer, string As %String) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).RemoveStringFromSkipList(domainId, skipListId, string)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  <p>Removes the User Dictionary entry registered at <var>position</var>. This method will
///  not impact the order or position of any remaning entries.</p>
///  <p><b>Deprecated</b>: please use RemoveEntry() in <class>%iKnow.UserDictionary</class></p>
ClassMethod RemoveUserDictionaryEntry(userDictId As %Integer, position As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).RemoveUserDictionaryEntry(userDictId, position)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// Returns whether or not the SkipList identified by <var>skipListId</var> contains the
/// supplied entity.
ClassMethod SkipListContainsElement(domainId As %Integer, skipListId As %Integer, entUniId As %Integer) As %Library.Boolean [ WebMethod ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).SkipListContainsElement(domainId, skipListId, entUniId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns whether or not the SkipList identified by <var>skipListId</var> contains the
/// supplied entity.
ClassMethod SkipListContainsString(domainId As %Integer, skipListId As %Integer, entity As %String) As %Library.Boolean [ WebMethod ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).SkipListContainsString(domainId, skipListId, entity, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Utils/MaintenanceWSAPI";

Parameter SERVICENAME = "iKnow.Utils.MaintenanceWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
