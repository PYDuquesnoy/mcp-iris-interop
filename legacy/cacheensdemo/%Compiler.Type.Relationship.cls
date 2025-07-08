/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Object Relationship Property Class
Class %Compiler.Type.Relationship Extends %Compiler.Type.Object [ NoContext, System = 2 ]
{

/// ACCESSPOLICY defines how collection is fetched to the client application.
/// 
/// 	EAGER:	The whole collection is fetched no later than it is first accessed by application in any manner.
/// 				If collection contains object values then objects are opened and instantiated in application memory.
/// 				For applications using POJO mode this means that application can use this collection even if it has
/// 				been disconnected from the server afterwards. Value EAGER is a requirement, meaning that if it is
/// 				specified then EAGER policy always be employed.
/// 
/// 	LAZY: 	Values in collection can be fetched as they are requested by the application, e.g. when methods get()
/// 				or Iterator.next() are invoked. Value LAZY is a hint meaning that if it is specified it tells that LAZY
/// 				policy may be used for this collection but does not guarantee that it is used. In case LAZY fetching is
/// 				used collection may become invalid when application disconnected from the server.
Parameter ACCESSPOLICY As STRING [ Constraint = ",lazy,eager", Flags = ENUM ];

/// Return the oref of the object referenced by this property. If the oref isn't present then swizzle the OID to produce one and relate the objects.
/// If <var>noswizzle</var> is passed as true then this will just return the current value for the property, so if it
/// has been swizzled already then it will return the oref, if it has not been swizzled it will return "" ($$$NULLOREF).
Method GetSwizzled(noswizzle As %Boolean = 0) As %RegisteredObject [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set prop=$$$QN(%property)
	Set runtimeclasstype=$$$getClassType(runtimetype)
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
	#; don't generate any code if the property is calculated
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	#; if it is datatype, just quit the instance variable
	If runtimeclasstype = $$$cCLASSCLASSTYPEDATATYPE Do  QUIT $$$OK
	. Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code="i%"_prop
	#; don't swizzle if the property type does not have swizzling interface
	Set ifswizzle = (runtimeclasstype = $$$cCLASSCLASSTYPEPERSISTENT) || (runtimeclasstype = $$$cCLASSCLASSTYPESERIAL)
	If 'ifswizzle Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code="r%"_prop QUIT $$$OK
	Set hasclassname=0 $$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	If collection="" Set hasclassname=%parameter("CLASSNAME")
	Set iscollection=''$listfind($$$cPROPCOLLECTIONREGULAR,collection)
	$$$GENERATE("	If noswizzle { RETURN r%"_prop_" }" )
	$$$GENERATE("	If r%"_prop_"'=$$$NULLOREF Quit r%"_prop)
	If 'iscollection {
		$$$GENERATE("	If i%"_prop_"="""" Quit $$$NULLOREF")
		If 'hasclassname { $$$GENERATE("	Set oid=$$$oidForm(i%"_prop_")") } Else { $$$GENERATE("	Set oid=i%"_prop) }
		$$$GENERATE("	Set oref=##class("_$$$QN(runtimetype)_").%Open(oid,,.sc) If $$$ISERR(sc)||(oref=$$$NULLOREF) $$$THROWSWIZZLEERR Quit $$$NULLOREF")
		$$$GENERATE("	Set modstate=$system.CLS.GetModifiedBits() Set r%"_prop_"=oref Do $system.CLS.SetModifiedBits(modstate)")
		$$$comMemberKeyGetLvar(inverse,%class,$$$cCLASSproperty,%property,$$$cPROPinverse)
		$$$GENERATE("	Do oref."_$$$QN(inverse_"Relate")_"($this)")
	} Else {
		$$$GENERATE("	If i%"_prop_"'="""" {")
		If 'hasclassname { $$$GENERATE("		Set oid=$$$oidForm(i%"_prop_")") } Else { $$$GENERATE("		Set oid=i%"_prop) }
		$$$GENERATE("		Set oref=##class("_$$$QN(runtimetype)_").%Open(oid,,.sc) If $$$ISERR(sc)||(oref=$$$NULLOREF) $$$THROWSWIZZLEERR Quit $$$NULLOREF")
		$$$comMemberKeyGetLvar(initialexpression,%class,$$$cCLASSinstancevar,%property,$$$cIVARinitialexpression)
		If initialexpression="""""" Set initialexpression=""
		$$$GENERATE("	} Else { Set oref=##class("_$$$QN(runtimetype)_").%New("_initialexpression_") If oref=$$$NULLOREF Quit $$$NULLOREF }")
		$$$GENERATE("	Set modstate=$system.CLS.GetModifiedBits() Set r%"_prop_"=oref Do $system.CLS.SetModifiedBits(modstate)")
		$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,%property,$$$cPROPtype)
		If '($$$classIsDataType(type)) { $$$GENERATE("	Set oref.ElementType="_$$$QuoteName(type)) $$$GENERATE("	Do oref.%SetModified(0)") }
	}
	$$$GENERATE("	Quit oref")
	QUIT $$$OK
}

/// Connect two objects in memory so that the relationship in each object has a swizzled reference
/// to its inverse relationship in the other object.
Method Relate(oref) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	If '($$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPrelationship)) QUIT $$$OK
	#; don't generate any code if the property is calculated
	If ($$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)) QUIT $$$OK
	Set prop=$$$QN(%property)
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
	If $$$classIsDataType(runtimetype) Quit $$$OK
	$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	Set iscollection=''$listfind($$$cPROPCOLLECTIONREGULAR,collection)
	#; If it is a collection then I want to search the collection for a) OID or b) oref. If OID found, just check
	#; to make sure the orefs are the same. Then we're done.
	If iscollection Do  QUIT $$$OK
	. Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code=".."_prop_".Relate(oref)"
	#; If its an atomic property then just verify that the oid is the same and/or the oref are the same.
	$$$GENERATE("	If r%"_prop_"=oref Quit $$$OK")
	Set hasclassname=%parameter("CLASSNAME")
	#; This condition checks to see if the existing unswizzled oid value is equal to the OID of the related object
	#; This condition ignores the possibility that the same oid might swizzle to two different orefs - not supposed to be possible so I don't check for it
	$$$GENERATE("	If i%"_prop_"'=$$$NULLOID,$$$oidPrimary(oref.""%%OID"")="_$select('hasclassname:"i%"_prop,1:"$$$oidPrimary(i%"_prop_")")_" Set modstate=$system.CLS.GetModifiedBits() Set r%"_prop_"=oref Do $system.CLS.SetModifiedBits(modstate) Quit $$$OK")
	#; This next condition says: This object is already related to another. We may decide to terminate that relationship
	#; or simply return an error...for now invoke UnRelate to sever the prior relationship...
	$$$GENERATE("	If r%"_prop_"'=$$$NULLOREF Do .."_$$$QN(%property_"UnRelate")_"(r%"_prop_")")
	#; This means that there is an unswizzled reference. We don't care (for now) if the reference is oref.%Oid() because this must be the
	#; stored side (the N side) of a 1:N relationship. 1:1 and M:N will change this but for now...
	$$$GENERATE("	Set tmp=i%"_prop_" Kill i%"_prop_",r%"_prop_" Set r%"_prop_"=oref,i%"_prop_"=tmp")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Unswizzles a property, if it has an oref                           |
Method UnSwizzle(force As %Integer = 0) As %Status [ CodeMode = generator, Private, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	#; don't generate any code if the property is a collection
	If collection'="" QUIT $$$OK
	#; don't generate any code if the property is calculated
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	Set prop=$$$QN(%property)
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set runtimeclasstype=$$$getClassType(runtimetype)
	#; don't generate any code if the property is datatype
	If runtimeclasstype = $$$cCLASSCLASSTYPEDATATYPE QUIT $$$OK
	#; don't swizzle if the property type does not have swizzling interface
	Set ifswizzle=(runtimeclasstype = $$$cCLASSCLASSTYPEPERSISTENT)||(runtimeclasstype = $$$cCLASSCLASSTYPESERIAL)
	If 'ifswizzle QUIT $$$OK
	#; quit if there is no oref
	$$$GENERATE(" Quit:r%"_prop_"=$$$NULLOREF $$$OK")
	Set hasclassname=0
	If collection="" Set hasclassname=%parameter("CLASSNAME")
	$$$comMemberKeyGetLvar(ismany,%class,$$$cCLASSproperty,%property,$$$cPROPcardinality)
	Set ismany=$select(ismany=$$$cPROPCARDINALITYMANY:1,ismany=$$$cPROPCARDINALITYCHILDREN:1,1:0)
	#; if the serial object is modified, then the property is modified, this will be picked up by set of i% value
	$$$GENERATE("	Set sc=.."_prop_".%GetSwizzleObject(force,.newvalue) Quit:$$$ISERR(sc) sc")
	$$$GENERATE("	Set modstate=$system.CLS.GetModifiedBits() Set r%"_prop_"=$$$NULLOREF Do $system.CLS.SetModifiedBits(modstate)")
	If hasclassname {
		$$$GENERATE(" Set i%"_prop_"=newvalue")
	} Else {
		$$$GENERATE(" Set i%"_prop_"=$$$oidPrimary(newvalue)")
	}
	$$$GENERATE(" Quit $$$OK")
	QUIT $$$OK
}

/// Terminate the relationship between two objects. For multi-valued relationships just invoke
/// its UnRelate() method.
Method UnRelate(oref) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	If '($$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPrelationship)) QUIT $$$OK
	#; don't generate any code if the property is calculated
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	Set prop=$$$QN(%property)
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
	If $$$classIsDataType(runtimetype) Quit $$$OK
	#; don't swizzle if the property type does not have swizzling interface
	$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	Set iscollection=''$listfind($$$cPROPCOLLECTIONREGULAR,collection)
	If collection="" 
	#; If it is a collection then I want to search the collection for a) OID or b) oref. If OID found, just check
	#; to make sure the orefs are the same. Then we're done.
	If iscollection Do  QUIT $$$OK
	. Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code=".."_prop_".UnRelate(oref)"
	#; If its an atomic property and it is this one, unrelate and quit...
	$$$GENERATE("	If r%"_prop_"=oref Set r%"_prop_"=$$$NULLOREF,i%"_prop_"=0,i%"_prop_"=$$$NULLOID Quit $$$OK")
	#; If this is swizzled then we have an internal relationship mismatch.
	$$$GENERATE("	If r%"_prop_"'=$$$NULLOREF Quit $$$ERROR($$$RelationshipError)")
	#; The object has a related unswizzled object. Force i% to change to set the modified flag
	$$$GENERATE("	Set i%"_prop_"=0,i%"_prop_"=$$$NULLOID")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Creates a new instance of this property's type class and returns its reference to the caller.
Method NewObject() As %ObjectHandle [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; method not for datatype attributes
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	If $$$classIsDataType(runtimetype) QUIT $$$OK
	#; if calculated and not SET method, then don't generate this method
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated),$$$comMemberDefined(%class,$$$cCLASSmethod,%property_"Set")=0 QUIT $$$OK
	#; set-up return type
	$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	Set iscollection=''$listfind($$$cPROPCOLLECTIONREGULAR,collection)
	$$$comMemberKeyGetLvar(initialexpression,%class,$$$cCLASSinstancevar,%property,$$$cIVARinitialexpression)
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
	If initialexpression="""""" Set initialexpression=""
	$$$GENERATE("	Set newobject=##class("_$$$QN(runtimetype)_").%New("_initialexpression_") If newobject=$$$NULLOREF Quit $$$NULLOREF")
	$$$GENERATE("	Set .."_$$$QN(%property)_"=newobject")
	If 'iscollection $$$comMemberKeyGetLvar(inverse,%class,$$$cCLASSproperty,%property,$$$cPROPinverse) $$$GENERATE("	Do .."_$$$QN(%property)_"."_$$$QN(inverse_"Relate")_"($this)")
	$$$GENERATE("	Quit newobject")
	QUIT $$$OK
}

/// Close the query that returns a list of related objects.
ClassMethod RClose(%qHandle As %Binary) As %Status [ CodeMode = generator, PublicList = SQLCODE, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a query
	If %mode="method" QUIT $$$OK
	#; A transient relationship or if this isn't a persistent class indicates that the load query
	#; should be implemented by hand. If not, then this degenerate method will keep things running smoothly...
	If $select($$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPtransient):1,$$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT:1,$$$comClassKeyGet(%class,$$$cCLASSnoextent):1,1:0) Set %code="$$$OK",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
	If '$Data(^oddEXTR(%class)) Set %code="$$$ERROR($$$MethodNotImplemented,"_$$$QuoteName(%class)_"_""::""_"_$$$QuoteName(%property_"RClose")_")",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
		#; Close cursor
	$$$GENERATE("	New SQLCODE Set SQLCODE=0")
	$$$GENERATE("	Do:$isobject($get(%qHandle)) %qHandle.%Destruct() Kill %qHandle")
	$$$GENERATE("	If SQLCODE { Set:$isobject($g(%sqlcontext)) %sqlcontext.%SQLCODE=SQLCODE,%sqlcontext.%Message=$g(%msg) Set sc=$$$ERROR($$$SQLCode,SQLCODE,$get(%msg)) } Else { Set sc=$$$OK }")
	$$$GENERATE("	Quit sc")
	QUIT $$$OK
}

/// Instantiate a query that returns a list of objects related to <var>inverse</var>.
ClassMethod RExec(ByRef %qHandle As %Binary, inverse As %String) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; A transient relationship or if this isn't a persistent class indicates that the load query
	#; should be implemented by hand. If not, then this degenerate method will keep things running smoothly...
	If $select($$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPtransient):1,$$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT:1,$$$comClassKeyGet(%class,$$$cCLASSnoextent):1,1:0) Set %code="$$$OK",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
	If '$Data(^oddEXTR(%class)) Set %code="$$$ERROR($$$MethodNotImplemented,"_$$$QuoteName(%class)_"_""::""_"_$$$QuoteName(%property_"RExec")_")",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
	$$$comClassKeyGetLvar(schematable,%class,$$$cCLASSsqlqualifiednameQ)
	Set idcolumns=$g($$$EXTSQLrowidcolumnlist($$$pEXT,%class))
	If ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault))="" Do
	. $$$comClassKeyGetLvar(sdef,%class,$$$cCLASSstoragestrategy)
	. $$$comMemberKeyGetLvar(rowidprop,%class,$$$cCLASSstorage,sdef,$$$cSDEFsqlrowidproperty)
	. Set rowidcolumn=$g($$$EXTPROPsqlcolumnname($$$pEXT,%class,rowidprop))
	. Set idcolumns=$select(rowidcolumn'="":$listbuild(rowidcolumn),1:"")
	If idcolumns=""  Set %code="$$$ERROR($$$MethodNotImplemented,"_$$$QuoteName(%class)_"_""::""_"_$$$QuoteName(%property_"RExec")_")",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
	Set select=$$quoter2^%apiSQL($list(idcolumns))
	For ptr=2:1:$listlength(idcolumns) Set select=select_","_$$quoter2^%apiSQL($list(idcolumns,ptr))
	$$$GENERATE("#EXECUTE s %msqlvar=""%qHandle""")
		#; define cursor
	set cursor = $get($$$tCURSORID(%class,$$$cCLASSproperty,%property)) if 'cursor { set cursor = $Increment($$$tCURSOR(%class)), $$$tCURSORID(%class,$$$cCLASSproperty,%property)=cursor } set cursor = "Q"_cursor
	$$$GENERATE("	&sql(DECLARE "_cursor_" CURSOR FOR")
	$$$GENERATE("		SELECT "_select_" FROM %NOPARALLEL "_schematable_" where "_$$quoter2^%apiSQL($$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPsqlfieldname))_"=:inverse)")
		#; Open cursor
	$$$GENERATE("	&sql(OPEN "_cursor_")")
	$$$GENERATE("	If SQLCODE Quit $$$ERROR($$$QueryCannotInstantiate,""SQLCODE = ""_SQLCODE_$s($get(%msg)="""":"""",1:"" %msg=""_%msg))")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Returns up to <var>FetchCount</var> number of rows (or up to 32k of data if <var>FetchCount</var>
/// is zero) in <var>RowSet</var>. <var>ReturnCount</var> indicates the number of rows returned. <var>AtEnd</var>
/// is TRUE if the query encountered an end-of-data condition while retrieving data - in other words, don't try calling
/// again.
ClassMethod RFetch(ByRef %qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ CodeMode = generator, PlaceAfter = RExec, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a query
	If %mode="method" QUIT $$$OK
	#; A transient relationship or if this isn't a persistent class indicates that the load query
	#; should be implemented by hand. If not, then this degenerate method will keep things running smoothly...
	If $select($$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPtransient):1,$$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT:1,$$$comClassKeyGet(%class,$$$cCLASSnoextent):1,1:0) Do  Quit $$$OK
	. $$$GENERATE(" Set ReturnCount=0,AtEnd=1,RowSet="""" Quit $$$OK")
	$$$comClassKeyGetLvar(sdef,%class,$$$cCLASSstoragestrategy)
	If '$Data(^oddEXTR(%class)) Set %code="$$$ERROR($$$MethodNotImplemented,"_$$$QuoteName(%class)_"_""::""_"_$$$QuoteName(%property_"RFetch")_")",%codemode=$$$cMETHCODEMODEEXPRESSION QUIT $$$OK
	Set idcolumns=$g($$$EXTSQLrowidcolumnlist($$$pEXT,%class))
	If ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault))="" Do
	. $$$comMemberKeyGetLvar(rowidprop,%class,$$$cCLASSstorage,sdef,$$$cSDEFsqlrowidproperty)
	. Set rowidcolumn=$g($$$EXTPROPsqlcolumnname($$$pEXT,%class,rowidprop))
	. Set idcolumns=$select(rowidcolumn'="":$listbuild(rowidcolumn),1:"")
	Set idcolumncnt=$listlength(idcolumns)
	If idcolumns'="" {
		Set into=":c1",idexpr="c1"
		For ptr=2:1:idcolumncnt {
			Set column=$list(idcolumns,ptr) If column'="" {
				Set into=into_",:c"_ptr,idexpr=idexpr_"_""||""_c"_ptr
			}
		}
		Set rowexpr="$lb("_idexpr_")"
	} Else {
		Set into="",rowexpr="",idexpr=""
	}
	set cursor = $get($$$tCURSORID(%class,$$$cCLASSproperty,%property)) if 'cursor { set cursor = $Increment($$$tCURSOR(%class)), $$$tCURSORID(%class,$$$cCLASSproperty,%property)=cursor } set cursor = "Q"_cursor
		#; generate fetch
	$$$GENERATE("	Set RowSet="""",ReturnCount=0,AtEnd=0")
	$$$GENERATE("	For {")
	$$$GENERATE("		&sql(FETCH "_cursor_" INTO "_into_")")
	$$$GENERATE("		If 'SQLCODE { Set RowSet=RowSet_"_rowexpr_",ReturnCount=ReturnCount+1 Quit:ReturnCount=FetchCount||(($length(RowSet)+($length(RowSet)\ReturnCount))>30000) }")
	$$$GENERATE("		ElseIf SQLCODE<0 {RETURN $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) } ") ; EEE003 < added error handling >
	$$$GENERATE("		Else { Set AtEnd=1 Quit }")
	$$$GENERATE("	}")
	$$$GENERATE("	RETURN $$$OK") ; EEE003 < return from the function (distinguishing RETURN from Quit for readability) >
	QUIT $$$OK
}

/// Set the value of this property to <var>newvalue</var>. If this property has a current value that
/// that is not <var>newvalue</var> then %Close it, decrement its reference count and UnRelate() it. Relate()
/// the new value.
Method Set(newvalue As %String) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	Set prop=$$$QN(%property)
	$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	Set iscollection=''$listfind($$$cPROPCOLLECTIONREGULAR,collection)
	If collection="" { Set hasclassname=%parameter("CLASSNAME") } Else { Set hasclassname=0 }
	$$$comMemberKeyGetLvar(inverse,%class,$$$cCLASSproperty,%property,$$$cPROPinverse)
	#; if property is datatype
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	If $$$classIsDataType(runtimetype) Do  QUIT $$$OK
	. Set validate=($$$comMemberKeyGet(%class,$$$cCLASSparameter,"PROPERTYVALIDATION",$$$cPARAMdefault)=1)
	#; if autovalidation on a SET has been specified, then perform the validation
	. If validate $$$GENERATE("	if newvalue'="""" { Set sc=.."_$$$QN(%property_"IsValid")_"(newvalue) Quit:$$$ISERR(sc) sc }")
	. $$$GENERATE("	Set i%"_prop_"=newvalue Quit $$$OK")
	#; falls through to here if property is not datatype
	#; just quit if it is the same value
	#; if newvalue if not a valid oref, quit with 0
	$$$GENERATE("	If newvalue=$$$NULLOREF {")
	$$$GENERATE("		If r%"_prop_"=$$$NULLOREF,i%"_prop_"=$$$NULLOID Quit $$$OK")
	$$$GENERATE("	} Else {")
	$$$GENERATE("		If '$$$objExists(newvalue) Quit $$$ERROR($$$OrefInvalid,newvalue)")
	#; check to see if the new value is the same as the old value
	$$$GENERATE("		If r%"_prop_"=newvalue Quit $$$OK")
	#; check if oid is the same as before if we have not swizzled this item
	$$$GENERATE("		If r%"_prop_"=$$$NULLOREF,i%"_prop_"'=$$$NULLOID,"_$select(hasclassname:"$$$oidPrimary(i%"_prop_")",1:"i%"_prop)_"=$$$oidPrimary(newvalue.""%%OID"") Set modstate=$system.CLS.GetModifiedBits() Set r%"_prop_"=newvalue Do newvalue."_$$$QN(inverse_"Relate")_"($this),$system.CLS.SetModifiedBits(modstate) Quit $$$OK")
	$$$GENERATE("	}")
	#; if there's already a referenced object, sever the relationship and close it
	If 'iscollection $$$GENERATE("	If r%"_prop_"'=$$$NULLOREF Do r%"_prop_"."_$$$QN(inverse_"UnRelate")_"($this)")
	$$$GENERATE("	Set r%"_prop_"=newvalue,i%"_prop_"=0,i%"_prop_"=$$$NULLOID")
	If 'iscollection $$$GENERATE("	If newvalue'=$$$NULLOREF Do newvalue."_$$$QN(inverse_"Relate")_"($this)")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// This method stores a new value for the OID of the referenced object. if swizzling has not occurred,
/// it simply stores the OID (after perhaps stripping the class name if CLASSNAME=0). If swizzling has occurred,
/// then it references the object to obtain its OID.  If it is the same, then nothing happens. If they
/// are different then the old object is closed and the new OID is stored.
Method SetObject(newvalue As %ObjectIdentity) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	#; don't generate any code if the property is a collection
	If collection'="" QUIT $$$OK
	#; don't generate any code if the property is calculated
	If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	Set prop=$$$QN(%property)
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set runtimeclasstype=$$$getClassType(runtimetype)
	#; don't generate any code if the property is datatype
	If runtimeclasstype = $$$cCLASSCLASSTYPEDATATYPE QUIT $$$OK
	#; don't swizzle if the property type does not have swizzling interface
	Set ifswizzle = $Case(runtimeclasstype,$$$cCLASSCLASSTYPEPERSISTENT:1,$$$cCLASSCLASSTYPESERIAL:1,:0)
	If 'ifswizzle QUIT $$$OK
	#; if we don't want a classname, then strip it
	Set hasclassname=0
	If collection="" Set hasclassname=%parameter("CLASSNAME")
	Set iscollection=''$listfind($$$cPROPCOLLECTIONREGULAR,collection)
	$$$comMemberKeyGetLO(inverse,origin,%class,$$$cCLASSproperty,%property,$$$cPROPinverse)
	Set newvalue=$select(hasclassname:"newvalue",1:"$$$oidPrimary(newvalue)")
	$$$GENERATE("	If r%"_prop_"=$$$NULLOREF Set i%"_prop_"="_newvalue_" Quit $$$OK")
	If runtimeclasstype=$$$cCLASSCLASSTYPEPERSISTENT {
		$$$GENERATE("	If newvalue'=$$$NULLOID,i%"_prop_"="_newvalue_" Quit $$$OK")
	}
	$$$GENERATE("	Set sc=.."_prop_".%GetSwizzleObject(0,.oid) Quit:$$$ISERR(sc) sc")
	$$$GENERATE("	If newvalue'=$$$NULLOID,$$$oidPrimary(oid)=$$$oidPrimary(newvalue) Quit $$$OK")
	$$$GENERATE("	"_$select('iscollection:"Do .."_prop_"."_$$$QN(inverse_"UnRelate")_"($this) ",1:"")_"Set r%"_prop_"=$$$NULLOREF,i%"_prop_"=0,i%"_prop_"="_newvalue_" Quit $$$OK")
	QUIT $$$OK
}

/// This method stores simply calls SetObject() with constructed Oid      |
Method SetObjectId(newid As %String) As %Status [ CodeMode = generator, GenerateAfter = SetObject, ServerOnly = 0 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if SetObject() is not there
	If $$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"SetObject")=0 QUIT $$$OK
	Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code=".."_$$$QN(%property_"SetObject")_"($$$oidForm(newid))"
	QUIT $$$OK
}

/// This method is generated for properties with SQLCOMPUTED = true. 
/// It contains code to compute a value for the property as defined in SQLCOMPUTECODE for the SQL Filer. 
ClassMethod SQLCompute() As %String [ CodeMode = generator, Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	Set %code = 0
		#; don't generate any code if it not for a property
	If %mode = "method" QUIT $$$OK
	$$$comMemberKeyGetLvar(sqlcomputecode,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputecode)
	If sqlcomputecode '= "" {
		$$$GENERATE("	QUIT $$$ERROR($$$MethodNotImplemented,""%Compiler.Type.Relationship::"_%property_"SQLCompute"")")
	}
	else { $$$GENERATE("	Quit """"") }
	Quit $$$OK
}

ClassMethod OnDelete(id As %RawString = "", concurrency As %Integer = -1) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
		// For a relationship, there is only one keyprop - this one (%property) - and the referenced key is always %1
	try {
		set %code=0
		set sc = $$$OK
			// don't generate any code if it not for a relationship
		if %mode '= "method" {
				// Don't generate any code for non-persistent classes:
			$$$comMemberKeyGetLvar(cardinality,%class,$$$cCLASSproperty,%property,$$$cPROPcardinality)
			if ($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT) && ('($$$comClassKeyGet(%class,$$$cCLASSnoextent))) && ((cardinality = $$$cPROPCARDINALITYONE) || (cardinality = $$$cPROPCARDINALITYPARENT)) {
				if '$$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPtransient) {
					$$$comMemberKeyGetLvar(ondelete,%class,$$$cCLASSproperty,%property,$$$cPROPondelete)
					$$$comClassKeyGetLvar(sqltable,%class,$$$cCLASSsqlqualifiednameQ)
					$$$comMemberKeyGetLvar(constraintkeyclass,%class,$$$cCLASSproperty,%property,$$$cPROPtype)
					set keycol = $$PrepareColumnForQuery^%occStorage(%class,%property)
					set where = keycol _ " = :id"
						// NOACTION is the default for CARDINALITY=ONE relationships
					if ondelete = $$$cPROPONDELETENOACTION {
							// NOACTION
						$$$GENERATE($Char(9)_"&sql(select %ID into :id from " _ sqltable _ " where " _ where _ ")")
						$$$GENERATE($Char(9)_"Quit $Select(SQLCODE:$$$OK,1:$$$ERROR($$$RelationshipRestrictDelete,$classname()_"".""_"_$$$QuoteName(%property)_"))")
					}
					elseif ondelete = $$$cPROPONDELETECASCADE {
							// CASCADE
						$$$GENERATE("	new %updcas Set %updcas=""%1""")
						$$$GENERATE("	set sc=.."_$$$QN(%property_"RExec")_"(.qh,id) quit:$$$ISERR(sc) sc" )
						$$$GENERATE("	for {")
						$$$GENERATE("		set sc=.."_$$$QN(%property_"RFetch")_"(.qh,0,.robjs,.fc,.end) Quit:$$$ISERR(sc)")
						$$$GENERATE("		set ptr=0 while $listnext(robjs,ptr,val) {")
						$$$GENERATE("			set sc=..%Delete($$$oidForm(val),concurrency) Quit:$$$ISERR(sc)")
						$$$GENERATE("		}")
						$$$GENERATE("		Quit:$$$ISERR(sc)||(end)")
						$$$GENERATE("	}")
						$$$GENERATE("	Do .."_$$$QN(%property_"RClose")_"(.qh)")
						$$$GENERATE("	quit sc")
					}
					elseif ondelete = $$$cFKEYONDELETESETNULL {
							// SETNULL
						$$$GENERATE("	new %updcas Set %updcas=""%1""")
						$$$GENERATE("	set sc=.."_$$$QN(%property_"RExec")_"(.qh,id) quit:$$$ISERR(sc) sc" )
						$$$GENERATE("	set sc=.."_$$$QN(%property_"RFetch")_"(.qh,0,.robjs,.fc,.end) quit:$$$ISERR(sc) sc")
						$$$GENERATE("	do {")
						$$$GENERATE("		set ptr=0 while $listnext(robjs,ptr,val) {")
						$$$GENERATE("			set oref=..%Open($$$oidForm(val),concurrency,.sc)")
						$$$GENERATE("			if $$$ISOK(sc) {")
						$$$GENERATE("				set oref."_$$$QN(%property)_"=""""")
						$$$GENERATE("				set sc=oref.%Save(0)")
						$$$GENERATE("			} else { quit }")
						$$$GENERATE("		}")
						$$$GENERATE("		if '$$$ISERR(sc) { if 'end { set sc=.."_$$$QN(%property_"RFetch")_"(.qh,0,.robjs,.fc,.end) } else { set fc = 0 } } else { set end = 1 }")
						$$$GENERATE("	} while 'end")
						$$$GENERATE("	do .."_$$$QN(%property_"RClose")_"(.qh)")
						$$$GENERATE("	quit sc")
					}
					elseif ondelete = $$$cFKEYONDELETESETDEFAULT {
							// SETDEFAULT
						set hasclassname = $$$comMemberArrayGet(%class,$$$cCLASSproperty,%property,$$$cPROPparameter,"CLASSNAME")
						set default = $get($$$EXTPROPinitialexpression($$$pEXT,%class,%property))
						if (default = "") { set default = """""" }
						$$$GENERATE("	new %updcas Set %updcas=""%1""")
						$$$GENERATE("	set t1="_default)
						$$$GENERATE("	set sc=.."_$$$QN(%property_"RExec")_"(.qh,id) quit:$$$ISERR(sc) sc" )
						$$$GENERATE("	set sc=.."_$$$QN(%property_"RFetch")_"(.qh,0,.robjs,.fc,.end) quit:$$$ISERR(sc) sc")
						$$$GENERATE("	do {")
						$$$GENERATE("		set ptr=0 while $listnext(robjs,ptr,val) {")
						$$$GENERATE("			set oref=..%Open($$$oidForm(val),concurrency,.sc)")
						$$$GENERATE("			if '$$$ISERR(sc) {")
						$$$GENERATE("				do oref."_$$$QN(%property_$Select('hasclassname:"SetObjectId",1:"SetObject"))_"(t1)")
						$$$GENERATE("				set sc=oref.%Save(0)")
						$$$GENERATE("			} else { quit }")
						$$$GENERATE("		}")
						$$$GENERATE("		if '$$$ISERR(sc) { if 'end { set sc=.."_$$$QN(%property_"RFetch")_"(.qh,0,.robjs,.fc,.end) } else { set fc = 0 } } else { set end = 1 }")
						$$$GENERATE("	} while 'end")
						$$$GENERATE("	do .."_$$$QN(%property_"RClose")_"(.qh)")
						$$$GENERATE("	quit sc")
					}
				}
				else {
						// Degenerate implementation for transient relationship
					$$$GENERATE($Char(9)_"quit $$$OK")
				}
			}
		}
	}
	catch {
		set sc = $select($extract($zerror,2,4)="ZCC":sc,1:$$$ERROR($$$ObjectScriptError,$zerror))
	}
	quit sc
}

}
