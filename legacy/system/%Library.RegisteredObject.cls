/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.RegisteredObject">Working with Registered Objects</a>.</p>
/// The <CLASS>%RegisteredObject</CLASS> class provides the core capabilities needed to 
/// manage the in-memory version of an object. Specifically, <CLASS>%RegisteredObject</CLASS> 
/// provides the ability to create and destroy object references (OREFs) as well as 
/// support for polymorphism. The <CLASS>%RegisteredObject</CLASS> class also provides the 
/// ability to swizzle other referenced objects (persistent or serial) into memory.
/// 
/// <p>Classes derived directly from <CLASS>%RegisteredObject</CLASS> can be used as <em>transient</em> 
/// objects; objects that exist in memory-and can be used from client applications-but 
/// are not stored in the database.</p>
Class %Library.RegisteredObject Extends %Library.Base [ Abstract, ClientDataType = HANDLE, OdbcType = INTEGER, SqlCategory = INTEGER, System = 1 ]
{

/// Optional name used by the <i>Form Wizard</i> for a class when generating forms.
Parameter CAPTION;

/// The Java type to be used when exported.
Parameter JAVATYPE;

/// This parameter controls the default validation behavior for the object. 
/// 
/// <p>It can take one of the following values:<br>
/// <table cols=2  >
/// <tr>
/// <td width="33%" valign="top">0: <i>NoValidate</i></td>
/// <td valign="top">Perform no automatic property validation.</td>
/// </tr>
/// <tr>
/// <td width="33%" valign="top">1: <i>ValidateOnSet</i></td>
/// <td valign="top">Perform validation (call the property's <b>..IsValid</b> method) 
/// every time an attribute value is set.</td>
/// </tr>
/// <tr>
/// <td width="33%" valign="top">2: <i>ValidateOnSave</i></td>
/// <td valign="top">Perform property validation (in the <METHOD>%ValidateObject</METHOD> method)) 
/// when the object is saved. This is only applicable to persistent objects.</td>
/// </tr>
/// </table>
/// 
/// <p>Note: The use of <i>ValidateOnSet</i> is not recommended-it can cause excessive 
/// communication between client and server in distributed applications. 
/// It is provided for compatability with previous versions.
Parameter PROPERTYVALIDATION As INTEGER [ Constraint = "0,1,2", Flags = ENUM ] = 2;

/// Serial value of object or the object identity
Property "%%OID" As %RawString [ Internal, Private, Transient ];

Method "%%OIDGet"() As %RawString [ Internal, ServerOnly = 1 ]
{
	Quit i%"%%OID"
}

/// This method is called by the system when the object is being destroyed
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %Destruct() As %Status [ CodeMode = generator, Final, GenerateAfter = %OnClose, Internal, Private, ServerOnly = 1 ]
{
	Set %code=0
	#; if method %OnClose is present then call it
	$$$comMemberKeyGetLvar(oncloserunnable,%class,$$$cCLASSmethod,"%OnClose",$$$cMETHrunnable)
	If oncloserunnable $$$GENERATE("	Try { Do ..%OnClose() } Catch closeerror {}")
	#; If ID object:
	#; get oid, if any, then kill arrays
	If $$$classIsPersistent(%class) {
		#; remove object from transaction lists...
		$$$GENERATE("	Kill $$$txLIST($this),$$$txOIDASSIGNED($this),$$$txOIDUNASSIGNED($this),$$$txMODIFIED($this)")
		#; Added for concurrency of persistent objects - Release locks!
		$$$GENERATE("	If $get(i%""%%OID"")'="""" {")
			#; remove oref from oid list and release any retained locks. This code assumes that %Concurrency set to a retained lock value implies that
			#; such locks are currently held. Setting %Concurrency without acquiring the lock will invalidate this assumption. Also, this code tests OID
			#; because objects that have not been assigned an OID cannot be locked.
		if $$$comMemberDefined(%class,$$$cCLASSmethod,"%ReleaseLock") {
				#; remove oref from oid list and release the lock
			$$$GENERATE("		If i%%Concurrency=3 { Do ..%ReleaseLock(""s"") } ElseIf i%%Concurrency=4 { Do ..%ReleaseLock(""e"") }")
		}
		$$$GENERATE("		$$$ActiveOidRemove(i%""%%OID"")")
		$$$GENERATE("	}")
	}
	#; Look for collection, if we find any notify them that we are going away so they can
	#; disconnect the data from this parent
	Set prop=""
	For  {
		Set prop=$$$comMemberNext(%class,$$$cCLASSproperty,prop) If prop="" Quit
		$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
		If $listfind($$$cPROPCOLLECTIONREGULAR,collection),'$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPcalculated) {
			$$$comMemberKeyGetLvar(relationship,%class,$$$cCLASSproperty,prop,$$$cPROPrelationship)
			If 'relationship {
				$$$GENERATE("	If $isobject($get(r%"_$$$QN(prop)_"))=1,$zobjcnt(r%"_$$$QN(prop)_")>1 Do r%"_$$$QN(prop)_".%Disconnect()")
			}
		}
	}	
	#; If nothing but try generated then no code needed
	If %code=0 Quit $$$OK
	If oncloserunnable $$$GENERATE("	If $isobject($get(closeerror))=1 Throw closeerror")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Clone the current object to a new object. If <var>deep</var> is 1 then
/// this does a deep copy which will also copy any subobjects and if <var>deep</var> is 0
/// then it will create another reference to any subobjects and increment
/// the reference count appropriately. It returns the new cloned object.<p>
/// Note that even if deep=0 when you clone a parent object in a parent child relationship
/// or a one object of a one to many relationship then it will construct clones of all the
/// child/many objects. This is because a child/many object can only point at a single parent
/// and so if we did not create a clone of these then you would have a relationship with zero
/// items in it. If you really just want to clone the object without these child/many objects
/// then pass deep=-1 to this method.<p>
/// After the clone is constructed it will call %OnConstructClone(object,deep,.cloned) on the clone 
/// if it is defined so that you can perform any additional steps e.g. taking out a lock. This
/// works just the same way as %OnNew() does.<p>
/// The <var>object</var> is the oref of the original object that was cloned.
/// The <var>cloned</var> array is just used internally when doing a deep clone to
/// prevent recursive loops, do not pass anything in at all for this parameter on the
/// initial call. If you write a %OnConstructClone and from here you wish to call
/// %ConstructClone on another object pass in the <var>cloned</var> array, e.g.
/// 'Do oref.%ConstructClone(1,.cloned)' so that it can prevent recursive loops.<p>
/// The <var>location</var> is used internally to pass the new location for stream objects.
Method %ConstructClone(deep As %Integer = 0, ByRef cloned As %String, location As %String) As %RegisteredObject [ ServerOnly = 0 ]
{
	If $data(cloned(+$this),oref) Quit oref
	Set clone=$system.CLS.CloneOref() If clone="" Quit ""
	Set cloned(+$this)=clone,cloned(+$this,0)=$this,cloned(+clone)=clone
	Set sc=clone.%ConstructCloneInit($this,.deep,.cloned,.location)
	If $$$ISERR(sc) Quit ""
	Quit clone
}

Method %ConstructCloneInit(object As %RegisteredObject, deep As %Integer = 0, ByRef cloned As %String, location As %String) As %Status [ CodeMode = generator, GenerateAfter = %OnConstructClone, Private, ServerOnly = 1 ]
{
	Set %code=0
	Set set="",merge="",prop=""
	For  {
		Set prop=$$$comMemberNext(%class,$$$cCLASSproperty,prop) If prop="" Quit
		Set qprop=$$$QN(prop)
		Kill origin
		$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcalculated) If calculated Continue
		$$$comMemberKeyGetLO(multi,origin,%class,$$$cCLASSproperty,prop,$$$cPROPmultidimensional) If multi Continue
		If prop="%%OID" {
			Set set=set_",i%"_qprop_"="""""
			If $length(set)>120 $$$GENERATE("	Set "_$extract(set,2,*)) Set set=""
			Continue
		}
		$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
		$$$comMemberKeyGetLO(relationship,origin,%class,$$$cCLASSproperty,prop,$$$cPROPrelationship)
		#; Handle regular collections
		If 'relationship,collection=$$$cPROPCOLLECTIONARRAY||(collection=$$$cPROPCOLLECTIONLIST) {
			$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
			$$$GENERATE("	Set i%"_qprop_"="""",r%"_qprop_"=""""")
			If '$$$classIsDataType(type) {
				Set deep($increment(deep))="Set key="""" For  Set value=.."_qprop_".GetNext(.key) Quit:key=""""  Set r%"_qprop_"(key)=$select(value=$$$NULLOREF:$$$NULLOREF,1:value.%ConstructClone(1,.cloned)),i%"_qprop_"(key)="""""
			}
			Continue
		}
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
		Set runtimeclasstype=$$$getClassType(runtimetype)
		If runtimeclasstype=$$$cCLASSCLASSTYPEDATATYPE Continue
		Set ifswizzle = $Case(runtimeclasstype,$$$cCLASSCLASSTYPEPERSISTENT:1,$$$cCLASSCLASSTYPESERIAL:1,$$$cCLASSCLASSTYPESTREAM:1,"":1,:0)
		If ifswizzle {
			$$$comMemberKeyGetLO(cardinality,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcardinality)
			If relationship {
				If $Select(cardinality="many":1,cardinality="children":1,1:0) {
					Set shallow($Increment(shallow))="If .."_qprop_"'=$$$NULLOREF {"
					Set shallow($Increment(shallow))="	If deep=-1 {"
					Set shallow($Increment(shallow))="		Set r%"_qprop_"=$$$NULLOREF,i%"_qprop_"="_$$$comMemberKeyGet(%class,$$$cCLASSinstancevar,prop,$$$cIVARinitialexpression)
					Set shallow($Increment(shallow))="	} Else {"
					Set shallow($Increment(shallow))="		If .."_qprop_".NotLoaded Do .."_qprop_".Load()"
					Set shallow($Increment(shallow))="		Set tmprel=r%"_qprop_",tmpref=tmprel.InverseReference,tmprel.InverseReference=$this"
					Set shallow($Increment(shallow))="		Set r%"_qprop_"=r%"_qprop_".%ConstructClone(0,.cloned),i%"_qprop_"="""""
					Set shallow($Increment(shallow))="		Set tmprel.InverseReference=tmpref"
					Set shallow($Increment(shallow))="	}"
					Set shallow($Increment(shallow))="}"
					Set deep($Increment(deep))="If $isobject(.."_qprop_")=1 {"
					Set deep($Increment(deep))="	If .."_qprop_".NotLoaded Do .."_qprop_".Load()"
					Set deep($Increment(deep))="	Set tmprel=r%"_qprop_",tmpref=tmprel.InverseReference,tmprel.InverseReference=$this"
					Set deep($Increment(deep))="	Set r%"_qprop_"=r%"_qprop_".%ConstructClone(1,.cloned),i%"_qprop_"="""""
					Set deep($Increment(deep))="	Set tmprel.InverseReference=tmpref"
					Set deep($Increment(deep))="}"
				} ElseIf cardinality="parent" {
					Set shallow($increment(shallow))="Set r%"_qprop_"="""",i%"_qprop_"="""""
					Set deep($increment(deep))="If $isobject(object."_qprop_")=1 {"
					Set deep($increment(deep))="	Set r%"_qprop_"=object."_qprop_".%ConstructClone(1,.cloned),i%"_qprop_"="""""
					Set deep($increment(deep))="}"
				}
			} ElseIf runtimeclasstype=$$$cCLASSCLASSTYPESTREAM {
				$$$GENERATE("	If i%"_qprop_"'=""""||($isobject(r%"_qprop_")=1) Set r%"_qprop_"=.."_qprop_".%ConstructClone(deep,.cloned),i%"_qprop_"=""""")
			} ElseIf runtimeclasstype=$$$cCLASSCLASSTYPESERIAL {
				Set deep($Increment(deep))="If $data(i%"_qprop_"),$isobject(.."_qprop_")=1 Set r%"_qprop_"=r%"_qprop_".%ConstructClone(1,.cloned),i%"_qprop_"="""""
			} Else {
				Set deep($Increment(deep))="If $isobject(.."_qprop_")=1 Set r%"_qprop_"=r%"_qprop_".%ConstructClone(1,.cloned),i%"_qprop_"="""""
			}
		} Else {
			If relationship,cardinality="parent" {
				Set deep($Increment(deep))="Set i%"_qprop_"=$$$NULLOREF"
			} Else {
				Set deep($Increment(deep))="If $isobject(i%"_qprop_")=1 Set i%"_qprop_"=i%"_qprop_".%ConstructClone(1,.cloned),i%"_qprop_"="""""
			}
		}
	}
	Set $extract(set,1)="",$extract(merge,1)=""
	If merge'="" $$$GENERATE("	Merge "_merge)
	If set'="" $$$GENERATE("	Set "_set)
	If $get(deep)>0&&($get(shallow)>0) {
		$$$GENERATE("	If deep>0 {")
		For i=1:1:$get(deep) $$$GENERATE("		"_deep(i))
		$$$GENERATE("	} Else {")
		For i=1:1:$get(shallow) $$$GENERATE("		"_shallow(i))
		$$$GENERATE("	}")
	} ElseIf $get(deep)>0 {
		$$$GENERATE("	If deep>0 {")
		For i=1:1:$get(deep) $$$GENERATE("		"_deep(i))
		$$$GENERATE("	}")
	} ElseIf $get(shallow)>0 {
		$$$GENERATE("	If deep<1 {")
		For i=1:1:$get(shallow) $$$GENERATE("		"_shallow(i))
		$$$GENERATE("	}")
	}
	#; Streams may copy the location from the container
	If $$$getClassType(%class)=$$$cCLASSCLASSTYPESTREAM,$$$comMemberDefined(%class,$$$cCLASSinstancevar,"%Location") {
		$$$GENERATE("	If $data(location) Set i%%Location=location")
	}
	#; If there is a %OnConstructClone, call it
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnConstructClone",$$$cMETHrunnable) $$$GENERATE("	Set sc=..%OnConstructClone(object,deep,.cloned) If $$$ISERR(sc) Quit $$$NULLOREF")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Returns true (1) if a property of this instance has been modified, otherwise false (0).
/// A TRUE result does not necessarily mean that any property has actually been changed. If
/// %IsModified() returns false then the object has not been modified. There are some
/// situations where we simply cannot efficiently detect a change in value. In these cases we
/// will set the modified status of the property.
Method %IsModified() As %Integer [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If the modified=0 then this class is always modified for backward compatability when we supported
	#; other modified states so we always call %SaveData even if the object is not changed which is
	#; what the original behavior was
	$$$comClassKeyGetLvar(modified,%class,$$$cCLASSmodified)
	Set %codemode=$$$cMETHCODEMODEEXPRESSION
	Set %code=$select(modified=0:"1",1:"$system.CLS.GetModified()")
	Quit $$$OK
}

/// This method is called by the system when the object is being constructed
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %Construct(initvalue As %RawString) As %Status [ CodeMode = generator, Final, GenerateAfter = %OnNew, Internal, Private, ServerOnly = 1 ]
{
	Set %code=0
	Set fastivar=$$fastivar^%occDescriptor(%class)
	#; This code initializes all instance variables
	#; to null for a new object. Don't initialize MULTIDIMENSIONAL props
	Set ivar="",list="",modset="",kill="",normcache=1
	For  {
		Set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar) Quit:ivar=""
		Kill origin
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPruntimetype)
		Set classtype=$$$getClassType(runtimetype)
		If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,ivar,$$$cPROPmultidimensional) {
			If 'fastivar Set kill=kill_",i%"_$$$QN(ivar)_$select(classtype'=$$$cCLASSCLASSTYPEDATATYPE:",r%"_$$$QN(ivar),1:"")
			Continue
		}
		$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPcollection)
		If collection=$$$cPROPCOLLECTIONARRAY||(collection=$$$cPROPCOLLECTIONLIST) {
			Set modset=modset_"m%"_$$$QN(ivar)_"=0,M%"_$$$QN(ivar)_"=0,"
		}
		If classtype=$$$cCLASSCLASSTYPESTREAM {
			$$$comMemberKeyGetLvar(expr,%class,$$$cCLASSinstancevar,ivar,$$$cIVARinitialexpression)
			If expr'="",expr'="""""" Set streaminit($increment(streaminit))="	Do .."_$$$QN(ivar)_".Write("_expr_"),.."_$$$QN(ivar)_".Rewind()"
			If fastivar Set list=list_",i%"_$$$QN(ivar)_"="""",r%"_$$$QN(ivar)_"="""""
		} ElseIf $$IsA^%occLibrary(runtimetype,"%Library.DynamicAbstractObject",,.normcache) {
			$$$comMemberKeyGetLvar(expr,%class,$$$cCLASSinstancevar,ivar,$$$cIVARinitialexpression)
			If expr'="",expr'="""""" {
				Set list=list_",i%"_$$$QN(ivar)_"="_$$$QN(expr)
			} ElseIf fastivar {
				Set list=list_",i%"_$$$QN(ivar)_"="""""
			}
			If fastivar,classtype'=$$$cCLASSCLASSTYPEDATATYPE Set list=list_",r%"_$$$QN(ivar)_"="""""
		} ElseIf classtype'=$$$cCLASSCLASSTYPESERIAL||(collection'="") {
			$$$comMemberKeyGetLvar(expr,%class,$$$cCLASSinstancevar,ivar,$$$cIVARinitialexpression)
			If expr'="",expr'="""""" {
				Set list=list_",i%"_$$$QN(ivar)_"="_expr
			} ElseIf fastivar {
				Set list=list_",i%"_$$$QN(ivar)_"="""""
			}
			If fastivar,classtype'=$$$cCLASSCLASSTYPEDATATYPE Set list=list_",r%"_$$$QN(ivar)_"="""""
		} Else {
			If fastivar {
				If classtype'=$$$cCLASSCLASSTYPEDATATYPE Set list=list_",r%"_$$$QN(ivar)_"="""""
			} Else {
				Set kill=kill_",i%"_$$$QN(ivar)
			}
		}
		If $length(list)>120 $$$GENERATE("	Set "_$extract(list,2,*)) Set list=""
		If $length(kill)>120 $$$GENERATE("	Kill "_$extract(kill,2,*)) Set kill=""
		If $length(modset)>120 $$$GENERATE("	Set "_$extract(modset,1,*-1)) Set modset=""
	}
	If list'="" $$$GENERATE("	Set "_$extract(list,2,*))
	If kill'="" $$$GENERATE("	Kill "_$extract(kill,2,*))
	For i=1:1:$get(streaminit) $$$GENERATE(streaminit(i))
	#; Mark the collection as not being modified so it will only validate if it is swizzled or it has been modified
	If modset'="" $$$GENERATE("	Set "_$extract(modset,1,*-1))
	#; find out if there is a %OnNew method. If there is a %OnNew, call it
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnNew",$$$cMETHrunnable) {
		$$$comMemberKeyGetLvar(formal,%class,$$$cCLASSmethod,"%OnNew",$$$cMETHformalspec)
		Set sc=$$serializeFormal^%occName($get($$$comMemberKeyRaw(%class,$$$cCLASSmethod,"%OnNew",$$$cPROPorigin),%class),%method,%class_"."_%method,formal,.ppformalspec) If $$$ISERR(sc) Quit sc
		Set ppformalspec=$$ResetDefaultValues^%occName(ppformalspec)
		$$$comMemberKeySet(%class,$$$cCLASSmethod,"%Construct",$$$cMETHuseractualtype,$$$normalize($$MethodUserActualtype^%occName(ppformalspec)))
		$$$comMemberKeySet(%class,$$$cCLASSmethod,"%Construct",$$$cMETHformalspecparsed,ppformalspec)
		Set persistent=$$$classIsPersistent(%class)
		If %code=0,'persistent {
			Set %codemode=$$$cMETHCODEMODECALL
			$$$GENERATE("..%OnNew")
		} Else {
			Do ProcessMethodFormalspec^%occName(%class,"%OnNew",.passbyref,.uservars)
			Set list=""
			For i=1:1:$length(passbyref) Set item=$piece(uservars,",",i),list=list_$select(i=1:"",1:",")_$select($extract(item,*-2,*)="...":"",1:".")_item
			If 'persistent {
				$$$GENERATE("	Quit ..%OnNew("_list_")")
			} Else {
				$$$GENERATE("	Try { Set sc=..%OnNew("_list_") } Catch newerror {}")
				$$$GENERATE("	If $isobject($get(newerror))=1||($$$ISERR(sc)) {")
				$$$GENERATE("		Kill $$$txLIST($this),$$$txOIDASSIGNED($this),$$$txOIDUNASSIGNED($this),$$$txMODIFIED($this)")
				$$$GENERATE("		If $get(i%""%%OID"")'="""" {")
				If $$$comMemberDefined(%class,$$$cCLASSmethod,"%ReleaseLock") {
						#; remove oref from oid list and release the lock
					$$$GENERATE("			If i%%Concurrency=3 { Do ..%ReleaseLock(""s"") } ElseIf i%%Concurrency=4 { Do ..%ReleaseLock(""e"") }")
				}
				$$$GENERATE("			$$$ActiveOidRemove(i%""%%OID"")")
				$$$GENERATE("		}")
				$$$GENERATE("		If $isobject($get(newerror))=1 Throw newerror")
				$$$GENERATE("	}")
				$$$GENERATE("	Quit sc")
			}
		}
	} ElseIf %code'=0 {
		$$$GENERATE("	Quit $$$OK")
	}
	QUIT $$$OK
}

/// Normalizes all of an object's property values by invoking the data type <b>Normalize</b> methods.
/// 
/// Many data types may allow many different representations of the same value. 
/// Normalization converts a value to its cannonical, or <em>normalized</em>, form.
Method %NormalizeObject() As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0,code=0
	$$$INITCODEQUEUE(1)
	Set prop=""
	For {
		Set prop=$$$comMemberNext(%class,$$$cCLASSproperty,prop) Quit:prop=""
		If prop="%%OID"||(prop="%Concurrency") Continue
		#; see if the datatype has Normalize() method
		If $$$comSubMemberDefined(%class,$$$cCLASSproperty,prop,$$$cPROPmethod,"Normalize")=0 Continue
		Kill origin
		#; do nothing if property is calculated
		$$$comMemberKeyGetLO(tmp,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcalculated) If tmp Continue
		#; do nothing if property is multidimensional
		$$$comMemberKeyGetLO(tmp,origin,%class,$$$cCLASSproperty,prop,$$$cPROPmultidimensional) If tmp Continue
		Set qprop=$$$QN(prop)
	
		#; Handle normalizing collections of datatypes
		$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
		If $listfind($$$cPROPCOLLECTIONREGULAR,collection) {
			$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
			If $$$classIsDataType(type) {
				$$$QUEUECODE(1,"	If m%"_qprop_" Set key="""" For  Set key=$order(i%"_qprop_"(key),1,data) Quit:key=""""  Set:data'="""" i%"_qprop_"(key)=.."_$$$QN(prop_"Normalize")_"(data)")
				Set code=1
			}
			Continue
		}
	
		#; do nothing if property is not a datatype
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
		If '$$$classIsDataType(runtimetype) Continue

		#; normalize this property
		$$$QUEUECODE(1,"	If m%"_qprop_" Set:i%"_qprop_"'="""" i%"_qprop_"=(.."_$$$QN(prop_"Normalize")_"(i%"_qprop_"))")
		Set code=1
	}
	If code {
		$$$GENERATE("	If '$system.CLS.GetModified() Quit $$$OK")
		$$$DEQUEUECODE(1)
	}
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// This method is somewhat similar to %IsModified but it also checks to see if swizzled
/// references would cause the object to become modified should they be serialized. This works
/// on the assumption that a reference to a persistent object will never be modified if the ID has
/// already been assigned. For references to serial objects, a call to %ObjectModified indicates
/// whether or not the serialized value is different. If the reference to a swizzled object is
/// different from the initial object state then the $$$objModAll macro will already return true.
/// Reference the <property>Set code.
/// 
/// Returns true (1) if this instance has been modified, otherwise false (0).
Method %ObjectModified() As %Integer [ CodeMode = generator, ServerOnly = 1 ]
{
	s %code=0
	$$$GENERATE("	If $system.CLS.GetModified() Quit 1")
	#; If the modified=0 then this class is always modified for backward compatability when we supported
	#; other modified states so we always call %SaveData even if the object is not changed which is
	#; what the original behavior was
	$$$comClassKeyGetLvar(modified,%class,$$$cCLASSmodified)
	#; for embedded objects, create new ones
	Set prop = ""
	For {
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop) Quit:prop=""
		Kill origin
		$$$comMemberKeyGetLO(tCollection,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
		if tCollection = "" { set tType = $$$cPROPruntimetype } else { set tType = $$$cPROPtype }
		$$$comMemberKeyGetLO(tPropType,origin,%class,$$$cCLASSproperty,prop,tType)
		Set classtype=$$$getClassType(tPropType) If classtype'=$$$cCLASSCLASSTYPESERIAL,classtype'=$$$cCLASSCLASSTYPESTREAM Continue
		$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcalculated) If calculated Continue
		$$$comMemberKeyGetLO(relationship,origin,%class,$$$cCLASSproperty,prop,$$$cPROPrelationship)
		#; Only generate modified check for embedded objects. Relationships with serial objects are difficult to implement and are rare but don't prevent it here...
		If relationship {
			$$$comMemberKeyGetLO(cardinality,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcardinality)
			If cardinality'=$$$cPROPCARDINALITYONE,cardinality'=$$$cPROPCARDINALITYPARENT Continue
		}
		set tPropQ = $$$QN(prop)
		if tCollection = "" {
			$$$GENERATE("	If r%"_tPropQ_"'=$$$NULLOREF,.."_tPropQ_".%ObjectModified() Quit 1")
		} else {
			#; If the property is swizzled then retrieve the object value from the SaveSet. If it isn't there
			#; then call GetObject (creates a new SaveSet to serialize the reference object only if necessary)
			$$$GENERATE("	Set tModified=0,tKey="""" For { Set tKey=$order(r%"_tPropQ_"(tKey),1,tOref) Quit:tKey=""""  If (tOref '= $$$NULLOREF) && (tOref.%ObjectModified()) { Set tModified = 1 Quit } } Quit:tModified 1")
		}
	}
	$$$GENERATE("	Quit "_$select(modified=0:"1",1:"0"))
	QUIT $$$OK
}

/// Build the list of reachable objects and their dependencies
Method %BuildObjectGraph(depth As %Integer = 3, root As %Boolean = 1) As %Status [ Internal, ServerOnly = 1 ]
{
	Set sc=..%AddToSaveSet(depth) If $$$ISERR(sc) Quit sc
	Set newdepth=$select(depth'=2:depth,1:1)
	Set i=""
	For {
		Set i=$order(%objTX(6,i),1,objRef) Quit:i=""
		If '$data(%objTX(0,+objRef)) Set sc=objRef.%AddToSaveSet(newdepth) If $$$ISERR(sc) Kill %objTX(6),%objTX(7),%objTX(8) Goto exit
	}
	Set i=""
	For {
		Set i=$order(%objTX(7,i),1,data) Quit:i=""
		Set intRef=$li(data),modified=$li(data,2)
		If '$data(%objTX(11,intRef)),$zobjref(intRef).%ObjectModified() {
			Set %objTX(2,$i(%objTX(2)))=$lb(intRef,modified),%objTX(11,intRef)=%objTX(2)
		}
	}
	Set i="" For  {
		Set i=$order(%objTX(8,i),1,data) Quit:i="" 
		Set intRef=$list(data),ownerRef=$list(data,2),type=$list(data,3)
		If type=2 {
			If $get(%objTX(1,%objTX(0,intRef),1))="" Set %objTX(1,%objTX(0,intRef),3,%objTX(0,ownerRef))="",%objTX(1,%objTX(0,ownerRef),2,%objTX(0,intRef))=""
		} ElseIf type=3 {
			If '$get(%objTX(11,intRef)) {
				Set serialVal=$zobjref(intRef)."%%OID"
				If $$$oidPrimary(serialVal)'=$list(data,4) {
					If $d(%objTX(11,ownerRef)) {
						Set %objTX(2,%objTX(11,ownerRef))=$lb(ownerRef,$li($get(%objTX(7,+$g(%objTX(0,ownerRef))),$lb("",2))),2)
					} Else {
						Set %objTX(2,$i(%objTX(2)))=$lb(ownerRef,$li($get(%objTX(7,+$g(%objTX(0,ownerRef))),$lb("",2))),2),%objTX(11,ownerRef)=%objTX(2)
					}
				}
				Set %objTX(1,%objTX(0,intRef),1)=serialVal
			} Else {
				Set %objTX(1,%objTX(0,intRef),3,%objTX(0,ownerRef))="",%objTX(1,%objTX(0,ownerRef),2,%objTX(0,intRef))=""
			}
		}
	}
	Kill %objTX(6),%objTX(7),%objTX(8)
	#; When called to shallow save do not process disconnected objects
	If depth=1||('root) Goto exit
	#; Process the disconnected objects to save. If also a DCO delete then don't add to SaveSet.
	For  {
		Set intRef = $Order(%objTX(4,""),1,objRef) Quit:intRef=""
		Kill %objTX(4,intRef)
		If '$data(%objTX(5,intRef)),'$data(%objTX(0,intRef)) {
			Set sc=objRef.%BuildObjectGraph(depth,0) If $$$ISERR(sc) Quit
			If $data(%objTX(5,intRef)) {
				#; This is true if the current object was in the disconnected set of one collection, but is
				#; deleted by another disconnected set at which point we should not be in the save graph at all
				Set sc=objRef.%RemoveFromSaveSet() If $$$ISERR(sc) Quit
			} Else {
				Set %objTX(5,intRef) = objRef
			}
		}
	}
exit	Quit sc
}

/// <p>This method adds the current object to the SaveSet containing objects that are part of the current %Save() for
/// persistent classes or %GetSwizzleObject for serial classes. A queue of objects to be saved or
/// serialized is also constructed. Only modified objects are included in the save queue. The value
/// (OID or serial value in OID form) of each object is also placed in the SaveSet.</p>
/// 
/// <p>This method will invoke the %OnAddToSaveSet method if it is implemented. See that method for
/// more information.</p>
/// <p>%AddToSaveSet should not ever be invoked directly except from <method>%OnAddToSaveSet</method>.</p>
/// 
/// <p>This method takes these parameters:
/// 
/// <var>depth</var>, with these values:<br>
/// <table cols=2  >
/// <tr>
/// <td width="33%" valign="top">1:</td>
/// <td valign="top">Include this object in the SaveSet and, if it has not been serialized put it in the save queue and invoke %AddToSaveSet on any objects referenced by this object to the SaveSet with a depth of 1.</td>
/// </tr>
/// <tr>
/// <td width="33%" valign="top">2:</td>
/// <td valign="top">Include this object in the SaveSet and save queue. Also invoke %AddToSaveSet on any referenced objects in the SaveSet with a depth of 1.</td>
/// </tr>
/// <tr>
/// <td width="33%" valign="top">3:</td>
/// <td valign="top">Include this object in the SaveSet and, if modified, the save queue. Also invoke %AddToSaveSet on any referenced objects in the SaveSet with a depth of 3.</td>
/// </tr>
/// </table>
/// 
/// <var>refresh</var>, with these values:<br>
/// <table cols=2  >
/// <tr>
/// <td width="33%" valign="top">0:</td>
/// <td valign="top">Add this object to the save set only if it isn't already included.</td>
/// </tr>
/// <tr>
/// <td width="33%" valign="top">1:</td>
/// <td valign="top">Add this object to the SaveSet even if it already exists. This causes 
/// object dependencies to be rebuilt. Typically, this value is only passed
/// by %OnAddToSaveSet when it modifies objects other than the current one.</td>
/// </tr>
/// </table>
/// 
/// <p>Note: Swizzled serial objects always have an empty serial value and will always be placed in the save queue and the SaveSet.
/// the value of <var>depth</var> simply gets passed on to its referenced objects.
Method %AddToSaveSet(depth As %Integer = 3, refresh As %Integer = 0) As %Status [ CodeMode = generator, GenerateAfter = (%OnAddToSaveSet, %OnAfterSave, %OnBeforeSave), PlaceAfter = %SerializeObject, ServerOnly = 1 ]
{
	Set %code=0,onafter=0,onbefore=0 $$$comMemberKeyGetLvar(onadd,%class,$$$cCLASSmethod,"%OnAddToSaveSet",$$$cMETHrunnable)
	$$$comMemberKeyGetLvar(connection,%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)
	Set runtimeclasstype=$$$getClassType(%class)
		#; The swizzling interface is implemented by subclasses of %RegisteredObject. Only swizzlable objects are included in the save set
		#; but any object can reference swizzlable objects that should be included. The swizzle type of a class is PERSISTENT, SERIAL or STREAM
	Set persistent=runtimeclasstype=$$$cCLASSCLASSTYPEPERSISTENT,serial=runtimeclasstype=$$$cCLASSCLASSTYPESERIAL,stream=runtimeclasstype=$$$cCLASSCLASSTYPESTREAM
		#; 'registered' is a flag that is true when an object does not implement the serialization (swizzling) interface
	Set registered = '( persistent + serial + stream )
		#; Don't redo this work if done once inside this transaction
	$$$GENERATE("	Set sc=$$$OK,intOref=+$this")
	$$$GENERATE("	If $data(%objTX(0,intOref),index) {")
	$$$GENERATE("		If 'refresh RETURN $$$OK")
	$$$GENERATE("		Set intPoref="""" For  Set intPoref=$order(%objTX(1,index,2,intPoref)) Quit:intPoref=""""  Kill %objTX(1,%objTX(0,intPoref),3,index),%objTX(1,index,2,%objTX(0,intPoref))")
	$$$GENERATE("	}")
	If serial {
		$$$GENERATE("	Set:'$d(index) (index,%objTX(0,intOref))=$i(%objTX(1)),%objTX(1,index)=$this Set %objTX(1,index,1)="""",%objTX(7,index)=$lb(intOref,2)")
	} ElseIf persistent {
		$$$comMemberKeyGetLvar(onafter,%class,$$$cCLASSmethod,"%OnAfterSave",$$$cMETHrunnable)
		$$$comMemberKeyGetLvar(onbefore,%class,$$$cCLASSmethod,"%OnBeforeSave",$$$cMETHrunnable)
		$$$comMemberKeyGetLvar(GUIDENABLED,%class,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		$$$comMemberKeyGetLvar(objjournal,%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault)
		$$$comMemberKeyGetLvar(tDSTIME,%class,$$$cCLASSparameter,"DSTIME",$$$cPARAMdefault)
		if ($$$ucase(tDSTIME) = "AUTO") {set tDSTIME = 1 }
		elseif ($$$ucase(tDSTIME) = "TIME") {
			set tDSTIME = 2
		}
		
		elseif ($$$ucase(tDSTIME) = "CONDITIONAL") { //DP-404466
			set tDSTIME = 3
		}
		else { set tDSTIME = 0 }
		$$$GENERATE("	Set:'$d(index) (index,%objTX(0,intOref))=$i(%objTX(1)),%objTX(1,index)=$this Set %objTX(1,index,1)=i%""%%OID"",%objTX(1,index,6)=1 If (i%""%%OID"" '= """") && (depth<2) { Quit $$$OK } Else { Set %objTX(7,index)=$lb(intOref,1) }")
		set tTriggered = 0
		if 'onafter && 'onbefore && 'onadd && 'GUIDENABLED && 'objjournal {
			set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
			While prop '= "" {
				if $$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPsqlcomputed) {
					if $$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPsqlcomputeonchange) [ "%%" { set tTriggered = 1 quit }
				}
				Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
			}
		}
		If ((onafter) || (onbefore) || (onadd)) || (objjournal) || (GUIDENABLED) || (tTriggered) || (tDSTIME) {
			//DP-404466
			If (tDSTIME=3){ 
				$$$comMemberKeyGetLvar(tDSCONDITION,%class,$$$cCLASSparameter,"DSCONDITION",$$$cPARAMdefault)
				$$$GENERATE("   If ("_tDSCONDITION_"){")
				$$$GENERATE("		Set %objTX(1,index,4)=$select(%objTX(1,index,1)="""":1,..%ExistsId($$$oidPrimary(%objTX(1,index,1))):0,1:1)")
				$$$GENERATE("   }")
			}
			Else {
				$$$GENERATE("	Set %objTX(1,index,4)=$select(%objTX(1,index,1)="""":1,..%ExistsId($$$oidPrimary(%objTX(1,index,1))):0,1:1)")
			}
		}
	
	} ElseIf stream {
		$$$GENERATE("	Set:'$d(index) (index,%objTX(0,intOref))=$i(%objTX(1)),%objTX(1,index)=$this Set %objTX(1,index,1)="""",%objTX(7,index)=$lb(intOref,3)")
	} Else {
		$$$GENERATE("	Set:'$d(index) (index,%objTX(0,intOref))=$i(%objTX(1)),%objTX(1,index)=$this Set %objTX(1,index,1)=-1")
	}
	If onadd {
		$$$GENERATE("	Set sc=..%OnAddToSaveSet($select(depth'=2:depth,1:1),"_$select(persistent:"%objTX(1,index,4)",1:0)_",$increment(%objTX(1,index,5))) Quit:$$$ISERR(sc) sc")
		#; Detect if the callback removed the current object from the save, if so do not process any of its properites
		$$$GENERATE("	If '$data(%objTX(0,intOref)) Quit $$$OK")
	}
	#;
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		Set qp=$$$QuoteName(prop),qprop=$$$QN(prop)
		Kill origin
		$$$comMemberKeyGetLO(propruntimetype,origin,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
		Set propruntimeclasstype = $$$getClassType(propruntimetype)
		$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
		Set propclasstype = $$$getClassType(type)
			#; do nothing if property is a datatype or the property is "container managed"
	/// TODO: DLP - detect "container managed" objects. Container managed objects are serialized directly by their container and are not
	///			serialized through the SaveGraph. Container managed objects must be literal or "self contained". A document object may have
	///			object valued properties but they are container managed by definition.
	///
	///			For now, detect "container managed" documents by checking the runtime type = %Document.Object. This isn't good long term as
	///			other classes can be container managed, streams specifically.
		#; Check propclasstype rather than propruntimeclasstype so we can detect $$$cCLASSCLASSTYPESYSTEM types in collections as
		#; these do not support adding to the save set either
		Set tContainerManaged=$select(propclasstype=$$$cCLASSCLASSTYPESYSTEM:1,
					      propclasstype=$$$cCLASSCLASSTYPEDYNAMIC:1,
					      propruntimetype="%Document.Object":1,
					      1:0)
		If (propruntimeclasstype '= $$$cCLASSCLASSTYPEDATATYPE) && ((connection = "") || (propruntimeclasstype '= $$$cCLASSCLASSTYPESTREAM)) && ('tContainerManaged) {
				#; don't swizzle if the property type does not have swizzling interface
			Set proppersistent = propruntimeclasstype = $$$cCLASSCLASSTYPEPERSISTENT, propserial = propruntimeclasstype = $$$cCLASSCLASSTYPESERIAL, propstream = propruntimeclasstype = $$$cCLASSCLASSTYPESTREAM
			$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcalculated)
			$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
			$$$comMemberKeyGetLO(proprelationship,origin,%class,$$$cCLASSproperty,prop,$$$cPROPrelationship) If proprelationship { $$$comMemberKeyGetLO(propcardinality,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcardinality) }
				#; If this is a collection of objects then add each object to the save set (the collection object itself does not need to go in the save set)
			If ( collection '= "") && ($listfind($$$cPROPCOLLECTIONREGULAR,collection)) && ('proprelationship) && ('calculated) {
					#; Process the collection
				If propclasstype '= $$$cCLASSCLASSTYPEDATATYPE {
					Set inttype=$select(registered:1,propclasstype=$$$cCLASSCLASSTYPEPERSISTENT:2,propclasstype=$$$cCLASSCLASSTYPESERIAL:3,propclasstype=$$$cCLASSCLASSTYPESTREAM:3,1:1)
					$$$GENERATE("	Set key=""""")
					$$$GENERATE("	For  {")
					$$$GENERATE("		Set key=$order(r%"_qprop_"(key),1,Poref) Quit:key=""""")
					$$$GENERATE("		If $isobject(Poref)=1 Set:'$data(%objTX(0,+Poref)) %objTX(6,$i(%objTX(6)))=Poref"_$select(inttype=1:"",1:" Set %objTX(8,$i(%objTX(8)))=$lb(+Poref,intOref,"_inttype_$select(inttype=3:",$$$oidPrimary(i%"_qprop_"(key))",1:"")_")"))
					$$$GENERATE("	}")
				}
			} Else {
				If '( (propstream) && ( $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPtransient) ) ) && '(calculated) && '($$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPmultidimensional)) {
						#; Relationships with cardinality = MANY or CHILDREN don't participate in the save SaveSet, they simply make the
						#; connections between related objects. NOTE: This line generates optimized version of same code as next couple of
						#; lines, if you change one you should change the other.
					If (proprelationship) && ((propcardinality=$$$cPROPCARDINALITYCHILDREN) || (propcardinality=$$$cPROPCARDINALITYMANY)) {
						$$$GENERATE("	Set Poref=r%"_qprop_" If Poref'=$$$NULLOREF,'$data(%objTX(0,+Poref)) Set %objTX(6,$i(%objTX(6)))=Poref")
					} Else {
						If 'registered,proppersistent {
							$$$GENERATE($Char(9)_"Set Poref=r%"_qprop_" If Poref'=$$$NULLOREF Set:'$data(%objTX(0,+Poref)) %objTX(6,$i(%objTX(6)))=Poref Set %objTX(8,$i(%objTX(8)))=$lb(+Poref,intOref,2)")
						} ElseIf 'registered,propserial||(propstream) {
								// Make sure the serial object is properly initialized
							$$$GENERATE($Char(9)_"if ('$d(i%"_qprop_"))&&(.."_qprop_")")
							$$$comMemberArrayGetLvar(hasclass,%class,$$$cCLASSproperty,prop,$$$cPROPparameter,"CLASSNAME")
							#; Serial objects behave like literals. If the serial object has been swizzled and placed in the SaveQueue then we need a dependency. Otherwise take it literally.
							If hasclass {
								$$$GENERATE("	Set Poref=r%"_qprop_" If Poref'=$$$NULLOREF Set:'$data(%objTX(0,+Poref)) %objTX(6,$i(%objTX(6)))=Poref Set %objTX(8,$i(%objTX(8)))=$lb(+Poref,intOref,3,$$$oidPrimary(i%"_qprop_"))")
							} Else {
								$$$GENERATE("	Set Poref=r%"_qprop_" If Poref'=$$$NULLOREF Set:'$data(%objTX(0,+Poref)) %objTX(6,$i(%objTX(6)))=Poref Set %objTX(8,$i(%objTX(8)))=$lb(+Poref,intOref,3,i%"_qprop_")")
							}
						} Else {
							$$$GENERATE("	Set Poref=r%"_qprop_" If Poref'=$$$NULLOREF,'$data(%objTX(0,+Poref)) Set %objTX(6,$i(%objTX(6)))=Poref")
						}
					}
				}
			}
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
	$$$GENERATECODEBLOCKS()
	$$$GENERATE("exit	Quit sc")
	QUIT $$$OK
}

/// <p>This method removes the current object from the SaveSet. If this object is also in the save queue
/// it is removed from there as well.</p>
Method %RemoveFromSaveSet() As %Status [ ServerOnly = 1 ]
{
	Set intRef=+$this
	Set i="" For  Set i=$order(%objTX(6,i),1,objRef) Quit:i=""  If objRef=$this Kill %objTX(6,i)
	Set i="" For  Set i=$order(%objTX(8,i),1,data) Quit:i=""  If $list(data)=intRef||($list(data,2)=intRef) Kill %objTX(8,i)
	#; If the object isn't in the SaveSet then just quit...
	If '$data(%objTX(0,intRef),objIdx) Quit $$$OK
	Kill %objTX(7,objIdx)
	#; Remove this object from successor lists
	Set intSucc="" For  Set intSucc=$order(%objTX(1,objIdx,3,intSucc)) Quit:intSucc=""  Kill %objTX(1,intSucc,2,objIdx)
	#; Remove this object from predecessor lists
	Set intPred="" For  Set intPred=$order(%objTX(1,objIdx,2,intPred)) Quit:intPred=""  Kill %objTX(1,intPred,3,objIdx)
	#; and remove the object from the SaveSet and SaveQueue
	Kill %objTX(1,objIdx),%objTX(0,intRef)
	If $data(%objTX(11,intRef)) Kill %objTX(2,%objTX(11,intRef)),%objTX(11,intRef)
	Quit $$$OK
}

/// 	This method retrieves all of the serial values for referenced objects and places them into the instance variables,
/// 	Validates, Normalizes, and serializes the object (with a save of the persistent image if persistent).
/// <br>
/// This method is not meant to be called directly. It is called by %Save and by %GetSwizzleObject.
Method %SerializeObject(ByRef serial As %Binary, partial As %Integer = 0) As %Status [ CodeMode = generator, GenerateAfter = (%OnAfterSave, %OnBeforeSave), ServerOnly = 1 ]
{
	s %code=0,onafter=0,onbefore=0,GUIDENABLED=0, journal = 0
	Set connection=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)
	Set runtimeclasstype=$$$getClassType(%class)
	Set persistent = runtimeclasstype = $$$cCLASSCLASSTYPEPERSISTENT,serial = runtimeclasstype = $$$cCLASSCLASSTYPESERIAL
	If persistent {
		$$$comMemberKeyGetLvar(onafter,%class,$$$cCLASSmethod,"%OnAfterSave",$$$cMETHrunnable) $$$comMemberKeyGetLvar(onbefore,%class,$$$cCLASSmethod,"%OnBeforeSave",$$$cMETHrunnable) $$$comMemberKeyGetLvar(GUIDENABLED,%class,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		Set journal = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault)
		Set tDSTIME = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"DSTIME",$$$cPARAMdefault)
		if ($$$ucase(tDSTIME) = "AUTO") {
			$$$comMemberKeyGetLvar(tDSINTERVAL,%class,$$$cCLASSparameter,"DSINTERVAL",$$$cPARAMdefault)
			if tDSINTERVAL '> 0 { set tDSTIME = 1 } else { set tDSTIME = 2 }
		}
		
		elseif ($$$ucase(tDSTIME) = "CONDITIONAL") { //DP-404466
			$$$comMemberKeyGetLvar(tDSINTERVAL,%class,$$$cCLASSparameter,"DSINTERVAL",$$$cPARAMdefault)
			$$$comMemberKeyGetLvar(tDSCONDITION,%class,$$$cCLASSparameter,"DSCONDITION",$$$cPARAMdefault)
			if tDSINTERVAL '> 0 { set tDSTIME = 3 } else { set tDSTIME = 4 }
		}
		else { set tDSTIME = 0 }
			#; Disable journal calls for %Storage.SQL - handled by triggers.
		If journal || tDSTIME {
			Set storageclass = ""
			$$$comClassKeyGetLvar(storagename,%class,$$$cCLASSstoragestrategy)
			If storagename '= "" $$$comMemberKeyGetLvar(storageclass,%class,$$$cCLASSstorage,storagename,$$$cSDEFtype)
			If $$$SQLStorageIsSQL(storageclass) { Set journal = 0, tDSTIME = 0 }
		}
	}
	$$$GENERATE($Char(9)_"try {")
	If persistent { $$$GENERATE($Char(9,9)_"If $get(%objTX2(+$this)) { Set partial = 1 } ElseIf ('partial) { Set %objTX2(+$this) = 1 }") }
	#;
		#; some of the code from this block will be placed into a temporary queue and then added to %code later
		#; tCode is that queue.
	set tCode = 0
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		Set qp=$$$QuoteName(prop),qprop=$$$QN(prop)
		Kill origin
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
		Set propruntimeclasstype=$$$getClassType(runtimetype)
			#; do nothing if property is a datatype or isn't storable
		If (propruntimeclasstype '= $$$cCLASSCLASSTYPEDATATYPE) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPcalculated)) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPmultidimensional)) && ((connection = "") || (propruntimeclasstype '= $$$cCLASSCLASSTYPESTREAM)) {
			$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
			Set propclasstype = $$$getClassType(type)
				#; don't swizzle if the property type does not have swizzling interface
			Set proppersistent = propruntimeclasstype = $$$cCLASSCLASSTYPEPERSISTENT, propserial = (propruntimeclasstype = $$$cCLASSCLASSTYPESERIAL), propstream = (propruntimeclasstype = $$$cCLASSCLASSTYPESTREAM) $$$comMemberKeyGetLO(required,origin,%class,$$$cCLASSproperty,prop,$$$cPROPrequired)
			$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
			$$$comMemberArrayGetLvar(hasclass,%class,$$$cCLASSproperty,prop,$$$cPROPparameter,"CLASSNAME")
			If ((collection = $$$cPROPCOLLECTIONARRAY) || (collection = $$$cPROPCOLLECTIONLIST)) && ((propclasstype = $$$cCLASSCLASSTYPEPERSISTENT) || (propclasstype = $$$cCLASSCLASSTYPESERIAL) || (propclasstype = $$$cCLASSCLASSTYPESTREAM)) && ('$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPrelationship)) {
					#; If the property is swizzled then retrieve the object value from the SaveSet. If it isn't there
					#; then call GetObject (creates a new SaveSet to serialize the reference object only if necessary)
				If propclasstype=$$$cCLASSCLASSTYPESTREAM {
					set tCode($Increment(tCode)) = $Char(9,9)_"Set key="""" For { Set key=$order(r%"_qprop_"(key),1,cref) Quit:key=""""  If cref'=$$$NULLOREF { If ('$data(%objTX(0,+cref))) { Set sc=cref.%GetSwizzleObject(1,.eoid) If $$$ISOK(sc) { Set cidx=$i(%objTX(1)),%objTX(0,+cref)=cidx,%objTX(1,cidx)=cref,%objTX(1,cidx,1)=eoid,%objTX(1,cidx,6)="_$select(propclasstype=$$$cCLASSCLASSTYPEPERSISTENT:1,1:2)_"} Else { $$$ThrowStatus(sc) } } Set M%"_qprop_"=1,i%"_qprop_"(key)="_$select('hasclass:"$$$oidRemoveClassName(%objTX(1,%objTX(0,+cref),1))",hasclass=1:"$lb($$$oidRemoveAd1(%objTX(1,%objTX(0,+cref),1)))",1:"%objTX(1,%objTX(0,+cref),1)")_" } }"
				} Else {
					set tElementOIDType = $Select($$$comMemberKeyGet(runtimetype,$$$cCLASSparameter,"IdCollection",$$$cPARAMdefault):0,1:1)
					set tCode($Increment(tCode)) = $Char(9,9)_"Set key="""" For { Set key=$order(r%"_qprop_"(key),1,cref) Quit:key=""""  If cref'=$$$NULLOREF { If ('$data(%objTX(0,+cref))) { Set sc=cref.%GetSwizzleObject(1,.eoid) If $$$ISOK(sc) { Set cidx=$i(%objTX(1)),%objTX(0,+cref)=cidx,%objTX(1,cidx)=cref,%objTX(1,cidx,1)=eoid,%objTX(1,cidx,6)="_$select(propclasstype=$$$cCLASSCLASSTYPEPERSISTENT:1,1:2)_"} Else { $$$ThrowStatus(sc) } } Set M%"_qprop_"=1,i%"_qprop_"(key)="_$select('hasclass:$select(tElementOIDType:"$$$oidRemoveClassName",1:"$$$oidPrimary")_"(%objTX(1,%objTX(0,+cref),1))",1:"%objTX(1,%objTX(0,+cref),1)")_" } }"
				}
			} ElseIf (proppersistent+propserial+propstream) {
				If 'propstream { set serialref = $select('hasclass:"$$$oidPrimary(%objTX(1,%objTX(0,+r%"_qprop_"),1))",1:"%objTX(1,%objTX(0,+r%"_qprop_"),1)") }
				Else { Set serialref = $select('hasclass:"$$$oidPrimary(%objTX(1,%objTX(0,+r%"_qprop_"),1))",hasclass=1:"$$$oidRemoveAd1(%objTX(1,%objTX(0,+r%"_qprop_"),1))",1:"%objTX(1,%objTX(0,+r%"_qprop_"),1)") }
					#; If the property is swizzled then retrieve the object value from the SaveSet. If it isn't there
					#; then call GetObject (creates a new SaveSet to serialize the reference object only if necessary)
				set tCode($Increment(tCode)) = $Char(9,9)_"If r%"_qprop_"'=$$$NULLOREF { Set:'$data(%objTX(0,+r%"_qprop_")) %objTX(0,+r%"_qprop_")=$i(%objTX(1)),%objTX(1,%objTX(0,+r%"_qprop_"))=r%"_qprop_",%objTX(1,%objTX(0,+r%"_qprop_"),1)=.."_$$$QN(prop_"GetObject")_"(1),%objTX(1,%objTX(0,+r%"_qprop_"),6)="_$select(proppersistent:1,1:2)_" Set M%"_qprop_"=1,i%"_qprop_"="_serialref_" }"
				If proppersistent && required { set tCode($Increment(tCode)) = $Char(9,9)_"If i%"_qprop_"="""" $$$ThrowStatus($$$ERROR($$$PropertyRequired,$classname()_""::""_"_qp_"))" }
			}
		}
		if ($$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPsqlcomputed)) && ('$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPcalculated)) {
				#; these lines will need to change once we have the ability to add %%INSERT/%%UPDATE in Studio
			$$$comMemberKeyGetLO(tComputeOn,origin,%class,$$$cCLASSproperty,prop,$$$cPROPsqlcomputeonchange)
			set tOnInsert = $$$ucase(tComputeOn) [ "%%INSERT"
			set tOnUpdate = $$$ucase(tComputeOn) [ "%%UPDATE"
			if tOnInsert + tOnUpdate {
				$$$comMemberKeyGetLO(tREADONLY,origin,%class,$$$cCLASSproperty,prop,$$$cPROPreadonly)
				if 'tREADONLY { set tSet = ".." _ qprop } else { set tSet = "i%" _ qprop }
				if persistent {
					if tOnInsert && 'tOnUpdate { $$$GENERATE($Char(9,9)_"if %objTX(1,%objTX(0,+$this),4) { do .."_$$$QN(prop_"SetT") _ "() }") }
					elseif 'tOnInsert && tOnUpdate { $$$GENERATE($Char(9,9)_"if '%objTX(1,%objTX(0,+$this),4) { do .."_$$$QN(prop_"SetT") _ "() }") }
					else { $$$GENERATE($Char(9,9)_"do .."_$$$QN(prop_"SetT") _ "()") }
				}
				else { $$$GENERATE($Char(9,9)_"do .."_$$$QN(prop_"SetT") _ "()") }
			}
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
	$$$GENERATE($Char(9,9)_"$$$THROWONERROR(sc,..%ValidateObject(,0))")
	$$$GENERATE($Char(9,9)_"$$$THROWONERROR(sc,..%NormalizeObject())")
	if tCode { for tPtr = 1:1:tCode { $$$GENERATE(tCode(tPtr)) } }
	If persistent {
		$$$GENERATE($Char(9,9)_"$$$txAddObject($this)")
		If onbefore { $$$GENERATE($Char(9,9)_"If 'partial { $$$THROWONERROR(sc,..%OnBeforeSave(%objTX(1,%objTX(0,+$this),4))) }") }

/// ##BEGIN EVENT: SAVEDATA
///	TODO: INSERT FILING EVENT TRIGGER CALL HERE
		$$$GENERATE($Char(9,9)_"Set id=$$$oidPrimary(serial),sc=..%SaveData(.id) If $$$ISERR(sc) { $$$ThrowStatus(sc) }")
		$$$GENERATE($Char(9,9)_"Set serial=(..%Oid())")
		if GUIDENABLED {
				// Generate code to assign a GUID to a new object (as indicated by the 4 subscript of the save graph). If this object has no GUID
				// assigned then assign on, either from the save graph (used by object synch), from the %%GUID property (as assigned by
				// calling %OverrideGuidAssignment()) or generate one from scratch. If the GUID is overridden then we must also make sure it is
				// unique.
			$$$GENERATE($Char(9,9)_"if ($get(%objTX(1,+$g(%objTX(0,+$this)),4))) && ('$D(^OBJ.GUID(1,serial))) {")
			$$$GENERATE($Char(9,9,9)_"set guid = $Get(%objGUID(+$this)) set:guid="""" guid=..""%%GUID""")
			$$$GENERATE($Char(9,9,9)_"if guid="""" { set guid = $system.Util.CreateGUID() }")
			$$$GENERATE($Char(9,9,9)_"elseif $D(^OBJ.GUID(0,guid)) { set sc=$$$ERROR($$$KeyNotUnique,""GUID='""_guid_""'""),i%""%%GUID""="""" $$$ThrowStatus(sc) }")
			$$$GENERATE($Char(9,9,9)_"set ^OBJ.GUID(0,guid)=serial,^OBJ.GUID(1,serial)=guid")
			$$$GENERATE($Char(9,9)_"}")
			$$$GENERATE($Char(9,9)_"set i%""%%GUID"" = """"")
		}
			#; Generate post-save actions that are only performed for a complete serialization
		$$$GENERATE($Char(9,9)_"if 'partial {")
		if journal {
			if journal '= 3 {
				if GUIDENABLED { $$$GENERATE($Char(9,9,9)_"$$$txJournalObjectSave($classname(),jid,$$$oidPrimary(serial),%objTX(1,%objTX(0,+$this),4),$Get(^OBJ.GUID(1,serial)),$this,iJPtr)") }
				else { $$$GENERATE($Char(9,9,9)_"$$$txJournalObjectSave($classname(),jid,$$$oidPrimary(serial),%objTX(1,%objTX(0,+$this),4),"""",$this,iJPtr)") }
			}
			else { $$$GENERATE($Char(9,9,9)_"$$$txJournal($classname(),jid,$$$oidPrimary(serial),%objTX(1,%objTX(0,+$this),4))") }
		}
		if onafter { $$$GENERATE($Char(9,9,9)_"$$$THROWONERROR(sc,..%OnAfterSave(%objTX(1,%objTX(0,+$this),4)))") }
		if tDSTIME = 1 { $$$GENERATE($Char(9,9,9)_"$$$DSTIME($classname(),$$$oidPrimary(serial),%objTX(1,%objTX(0,+$this),4))") }
		elseif tDSTIME = 2 { $$$GENERATE($Char(9,9,9)_"$$$DSTIMEH($classname(),$$$oidPrimary(serial),%objTX(1,%objTX(0,+$this),4),"_$Select(tDSINTERVAL:tDSINTERVAL,1:1)_",tDST,tDSS)") }
		//DP-404466
		elseif tDSTIME = 3 { $$$GENERATE($Char(9,9,9)_"If ("_tDSCONDITION_") { $$$DSTIME($classname(),$$$oidPrimary(serial),%objTX(1,%objTX(0,+$this),4)) }") }
		elseif tDSTIME = 4 { $$$GENERATE($Char(9,9,9)_"If ("_tDSCONDITION_") { $$$DSTIMEH($classname(),$$$oidPrimary(serial),%objTX(1,%objTX(0,+$this),4),"_$Select(tDSINTERVAL:tDSINTERVAL,1:1)_",tDST,tDSS) }") }
		
		$$$GENERATE($Char(9,9,9)_"Set %objTX2(+$this) = 0")
		$$$GENERATE($Char(9,9)_"}")
/// END EVENT: SAVEDATA
	} ElseIf serial {
		$$$GENERATE($Char(9,9)_"Set serial=..%GetSerial(0),class=$classname(),class=$$$DenormalizeClassname(class),serial=$$$oidCompose(serial,class),i%""%%OID""=serial")
	} ElseIf runtimeclasstype = $$$cCLASSCLASSTYPESTREAM {
		$$$GENERATE($Char(9,9)_"$$$txAddObject($this)")
		If onbefore $$$GENERATE($Char(9,9)_"If 'partial { $$$THROWONERROR(sc,..%OnBeforeSave(1)) }")
		#; Keep track of modified streams for triggers
		$$$GENERATE($char(9,9)_"If ..%ObjectModified() Set %objTX(10,+$this)=""""")
		$$$GENERATE($Char(9,9)_"Set id=$$$oidPrimary(serial),sc=..%SaveData(.id) If $$$ISERR(sc) { $$$ThrowStatus(sc) }")
		If onafter $$$GENERATE($Char(9,9)_"If 'partial {  $$$THROWONERROR(sc,..%OnAfterSave(1)) }")
		$$$GENERATE($Char(9,9)_"Set serial=..%Oid(),i%""%%OID""=serial")
	}
	$$$GENERATE($Char(9,9)_"set sc=$$$OK")
	$$$GENERATE($Char(9)_"}")
	$$$GENERATE($Char(9)_"catch tException {")
	If persistent { $$$GENERATE($Char(9,9)_"If 'partial { Set %objTX2(+$this) = 0 }") }
	$$$GENERATE($Char(9,9)_"set sc = tException.AsStatus()")
	$$$GENERATE($Char(9)_"}")
	$$$GENERATE($Char(9)_"Quit sc")
	Quit $$$OK
}

/// This method is used by Language Binding Engine to 
/// send the whole object and all objects it referes to 
/// to the client.
Method %BindExport(dev As %String, ByRef Seen As %String, RegisterOref As %Boolean, AllowedDepth As %Integer, AllowedCapacity As %Integer) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
        Set %code = 0
        $$$GENERATE("   i $d(Seen(+$this)) q $$$OK")
        $$$GENERATE("   Set Seen(+$this)=$this")

        ; swizzle all properties before sending
        s Status = $$$OK
        s NumBranches=0
        $$$GENERATE("   s sc = $$$OK")
        s pname="" f  s pname=$$$comMemberNext(%class,$$$cCLASSinstancevar,pname) q:pname=""  d  q:$$$ISERR(Status)
        . i $$$comMemberKeyGet(%class,$$$cCLASSproperty,pname,$$$cPROPprivate) q
		. $$$setIvarHasRefSlot(map,%class,pname)
        . i 'map q
        . $$$GENERATE(" s proporef=.."_$$$QuoteName(pname))
        . i $i(NumBranches)
        . s prop(pname)=""
        $$$GENERATE("   d:RegisterOref InitObjVar^%SYS.BINDSRV($this)")
        $$$GENERATE("   i dev'="""" $$$BindPutOref(dev,$this)")
        If NumBranches>0 {
			$$$GENERATE(" If AllowedDepth>0 Set AllowedDepth = AllowedDepth - 1")
			$$$GENERATE(" If AllowedCapacity>0 Set AllowedCapacity = AllowedCapacity - 1/"_NumBranches)
		}
       
        ; send properties
        s pname="" f  s pname=$order(prop(pname)) q:pname=""  d  q:$$$ISERR(Status)
        . $$$comMemberKeyGetLvar(proptype,%class,$$$cCLASSproperty,pname,$$$cPROPtype)
        . $$$GENERATE(" s proporef=.."_$$$QuoteName(pname))
        . s collection=$$GetCollectionOfProperty^%occJava5(%class,pname,"")
        . i (collection=3)!(collection=4)!(collection=5) d
        . . $$$GENERATE("       i proporef'="""" d")
     . . $$$GENERATE("  . s idx="""" i proporef'="""" f  s elemoref=proporef.GetNext(.idx) q:idx=""""  $$$BindExportObj(elemoref,dev,Seen,RegisterOref,AllowedDepth,AllowedCapacity,sc) q:$$$ISERR(sc)")
     . . $$$GENERATE("  q:$$$ISERR(sc) sc")
        . i (collection > 0) d
        . . $$$GENERATE("       i proporef'="""",dev'="""" $$$BindPutOref(dev,proporef)")
        . . $$$GENERATE("       if proporef'="""",dev'="""" d")
        . . $$$GENERATE("       . $$$BindPutStr(dev,"_collection_")")
        . . $$$GENERATE("       . $$$BindPutStr(dev,proporef.Count())")
        . . i (collection=1)!(collection=3)!(collection=5) d
        . . . $$$GENERATE("     . for i=1:1:proporef.Count()  $$$BindPutStr(dev,proporef.GetAt(i))")
        . . i (collection=2)!(collection=4) d
        . . . $$$GENERATE("     . s idx="""" f  s value=proporef.GetNext(.idx) q:idx=""""  $$$BindPutStr(dev,idx) $$$BindPutStr(dev,value)")
        . else  if ($p(proptype,".") '= "%Library")  d
        . . $$$GENERATE("       i proporef'="""" $$$BindExportObj(proporef,dev,Seen,RegisterOref,AllowedDepth,AllowedCapacity,sc) q:$$$ISERR(sc) sc")
        $$$GENERATE("   Quit sc")
        Quit Status
}

/// <p>This method validates an object.</p>
/// <p>The <METHOD>%Save</METHOD> method of a persistent class calls this method before filing any objects in the database. The
/// <METHOD>%ValidateObject</METHOD> of a referencing object can call it. You can also call it explicitly at any time.</p>
/// <p><METHOD>%ValidateObject</METHOD> does the following:</p>
/// <ol>
/// <li>If present, it will call a user-supplied <METHOD>%OnValidateObject</METHOD> method.</li>
/// <li>It checks if any required property values are missing.</li>
/// <li>If the <i>PROPERTYVALIDATION</i> class parameter is set to <var>ValidateOnSave</var>, it validates each non-null property value by calling the
/// property method <var>IsValid</var> on each literal property and the <var>%ValidateObject</var> method for each object-valued embedded object
/// property (properties whose type extend %SerialObject).</li>
/// <li>If <var>checkserial</var> is 1, it forces the checking of any embedded object properties by calling their <var>%ValidateObject</var> method after
/// swizzling this property.
/// <li>If <var>checkserial</var> is 2, it forces the checking of any collections of serial types by iterating over those collections and calling their
/// <METHOD>%ValidateObject</METHOD> method after swizzling this property, in addition to the validation that occurs when checkserial is 1.
/// </ol>
/// <p><METHOD>%ValidateObject</METHOD> returns a %Status indicating success or error. It is up to the caller to process the error value.</p>
/// <p><METHOD>%ValidateObject</METHOD> does not validate object-valued reference properties (properties whose type extends %Persistent) due to the possibility
/// of circular dependencies between objects. The <METHOD>%Save</METHOD> method of a persistent class automatically detects and handles circular references
/// between objects. If you require the validation of reference properties, you can override this method in a subclass or call <METHOD>%Save</METHOD> directly.</p>
Method %ValidateObject(unused As %Integer = 0, checkserial As %Integer = 1) As %Status [ CodeMode = generator, GenerateAfter = %OnValidateObject, ServerOnly = 1 ]
{
	set %code=0
		#; class parameter PROPERTYVALIDATION=2 : ValidateOnSave
		#; validate=1 if validation is called for....
		#; lcode holds the code in 'suspension' until it can be logically generated.
		#; Code Queue 1 is for code that executed only when ..%IsModified is TRUE
		#; Code Queue 2 is for required reference and embedded properties
		#; Code Queue 3 is for embedded property validation (this queue is not used)
	$$$INITCODEQUEUE(1)
	$$$INITCODEQUEUE(2)
	set tClassType = $$$getClassType(%class)
	set onvalidate=0,classispersistent=tClassType=$$$cCLASSCLASSTYPEPERSISTENT
	$$$comMemberKeyGetLvar(validate,%class,$$$cCLASSparameter,"PROPERTYVALIDATION",$$$cPARAMdefault)
		#; find out if there is a %OnValidateObject method. If there is, call it first
	if $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnValidateObject",$$$cMETHrunnable) $$$GENERATE($Char(9)_"Set sc=..%OnValidateObject()") set onvalidate=1
	if 'onvalidate { $$$GENERATE($Char(9)_"set sc=$$$OK") }
	if tClassType = $$$cCLASSCLASSTYPESERIAL {
		$$$comMemberKeyGetLvar(tVALIDIFNULL,%class,$$$cCLASSparameter,"VALIDIFNULL",$$$cPARAMdefault)
		if tVALIDIFNULL {
			$$$GENERATE($Char(9)_"if ..%IsNull() { quit sc }")
		}
	}
	set prop = ""
	for {
		set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop) quit:prop=""
		kill origin
			#; Calculated, ReadOnly and multidimensional properties are never validated....
		if (prop="%%OID")||(prop="%Concurrency")||$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPcalculated)||$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPreadonly)||$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPmultidimensional) {
			continue
		}
		set qp = $$$QuoteName(prop), qprop = $$$QN(prop)
		$$$comMemberKeyGetLO(required,origin,%class,$$$cCLASSproperty,prop,$$$cPROPrequired)
			// The IDENTITY property is assigned a value during SAVE if no value is present, effectively satisfying the REQUIRED constraint
			// all of the time. If it is satisfied all of the time then there is no need to check it for the IDENTITY property. 
		if required && ($$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,prop,$$$cPROPidentity)) { set required = 0 }
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
		set runtimeclasstype = $$$getClassType(runtimetype)
		set literal = runtimeclasstype = $$$cCLASSCLASSTYPEDATATYPE, persistent = runtimeclasstype = $$$cCLASSCLASSTYPEPERSISTENT, serial = runtimeclasstype = $$$cCLASSCLASSTYPESERIAL, stream = runtimeclasstype = $$$cCLASSCLASSTYPESTREAM
		$$$comMemberKeyGetLO(transient,origin,%class,$$$cCLASSproperty,prop,$$$cPROPtransient)
			#; collections of literals will be treated as embedded objects, so they don't go here.
			#; 'literal' is TRUE for datatype attributes, FALSE for all others
		if literal {
			set tSuppressRequiredCheck = 0
			if required {
				if classispersistent && ($case(runtimetype,"%Library.Counter":1,"%Library.RowVersion":1,"%Library.AutoIncrement":1,:0)) {
					set tSuppressRequiredCheck = 1
					$$$QUEUECODE(1,$Char(9)_"if ..%Id() '= """" { Set iv=.."_qprop_" If iv="""" Set rc=$$$ERROR($$$PropertyRequired,$classname()_""::"_prop_"(""_$this_"""_$select(classispersistent:",ID=""_..%Id()_""",1:"")_")""),sc=$$$ADDSC(sc,rc) }")
				}
				else {
					$$$QUEUECODE(1,$Char(9)_"Set iv=.."_qprop_" If iv="""" Set rc=$$$ERROR($$$PropertyRequired,$classname()_""::"_prop_"(""_$this_"""_$select(classispersistent:",ID=""_..%Id()_""",1:"")_")""),sc=$$$ADDSC(sc,rc)")
				}
			}
			if validate = 2 {
				if 'required || tSuppressRequiredCheck { $$$QUEUECODE(1,"	If m%"_qprop_" Set iv=.."_qprop_" If iv'="""" Set rc=(.."_$$$QN(prop_"IsValid")_"(iv)) If $$$ISERR(rc) Set sc=$$EmbedErr^%occSystem(sc,rc,$$$ERRORCODE($$$DatatypeValidationFailed),"_qp_",iv)") }
				else { $$$QUEUECODE(1,$Char(9)_"If m%"_qprop_" Set rc=(.."_$$$QN(prop_"IsValid")_"(iv)) If $$$ISERR(rc) Set sc=$$EmbedErr^%occSystem(sc,rc,$$$ERRORCODE($$$DatatypeValidationFailed),"_qp_",iv)") }
			}
		}
		else {
				#; Test if this is a required relationship many/children side
			if required {
				$$$comMemberKeyGetLO(relationship,origin,%class,$$$cCLASSproperty,prop,$$$cPROPrelationship)
				$$$comMemberKeyGetLO(cardinality,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcardinality)
				if relationship,$select(cardinality="many":1,cardinality="children":1,1:0) {
					$$$QUEUECODE(1,$Char(9)_"If .."_qprop_".IsEmpty() Set rc=$$$ERROR($$$RelationshipChildRequired,$classname()_""::"_prop_"(""_$this_"""_$select(classispersistent:",ID=""_..%Id()_""",1:"")_")""),sc=$$$ADDSC(sc,rc)")
				}
			}
				#; Transient references don't get validated...
			if 'transient {
					#; 'persistent' is TRUE for reference attributes, false for all others
					#; 'serial' is TRUE for embedded objects, false for all others
					#; Check for required properties...
				if persistent,required $$$QUEUECODE(2,"	If r%"_qprop_"="""",i%"_qprop_"="""" Set rc=$$$ERROR($$$PropertyRequired,$classname()_""::"_prop_"(""_$this_"""_$select(classispersistent:",ID=""_..%Id()_""",1:"")_")""),sc=$$$ADDSC(sc,rc)")
					#; This is embedded object validation....
				if serial {
					if 'required {
						$$$QUEUECODE(2,$Char(9)_"If (r%"_qprop_"'=$$$NULLOREF)||m%"_qprop_" Set iv=.."_qprop_" If checkserial Set rc=iv.%ValidateObject(,1) If $$$ISERR(rc) Set sc=$$EmbedErr^%occSystem(sc,rc,$$$ERRORCODE($$$DatatypeValidationFailed),"_qp_",.."_qprop_")")
					}
					else {
						$$$QUEUECODE(2,$Char(9)_"If (r%"_qprop_"'=$$$NULLOREF)||m%"_qprop_" { Set iv=.."_qprop_" If checkserial { Set rc=iv.%ValidateObject(,1) If $$$ISERR(rc) { Set sc=$$EmbedErr^%occSystem(sc,rc,$$$ERRORCODE($$$DatatypeValidationFailed),"_qp_",.."_qprop_") } } if iv.%IsNull() { Set rc=$$$ERROR($$$PropertyRequired,$classname()_""::"_prop_"(""_$this_"""_$select(classispersistent:",ID=""_..%Id()_""",1:"")_")""),sc=$$$ADDSC(sc,rc) } }")
					}
				} elseif stream {
					if required {
						$$$QUEUECODE(2,$Char(9)_"If (r%"_qprop_"'=$$$NULLOREF)||m%"_qprop_",.."_qprop_".%IsNull() { Set rc=$$$ERROR($$$PropertyRequired,$classname()_""::"_prop_"(""_$this_"""_$select(classispersistent:",ID=""_..%Id()_""",1:"")_")""),sc=$$$ADDSC(sc,rc) }")
					}
				} else {
						#; Collections of datatypes need to be validated here
					$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
					if $listfind($$$cPROPCOLLECTIONREGULAR,collection) {
						if required $$$QUEUECODE(1,$Char(9)_"If $order(i%"_qprop_"(""""))="""" Set rc=$$$ERROR($$$CollectionPropertyRequired,$classname()_""::"_prop_"(""_$this_"""_$select(classispersistent:",ID=""_..%Id()_""",1:"")_")""),sc=$$$ADDSC(sc,rc)")
						$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
						set propclasstype=$$$getClassType(type)
						if propclasstype=$$$cCLASSCLASSTYPEDATATYPE,validate=2 {
							$$$QUEUECODE(1,$Char(9)_"If m%"_qprop_" Set key="""",rc=$$$OK For  Set key=$order(i%"_qprop_"(key),1,val) Quit:key=""""  If val'="""" Set rc=.."_$$$QN(prop_"IsValid")_"(val) If $$$ISERR(rc) Set sc=$$EmbedErr^%occSystem(sc,rc,$$$ERRORCODE($$$DatatypeValidationFailed),"_qp_"_""(""_key_"")"",val)")
						} elseif propclasstype=$$$cCLASSCLASSTYPESERIAL,validate=2 {
							$$$QUEUECODE(2,$Char(9)_"If checkserial >= 2, ((r%"_qprop_" '= $$$NULLOREF) || m%"_qprop_") {")
							$$$QUEUECODE(2,$Char(9,9)_"set key = """", rc = $$$OK")
							$$$QUEUECODE(2,$Char(9,9)_"for {")
							$$$QUEUECODE(2,$Char(9,9,9)_"set iv = .."_qprop_".GetNext(.key)")
							$$$QUEUECODE(2,$Char(9,9,9)_"if iv '= $$$NULLOREF {")
							$$$QUEUECODE(2,$Char(9,9,9,9)_"set rc = iv.%ValidateObject(,checkserial)")
							$$$QUEUECODE(2,$Char(9,9,9,9)_"if $$$ISERR(rc) set sc = $$EmbedErr^%occSystem(sc, rc, $$$ERRORCODE($$$DatatypeValidationFailed), "_qp_"_"".GetAt(""_key_"")"", iv)")
							$$$QUEUECODE(2,$Char(9,9,9)_"} else { quit:(key="""") }")
							$$$QUEUECODE(2,$Char(9,9)_"}")
							$$$QUEUECODE(2,$Char(9)_" }")
						}
					}
				}
			}	// if 'transient block end
		}	// else - for non-literal properties
	}
		#; Generate the code...
		#;    '$$$CODEQUEUESIZE(1)' indicates that datatype validation is present
		#;    $$$DEQUEUEBLOCK copies a code queue into %code, prepending each line with
		#;    the second parameter.
	if $$$CODEQUEUESIZE(2) { $$$DEQUEUECODE(2) }
	if $$$CODEQUEUESIZE(1) {
		$$$GENERATE("	If '$system.CLS.GetModified() Quit sc")
		$$$DEQUEUECODE(1)
	}
		#;    '$$$CODEQUEUESIZE(2)' indicates that embedded/reference validation is present
		#; Other checks made, generate the QUIT and leave..
	if $$$CODEQUEUESIZE(1) || $$$CODEQUEUESIZE(2) {
		$$$GENERATE("	Quit sc")
		QUIT $$$OK
	}
	#; No other validation checks made, generate a single line
	If onvalidate {
		$$$GENERATE("	Quit sc")
	} Else {
		$$$GENERATE("	Quit $$$OK")
	}
	quit $$$OK
}

/// This callback method is invoked when the current object is added to the SaveSet,
/// either because %Save() was invoked on this object or on an object that references this object.
/// %OnAddToSaveSet can modify the current object. It can also add other objects to the current
/// SaveSet by invoking %AddToSaveSet or remove objects by calling %RemoveFromSaveSet.
/// 
/// <P>If this method returns an error status then %Save() will fail and the transaction
/// will be rolled back.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%ConstructClone</METHOD> method to 
/// provide notification that a clone of an object is being created. It passes in the
/// oref of the object that was cloned in <var>object</var>.
/// 
/// <P>If this method returns an error then the object will not be created.
Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// If instead of returning a %Status code this returns an oref and this oref is a subclass of the current
/// class then this oref will be the one returned to the caller of %New method.
Method %OnNew() As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

}
