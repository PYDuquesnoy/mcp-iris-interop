/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Utils.MaintenanceAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Utils.MaintenanceAPI</class> for more information.</p>
Class %iKnow.Utils.MaintenanceQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

///  Adds an existing entity (by ID) to a SkipList.
/// For cross-domain SkipLists, use <method>AddStringToSkipList</method>
ClassMethod AddEntityToSkipList(domainId As %Integer, skipListId As %Integer, entUniId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).AddEntityToSkipList(domainId, skipListId, entUniId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  Adds a string to a SkipList, adding it as an entity if it didn't exist in the domain before.
ClassMethod AddStringToSkipList(domainId As %Integer, skipListId As %Integer, string As %String(MAXLEN=32767)) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).AddStringToSkipList(domainId, skipListId, string)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  <p>Adds a single entry to a User Dictionary at <var>position</var>. If <var>position</var> <= 0 (default),
///  it is added at the bottom of the list, otherwise at the requested position, shifting
///  existing entries down if it was already taken.</p>
///  <p><b>Deprecated</b>: please use AddEntry() in <class>%iKnow.UserDictionary</class></p>
ClassMethod AddUserDictionaryEntry(userDictId As %Integer, rewriteFrom As %String(MAXLEN=32767), rewriteTo As %String(MAXLEN=32767), ByRef position As %Integer = 0) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).AddUserDictionaryEntry(userDictId, rewriteFrom, rewriteTo, .position)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

/// Clears the contents of a single SkipList.
ClassMethod ClearSkipList(pDomainId As %Integer, pSkipListId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).ClearSkipList(pDomainId, pSkipListId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  <p>Create a new SkipList with the given name and description</p>
ClassMethod CreateSkipList(domainId As %Integer, name As %String(MAXLEN=32767), description As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).CreateSkipList(domainId, name, description, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>This method creates a User Dictionary with a given <var>name</var> and optional <var>description</var> and
///  returns the created user dictionary ID afterwards. This method will return -1 if an error occurred,
///  which is passed by reference as <var>sc</var>.</p>
///  <p><b>Deprecated</b>: please use %New() in <class>%iKnow.UserDictionary</class></p>
ClassMethod CreateUserDictionary(name As %String(MAXLEN=32767), description As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).CreateUserDictionary(name, description, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Drops a SkipList (entities part of the list will not be deleted from the domain)
ClassMethod DropSkipList(domainId As %Integer, skipListId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).DropSkipList(domainId, skipListId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  This method drops the User Dictionary identified by the supplied <var>userDictId</var>,
///  including all its entries.
///  <p><b>Deprecated</b>: please use %DeleteId() in <class>%iKnow.UserDictionary</class></p>
ClassMethod DropUserDictionary(userDictId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).DropUserDictionary(userDictId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  Retrieves a list of all the strings in the specified SkipList
Query GetSkipListElements(domainId As %Integer, skipListId As %Integer) As %Library.Query(ROWSPEC = "entUniId:%Integer,entity:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetSkipListElementsExecute(ByRef qHandle As %Binary,  domainId As %Integer, skipListId As %Integer) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListElements("^||%IKQ.Result("_r_")", domainId, skipListId)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetSkipListElementsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetSkipListElementsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetSkipListElementsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetSkipListElementsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  Finds the SkipList ID corresponding to the supplied name.
ClassMethod GetSkipListId(domainId As %Integer, name As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(domainId, name, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Retrieves a list of all the SkipLists registered in this domain.
Query GetSkipLists(domainId As %Integer, pIncludeCrossDomain As %Boolean = 0) As %Library.Query(ROWSPEC = "skipListId:%Integer,name:%String(MAXLEN=32767),description:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetSkipListsExecute(ByRef qHandle As %Binary,  domainId As %Integer, pIncludeCrossDomain As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipLists("^||%IKQ.Result("_r_")", domainId, pIncludeCrossDomain)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetSkipListsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetSkipListsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetSkipListsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetSkipListsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  Returns a list of all the User Dictionaries in this namespace.
///  <p><b>Deprecated</b>: please use <class>%iKnow.UserDictionary</class></p>
Query GetUserDictionaries() As %Library.Query(ROWSPEC = "userDictId:%Integer,name:%String(MAXLEN=32767),description:%String(MAXLEN=32767)") [ Deprecated, SqlProc ]
{
}

ClassMethod GetUserDictionariesExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).GetUserDictionaries("^||%IKQ.Result("_r_")")
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetUserDictionariesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetUserDictionariesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetUserDictionariesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetUserDictionariesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Returns the contents of a User Dictionary.</p>
///  <p><b>Deprecated</b>: please use GetEntries() in <class>%iKnow.UserDictionary</class></p>
Query GetUserDictionaryEntries(userDictId As %Integer) As %Library.Query(ROWSPEC = "position:%Integer,rewriteFrom:%String(MAXLEN=32767),rewriteTo:%String(MAXLEN=32767)") [ Deprecated, SqlProc ]
{
}

ClassMethod GetUserDictionaryEntriesExecute(ByRef qHandle As %Binary,  userDictId As %Integer) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).GetUserDictionaryEntries("^||%IKQ.Result("_r_")", userDictId)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetUserDictionaryEntriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetUserDictionaryEntriesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetUserDictionaryEntriesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetUserDictionaryEntriesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  Returns the ID corresponding to the supplied User Dictionary <var>name</var>.
///  <p><b>Deprecated</b>: please use NameIndexOpen() <class>%iKnow.UserDictionary</class></p>
ClassMethod GetUserDictionaryId(name As %String(MAXLEN=32767)) As %Library.Integer [ SqlProc ]
{
	quit ##class(%iKnow.Utils.MaintenanceAPI).GetUserDictionaryId(name)
}

/// Returns whether or not there are any SkipLists in the domain
ClassMethod HasSkipLists(pDomainId As %Integer) As %Library.Boolean [ SqlProc ]
{
	quit ##class(%iKnow.Utils.MaintenanceAPI).HasSkipLists(pDomainId)
}

///  Removes an entity (by ID) from a SkipList (but not from the domain)
/// For cross-domain SkipLists, use <method>RemoveStringFromSkipList</method>
ClassMethod RemoveEntityFromSkipList(domainId As %Integer, skipListId As %Integer, entUniId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).RemoveEntityFromSkipList(domainId, skipListId, entUniId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  Removes a string from a SkipList (but not from the domain)
ClassMethod RemoveStringFromSkipList(domainId As %Integer, skipListId As %Integer, string As %String(MAXLEN=32767)) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).RemoveStringFromSkipList(domainId, skipListId, string)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  <p>Removes the User Dictionary entry registered at <var>position</var>. This method will
///  not impact the order or position of any remaning entries.</p>
///  <p><b>Deprecated</b>: please use RemoveEntry() in <class>%iKnow.UserDictionary</class></p>
ClassMethod RemoveUserDictionaryEntry(userDictId As %Integer, position As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Utils.MaintenanceAPI).RemoveUserDictionaryEntry(userDictId, position)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

/// Returns whether or not the SkipList identified by <var>skipListId</var> contains the
/// supplied entity.
ClassMethod SkipListContainsElement(domainId As %Integer, skipListId As %Integer, entUniId As %Integer, Output scText As %String = "") As %Library.Boolean [ SqlProc ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).SkipListContainsElement(domainId, skipListId, entUniId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Returns whether or not the SkipList identified by <var>skipListId</var> contains the
/// supplied entity.
ClassMethod SkipListContainsString(domainId As %Integer, skipListId As %Integer, entity As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Boolean [ SqlProc ]
{
	set retVal = ##class(%iKnow.Utils.MaintenanceAPI).SkipListContainsString(domainId, skipListId, entity, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

}
