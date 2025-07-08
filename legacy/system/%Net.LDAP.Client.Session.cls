/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (LDAPCli, %syLDAPFunc)

/// WARNING: This class and its methods are all deprecated; please use <class>%SYS.LDAP</class> class instead.
Class %Net.LDAP.Client.Session Extends %RegisteredObject [ Deprecated, ServerOnly = 1, System = 4 ]
{

/// Cleanup Get Values to return Cos %RawString and type overwrite using args
/// 
/// Session ID
Property SessionID As %Integer [ Internal ];

/// Shared library ID
Property SharedLibID As %Integer [ Internal ];

/// Search attributes only (Return no value)
Property SearchAttrsOnly As %Integer;

/// If set indicates that LDAP should chase 
/// referrals/references returned in a search 
Property Referrals As %Integer;

/// Size limit
Property MaxItems As %Integer;

Property ConvertFormat As %String [ Internal ];

/// Lib/DLL version function.
Property FNLibVer As %Integer [ Internal ];

/// Init function.
Property FNInit As %Integer [ Internal ];

/// Connect Function
Property FNConnect As %Integer [ Internal ];

/// SASL Connect Function
Property FNSASLConnect As %Integer [ Internal ];

/// Close Function
Property FNClose As %Integer [ Internal ];

/// GetLastError function
Property FNGetLastErr As %Integer [ Internal ];

/// GetLastError function
Property FNGetLastLibErr As %Integer [ Internal ];

/// GetErrStr function
Property FNGetErrStr As %Integer [ Internal ];

/// Add function
Property FNAdd As %Integer [ Internal ];

/// Delete function
Property FNDelete As %Integer [ Internal ];

/// Search entry(s) function
Property FNSearch As %Integer [ Internal ];

/// Delete Entry function
Property FNRelEntry As %Integer [ Internal ];

/// Get first entry
Property FNFirstEntry As %Integer [ Internal ];

/// Get next entry
Property FNNextEntry As %Integer [ Internal ];

/// Get next entry 
Property FNGetEntryAttr As %Integer [ Internal ];

/// Delete Entry Name/DN 
Property FNGetEntryDN As %Integer [ Internal ];

/// Get next entry  
Property FNRelAttrib As %Integer [ Internal ];

/// Get attribute value function ID
Property FNAttribValue As %Integer [ Internal ];

/// Get attribute name function ID
Property FNAttribName As %Integer [ Internal ];

/// An entry first and next attribute iterator.
Property FNFirstAttrib As %Integer [ Internal ];

Property FNNextAttrib As %Integer [ Internal ];

Property FNRelBigObj As %Integer [ Internal ];

Property FNAddRefBigObj As %Integer [ Internal ];

Property FNNewBigObj As %Integer [ Internal ];

Property FNGetSubObj As %Integer [ Internal ];

Property FNAppendObj As %Integer [ Internal ];

Property FNRename As %Integer [ Internal ];

Property FNCompare As %Integer [ Internal ];

Property FNCommitChanges As %Integer [ Internal ];

Property FNGetFormat As %Integer [ Internal ];

/// Destructor
Method %OnClose() As %Status [ Internal ]
{
 i $$$USELDAPCLI {
	;w "Close",!
	if (+..SharedLibID) {
		d:(..FNClose'=0) $ZF(-5, ..SharedLibID, ..FNClose, ..SessionID)
		// Note: The shared lib is not ref-counted
		// keep the shared lib.. other instance might be using it..
	}
 	q $$$OK
 } else {
 s Status=##Class(%SYS.LDAP).UnBinds(..SessionID)
 q $$$OK
 }
}

/// Constructor
Method %OnNew() As %Status [ Internal ]
{
 i $$$USELDAPCLI {
	;w "New obj",!
	s ..SharedLibID=0
	s ..ConvertFormat="UTF8"
	q $$$OK
 } else {
	q $$$OK
 }
}

/// Init LDAP client interface.
/// 
Method Init(Server As %String, port As %Integer) As %Status [ Internal ]
{
 i $$$USELDAPCLI {
	if (+..SharedLibID=0) {
		s $ZT="errorTrap",..SharedLibID=0
		set libname=$$$LDAPLIBRARY_$s($zv["Windows":".dll",$zv["UNIX":".so",$zv["VMS":".exe",1:".dll") 
		Set ..SharedLibID=$zf(-4,1,$g(^%SYS("bindir"))_libname)
		;W !,"Connect: using shared lib ",..SharedLibID,!
errorTrap
		s $zt=""
		Quit:(..SharedLibID=0) $$$ERROR($$$LDAPLoadFailed,$g(^%SYS("bindir"))_libname)
		set ..FNLibVer=$ZF(-4,3,..SharedLibID,"LDAPLibVer")
		set libver=$ZF(-5, ..SharedLibID, ..FNLibVer)
		Quit:(libver '= $$$kLDAPLibVersion) $$$ERROR($$$LDAPInvalidLib, $$$kLDAPLibVersion,libver)
		;; The following functions #'s will go away when the DLL is stabilized
		set ..FNInit=$ZF(-4,3,..SharedLibID,"LDAPInit")
		set ..FNConnect=$ZF(-4,3,..SharedLibID,"LDAPConnect")
		set ..FNSASLConnect=$ZF(-4,3,..SharedLibID,"LDAPSASLConnect")
		set ..FNClose=$ZF(-4,3,..SharedLibID,"LDAPClose")
		set ..FNGetLastErr=$ZF(-4,3,..SharedLibID,"LDAPGetLastErr")
		set ..FNGetLastLibErr=$ZF(-4,3,..SharedLibID,"LDAPGetLibErr")
		set ..FNGetErrStr=$ZF(-4,3,..SharedLibID,"LDAPGetErrStr")
		set ..FNAdd=$ZF(-4,3,..SharedLibID,"LDAPAdd")
		set ..FNDelete=$ZF(-4,3,..SharedLibID,"LDAPDelete")
		set ..FNSearch=$ZF(-4,3,..SharedLibID,"LDAPSearch")
		set ..FNRelEntry=$ZF(-4,3,..SharedLibID,"LDAPRelEntry")
		set ..FNFirstEntry=$ZF(-4,3,..SharedLibID,"LDAPFirstEntry")
		set ..FNNextEntry=$ZF(-4,3,..SharedLibID,"LDAPNextEntry")
		set ..FNGetEntryAttr=$ZF(-4,3,..SharedLibID,"LDAPGetEntryAttr")
		set ..FNRelAttrib=$ZF(-4,3,..SharedLibID,"LDAPRelAttr")
		set ..FNGetEntryDN=$ZF(-4,3,..SharedLibID,"LDAPGetEntryDN")
		set ..FNAttribName=$ZF(-4,3,..SharedLibID,"LDAPAttribName")
		set ..FNAttribValue=$ZF(-4,3,..SharedLibID,"LDAPAttribValue")
		set ..FNFirstAttrib=$ZF(-4,3,..SharedLibID,"LDAPAttribFirst")
		set ..FNNextAttrib=$ZF(-4,3,..SharedLibID,"LDAPAttribNext")
		Set ..FNRelBigObj=$ZF(-4,3,..SharedLibID,"LDAPRelBigObj")
		Set ..FNAddRefBigObj=$ZF(-4,3,..SharedLibID,"LDAPAddRefBigObj")
		Set ..FNNewBigObj=$ZF(-4,3,..SharedLibID,"LDAPNewBigObj")
		Set ..FNGetSubObj=$ZF(-4,3,..SharedLibID,"LDAPGetSubObj")
		Set ..FNAppendObj=$ZF(-4,3,..SharedLibID,"LDAPAppendObj")
		Set ..FNRename=$ZF(-4,3,..SharedLibID,"LDAPRename")
		Set ..FNCompare=$ZF(-4,3,..SharedLibID,"LDAPCompare")
		Set ..FNCommitChanges=$ZF(-4,3,..SharedLibID,"LDAPCommitChanges")
		Set ..FNGetFormat=$ZF(-4,3,..SharedLibID,"LDAPGetAPIFormat")
	}
	if (+..SessionID=0) {
		;W !,"Connect: Initing session ",..FNInit
		q:(..FNInit=0)||(..FNGetFormat=0) $$$ERROR($$$LDAPInvalidLib, $$$kLDAPLibVersion,-1)
		s ..ConvertFormat=$ZF(-5, ..SharedLibID, ..FNGetFormat)
		q:(..ConvertFormat="") $$$ERROR($$$LDAPInvalidLib, $$$kLDAPLibVersion,-1)
		s ..SessionID=$ZF(-5, ..SharedLibID, ..FNInit, ..ConvertToPlatStr(Server), +port)
		q:..SessionID=0 ..GetLastError()
	}
	q $$$OK
 } else {
 s LD=##Class(%SYS.LDAP).Init(Server,+port)
 s ..SessionID=LD
 i LD=0 q ..GetLastError()
 q $$$OK
 }
}

/// Establish connection to a LDAP server. You have to connect first before invoking other methods.
/// 
Method Connect(Server As %String = "127.0.0.1", port As %Integer = 0, UserName As %String = "", Password As %String = "", UseSSL As %Boolean = 0) As %Status
{
 i $$$USELDAPCLI {
	if (+..SessionID=0) {
		Set comp=..Init(Server,port)
		Quit:(comp'=$$$OK) comp
	}
	q:..FNConnect=0 $$$ERROR($$$LDAPInvalidLib, $$$kLDAPLibVersion,-2)
	s comp=$ZF(-5, ..SharedLibID, ..FNConnect, ..SessionID,
			 ..ConvertToPlatStr(UserName), ..ConvertToPlatStr(Password),
			 +..Referrals)
	q:(comp=0) ..GetLastError()
	q $$$OK
 } else {
 if (+..SessionID=0) {
	Set comp=..Init(Server,port)
	Quit:(comp'=$$$OK) comp
 }
 s Status=##class(%SYS.LDAP).SimpleBinds(..SessionID,UserName,Password)
 i Status'=$$$LDAPSUCCESS q ..GetLastError()
 q $$$OK
 }
}

/// Authenticates client to an LDAP server using a SASL 
/// (Simple Authentication and Security Layer) mechanism.
/// <a href=http://www.ietf.org/rfc/rfc2222.txt>(see RFC2222).</a>
/// <p>Note: The LDAP server must support that SASL mechanism for authentication.</p>
/// <p>You have to connect first before invoking any methods.</p>
/// <p>If the server sends a challenge to your client, check the 
/// <b>ServerData</b> argument for the server's challenge. Call the <b>SASLConnect()</b> method again to send a
/// response to that challenge. </p>
/// <p>Example: </p>
/// <p>set comp=SASLConnect("localhost",0,"uid=u123,ou=people,o=isctest.com","abcMechanism","secret",srvData)</p>
/// <p>write:(comp=$$$OK) "Server credential is : ",srvData,!</p>
Method SASLConnect(Server As %String = "127.0.0.1", port As %Integer = 0, DistinguishedName As %String = "", AuthMechanism As %String, Credentials As %String, ByRef ServerData As %String) As %Status
{
 i $$$USELDAPCLI {
	if (+..SessionID=0) {
		Set comp=..Init(Server,port)
		Quit:(comp'=$$$OK) comp
	}
	;w !,"SASLConnect: Connecting!! ",..FNSASLConnect,!
	q:..FNSASLConnect=0 $$$ERROR($$$LDAPInvalidLib, $$$kLDAPLibVersion,-3)
	s ret=$ZF(-5, ..SharedLibID, ..FNSASLConnect, ..SessionID,
			 ..ConvertToPlatStr(DistinguishedName),
			 ..ConvertToPlatStr(AuthMechanism),Credentials,
			 +..Referrals)
	s comp=$a(ret)
	W "SASL connect comp == 0x0",$zh(comp)
	q:(comp=0) ..GetLastError()
	s ServerData=$e(ret,2,$l(ret)) ;; last byte is $l + 1
	;; if comp = 1,<Server's challenge>
	q:(comp=1) $$$ERROR($$$LDAPSASLChallenge)
	;; otherwise the comp==2  -- the client is successfully authenticated
	Set ServerData=$P(comp,",",2)
	q $$$OK
 } else {
#;Note that this is not currently supported
 q $$$ERROR($$$LDAPSASLChallenge)
 }
}

/// Create a new entry
Method AddNewEntry(DN As %String, attribs As %Net.LDAP.Client.PropList) As %Status
{
 i $$$USELDAPCLI {
	q:(+..SessionID=0) $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
	q:(attribs.Parent'=$this) $$$ERROR($$$LDAPNotParent)
	set k = 0
	;w !,"AddNewEntry: Add Entry(",DN,") With the following attributes:"
	;for {
	 ;if attribs.GetNext(.k)=0 q
	 ;write !,"AddNewEntry: attrib(",attribs.GetAttrib(k),") Value(",attribs.GetValue(k),")"
	;}
	;W !,"attrib name list",! zzdump attribs.NameList.NameList
	;W !,"attrib value list",! zzdump attribs.ValueList
	;W !,"attrib type list",! zzdump attribs.TypeList
	;W !
	If (..FNAdd=0) $$$LDAPRaiseException
	s comp=$ZF(-5, ..SharedLibID, ..FNAdd, ..SessionID,
			 ..ConvertToPlatStr(DN),attribs.NameList.NameList,
			 attribs.ValueList,attribs.TypeList)
	q:(comp=0) ..GetLastError()
	q $$$OK
 } else {
 q:(+..SessionID=0) $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
 q:(attribs.Parent'=$this) $$$ERROR($$$LDAPNotParent)
 s Status=$$$LDAPAddExtSCompat(..SessionID, DN, attribs.NameList.NameList,attribs.ValueList,attribs.TypeList)
 i Status'=$$$LDAPSUCCESS q ..GetLastError()
 q $$$OK
 }
}

/// Delete an entry
Method DeleteEntry(DN As %String) As %Status
{
 i $$$USELDAPCLI {
	q:+..SessionID=0 $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
	If (..FNDelete=0) $$$LDAPRaiseException
	s comp=$ZF(-5, ..SharedLibID, ..FNDelete, ..SessionID, ..ConvertToPlatStr(DN))
	q:(comp=0) ..GetLastError()
	q $$$OK
 } else {
 q:+..SessionID=0 $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
 s Status=##Class(%SYS.LDAP).DeleteExts(..SessionID,DN,"","")
 i Status'=$$$LDAPSUCCESS q ..GetLastError()
 q $$$OK
 }
}

/// Rename an entry
/// <p><b>DN</b> <b>D</b>istinguished <b>N</b>ame of the entry<p>
/// <p><b>NewRDN</b> New <b>R</b>elative <b>D</b>istinguished <b>N</b>ame to assign to the entry</p>
/// <p><b>NewParent</b> DN of the new parent to move the entry under. 
/// Pass "" if you do not want to move the entry to a different location.</p>
/// <p><b>DelOldRDN</b> If 0, the old RDN is retained as an attribute in the modified entry </p>
Method RenameEntry(DN As %String, NewRDN As %String, NewParent As %String = "", DelOldRDN As %Boolean = 0) As %Status
{
 i $$$USELDAPCLI {
	q:+..SessionID=0 $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
	If (..FNRename=0) $$$LDAPRaiseException
	s comp=$ZF(-5, ..SharedLibID, ..FNRename, ..SessionID, ..ConvertToPlatStr(DN),
				..ConvertToPlatStr(NewRDN), ..ConvertToPlatStr(NewParent), +DelOldRDN) 
	q:(comp=0) ..GetLastError()
	q $$$OK
 } else {
 q:+..SessionID=0 $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
 s Status=##Class(%SYS.LDAP).RenameExts(..SessionID,DN,NewRDN,NewParent,+DelOldRDN,"","")
 i Status'=$$$LDAPSUCCESS q ..GetLastError()
 q $$$OK
 }
}

/// Comapre an entry attribute value
/// <p><b>DN</b> <b>D</b>istinguished <b>N</b>ame of the entry.<p>
/// <p><b>Attrib</b> Attribute to compare its value.</p>
/// <p><b>Value</b> The value to compare with.</p>
/// <p><b>Binary</b> True if the value is binary.</p>
Method CompareEntryValue(DN As %String, Attrib As %String, Value As %RawString, Binary As %Boolean = 0) As %Boolean
{
 i $$$USELDAPCLI {
	q:+..SessionID=0 $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
	If (..FNCompare=0) $$$LDAPRaiseException
	if ($IsObject(Value)) q $$$ERROR(LDAPUnknownObj) ;; < 32k objs could be compared for now!!
	if ('Binary) s Value=..ConvertToPlatStr(Value)
	s comp=$ZF(-5, ..SharedLibID, ..FNCompare, ..SessionID, ..ConvertToPlatStr(DN),
				..ConvertToPlatStr(Attrib), Value, +Binary) 
	q:(comp=0) 0
	q:(comp=1) 1
	q ..GetLastError()
 } else {
 q:+..SessionID=0 $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
 s Status=$$$LDAPCompareExtSCompat(..SessionID, DN, Attrib, Value, +Binary)
 i Status=$$$LDAPCOMPAREFALSE q 0
 i Status=$$$LDAPCOMPARETRUE q 1
 q ..GetLastError()
 }
}

/// Edit/Modify current entry attributes.
/// <p>Returns EditEntry object, use the returned object to modify the attributes</p> 
Method EditEntry(DN As %String) As %Net.LDAP.Client.EditEntry
{
	s x=##class(%Net.LDAP.Client.EditEntry).%New()
	s x.Parent=$this
	s x.DN=..ConvertToPlatStr(DN)
	s x.Q=..GetPropList()
	q x
}

/// Get $list of supported controls, and extensions
Method TestDispControlList() As %Status [ Internal ]
{
		;; build a list of desired attributes 
	set sl=..GetStringList()
 	d sl.InsertStr("supportedControl","supportedExtension","supportedSASLMechanisms","supportedLDAPVersion","altServer","namingContexts")
 	;; d sl.InsertStr("supportedControl","supportedExtension")
	Set ents=..Search("",0, "(ObjectClass=*)",sl,1000)
	if ('$IsObject(ents)) {
		w "No entries!!",!
		q ents
	} else {
		s entDN=""
      	s ent=ents.GetNext(.entDN)
      	if ($IsObject(ent)) {
			s count=$i(count)
      		w " ",count," - Entry(",entDN,")",!
      		set attrNM=""
      		f  { ; iterate through each attribute of an entry
		      	s val=ent.GetNext(.attrNM)
		      	q:(attrNM="")
		      	w "   Attr(",attrNM,")",!
		      	;; iterate through values associated with each attribute
		      	f i=1:1:val.GetNumItems() { 
		      		w "     ",i," - Value(",val.GetValue(i),")",!
		      	}
      		}
     	}
  	}
	q $$$OK
}

/// Return last error associated with this session
Method GetLastError(ByRef errNum As %Integer = 0, ByRef errStr As %String = "") As %Status [ Internal ]
{
 i $$$USELDAPCLI {
	if (+..SharedLibID) {
		s errNum=$ZF(-5, ..SharedLibID, ..FNGetLastErr, ..SessionID)
		if ('errNum) {
			s errNum=$ZF(-5, ..SharedLibID, ..FNGetLastLibErr, ..SessionID)
			if (errNum=1) { // kErrMallocFailed
				q $$$ERROR($$$LDAPOutOfHeap)
			} elseif (errNum=3) { // kErrTooManyItems
				q $$$ERROR($$$LDAPOverflow)
			} elseif (errNum=4) { // kErrUnknownObj
				q $$$ERROR($$$LDAPUnknownObj)
			} else { // errnum 2 kErrInternalErr || unexpected!!
				q $$$ERROR($$$LDAPInvalidLib)
			}
		} else {
			s errStr=$ZF(-5, ..SharedLibID, ..FNGetErrStr, errNum)
			q $$$ERROR($$$LDAPerror,errNum,..ConvertFromPlatStr(errStr))
		}
	} else {
		q $$$ERROR($$$LDAPNotInited)
	}
 } else {
 q:+..SessionID=0 $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
 s errNum=##Class(%SYS.LDAP).GetError(..SessionID)
 s errStr=##Class(%SYS.LDAP).Err2String(errNum)
 q $$$ERROR($$$LDAPerror,errNum,errStr)
 }
}

/// Return a new prop list object. 
/// Used to maintain attribute and value pairs.See %Net.LDAP.Client.PropList object.
Method GetPropList() As %Net.LDAP.Client.PropList
{
	s x=##class(%Net.LDAP.Client.PropList).%New()
	s x.Parent=$this
	q x
}

/// Return a new StringList list object. 
/// Used to maintain a list of strings i.e. list of attributes.
Method GetStringList() As %Net.LDAP.Client.PropList
{
	q ##class(%Net.LDAP.Client.StringList).%New($this)
}

/// Return a new value list object.
/// Value list is used to associate multiple values with an attribute.
/// See %Net.LDAP.Client.ValueList Object.
Method GetValueList(binary As %Boolean = 0) As %Net.LDAP.Client.ValueList
{
	s x=##class(%Net.LDAP.Client.ValueList).%New()
	s x.Parent=$this
	s x.Binary=binary
	q x
}

/// Search LDAP DB
/// <b>base</b>: search base
/// <p><b>scope</b>: 0==search base, 1==search one level,  2==search subtree</P>
/// <p><b>filter</b>: the search criteria <a href=http://www.ietf.org/rfc/rfc2254.txt>(see RFC2254).</a></P>
/// <p><b>attrs</b>: list of attributes to return per found entry.</P>
/// If search fails the returned value is $$$ISERR
Method Search(base As %String, scope As %Net.LDAP.Client.Search.Scope = 2, filter As %String, attrs As %Net.LDAP.Client.StringList = "", timeout As %Integer = 10000) As %Net.LDAP.Client.Entries
{
 i $$$USELDAPCLI {
	q:((+..SharedLibID=0)||(+..FNSearch=0)) $$$ERROR($$$LDAPNotInited)
	s result=$ZF(-5, ..SharedLibID, ..FNSearch,..SessionID,
		..ConvertToPlatStr(base),scope,..ConvertToPlatStr(filter),
		attrs.NameList,timeout,..MaxItems,..SearchAttrsOnly)
	q:(result=0) ..GetLastError()
	s entry=##class(%Net.LDAP.Client.Entries).%New()
	s entry.Parent=$this
	s entry.ResultSet=result
	q entry
 } else {
 q:+..SessionID=0 $$$ERROR($$$LDAPNotInited) ;; session is not initted/connected
#;Attributes are already in platform format, unconvert it before we call search.
 i attrs'="" {
	 s Attributes=$$ConvertFromPlatformList(attrs.NameList)
 } else {
	s Attributes=""
 }
 s Status=##Class(%SYS.LDAP).SearchExts(..SessionID,base,scope,filter,Attributes,+..SearchAttrsOnly,"","",timeout,..MaxItems,.result)
 i Status'=$$$LDAPSUCCESS q ..GetLastError()
 s entry=##class(%Net.LDAP.Client.Entries).%New()
 s entry.Parent=$this
 s entry.ResultSet=result
 q entry
 }
}

Method ConvertFromPlatStr(s As %String) As %String [ Internal ]
{
 i $$$USELDAPCLI {
	if (..ConvertFormat="UTF8") {
		// standard format.. singe byte nil char
		q:($l(s)>1) $zconvert($e(s,1,$l(s)-1),"i",..ConvertFormat)
	} else {
		// two byte terminator
		q:($l(s)>2) $zconvert($e(s,1,$l(s)-2),"i",..ConvertFormat)
	}
	q ""
 } else {
 q $$ConvertFromPlatformString(s)
 }
}

Method ConvertToPlatStr(s As %String, term As %Boolean = 1) As %String [ Internal ]
{
 i $$$USELDAPCLI {
	if (term) { s term=$C(0) 
	} else { s term="" }
	q $zconvert(s_term,"o",..ConvertFormat)
 } else {
 q $$$ConvertToPlatformString(s)
 }
}

ClassMethod TestConnect(testnum As %Integer = 0, ByRef DC As %String, pwd As %String) As %Integer [ Internal ]
{
	s err=""
	s x=##class(%Net.LDAP.Client.Session).%New()
	s x.Referrals=1
	w !,"Job num = ",$J
	if (testnum) {
		set:('$d(DC)) DC="CN=Users,DC=development,DC=iscinternal,DC=com"
		set host="developmentad",user="CN=administrator"
	} else {
		set:('$d(DC)) DC="DC=testldap,DC=com"
		set host="lx2",user="CN=admin"
	}
	w !,"host[",host,"] ?"
	r zz
	s:($l(zz)) host=zz
	w !,"DC[",DC,"] ?"
	r zz
	s:($l(zz)) DC=zz
	s user=user_","_DC
	w !,"user[",user,"] ?"
	r zz
	s:($l(zz)) user=zz
	if ('$data(pwd)) {
		w !,"Password ? "
		r pwd
	}
	w !,"Connecting to <",host,">, user <",user,">, pwd <",pwd,">"
	w !,"To connect Enter <CR>"
	read zz
	s c=x.Connect(host,0,user,pwd, 0)
	IF ($$$ISERR(c)) {
		d DecomposeStatus^%apiOBJ(c,.err)
		W !,"Failed to connect : err : ", err(err),!
		q ""
	}
	w !,"Connected to (",DC,")",!
	q x
}

ClassMethod TestCreateDN(x As %Net.LDAP.Client.Session, DC As %String, ByRef cn As %String) As %String [ Internal ]
{
	;; Build attributes to be added to the entry
	s p=x.GetPropList()
	s c=p.Insert("objectclass","organizationalRole") w:(c'=$$$OK) "objclass attrib insert failed!!",!
	s gktt="description"  ;; Test attrib
	s gkttv="Initial Test string "
	f i=1:1:5 s gkttv=gkttv_" "_i_", "
	s c=p.Insert(gktt,gkttv) w:(c'=$$$OK) "1-'"_gktt_"' attrib insert failed!!",!
	; s c=p.Insert(gktt,"Test 2"_gkttv) w:(c'=$$$OK) "2-'"_gktt_"' attrib insert failed!!",!
	; s c=p.Insert(gktt,"Test 3"_gkttv_$char(0),1) w:(c'=$$$OK) "3-'"_gktt_"' bin attrib insert failed!!",!
	s cn="test4"
	s c=p.Insert("cn",cn) w:(c'=$$$OK) "cn attrib insert failed!!",!
	s DN="cn="_cn_","_DC
	s c=x.AddNewEntry(DN,p)
	IF ($$$ISERR(c)) {
		d DecomposeStatus^%apiOBJ(c,.err)
		W "--- Failed to add/create a new entry(",DN,") : err : ", err(err),!
	} else {
		w "Entry added (",DN,")",!
	}
	q DN
}

ClassMethod TestDump(x As %Net.LDAP.Client.Session, DC As %String, scope As %Net.LDAP.Client.Search.Scope = 2) As %Status [ Internal ]
{
	;; build a list of desired attributes 
	set sl=x.GetStringList()
	d sl.InsertStr("ObjectClass","cn","badPwdCount","description","postalAddress")
	s x.MaxItems=1000  ;; specify max number of results
	s count=0
	w !,"Search base<",DC,">",!
	Set ents=x.Search(DC,scope, "(ObjectClass=*)",sl,1000)
	if ('$IsObject(ents)) {
		d DecomposeStatus^%apiOBJ(ents,.err)
		W "Search failed : err : ", err(err),!
	} else {
		w !,"Search result:",!
		s entDN=""
  		f  { ; iterate through returned entries
      		s ent=ents.GetNext(.entDN)
      		if ($IsObject(ent)) {
	      		s count=count+1
    	  		w " ",count," - Entry(",entDN,")",!
	      		set attrNM=""
      			f  { ; iterate through each attribute of an entry
		      		s val=ent.GetNext(.attrNM)
		      		q:(attrNM="")
		      		w "   Attr(",attrNM,")",!
		      		;; iterate through values associated with each attribute
		      		f i=1:1:val.GetNumItems() { 
      					w "     ",i," - Value(",val.GetValue(i),")",!
		      		}
      			}
      		} else {
				q  ;; list end
      		}
   		}
	}
	q count
}

ClassMethod TestDelete(x As %Net.LDAP.Client.Session, DN As %String) As %Status [ Internal ]
{
	s c=x.DeleteEntry(DN)
	IF ($$$ISERR(c)) {
		d DecomposeStatus^%apiOBJ(c,.err)
		W "--- Failed to delete entry(",DN,") : err : ", err(err),!
	} else {
		w "Deleted entry (",DN,") OK!!",!
	}
	q c
}

/// w ##class(%Net.LDAP.Client.Session).Test(0) 
ClassMethod Test(testnum As %Integer = 0, scope As %Net.LDAP.Client.Search.Scope = 2) As %Integer [ Internal ]
{
	;; Connect
	s x=##class(%Net.LDAP.Client.Session).TestConnect(testnum,.DC)
	q:(x="") x
	w "DC=",DC,!,!
	
	;; Create test DN
	s DN=##class(%Net.LDAP.Client.Session).TestCreateDN(x,DC,.cn)
	w "DN=",DN,!,!
	
	;; Rename an Entry
	s c=x.RenameEntry(DN,"cn=testxx","",1)
	if ($$$ISERR(c)) {
		d DecomposeStatus^%apiOBJ(c,.err)
		W "--- Failed to Rename the new entry(",DN,") to(","testxx",") : err : ", err(err),!
	} else {
		w "Rename 'testxx' back to '",cn,"'",!
		s c=x.RenameEntry("cn=testxx,"_DC,"cn="_cn,"",1)
		if ($$$ISERR(c)) d DecomposeStatus^%apiOBJ(c,.err) W "--- Failed to restore the name(",DN,") : err : ", err(err),!
	}
	
	;; Dump the obj tree
	s count=##class(%Net.LDAP.Client.Session).TestDump(x,DC,scope)
	w !,"Search done!! Count == ",count,!,!

	;; Compare values!!
	s c=x.CompareEntryValue(DN,"cn",cn)
	if (c = -1) {
		d DecomposeStatus^%apiOBJ(c,.err)
		W "--- Failed to compare entry(",DN,") : err : ", err(err),!
	} else {
		if (c) {
			w "Compared OK!!",!
		} else {
			w "Compare returned FALSE!!",!
		}
	}
	;; Delete the test DN
	s c=##class(%Net.LDAP.Client.Session).TestDelete(x,DN)

	w !,"Supported controls are:",!
	s c=x.TestDispControlList()
	if ($$$ISERR(c)) {
		d DecomposeStatus^%apiOBJ(c,.err)
		W "--- Failed to Get Control List : err : ", err(err),!
	}
	w !,"Job num = ",$J,!
	w "TO exit Enter <CR>"
	read zz
}

/// 
/// foo As %Boolean = 0
ClassMethod Test1(testnum... As %Integer) As %Integer [ Internal ]
{
	w "testnum = ",testnum,!
	break
	f i=1:1:testnum w "testnum(",i,") == (",testnum(i),")",!
	;w foo,!
	h 2
	q 1
}

}
