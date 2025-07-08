/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %syLDAPFunc, %occInclude)

/// Requires %syLDAP.INC to be included in your COS routine for some macro definitions.<br>
/// The class methods 
/// described below are built on top of the interfaces OPENLDAP provides.
/// For more information on OPENLDAP, see www.openldap.org.<br><br>
/// This class only supports the OPENLDAP version 3 protocols.<br> It is based on OPENLDAP's
/// source version openldap-2.4.48.<br>
/// This class allows the user to interface with an LDAP database. The user
/// can use the methods provided to authenticate themselves, Search,
/// Add, Modify, Rename, and Delete entries in the LDAP database.<br><br>
/// Error Handling:<br>
/// Every time an LDAP method is called, a success status or error status
/// is either returned or set into the LDAP session. If the method does not return
/// the error as a result of the call, then the caller needs to retrieve the
/// error with a call to either the GetError method, or the GetLastError method.
/// The caller should test the return values for success or failure
/// after every call.<br><br>
/// Example:<br>
/// s Status=##Class(%SYS.LDAP).AddExts(LD,DN,Attributes)<br>
/// i Status'=$$$LDAPSUCCESS {<br>
/// w !,"AddExts error: "_Status_" - "_##Class(%SYS.LDAP).Err2String(Status) <br>
/// g LDAPError<br>
/// }<br><br>
/// See the LDAP.mac routine for extensive LDAP samples. This routine is available on GitHub at 
/// https://github.com/intersystems/Samples-Security<br>
Class %SYS.LDAP [ Abstract, System = 4 ]
{

/// Add an entry to the LDAP directory tree.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// DN - String that contains the distinguished name of the entry
/// to add. <br><br>
/// ATTR - <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> formatted with attributes to add to the new entry.<br>
/// Each element in the list is a separate attribute to be added to the new entry.<br>
/// Attribute=$lb(op,type,vals)<br>
/// op - For create, set to 0. However, if the vals parameter is to be treated
/// as binary, then pass in 128 for this parameter.<br>
/// type - Name of the attribute. Example="Telephone". <br>
/// vals - <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of the values to assign to the attribute. If this is a single entry
/// attribute, then $lb(Value), Example=$lb("617-621-0600"). If a multi-value entry, then
/// $lb(Value1,Value2,...,Valuen). If the data is to be treated as binary (e.g. jpeg file),
/// then make sure that 128 is passed for the op.<br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br> 
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Examples:<br><br>
/// s Attr1=$lb(0,"displayName",$lb(Jim Nilson))<br>
/// s Attr2=$lb(0,"telephoneNumber",$lb("617-621-0600")<br>
/// s Attr3=$lb(0,"objectClass",$lb("top","person","organizationalPerson","user")<br>
/// s Attr4=$lb(128,"Picture",$lb(Jpegbitstring))<br>
/// s Attributes=$lb(Attr1,Attr2,Attr3,Attr4)<br>
/// ; Note the special character identifier "\" which is needed before the "," in the name<br>
/// s DN="CN=Nilson\, Jim,OU=Users,OU=England,DC=iscinternal,DC=com"<br>
/// s Status=##Class(%SYS.LDAP).AddExts(LD,DN,Attributes)<br><br>
/// Note: See the ModifyExts method below for how to manipulate passwords on a Windows
/// Active Directory LDAP server.<br>
ClassMethod AddExts(LD As %Integer, DN As %String, ATTR As %List, ServerControls As %String = "", ClientControls As %String = "") As %Integer
{
 q $$$ldapaddexts(LD,DN,ATTR,"","")
}

/// Authenticate a Windows client to a Windows Active Directory LDAP Server.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// DN - Distinguished name of the entry to bind. Currently always "".<br><br>
/// Cred - A <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> value that contains the credentials with which to 
/// authenticate. Currently only supported credentials are 
/// $lb(Username,Domain,Password).<br><br>
/// Method - Indicates the authentication method to use. The following are supported:<br>
/// $$$LDAPAUTHSICILY <br>
/// $$$LDAPAUTHMSN <br>
/// $$$LDAPAUTHNTLM <br>
/// $$$LDAPAUTHDPA<br>
/// $$$LDAPAUTHNEGOTIATE<br>
/// $$$LDAPAUTHDIGEST <br>
/// <br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// This method is valid only for Windows clients talking to a Windows Active
/// Directory LDAP server. Use SimpleBinds for OPENLDAP servers. If you have retrieved
/// full DN of the Windows user using the LDAP search method, then you may use
/// SimpleBinds on the Windows Active Directory LDAP server also.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).Binds(LD,"",$lb(Username,Domain,Password),$$$LDAPAUTHNEGOTIATE)<br>
/// <br>
/// See the documentation in SimpleBindS which shows how to handle errors and retry the operation.<br>
ClassMethod Binds(LD As %Integer, DN As %String = "", Cred As %List, Method As %Integer) As %Integer
{
 s $zt="Error"
 q $$$ldapbinds(LD,"",Cred,Method)
Error s $zt=""
 i $ze["<ZPASS" q $$$LDAPINVALIDCREDENTIALS
 ztrap $ze
}

/// Verify search filter syntax.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// SearchFilter - String that contains the name of the filter to check.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// This method is valid only for Windows clients.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).CheckFilter(LD,"(objectclass=*)")<br>
ClassMethod CheckFilter(LD As %Integer, SearchFilter As %String) As %Integer
{
 q $$$ldapcheckfilter(LD,SearchFilter)
}

/// Determine if an attribute, for a given entry, holds a known value.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// DN - String that contains the distinguished name of the entry 
/// to compare.<br><br>
/// Attr - String that contains the attribute to compare.<br><br>
/// Data - String or list value to be compared to the attribute value. If the data is
/// a string, then simply pass in the string. If the data is binary, then pass in 
/// $lb(binaryvalue).<br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br> 
/// Return Values:<br><br>
/// If the function succeeds, and the attribute and known values match,
/// $$$LDAPCOMPARETRUE is returned.<br>
/// If the values do not match, $$$LDAPCOMPAREFALSE is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).CompareExts(LD,"CN=Nilson,OU=Users,DC=iscinternal,DC=com","mail","nilson@intersystems.com)<br><br>
ClassMethod CompareExts(LD As %Integer, DN As %String, Attr As %String, Data As %String, ServerControls As %String = "", ClientControls As %String = "") As %Integer
{
 q $$$ldapcompareexts(LD,DN,Attr,Data,"","")
}

/// Establish a connection to an LDAP server.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Timeout - The number of seconds to spend in an attempt to 
/// establish a connection before a timeout. If 0, the function uses a
/// default timeout value. <br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// This method is valid only for Windows clients.<br>
/// Use this function to force a connection to an LDAP server from a
/// Windows client. This connection would normally be done as part of the LDAP
/// methods (like SimpleBinds). However, when diagnosing problems, performing the
/// connection by itself can help narrow down connection issues versus search issues.<br>
ClassMethod Connect(LD As %Integer, Timeout As %Integer = 0) As %Integer
{
 q $$$ldapconnect(LD,Timeout)
}

/// Count the number of search entries that an LDAP server returned.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// SearchResult - The search result as returned by SearchExts.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, it returns the number of entries.<br>
/// If the function fails, the return value is -1. The actual session
/// error can be returned by a call to the GetError method.<br><br>
/// Comments:<br><br>
/// The CountEntries function returns the number of entries contained, 
/// or remaining in a chain of entries. Call the function with the return
/// value from SearchExts.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).SearchExts(LD,BaseDN,$$$LDAPSCOPESUBTREE,Filter,Attributes,0,"","",2,ServerTimeout,.SearchResult)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s NumEntries=##Class(%SYS.LDAP).CountEntries(LD,SearchResult)<br>
/// i NumEntries=-1 s Status=##Class(%SYS.LDAP).GetError(LD) q Status
ClassMethod CountEntries(LD As %Integer, SearchResult As %Integer) As %Integer
{
 q $$$ldapcountentries(LD,SearchResult)
}

/// Count the number of values returned by a GetValue call.<br><br>
/// Parameters:<br><br>
/// Values - Values as returned by GetValues.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, it returns the number of entries in the list.<br>
/// The actual session error status can be returned by a call to 
/// the GetError method.<br><br>
/// Examples:<br><br>
/// Values=##Class(%SYS.LDAP).GetValues(LD,CurrentEntry,Attr)<br>
/// s Len=##Class(%SYS.LDAP).CountValues(Values)<br>
ClassMethod CountValues(Values As %List) As %Integer
{
 q $$$ldapcountvalues(Values)
}

/// Count the number of values in a binary list returned by a GetValuesLen call.<br><br>
/// Parameters:<br><br>
/// Values - Values as returned by GetValuesLen.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, it returns the number of entries in the list.<br>
/// The actual session error status can be returned by a call to 
/// the GetError method.<br><br>
/// Examples:<br><br>
/// Values=##Class(%SYS.LDAP).GetValuesLen(LD,CurrentEntry,Attr)<br>
/// s Len=##Class(%SYS.LDAP).CountValuesLen(Values)<br>
ClassMethod CountValuesLen(Values As %List) As %Integer
{
 q $$$ldapcountvalueslen(Values)
}

/// Remove a leaf entry from the directory tree.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// DN - String that contains the distinguished name of the entry
/// to delete. <br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br> 
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).DeleteExts(LD,"CN=Nilson\, Jim,OU=Users,OU=England,DC=iscinternal,DC=com")<br><br>
ClassMethod DeleteExts(LD As %Integer, DN As %String, ServerControls As %String = "", ClientControls As %String = "") As %Integer
{
 q $$$ldapdeleteexts(LD,DN,"","")
}

/// Convert a numeric LDAP error code into a string that describes the error.<br><br>
/// Parameters:<br><br>
/// Error - Error as returned by LDAP methods, or as returned by the method GetError.<br><br>
/// Return Values:<br><br>
/// If the method succeeds, a string that describes the error is returned.<br>
/// If the function fails, "" is returned.<br>
/// The actual session error status can be returned by a call to 
/// the GetError method.<br><br>
/// Examples:<br><br>
/// s NumEntries=##Class(%SYS.LDAP).CountEntries(LD,SearchResult)<br>
/// i NumEntries=-1 s Msg=##Class(%SYS.LDAP).Err2String(##Class(%SYS.LDAP).GetError(LD))
ClassMethod Err2String(Error) As %String
{
 q $$$ldaperr2string(Error)
}

/// Escape a search filter.<br><br>
/// Parameters:<br><br>
/// SearchFilter (byref) - String that contains the filter to escape.<br><br>
/// Return Values:<br><br>
/// SearchFilter - Returned filter with the characters escaped.<br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// Search filters need to be escaped according to LDAP rules. See:<br><br>
/// https://msdn.microsoft.com/en-us/library/aa746475(v=vs.85).aspx<br><br>
/// Here is the character substitution this method provides.<br><br> 
/// * -	\2a<br>
/// ( -	\28<br>
/// ) -	\29<br>
/// \ -	\5c<br>
/// / -  \2f<br>
/// NUL - \00<br>
/// <br>
/// Examples:<br><br>
/// s SearchFilter="Markus\, Paul,OU=People,OU=Havens,DC=thehavenshospital,DC=org<br>
/// s Status=##Class(%SYS.LDAP).EscapeFilter(.SearchFilter)<br>
/// w !,SearchFilter<br>
/// Markus\5c, Paul,OU=People,OU=Havens,DC=thehavenshospital,DC=org<br>
ClassMethod EscapeFilter(ByRef SearchFilter As %String) As %Integer
{
 s ReplaceString="*()\/"_$c(0)
#;Quick check to see if there are any matching characters
 i $translate(SearchFilter,ReplaceString)=SearchFilter q $$$LDAPSUCCESS
 s EncodedFilter=""
 f i=1:1:$l(SearchFilter) {
	s Char=$e(SearchFilter,i)
 	s Found=$find(ReplaceString,Char)
 	i Found {
		s String=$zcvt($zhex(+$a($e(ReplaceString,Found-1))),"L")
		i String="0" s String="00"
	 	s EncodedFilter=EncodedFilter_"\"_String
 	} else {
 		s EncodedFilter=EncodedFilter_Char
 	}
 } 
 s SearchFilter=EncodedFilter
 q $$$LDAPSUCCESS
}

/// Return a pointer to the first entry of a message.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// SearchResult - The search result as returned by SearchExts.<br><br>
/// Return Values:<br><br>
/// If the method succeeds, it returns the entry.<br>
/// If no entry exists in
/// the result set, it returns 0, and a call to GetError returns 
/// $$$LDAPSUCCESS.<br>
/// If the function fails, it returns 0 and a call to GetError returns the
/// session error.<br><br>
/// Comments:<br><br>
/// Use FirstEntry in conjunction with NextEntry to step through 
/// and retrieve the list of entries from a search result chain.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).SearchExts(LD,BaseDN,$$$LDAPSCOPESUBTREE,Filter,Attributes,0,"","",2,ServerTimeout,.SearchResult)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s Entry=##Class(%SYS.LDAP).FirstEntry(LD,SearchResult)<br>
/// s Status=##Class(%SYS.LDAP).GetError(LD)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
ClassMethod FirstEntry(LD As %Integer, SearchResult As %Integer) As %Integer
{
 q $$$ldapfirstentry(LD,SearchResult)
}

/// Retrieve the distinguished name for a given entry.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Entry - Entry whose distinguished name is to be retrieved, as returned
/// by the FirstEntry or NextEntry methods.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, it returns the distinguished name.<br>
/// If the function fails, it returns "". <br>
/// The actual session error 
/// status can be returned by a call to the GetError method.<br><br>
/// Examples:<br><br>
/// s Entry=##Class(%SYS.LDAP).FirstEntry(LD,SearchResult)<br>
/// s Status=##Class(%SYS.LDAP).GetError(LD)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s DN=##Class(%SYS.LDAP).GetDN(LD,Entry)<br>
/// i DN="" s Status=##Class(%SYS.LDAP).GetError(LD)
ClassMethod GetDN(LD As %Integer, Entry As %Integer) As %String
{
 q $$$ldapgetdn(LD,Entry)
}

/// Retrieve the last error code returned by an LDAP call for a specific session.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Return Values:<br><br>
/// An LDAP error code.<br><br>
/// Comments:<br><br>
/// Use the GetError method to return the last LDAP error message for a
/// specific session. The value from the GetError method may in turn be passed
/// to the Err2String method to get error text for the error.<br>
/// Error numbers >= $zh("5000") are ISC internal LDAP errors.<br><br>
/// Examples:<br><br> 
/// s Status=##Class(%SYS.LDAP).GetError(LD)<br>
/// s Msg=##Class(%SYS.LDAP).Err2String(Status)<br>
ClassMethod GetError(LD) As %Integer
{
 q $$$ldapgeterror(LD)
}

/// Retrieve the last error code returned by an LDAP call.<br><br>
/// Return Values:<br><br>
/// An LDAP error code.<br><br>
/// Comments:<br><br>
/// Use the GetLastError method to return the last LDAP error message.
/// The value from the GetLastError method may in turn be passed
/// to the Err2String method to get error text for the error.<br>
/// Returned errors are only in the LDAP error range and do not
/// include ISC internal errors.<br><br>
/// Examples:<br><br> 
/// s Status=##Class(%SYS.LDAP).GetLastError()<br>
/// s Msg=##Class(%SYS.LDAP).Err2String(Status)<br>
ClassMethod GetLastError() As %Integer
{
 q $$$ldapgetlasterror
}

/// Search the LDAP directory using a pages search and return a requested set of attributes for each entry.<br><br>
/// This is a Windows only method.<br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Page - Pointer to page of results as returned by SearchInitPage() method.
/// Timeout - Specifies both the local search time-out value in seconds
/// and the operation time limit that is sent to the server within
/// the search request. <br><br>
/// PageSize - Number of records to be returned in each page for each call to GetNextPages().<br><br>
/// TotalPages (byRef) - Estimated number of pages which will be returned by the search. Depending on the
/// type of the LDAP server, this number may always be 0 (unknown).<br><br>
/// SearchResult (byRef) - Contains the results of the search upon completion
/// of the call.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If there are more results to retrieve, then 
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// <b>When done with the search results you need to free the search results the following way:<br><br>
/// 1) First call the MsgFree(SearchResult) method.<br>
/// 2) Then call the the SearchAbandonPage(LD,Page)() method.<br>
/// Failure to do this before a call to UnBinds may cause your process to core on a future LDAP call.<br><br>
/// </b>
/// Note that the caller can have several different searches "open" at the 
/// same time by using a different variable for the SearchResult parameter.<br><br>
/// Examples:<br><br>
/// Search for all users in the LDAP database. Return
/// their display name, e-mail and telephone number. Use a timeout of 10 seconds,
/// and return at most 100 items for each call to the GetNextPages() method.<br><br>
/// s Page=##Class(%SYS.LDAP).SearchExts(LD,"DC=mydomain,DC=com",<br>
/// $$$LDAPSCOPESUBTREE,"sAMAccountname=*",<br>
/// $lb("displayName","mail","telephoneNumber"),0,"","",10,100,"")<br>
/// s Status=##Class(%SYS.LDAP).GetNextPages(LD,Page,10,100,.TotalPages,.SearchResult)<br>
/// While (Status=$$$LDAPSUCCESS) {<br>
/// ; Process page of results here<br><br><br>
/// ; Now get the next page of results<br>
/// s Status=##Class(%SYS.LDAP).GetNextPages(LD,Page,10,100,.TotalPages,.SearchResult)<br>
/// }<br>
/// i Status=$$$LDAPNORESULTSRETURNED {w !,"End of search"} else { w !,"Error "_Status} <br>
/// s Status=##Class(%SYS.LDAP).MsgFree(SearchResult)<br>
/// s Status=##Class(%SYS.LDAP).SearchAbandonPage(LD, Page)<br>
ClassMethod GetNextPages(LD As %Integer, Page As %Integer, Timeout As %Integer, PageSize As %Integer, ByRef TotalPages As %Integer, ByRef SearchResult As %Integer) As %Integer
{
 i $$$ISWINDOWS {
	q $$$ldapgetnextpages(LD,Page,Timeout,PageSize,.TotalPages,.SearchResult)
 } else {
	 q 0
 }
}

/// Get options for an LDAP session.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Option - The name of the option to get. See valid options below.<br><br>
/// OutValue - Value of that option.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, the return value is $$$LDAPSUCCESS.<br>
/// If the function fails, it returns an error code.<br><br>
/// Valid Options:<br><br>
/// $$$LDAPOPTERRORNUMBER - Returns the last LDAP error.<br><br>
/// $$$LDAPOPTNETWORKTIMEOUT - Returns the network timeout value after which poll/select
/// following a connect returns in case of no activity. Specifying seconds set to 0 results
/// in an infinite timeout, which is the default. Normally there is no need to change the default.
/// This is available on Unix platforms only.<br><br>
/// $$$LDAPOPTTIMEOUT - Returns the timeout value for the synchronous API calls. 
/// Specifying seconds set to 0 results in an infinite timeout, which is the default.
/// Normally there is no need to change the default. This is available on Unix platforms only.<br><br>
/// $$$LDAPOPTSSL - Returns 0/1 whether SSL is enabled on the connection. The connection must have already
/// been established before this will acurately return 0/1. This means calling StartTLS(),
/// or SearchExts(), or additionally on Windows Connect().<br><br>
/// $$$LDAPOPTERRORSTRING - When called after a Bind operation, may give additional information about the cause
/// of the bind failure. Additional information is not available on Windows clients or if using an OPENLDAP server.<br>
/// Examples:<br><br>
/// Get last LDAP error on the session.<br>
/// s Status=##Class(%SYS.LDAP).GetOption(LD,$$$LDAPOPTERRORNUMBER,.ErrorNum)<br><br>
/// Note: Previous versions allowed the option $$$LDAPOPTPROTOCOLVERSION and 
/// $$$LDAPOPTREFERRALS to be specified.
/// These options are deprecated. SetOption calls using this option will be ignored and always will
/// return success. Version is now always set to 3, and referrals are always turned off.
ClassMethod GetOption(LD As %Integer, Option As %Integer, ByRef OutValue As %String) As %Integer
{
 q $$$ldapgetoption(LD,Option,.OutValue)
}

/// Return string values for a given attribute. Use GetValuesLen for binary data.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Entry - Pointer to the search entry as returned by the FirstEntry or
/// NextEntry methods.<br><br>
/// Attr - String that contains the attribute whose values are to be retrieved.
/// The passed string can be as returned by FirstAttribute or NextAttribute, or
/// a caller supplied string.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> element is returned containing the values
/// of the attribute.<br>
/// If the function fails, it returns "". <br>
/// The actual session error 
/// status can be returned by a call to the GetError method.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).SearchExts(LD,BaseDN,$$$LDAPSCOPESUBTREE,Filter,Attributes,0,"","",2,ServerTimeout,.SearchResult)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s Entry=##Class(%SYS.LDAP).FirstEntry(LD,SearchResult)<br>
/// s Status=##Class(%SYS.LDAP).GetError(LD)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s ValueList=##Class(%SYS.LDAP).GetValues(LD,Entry,"sAMAccountname")
/// i ValueList="" q ##Class(%SYS.LDAP).GetError(LD)<br>
/// w !,"sAMAccountname="_$li(ValueList,1)
ClassMethod GetValues(LD As %Integer, Entry As %Integer, ByRef Attr As %String) As %List
{
 q $$$ldapgetvalues(LD,Entry,Attr)
}

/// Return binary values for a given attribute. Use GetValues to return string values.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Entry - Pointer to the search entry as returned by the FirstEntry or
/// NextEntry methods.<br><br>
/// Attr - String that contains the attribute whose values are to be retrieved.
/// The passed string can be as returned by FirstAttribute or NextAttribute, or
/// a caller supplied string.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> element is returned containing the values
/// of the attribute.<br>
/// If the function fails, it returns "". <br>
/// The actual session error 
/// status can be returned by a call to the GetError method.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).SearchExts(LD,BaseDN,$$$LDAPSCOPESUBTREE,Filter,Attributes,0,"","",2,ServerTimeout,.SearchResult)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s Entry=##Class(%SYS.LDAP).FirstEntry(LD,SearchResult)<br>
/// s Status=##Class(%SYS.LDAP).GetError(LD)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s ValueList=##Class(%SYS.LDAP).GetValuesLen(LD,Entry,"jpegbinarypicture")<br>
/// i ValueList="" q ##Class(%SYS.LDAP).GetError(LD)<br>
/// d Displayjpeg($li(ValueList,1))<br>
ClassMethod GetValuesLen(LD As %Integer, Entry As %Integer, ByRef Attr As %String) As %List
{
 q $$$ldapgetvalueslen(LD,Entry,Attr)
}

/// Initialize a connection to a LDAP server.<br><br>
/// Parameters:<br><br> 
/// HostName - Space-separated list of host names running an LDAP server 
/// to which to connect. Each host name in the list can include an optional 
/// port number which is separated from the host itself with a colon (:). The host name must be a
/// fully qualified domain name. A fully qualified domain name (FQDN), sometimes referred to 
/// as an absolute domain name, is a domain name that specifies its exact location in the tree
/// hierarchy of the Domain Name System (DNS). It specifies all domain levels, including the 
/// top-level domain and the root domain. A fully qualified domain name is distinguished 
/// by its unambiguity; it can only be interpreted one way. For example, given a device with 
/// a local hostname myhost and a parent domain name example.com, the fully qualified domain 
/// name is myhost.example.com. The FQDN therefore uniquely identifies the device; while there 
/// may be many hosts in the world called myhost, there can only be one myhost.example.com.
/// When using a Windows Active Directory server as an LDAP server, and a Windows client, 
/// a null string will find the default LDAP server for the domain.<br><br>
/// PortNumber - Contains the TCP port number to which to connect. This defaults to 389
/// if not specified. This parameter is ignored if a host name includes a port number.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, it returns a handle to the LDAP session. The session 
/// handle must be freed with a call to UnBinds when it is no longer required.<br>
/// If the function fails, it returns 0. Use GetLastError to retrieve 
/// the error code.<br><br>
/// Note that Init does not make an actual connection to the LDAP server, it simply
/// initializes the connection information. The actual connection will happen during the
/// first request for data from the LDAP server. <br><br>
/// Examples:<br><br>
/// Creates a session to your default LDAP server on port 389.<br>
/// s LD = ##Class(%SYS.LDAP).Init()<br><br>
/// Creates a session to the LDAP server called "ldapserver" on default port 389.<br>
/// s LD = ##Class(%SYS.LDAP).Init("ldapserver.example.com")<br><br>
/// Creates a session to the LDAP server called "ldapserver" on port 389.<br>
/// s LD = ##Class(%SYS.LDAP).Init("ldapserver.example.com",389)<br><br>
/// Creates a session to either the LDAP server called "ldapserver" or
/// if it is unavailable, to LDAP server "backupldapserver" on port 389.<br>
/// s LD = ##Class(%SYS.LDAP).Init("ldapserver.example.com backupldapserver.example.com")<br><br>
/// Secure Connections:<br>
/// For a Windows client, make sure you have the CA certificates already loaded
/// in the Certificates(local computer)\Trusted Root Certification Authorities certificate store.
/// NOTE: If the certificates are stored in the Certificates(current user)\Trusted Root Certification 
/// Authorities certificate store, then the SSL connection may fail with Error code 81 if the process
/// is running in the background.
/// For a Unix client, make sure the protections on the certificate file allow your process to
/// be able to read it, and that any additional certificate or LDAP options are specified in the 
/// ldap.conf file.<br>
/// It is recommended that on the Active Directory Server that the parameter 
/// "LDAP server signing requirements" be set to "Require signature". This prevents any LDAP bind command 
/// on the server on port 389 to be executed unless the channel is encrypted with StartTLS. See<br><br>
/// https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/domain-controller-ldap-server-signing-requirements<br><br>
/// To create a secure SSL connection to an LDAP server, here are the calls you need to make for each
/// platform type.<br><br>
/// 1) Windows Client to Windows Active Directory LDAP server.<br>
/// Using the StartTLSs call<br>
/// s LD=##Class(%SYS.LDAP).Init("ldapserver.example.com",389)<br>
/// s Status=##Class(%SYS.LDAP).StartTLSs(LD)<br><br>
/// or<br><br>
/// Using a direct connection to the LDAP SSL port.<br>
/// s LD=##Class(%SYS.LDAP).Init("ldapserver.example.com",636)<br><br>
/// 2) Windows Client to OpenLDAP server<br>
/// Using a direct connection to the LDAP SSL port.<br>
/// s LD=##Class(%SYS.LDAP).Init("ldapserver.example.com",636)<br><br>
/// Or<br>
/// using the StartTLSs call <br>
/// s LD=##Class(%SYS.LDAP).Init("ldapserver.example.com")<br>
/// s Status=##Class(%SYS.LDAP).StartTLSs(LD)<br><br> 
/// 3) Unix client to Windows Active Directory LDAP server.<br>
/// Using the StartTLSs call. If you want to connect directly to port 636 without using StartTLSs, use the
/// ##Class(%SYS.LDAP).Initialize() method.<br>
/// Note that there are other options pertaining to certificates which can be specified in
/// the LDAP.CONF file on the Unix client (usually found in /etc/openldap/ldap.conf). The
/// settings in this configuration file will be applied to your LDAP sessions you create. Read the 
/// man pages for ldap.conf for more information on the parameters.<br>
/// s LD=##Class(%SYS.LDAP).Init("ldapserver.example.com")<br>
/// s Status=##Class(%SYS.LDAP).SetOption(LD,$$$LDAPOPTXTLSCACERTFILE,CACertFileName)<br>
/// s Status=##Class(%SYS.LDAP).StartTLSs(LD)<br><br>
/// 4) Unix client to OpenLDAPserver.<br>
/// Using the StartTLSs call. If you want to connect directly to port 636 without using StartTLSs, use the
/// ##Class(%SYS.LDAP).Initialize() method<br>
/// Note that there are other options pertaining to certificates which can be specified in
/// the LDAP.CONF file on the Unix client (usually found in /etc/openldap/ldap.conf). The
/// settings in this configuration file will be applied to your LDAP sessions you create. Read the 
/// man pages for ldap.conf for more information on the parameters.<br>
/// s LD=##Class(%SYS.LDAP).Init("ldapserver.example.com")<br>
/// s Status=##Class(%SYS.LDAP).SetOption(LD,$$$LDAPOPTXTLSCACERTFILE,CACertFileName)<br>
/// s Status=##Class(%SYS.LDAP).StartTLSs(LD)<br><br>
/// Error codes:<br><br>
/// When connecting using SSL, several different error codes could be returned when the 
/// connection is formed.<br>
/// -11 or -12 - The certificate is not correct for the LDAP server, or the FQDN host name
/// was not specified correctly. Make sure that you have the CA certificate properly installed on
/// the client, in the correct directory. On a Windows client, make sure it is in local 
/// computer certificate store. On a Unix client, make sure the process has read access to the
/// certificate, and that the file specification in the setoption call is correct. Make sure that the
/// LDAP server name specified is the FQDN (e.g. ldapserver.example.com) and not just "ldapserver",
/// or an ip address.<br>
/// 81 - Most likely the certificate is not in the correct Windows certificate store. Import it into the
/// local computer store.<br>
/// When on a Unix client, if you try to form an SSL connection with one certificate, and the 
/// certificate is wrong, or the server is incorrect, your connection may fail even after you have corrected
/// the problem. The issue here is that the process caches the certificate and node information
/// at the O/S level. To correct this, simply log your process out of the system, then log back in.<br>
ClassMethod Init(HostName As %String = "", PortNumber As %Integer = {$$$LDAPPORT}) As %Integer
{
 s LD=$$$ldapinit(HostName,PortNumber)
 q LD
}

/// Connect from a Unix system to a LDAP server.<br>
/// <br>
/// This sets up a connection from a Unix machine to an LDAP server with or
/// without TLS.<br>
/// 1) Connect without using TLS to port 389.<br>
/// Set Status=##Class(%SYS.LDAP).Initialize(.ld,"ldap://domain.com")<br>
/// 2) Connect using TLS directly to port 636<br>
/// Set Status=##Class(%SYS.LDAP).Initialize(.ld,"ldaps://domain.com")<br>
/// Set Status=##Class(%SYS.LDAP).SetOption(LD,$$$LDAPOPTXTLSCACERTFILE,"/iris/mgr/CACertFile.pem")<br>
/// <br>
/// Note that the actual connection to the LDAP server will be made when the first operation on the channel
/// which returns data is executed, such as a SimpleBinds().
ClassMethod Initialize(ByRef LD As %Integer = "", URL As %String) As %Integer
{
 s Status=$$$ldapinitialize(.LD,URL)
 i LD'=0 d ##Class(%SYS.LDAP).SetOption(LD,$$$LDAPOPTREFERRALS,$$$LDAPOPTOFF)
 q Status
}

/// Return the first attribute of an Entry.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Entry - The entry whose attributes are to be stepped through, as returned by the
/// FirstEntry or NextEntry methods.<br><br>
/// Ptr (ByRef) - Used internally to track the current attribute.<br>
/// Return Values:<br><br>
/// If the function succeeds, a string containing the name of the first
/// attribute is returned.<br>
/// If the function fails, it returns "".<br>
/// The actual session error 
/// status can be returned by a call to the GetError method.<br><br>
/// Comments:<br><br>
/// Use the FirstAttribute with the NextAttribute method to step through
/// a list of attributes in the entry. Once the Attribute name is returned,
/// you can call the GetValues or GetValuesLen method to return the values for that 
/// attribute.<br>
/// Pass the Ptr parameter by reference to track the current position in 
/// the entry. <br><br>
/// Examples:<br><br>
/// Loop through all attributes of an entry<br>
/// s CurrentEntry=##Class(%SYS.LDAP).FirstEntry(LD,SearchResult)<br>
/// s AttrName=##Class(%SYS.LDAP).FirstAttribute(LD,CurrentEntry,.Ptr)<br>
/// while (AttrName'="") {<br>
/// s AttrValues=##Class(%SYS.LDAP).GetValues(LD,CurrentEntry,AttrName)<br>
/// s AttrName=##Class(%SYS.LDAP).NextAttribute(LD,CurrentEntry,.Ptr)<br>
/// }<br> 
ClassMethod FirstAttribute(LD As %Integer, Entry As %Integer, ByRef Ptr As %Integer) As %String
{
 q $$$ldapfirstattribute(LD,Entry,.Ptr)
}

/// Modify an entry in the directory tree.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// DN - String that contains the distinguished name of the entry
/// to modify. <br><br>
/// ATTR - <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> formatted with attributes to modify in the new entry.<br><br>
/// Each element in the list is a separate attribute to be modified in the new entry.<br>
/// Attribute=$lb(op,type,vals)<br>
/// op - Operation to be performed as follows:<br>
/// 0 - Add - The given values are added to the entry, creating the attribute if necessary.<br>
/// 1 - Delete - The given values are deleted from the entry, removing the attribute if no values remain. If the entire 
/// attribute is to be deleted, the mod_values field should be set to NULL ($lb("")).<br>
/// 2 - Replace - The attribute will have the listed values after the modification, having been created if necessary. If set
/// to null, then the attribute is deleted.<br> 
/// 128 - This value should be combined (ORed) with the Add/Delete/Replace value if the data to
/// be inserted is Binary (e.g. jpeg file.)<br>
/// type - Name of the attribute. Example="Telephone". <br>
/// vals - <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of the values to assign to the attribute. If this is a single entry
/// attribute, then $lb(Value), Example=$lb("617-621-0600"). If a multi-value entry, then
/// $lb(Value1,Value2,...,Valuen). <br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br> 
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Examples:<br><br>
/// s Attr1=$lb(0,"displayName",$lb(Jim Nilson))<br>
/// s Attr2=$lb(0,"telephoneNumber",$lb("617-621-0600")<br>
/// ; Replace the Objectclass attribute<br>
/// s Attr3=$lb(2,"objectClass",$lb("top","person","organizationalPerson","user")<br>
/// ;Replace Binary value for a jpeg photo<br>
/// s Attr4=$lb(130,"Photo",$lb(jpegphoto))<br>
/// ; Delete Address2 attribute<br>
/// a Attr5=$lb(1,"Address2","")<br>
/// s Attributes=$lb(Attr1,Attr2,Attr3,Attr4,Attr5) <br>
/// s DN="CN=Nilson\, Jim,OU=Users,OU=England,DC=iscinternal,DC=com"<br>
/// s Status=##Class(%SYS.LDAP).ModifyExts(LD,DN,Attributes)<br><br>
/// Note:<br>
/// Changing a password on a Windows Active Directory LDAP server.<br>
/// The user must first be created before the
/// password change can take place, and the password change must take place over an
/// encrypted channel. The password is contained in the unicodePwd attribute, and must
/// be formatted in a specific way. When initially creating the user, the unicodePwd
/// attribute must not be specified, or the creation of the user will fail.<br>
/// To format the password, a leading and trailing double quote must be added to it.
/// Then it must be converted to unicode.
/// Then when passed into the modify function, it must be passed in as a binary value,
/// with the "Replace" operation. It must be the only operation contained in the modify call; 
/// No other attribute can be changed at the same time.<br><br>
/// s password="NewPassword"<br>
/// s ChangePassword=$zcvt(""""_password_"""","o","UnicodeLittle")<br>
/// s Attr1=$lb(130,"unicodePwd",$lb(ChangePassword))<br>
/// s Attributes=$lb(Attr1)<br>
/// s Status=##Class(%SYS.LDAP).ModifyExts(LD,DN,Attributes,"","")<br><br>
/// Note: In order to change a password, the user must have binded to the LDAP server
/// with an account which has administrator privilege on the system. The password
/// which is set must also pass any length or pattern requirements imposed by the
/// security system on the LDAP server.<br><br>
/// Changing your own password on a Windows Active Directory LDAP server is similar to above, 
/// except that you need to bind to the LDAP server using your own username, and must also
/// pass in the old password with the delete attribute. These must also be the only
/// two attributes passed in the modify method.<br><br>
/// s oldpassword="OldPassword"<br>
/// s password="NewPassword"<br>
/// s ChangeOldPassword=$zcvt(""""_oldpassword_"""","o","UnicodeLittle")<br>
/// s ChangeNewPassword=$zcvt(""""_password_"""","o","UnicodeLittle")<br>
/// s Attr1=$lb(128,"unicodePwd",$lb(ChangeOldPassword))<br>
/// s Attr2=$lb(129,"unicodePwd",$lb(ChangePassword))<br>
/// s Attributes=$lb(Attr1,Attr2)<br>
/// s Status=##Class(%SYS.LDAP).ModifyExts(LD,DN,Attributes,"","")<br><br>
ClassMethod ModifyExts(LD As %Integer, DN As %String, ATTR As %List, ServerControls As %String = "", ClientControls As %String = "") As %Integer
{
 q $$$ldapmodifyexts(LD,DN,ATTR,"","")
}

/// Free the results of the last LDAP SearchExts method call.<br><br>
/// Parameter:<br><br>
/// SearchResult - Contains the results of the SearchExts method.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// When done with the search results you must free the search results
/// by calling this method.<br><br>
/// <br>Failure to do this before a call to UnBinds may cause your process to core on a future LDAP call.</b><br>
/// <br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).MsgFree(SearchResult)<br>
ClassMethod MsgFree(SearchResult As %Integer) As %Integer
{
 q $$$ldapmsgfree(SearchResult)
}

/// Return the next attribute of an Entry.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Entry - The entry whose attributes are to be stepped through, as returned by the
/// FirstEntry or NextEntry methods.<br><br>
/// Ptr (ByRef)- Used internally to track the current attribute.<br>
/// Return Values:<br><br>
/// If the function succeeds, a string containing the name of the next
/// attribute is returned.<br>
/// If the function fails, it returns "".<br>
/// The actual session error 
/// status can be returned by a call to the GetError method.<br><br>
/// Comments:<br><br>
/// Use the NextAttribute with the FirstAttribute method to step through
/// a list of attributes in the entry. Once the attribute name is returned,
/// you can call the GetValue or GetValuesLen method to return the values for that 
/// attribute.<br>
/// Pass the Ptr parameter by reference to track the current position in 
/// the entry. <br><br>
/// Examples:<br><br>
/// Loop through all attributes of an entry<br>
/// s CurrentEntry=##Class(%SYS.LDAP).FirstEntry(LD,SearchResult)<br>
/// s AttrName=##Class(%SYS.LDAP).FirstAttribute(LD,CurrentEntry,.Ptr)<br>
/// while (AttrName'="") {<br>
/// s AttrValues=##Class(%SYS.LDAP).GetValues(LD,CurrentEntry,AttrName)<br>
/// s AttrName=##Class(%SYS.LDAP).NextAttribute(LD,CurrentEntry,.Ptr)<br>
/// <br> 
ClassMethod NextAttribute(LD As %Integer, Entry As %Integer, ByRef Ptr As %Integer) As %String
{
 q $$$ldapnextattribute(LD,Entry,.Ptr)
}

/// Return the next entry of a message.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Entry - The Entry as previously returned by FirstEntry() or NextEntry().<br><br>
/// Return Values:<br><br>
/// If the method succeeds, it returns the entry.<br>
/// If no entry exists in
/// the result set, it returns 0, and a call to GetError returns 
/// $$$LDAPSUCCESS.<br>
/// If the function fails, it returns 0 and a call to GetError returns the
/// session error.<br><br>
/// Comments:<br><br>
/// Use NextEntry in conjunction with FirstEntry to step through 
/// and retrieve the list of entries from a search result chain.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).SearchExts(LD,BaseDN,$$$LDAPSCOPESUBTREE,Filter,Attributes,0,"","",2,ServerTimeout,.SearchResult)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s Entry=##Class(%SYS.LDAP).FirstEntry(LD,SearchResult)<br>
/// s Status=##Class(%SYS.LDAP).GetError(LD)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s Entry=##Class(%SYS.LDAP).NextEntry(LD,Entry)<br>
/// s Status=##Class(%SYS.LDAP).GetError(LD)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
/// s Entry=##Class(%SYS.LDAP).NextEntry(LD,Entry)<br>
/// s Status=##Class(%SYS.LDAP).GetError(LD)<br>
/// i Status'=$$$LDAPSUCCESS q Status<br>
ClassMethod NextEntry(LD As %Integer, Entry As %Integer) As %Integer
{
 q $$$ldapnextentry(LD,Entry)
}

/// Rename the distinguished name of an entry in the directory.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// DN - String that contains the distinguished name of the entry 
/// to rename.<br><br>
/// NewRDN - String that contains the new relative distinguished name.<br><br>
/// NewParent - String that contains the distinguished name of the 
/// new parent for this entry or "". This parameter enables you to
/// move the entry to a new parent container.<br><br>
/// DeleteOldRdn - 1 if the old relative distinguished name should be 
/// deleted; 0 if the old relative distinguished name should be retained.<br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br> 
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).RenameExts(LD,"CN=Nilson,OU=Users,DC=iscinternal,DC=com","CN=Nelson","",1)<br><br>
ClassMethod RenameExts(LD As %Integer, DN As %String, NewRDN As %String, NewParent As %String = "", DeleteOldRdn As %Boolean = 1, ServerControls As %String = "", ClientControls As %String = "") As %Integer
{
 q $$$ldaprenameexts(LD,DN,NewRDN,NewParent,DeleteOldRdn,"","")
}

/// Authenticate a client to a server, using a SASL mechanism.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// DN - Full distinguished name of the user to authenticate. This is
/// usually in some form similar to the following:<br><br>
/// "CN=testuser,OU=Users,OU=Cambridge,DC=mydomain,DC=com"<br><br>
/// Mechanism - Type of SASL authentication to perform. Currently only "EXTERNAL"
/// is supported. Pass "" for the DN and ClientCredentials.<br>
/// ClientCredentials - Credentials for the DN.<br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br> 
/// ServerCredentials - Server credentials.<br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br> This function should only be used on connections which
/// has been encrypted with SSL/TLS.<br><br>
/// On a Unix client, use the SetOption calls with $$$LDAPOPTXTLSCERTFILE and
/// $$$LDAPOPTXTLSKEYFILE to pass in the Public and Private key files.
/// Examples:<br><br>
/// Initialize a connection to the default Windows domain LDAP server, start the TLS connection,
/// and bind to the server.<br>
/// s LD=##Class(%SYS.LDAP).Init()<br>
/// s Status=##Class(%SYS.LDAP).StartTLSs(LD)
/// s Status=##Class(%SYS.LDAP).SASLBinds(LD,"","EXTERNAL","","","",.ServerCredentials)
ClassMethod SASLBinds(LD As %Integer, DN As %String, Mechanism As %String, ByRef ClientCredentials As %String, ServerControls As %String = "", ClientControls As %String = "", ByRef ServerCredentials As %String = "") As %Integer [ Internal ]
{
 q $$$ldapsaslbinds(LD,DN,Mechanism,ClientCredentials,ServerControls,ClientControls,ServerCredentials)
}

/// Search the LDAP directory and return a requested set of attributes for each entry.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Base - String that contains the distinguished name of the entry 
/// at which to start the search. <br><br>
/// Scope - Specifies one of the following values to indicate the 
/// scope of the search.<br><br>
/// $$$LDAPSCOPEBASE -Search the base entry only.<br> 
/// $$$LDAPSCOPEONELEVEL - Search all entries in the first 
/// level below the base entry, excluding the base entry.<br> 
/// $$$LDAPSCOPESUBTREE - Search the base entry and all 
/// entries in the tree below the base.<br><br>
/// Filter - String that specifies the search filter. <b>The search filter may need to
/// be escaped for certain characters. On Unix clients, you may get a "Bad Filter" error.
/// See the EscapeFilter() method.</b><br><br>
/// Attrs - <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> containing strings indicating which attributes to return
/// for each matching entry. Pass "" to retrieve all available attributes.<br><br>
/// AttrsOnly - A boolean value that should be zero if both attribute 
/// types and values are to be returned, 1 if only types are wanted. <br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br> 
/// Timeout - Specifies both the local search time-out value in seconds
/// and the operation time limit that is sent to the server within
/// the search request. <br><br>
/// SizeLimit - A limit on the number of entries to return from the search. 
/// A value of zero means no limit. If you set this to some value, and the number of
/// results returned by the search is more than this, then the search may return
/// a size limit exceeded error. Note that the number of entries able to be returned
/// is also controlled by a parameter on the LDAP server. If the search returns more than this
/// limit, then a size limit exceeded error will also be returned. Microsoft Active Directory
/// servers by default can return up to 1,000 entries for a search. If your search exceeds this size,
/// you can use the SearchInitPage() and GetNextPages() methods to use a paged search.
/// See <br><br>https://support.microsoft.com/en-us/help/315071/how-to-view-and-set-ldap-policy-in-active-directory-by-using-ntdsutil for more info.<br><br>
/// SearchResult (byRef) - Contains the results of the search upon completion
/// of the call.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// <b>When done with the search results you need to free the search results in
/// one of the following ways:<br><br>
/// 1) Call the MsgFree(SearchResult) method.<br>
/// 2) Call SearchExts again, and pass the SearchResult parameter back in unchanged.<br><br>
/// Failure to do this before a call to UnBinds may cause your process to core on a future LDAP call.<br><br>
/// </b>
/// Note that the caller can have several different searches "open" at the 
/// same time by using a different variable for the SearchResult parameter.<br><br>
/// Examples:<br><br>
/// Search for all users whose Windows login name starts with "steve". Return
/// their display name, e-mail and telephone number. Use a timeout of 10 seconds,
/// and return at most 20 items.<br>
/// s Status=##Class(%SYS.LDAP).SearchExts(LD,"DC=mydomain,DC=com",<br>
/// $$$LDAPSCOPESUBTREE,"sAMAccountname=steve*",<br>
/// $lb("displayName","mail","telephoneNumber"),0,"","",10,20,.SearchResult)<br><br>
/// After calling this method, the user should test for the success of the search before further examining
/// the search result as follows:<br>
/// s NumEntries=##Class(%SYS.LDAP).CountEntries(LD,SearchResult)<br>
/// i NumEntries=-1 s Status=##Class(%SYS.LDAP).GetError(LD) q Status<br>
/// i NumEntries=0 w !,"No search entries found" g SearchAgain<br>
/// <b>Note that the SearchResult buffer must be freed with MsgFree(SearchResult) even after a failed search.</b><br><br>
/// See the documentation in SimpleBindS which shows how to handle errors and retry the operation.<br>
ClassMethod SearchExts(LD As %Integer, Base As %String, Scope As %Integer, Filter As %String, Attrs As %List, AttrsOnly As %Boolean = 0, ServerControls As %String = "", ClientControls As %String = "", Timeout As %Integer = 0, SizeLimit As %Integer = 0, ByRef SearchResult As %Integer) As %Integer
{
 q $$$ldapsearchexts(LD,Base,Scope,Filter,Attrs,AttrsOnly,"","",Timeout,SizeLimit,.SearchResult)
}

/// Search the LDAP directory using a paged search and return a requested set of attributes for each entry.<br><br>
/// This is a Windows only method.<br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Base - String that contains the distinguished name of the entry 
/// at which to start the search. <br><br>
/// Scope - Specifies one of the following values to indicate the 
/// scope of the search.<br><br>
/// $$$LDAPSCOPEBASE -Search the base entry only.<br> 
/// $$$LDAPSCOPEONELEVEL - Search all entries in the first 
/// level below the base entry, excluding the base entry.<br> 
/// $$$LDAPSCOPESUBTREE - Search the base entry and all 
/// entries in the tree below the base.<br><br>
/// Filter - String that specifies the search filter.<br><br>
/// Attrs - <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> containing strings indicating which attributes to return
/// for each matching entry. Pass "" to retrieve all available attributes.<br><br>
/// AttrsOnly - A boolean value that should be zero if both attribute 
/// types and values are to be returned, 1 if only types are wanted. <br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br> 
/// Timeout - Specifies both the local search time-out value in seconds
/// and the operation time limit that is sent to the server within
/// the search request. <br><br>
/// SizeLimit - A limit on the number of entries to return from the search for each page. 
/// SortOrder - Ignored, pass as "".<br><br>
/// Return Values:<br><br>
/// Page - Contains a pointer to the initialized page of results which should be passed to the 
/// GetNextPages() method.<br><br>
/// Comments:<br><br>
/// <b>When done with the search results you need to free the search results and page the following way:<br><br>
/// 1) First call the MsgFree(SearchResult) method.<br>
/// 2) Then call the the SearchAbandonPage(LD,Page)() method.<br>
/// Failure to do this before a call to UnBinds may cause your process to core on a future LDAP call.<br><br>
/// </b>
/// Note that the caller can have several different searches "open" at the 
/// same time by using a different variable for the Page parameter.<br><br>
/// This method allows the user to perform a single search on the LDAP directory which would enought records 
/// to exceed the MaxPageSize parameter (default 1,000) on the LDAP server. An example of this would be
/// to build a phone list of all the employees in the LDAP database, where there are more than
/// 1,000 employees.<br><br>
/// Examples:<br><br>
/// Search for all users in the LDAP database. Return
/// their display name, e-mail and telephone number. Use a timeout of 5 seconds,
/// and return at most 100 items for each call to the GetNextPages() method.<br>
/// s Page=##Class(%SYS.LDAP).SearchInitPage(LD,"DC=mydomain,DC=com",<br>
/// $$$LDAPSCOPESUBTREE,"sAMAccountname=*",<br>
/// $lb("displayName","mail","telephoneNumber"),0,"","",5,100,"")<br>
/// ; Lets limit each next page to 5 entries<br>
/// s Status=##Class(%SYS.LDAP).GetNextPages(LD,Page,5,5,.TotalCount,.SearchResult)<br>
/// While (Status=$$$LDAPSUCCESS) {<br>
/// 	Set Result = ##Class(%SYS.LDAP).FirstEntry(LD, SearchResult)<br>
/// 	Set DN = ##Class(%SYS.LDAP).GetDN(tLDAPSession, Result)<br>
/// 	Write "DN = ",tDN,! ; only print the first DN in each set of 5<br>
/// 	Set Status = ##Class(%SYS.LDAP).GetNextPages(LD,Page,5,5,.TotalCount,.SearchResult)<br>
/// }<br>
/// i Status=$$$LDAPNORESULTSRETURNED {w !,"End of search"} else { w !,"Error "_Status} <br>
/// Set Status = ##Class(%SYS.LDAP).SearchAbandonPage(LD, Page)<br>
ClassMethod SearchInitPage(LD As %Integer, Base As %String, Scope As %Integer, Filter As %String, Attrs As %List, AttrsOnly As %Boolean = 0, ServerControls As %String = "", ClientControls As %String = "", Timeout As %Integer = 0, SizeLimit As %Integer = 0, SortKey As %String = "") As %Integer
{
 i $$$ISWINDOWS {
	q $$$ldapsearchinitpage(LD,Base,Scope,Filter,Attrs,AttrsOnly,"","",Timeout,SizeLimit,"")
 } else {
	q 0
 }
}

/// Free the page pointer returned by the SearchInitPage() method()
/// This is a Windows only method.<br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// When done with the search results you must free the search page
/// by calling this method.<br><br>
/// <br>Failure to do this before a call to UnBinds may cause your process to core on a future LDAP call.</b><br>
/// <br>
/// Examples:<br><br>
/// s Status=##Class(%SYS.LDAP).SearchAbandonPage(LD,Page)<br>
ClassMethod SearchAbandonPage(LD As %Integer, Page As %Integer) As %Integer
{
 q $$$ldapsearchabandonpage(LD,Page)
}

/// Set options for an LDAP session.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Option - The name of the option to set. See valid options below.<br><br>
/// InValue - Value that the option is to be given. The actual value of 
/// this parameter depends on the setting of the option parameter. 
/// The constants $$$LDAP_OPT_ON and $$$LDAP_OPT_OFF can be given for options
/// that have on or off settings.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, the return value is $$$LDAPSUCCESS.<br>
/// If the function fails, it returns an error code.<br><br>
/// <br>
/// $$$LDAPOPTXTLSNEWCTX - Clears the current SSL/TLS context for the process. If you have called SetOption with any of the
/// LDAPOPTXTLS* parameters below, and then need to change that option, you need to first clear the previous SSL/TLS settings
/// with this option.<br><br>
/// $$$LDAPOPTXTLSCACERTFILE - Directory and name of TLS certificate.
/// The certificate needed is that of the certificate authority that signed 
/// the certificate of the LDAP server. It needs to be in .PEM format. Available on Unix only.<br><br>
/// $$$LDAPOPTXTLSCERTFILE - Directory and name of Client X.509 certificate. Available on Unix only.<br><br>
/// $$$LDAPOPTXTLSKEYFILE - Directory and name of the Client X.509 certificate private key. 
/// Notes: Private keys with passwords are not supported by openldap (see the man pages). Available on Unix only.<br><br>
/// $$$LDAPOPTNETWORKTIMEOUT - Sets the network timeout value after which poll/select
/// following a connect returns in case of no activity. Specifying seconds set to 0 results
/// in an infinite timeout, which is the default. Normally there is no need to change the default.
/// This is available on Unix platforms only.<br><br>
/// $$$LDAPOPTTIMEOUT - Sets the timeout value for the synchronous API calls. 
/// Specifying seconds set to 0 results in an infinite timeout, which is the default.
/// Normally there is no need to change the default. This is available on Unix platforms only.<br><br>
/// Examples:<br><br>
/// Set location of TLS certificate for TLS connection:<br>
/// s Status=##Class(%SYS.LDAP).SetOption(LD,$$$LDAPOPTXTLSCACERTFILE,"/usr/share/ssl/certs/ldapserver.pem")<br><br>
/// Note: Previous versions allowed the option $$$LDAPOPTPROTOCOLVERSION and 
/// $$$LDAPOPTREFERRALS to be specified.
/// These options are deprecated. SetOption calls using this option will be ignored and always will
/// return success. Version is now always set to 3, and referrals are always turned off.<br><br>
/// Note: If you set the TLS options on a Unix client, then issue a StartTLS call
/// to an LDAP server then Unbind the connection, the previous TLS settings 
/// will remain active even
/// if the SetOption call is subsequently made with a different certificate. Subsequent LDAP
/// StartTLS calls will use the SetOption values from the first StartTLS call until the InterSystems IRIS process exits.
/// To reset to a different certificate, You need to call:<br>
/// s Status=##Class(%SYS.LDAP).SetOption(LD,$$$LDAPOPTXTLSNEWCTX,0) ; Clear prior certificate<br>
/// s Status=##Class(%SYS.LDAP).SetOption(LD,$$$LDAPOPTXTLSCACERTFILE,"/usr/share/ssl/certs/newcert.pem")<br><br>
/// Note that if you have not previously created a SSL connection, the $$$LDAPOPTXTLSNEWCTX option will return an error.
/// Depending on the structure of your code, it might be better to call this immediately before you call UnBind().
/// 
ClassMethod SetOption(LD As %Integer, Option As %Integer, InValue As %String) As %Integer
{
 q $$$ldapsetoption(LD,Option,InValue)
}

/// Authenticate a client to a server, using a plaintext password.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// DN - Full distinguished name of the user to authenticate. This is
/// usually in some form similar to the following:<br><br>
/// "CN=testuser,OU=Users,OU=Cambridge,DC=mydomain,DC=com"<br><br>
/// Password - Password for the DN.<br>
/// NOTE: If the password used is a NULL string, then the SimpleBinds function
/// will attempt to do an "unauthenticated" bind to the LDAP server. If unauthenticated binds are
/// allowed by the server, then SimpleBinds will allways succeed when a NULL password is
/// passed. If you are using this method to authenticate a user entered password, then before
/// calling this function you must make sure that the password entered is not NULL.<br>
/// if you wish to do an LDAP "anonymous" bind, pass a null username and password into this
/// method.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br> This function should only be used on connections which
/// has been encrypted with SSL/TLS as it sends plaintext usernames and passwords
/// across the channel.<br><br>
/// Examples:<br><br>
/// Initialize a connection to the default Windows domain LDAP server, start the TLS connection,
/// and bind to the server.<br>
/// s LD=##Class(%SYS.LDAP).Init()<br>
/// s Status=##Class(%SYS.LDAP).StartTLSs(LD)<br>
/// ;If using for authentication of the user, make sure the password entered is not null.<br>
/// i PW="" w !,"LDAP password cannot be null" q<br>
/// s Status=##Class(%SYS.LDAP).SimpleBinds(LD,DN,PW)<br><br>
/// Perform an Anonymous bind.<br>
/// s Status=##Class(%SYS.LDAP).SimpleBinds(LD,"","")<br><br>
/// Perform an Unauthenticated bind.<br>
/// s Status=##Class(%SYS.LDAP).SimpleBinds(LD,DN,"")<br><br>
/// Sometimes a Bind or other LDAP operation may fail with a "Server Down" error on Unix (-1). This is sometimes
/// because one of the system calls is interrupted by a Unix signal or temporary network glitch. In cases like this,
/// the operation can usually be retried: <br><br>
/// <pre>
/// RetryInit
///  s LD=##Class(%SYS.LDAP).Init()
///  s Status=##Class(%SYS.LDAP).StartTLSs(LD)
///  s Status=##Class(%SYS.LDAP).SimpleBinds(LD,Username,Password)
///  i Status'=$$$LDAPSUCCESS {
/// 	d CloseServer
/// 	i Status=$$$XLDAPSERVERDOWN {
/// 		i RetryCount<5 {
/// 			s RetryCount=RetryCount+1 
/// 			h .5 
/// 			g RetryInit
/// 		}
/// 	}
/// 	s Status=$$$ERROR($$$LDAPInvalidPassword,Status,##Class(%SYS.LDAP).Err2String(Status)_":"_$g(ErrString))
/// 	g LDAPError
///  }
/// .....
/// CloseServer
/// #;Make sure we free the search buffers here. If we don't we may crash in the unbind on some
/// #;unix boxes.
///  i $d(SearchResult) {
/// 	 Try {
/// 		 d ##Class(%SYS.LDAP).MsgFree(SearchResult)
/// 		 k SearchResult
/// 	 } catch {}
///  }
///  i $d(LD) {
/// 	 Try {
/// 		 s Status1=##Class(%SYS.LDAP).UnBinds(LD)
/// 		 k LD
/// 	 } catch {}
///  }
///  q
/// </pre>
ClassMethod SimpleBinds(LD As %Integer, DN As %String, Password As %String) As %Integer
{
 s $zt="Error"
 q $$$ldapsimplebinds(LD,DN,Password)
Error s $zt=""
 i $ze["<ZPASS" q $$$LDAPINVALIDCREDENTIALS
 ztrap $ze
}

/// Start using TLS encryption on an active LDAP session.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// In order to use TLS, the client needs to have a certificate installed on
/// it.
/// For Windows systems, the certificate needs to be installed in the
/// Windows certificate database.<br>
/// Note for Unix, the certificate needs to be copied to the system, and
/// the SetOption method must be called to load the certificate. The certificate 
/// must be in .PEM format.<br><br>
/// Examples:<br><br>
/// This example starts a TLS connection on a Unix machine.<br>
/// s LD=##Class(%SYS.LDAP).Init("myldapserver.example.com")<br>
/// s Status=##Class(%SYS.LDAP).SetOption(LD,$$$LDAPOPTXTLSCACERTFILE,"/usr/share/ssl/certs/ldapserver.pem")<br>
/// s Status=##Class(%SYS.LDAP).StartTLSs(LD)<br>
ClassMethod StartTLSs(LD As %Integer) As %Integer
{
 q $$$ldapstarttlss(LD,"","","","")
}

/// Stop using TLS encryption on an active LDAP session.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// This is a Windows only method and is not supported under Unix.<br>
ClassMethod StopTLSs(LD As %Integer) As %Integer
{
 q $$$ldapstoptlss(LD)
}

/// End an LDAP session and frees its resources.<br><br>
/// Parameters:<br><br>
/// LD - The session handle returned by the Init method.<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Comments:<br><br>
/// Call this method whenever you are finished with an LDAP session
/// and have an LD handle to pass to it.<br>
ClassMethod UnBinds(LD As %Integer) As %Integer
{
 q $$$ldapunbinds(LD)
}

ClassMethod Get(Name As %String, ByRef Properties As %String) As %Status [ Internal ]
{
 $$$AddAllRoleTemporary ; Verified 10/17/17 STC
 n $namespace
 s $namespace="%SYS"
 Set Status = ##class(Security.LDAPConfigs).Get(Name,.Properties)
 q Status
}

/// List of LDAPConfigs.<br>
/// Names - Comma separated list of LDAP names, "*" = All<br>
/// Flags - 0 - Use "Startswith" as the selection on the name.<br>
/// Flags - 1 - Use "Contains" as the selection on the name.<br>
/// Note: This query may change in future versions<br>
Query List(Names As %String = "*", Flags As %Integer = 0) As %Query(ROWSPEC = "Name:%String,LDAP Enabled:%String,Description") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef %qHandle As %Binary, Names As %String = "*", Flags As %Integer = 0) As %Status [ Internal ]
{
 #EXECUTE s %msqlvar="%qHandle" 
 i Flags=0 {
	&SQL(DECLARE LDAPConfigsListCursor CURSOR for 
		SELECT Name,LDAPFlags,Description
		FROM Security.LDAPConfigs
 		WHERE (%SYSTEM.Util_CheckName(:Names,Name)=1)
		ORDER BY Name)
 #EXECUTE k %msqlvar
	&SQL(OPEN LDAPConfigsListCursor)
 } else {
	&SQL(DECLARE LDAPConfigsListCursor0 CURSOR for 
		SELECT Name,LDAPFlags,Description
		FROM Security.LDAPConfigs
 		WHERE (%SYSTEM.Util_CheckNameContains(:Names,Name)=1)
		ORDER BY Name)
 #EXECUTE k %msqlvar
	&SQL(OPEN LDAPConfigsListCursor0)
 }
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 s %qHandle("Flags")=Flags
 Quit $$$OK
}

ClassMethod ListFetch(ByRef %qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListExecute ]
{
 i %qHandle("Flags")=0 {
	&SQL(FETCH LDAPConfigsListCursor
		INTO :Name,:LDAPFlags,:Description)
 } else {
	&SQL(FETCH LDAPConfigsListCursor0
		INTO :Name,:LDAPFlags,:Description)
 }
 	if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
	If SQLCODE=100 {
		Set Row="",AtEnd=1
	} Else {
		s Enabled=$zb(LDAPFlags,$$$LDAPEnabled,1)=$$$LDAPEnabled
		Set Row=$LB(Name,##Class(Security.Datatype.BooleanYN).LogicalToDisplay(Enabled),Description)
		Set AtEnd=0
	}
	Quit $$$OK
}

ClassMethod ListClose(ByRef %qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListExecute ]
{
 i %qHandle("Flags")=0 {
	&SQL(CLOSE LDAPConfigsListCursor)
 } else {
	&SQL(CLOSE LDAPConfigsListCursor0)
 }
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
}

}
