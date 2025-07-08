/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.SerialObject">Introduction to Serial Objects</a>.</p>
/// The <b>%SerialObject</b> class builds upon the functionality provided by the 
/// <CLASS>%RegisteredObject</CLASS> class and gives an object 
/// the ability to serialize itself and be embedded within another object.
Class %Library.SerialObject Extends %SwizzleObject [ Abstract, ClassType = serial, NoExtent, SqlCategory = STRING, System = 2 ]
{

/// This parameter specifies the delimiter character used when created a serialized 
/// version of the object. If the parameter is set to null string ("") then a length 
/// delimited ($List) string is used which can be manipulated using the <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$List</a> functions.
Parameter SERIALDELIMITER;

/// A serial object is converted to a delimited string containing the 
/// object's property values when it is projected via ODBC. 
/// <var>ODBCDELIMITER</var> is the delimiter character 
/// used to construct the delimited string.
Parameter ODBCDELIMITER = ",";

/// 	If true, %ValidateObject will return $$$OK for instances that are null as determined by %IsNull().
/// 	If FALSE (the default), %ValidateObject will perform a full validation on the instance, even if it is
/// 	null. This means that if VALIDIFNULL is TRUE then the property constraint, REQUIRED, can be defined
/// 	without causing failures on null objects. It is important to note that a property with an INITIALEXPRESSION
/// that returns a non-null initial value will cause %IsNull() to return FALSE for a new, otherwise unmodified
/// instance.
Parameter VALIDIFNULL As BOOLEAN = 0;

/// Deletes streams referenced by this object and calls %Delete on any embedded objects
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// 
ClassMethod %Delete(oid As %ObjectIdentity = "", concurrency As %Integer = -1) As %Status [ CodeMode = generator, Final, GenerateAfter = %OnDelete, ServerOnly = 0 ]
{
	s %code=0
		#; Build a list of existent dependent items, such as streams (for now, that is all...)...
	Set property = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While property '= "" {
		Kill origin
		$$$comMemberKeyGetLO(relationship,origin,%class,$$$cCLASSproperty,property,$$$cPROPrelationship)
		If relationship {
			$$$comMemberKeyGetLO(cardinality,origin,%class,$$$cCLASSproperty,property,$$$cPROPcardinality)
			If cardinality="children" {
				$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				$$$comMemberKeyGetLO(inverse,origin,%class,$$$cCLASSproperty,property,$$$cPROPinverse)
				Set cascade(property)=$lb(type,inverse)
			} ElseIf cardinality="many" {
				$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				$$$comMemberKeyGetLO(inverse,origin,%class,$$$cCLASSproperty,property,$$$cPROPinverse)
				Set restrict(property)=$lb(type,inverse)
			}
		} Else {
			$$$comMemberKeyGetLO(storable,origin,%class,$$$cCLASSproperty,property,$$$cPROPstorable)
			If storable {
				$$$comMemberKeyGetLO(proptype,origin,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				Set propclasstype = $$$getClassType(proptype)
				$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,property,$$$cPROPcollection)
				If propclasstype = $$$cCLASSCLASSTYPESTREAM { Set stream(property) = collection, stream(property,1) = proptype }
				ElseIf (propclasstype = $$$cCLASSCLASSTYPESERIAL) && ($$$comMemberKeyGet(proptype,$$$cCLASSmethod,"%Delete",$$$cMETHrunnable)) { Set serial(property) = collection, serial(property,1) = proptype }
			}
		}
		Set property = $$$comMemberNext(%class,$$$cCLASSproperty,property)
	}
	If $Data(serial) || $Data(stream) {
			#; Generate the method...
		$$$GENERATE("	Quit:oid="""" $$$OK")
		$$$GENERATE("	If concurrency = -1 Set concurrency="_%parameter("DEFAULTCONCURRENCY"))
		$$$GENERATE("	If (concurrency > 4) || (concurrency < 0) || (concurrency '= (concurrency\1)) Quit $$$ERROR($$$ConcurrencyValueInvalid)")
			#; get class name
		$$$GENERATE("	Set class=$$$oidClassName(oid)")
			#; if class name is not present in oid, we must call the
			#; class method %OnDetermineClass
		If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnDetermineClass",$$$cMETHrunnable) {
			$$$GENERATE("	If class="""" { Set sc=..%OnDetermineClass(oid,.class) Quit:$$$ISERR(sc) sc Set oid=$$$oidInsertClassName(oid,class) } Else { Set class=$$$NormalizeClassname(class) }")
				#; See if we are the correct class. If not, dispatch polymorphically to correct %Delete()
			$$$GENERATE("	If $classname()'=class Quit $classmethod(class,""%Delete"",oid,concurrency)")
		} Else {
			$$$GENERATE("	If class="""" { Set class=$classname(),oid=$$$oidInsertClassName(oid,$classname()) } Else { Set class=$$$NormalizeClassname(class) If $classname()'=class { Quit $classmethod(class,""%Delete"",oid,concurrency) } }")
		}
			#; If TP is turned on start a transaction...
		$$$GENERATE("	If $$$txNOTINTRAN { Set traninit=1 $$$txBeginTranJrn } Else { Set traninit=0 }")
			#; find out if there is a %OnDelete method. If there is, call it
		If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnDelete",$$$cMETHrunnable) { $$$GENERATE("	Set sc=..%OnDelete(oid) g:$$$ISERR(sc) %DeleteEnd") }
			#; Generate CASCADE referential actions
		Set relationship = $Order(cascade(""))
		While relationship '= "" {
			Set rclass=$li(cascade(relationship)),rinverse=$li(cascade(relationship),2)
			$$$GENERATE("	Set sc=##class("_rclass_")."_rinverse_"RExec(.qh,id) Goto:$$$ISERR(sc) %DeleteEnd" )
			$$$GENERATE("	For {")
			$$$GENERATE("		Set sc=##class("_rclass_")."_rinverse_"RFetch(.qh,0,.robjs,.fc,.end) Quit:$$$ISERR(sc)||(end)")
			$$$GENERATE("		Set ptr=0 While $listnext(robjs,ptr,val) {")
			$$$GENERATE("			Set sc=##class("_rclass_").%Delete($$$oidForm(val),concurrency) Quit:$$$ISERR(sc)")
			$$$GENERATE("		}")
			$$$GENERATE("		Quit:$$$ISERR(sc)")
			$$$GENERATE("	}")
			$$$GENERATE("	Do ##class("_rclass_")."_rinverse_"RClose(.qh)")
			$$$GENERATE("	Goto:$$$ISERR(sc) %DeleteEnd")
			Set relationship = $Order(cascade(relationship))
		}
			#; Open the object being deleted: (no need to check for the existence of such actions before swizzling - already done above)
		$$$GENERATE("	Set oref=..%Open(oid) If oref=$$$NULLOREF Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),$$$oidPrimary(oid)) Goto %DeleteEnd")
		If $Data(serial) {
			Set property = $Order(serial(""))
			While property '= "" {
				If serial(property) = "" { $$$GENERATE("	Set sc = ##class("_serial(property,1)_").%Delete(oref."_property_"GetObject(0),concurrency) Goto:$$$ISERR(sc) %DeleteEnd") }
				ElseIf serial(property) = $$$cPROPCOLLECTIONLIST {
					$$$GENERATE("	Set key="""" For ptr=1:1 Set value=oref."_property_".GetObjectNext(.key) Quit:key=""""  Set sc = ##class("_serial(property,1)_").%Delete(value,concurrency) Goto:$$$ISERR(sc) %DeleteEnd")
				} ElseIf serial(property) = $$$cPROPCOLLECTIONARRAY {
					$$$GENERATE("	Set key="""" For  Set value=oref."_property_".GetObjectNext(.key) Quit:key=""""  Set sc = ##class("_serial(property,1)_").%Delete(value,concurrency) Goto:$$$ISERR(sc) %DeleteEnd")
				}
				Set property = $Order(serial(property))
			}
		}
		If $Data(stream) {
			Set property = $Order(stream(""))
			While property '= "" {
				if stream(property) = "" { $$$GENERATE("	Set stream=oref."_property_"GetObject() If stream'="""" Set sc=##class("_stream(property,1)_").%Delete(stream,concurrency) If $$$ISERR(sc) Goto %DeleteEnd") }
				elseif stream(property) = $$$cPROPCOLLECTIONLIST { $$$GENERATE("	Set key="""" For ptr=1:1 Set value=oref."_property_".GetObjectNext(.key) Quit:key=""""  i value'="""" Set sc = ##class("_stream(property,1)_").%Delete(value,concurrency) Goto:$$$ISERR(sc) %DeleteEnd") }
				elseif stream(property) = $$$cPROPCOLLECTIONARRAY { $$$GENERATE("	Set key="""" For  Set value=oref."_property_".GetObjectNext(.key) Quit:key=""""  i value'="""" Set sc = ##class("_stream(property,1)_").%Delete(value,concurrency) Goto:$$$ISERR(sc) %DeleteEnd") }
				Set property = $Order(stream(property))
			}
		}
		$$$GENERATE("	Set oref=$$$NULLOREF")
			#; Generate RESTRICT referential actions
		Set relationship = $Order(restrict(""))
		While relationship '= "" {
			Set rclass=$li(restrict(relationship)),rinverse=$li(restrict(relationship),2)
			$$$GENERATE("	Set sc=##class("_rclass_")."_rinverse_"RExec(.qh,id) Goto:$$$ISERR(sc) %DeleteEnd" )
			$$$GENERATE("	Set sc=##class("_rclass_")."_rinverse_"RFetch(.qh,1,.robjs,.fc,.end) Do ##class("_rclass_")."_rinverse_"RClose(.qh)")
			$$$GENERATE("	Goto:$$$ISERR(sc) %DeleteEnd")
			$$$GENERATE("	If fc Set sc=$$$ERROR($$$RelationshipRestrictDelete,"""_rclass_"."_rinverse_""") Goto %DeleteEnd")
			Set relationship = $Order(restrict(relationship))
		}
		$$$GENERATE("	Set sc = $$$OK")
		$$$GENERATE("%DeleteEnd	If traninit { If $$$ISOK(sc) { $$$txCommit } Else { $$$txRollback(sc) } }")
		$$$GENERATE("	Quit sc")
	}
	QUIT $$$OK
}

/// Deletes the stored version of the object with ID <var>id</var> from the database. 
/// 
/// <p><METHOD>%DeleteId</METHOD> is identical in operation to the <METHOD>%Delete</METHOD> method except 
/// that it uses and Id value instead of an OID value to find an object.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument.
ClassMethod %DeleteId(id As %String, concurrency As %Integer = -1) As %Status [ Final, ServerOnly = 0 ]
{
	Quit ..%Delete($$$oidForm(id),.concurrency)
}

/// Returns true if this is a "NULL" serial object. Subclasses of %SerialObject are expected to override
/// this method. The default implementation returns 0 (false) indicating that the serial object is not
/// null. The default serialization class will generate an IsNull method that checks each property for null
/// and if all are null then IsNull() is 1 (true).
Method %IsNull() As %Boolean [ CodeMode = expression ]
{
0
}

/// Swizzles a serial object from the value passed and returns an OREF referring to the object. 
/// <var>initvalue</var> is the Id (serial value, not a full OID) value of the object to swizzle.
/// 
/// <p><METHOD>%OpenId</METHOD> is identical in operation to the <METHOD>%Open</METHOD> method except 
/// that it uses and Id value instead of an OID value to find an object instance.
/// 
/// <p><METHOD>%OpenId</METHOD> returns an OREF value that refers to the in-memory object instance.
ClassMethod %OpenId(initvalue As %String, concurrency As %Integer = -1, ByRef sc As %Status = {$$$OK}) As %ObjectHandle [ CodeMode = expression, Final, ServerOnly = 0 ]
{
..%Open($$$oidForm(initvalue))
}

/// Creates an instance (in-memory version) of a serial object from the 
/// serialized value <var>initvalue</var>. Note that <var>concurrency</var> is not used, the argument is kept to keep
/// the interface consistent with <class>%Library.Persistent</class>. If an error occurrs it is returned by refence in <var>sc</var>.
ClassMethod %Open(initvalue As %ObjectIdentity, concurrency As %Integer = -1, ByRef sc As %Status = {$$$OK}) As %ObjectHandle [ Final, ServerOnly = 0 ]
{
	#; if not passed an initial state, quit with $$$NULLOREF
	If '$data(initvalue) Quit $$$NULLOREF
	Set class=$$$oidClassName(initvalue)
	#; if class name is not present in initvalue, we must call the
	#; class method %OnDetermineClass if it is present or use this
	#; class for the class name
	If class="" {
		If $system.CLS.IsMthd("%OnDetermineClass") { Set sc=..%OnDetermineClass(initvalue,.class) Quit:$$$ISERR(sc) $$$NULLOREF } Else { Set class=$classname() }
		Set initvalue=$$$oidInsertClassName(initvalue,class)
	} Else {
		Set class=$$$NormalizeClassname(class)
	}
	If class'=$classname() Quit $classmethod(class,"%Open",initvalue,,.sc)
	Set oref=$$$CreateObject(class) If oref=$$$NULLOREF Set sc = $$$ERROR($$$AbstractClassNotInstantiable,class) Quit oref
	Set sc=oref.%LoadInit(initvalue) If $$$ISERR(sc) Quit $$$NULLOREF
	#; call %SetSerial() and, if it fails, destroy the object
	Set sc=oref.%SetSerial($$$oidPrimary(initvalue)) If $$$ISERR(sc) Quit $$$NULLOREF
	#; set object as not modified
	Do $system.CLS.SetModified(oref,0)
	#; find out if there is a %OnOpen method. If there is a %OnOpen, call it
	If $system.CLS.IsMthd(oref,"%OnOpen") Set sc=oref.%OnOpen() If $$$ISERR(sc) Quit $$$NULLOREF
	Quit oref
}

Method %LoadInit(oid As %ObjectIdentity) As %Status [ CodeMode = generator, Final, Internal, Private ]
{
	#; This code initializes all transient properties if the load was
	#; successful. Transient collections are also initialized.
	Set ivar="",set="i%""%%OID""=oid,"
	For  {
		Set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar) Quit:ivar=""
		If ivar="%%OID" Continue
		If $length(set)>120 $$$GENERATE("	Set "_$extract(set,1,*-1)) Set set=""
		Kill origin
		$$$comMemberKeyGetLO(multi,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPmultidimensional)
		If multi Continue
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPruntimetype)
		If '$$$classIsDataType(runtimetype) {
			Set set=set_"r%"_$$$QN(ivar)_"="""","
		}
		$$$comMemberKeyGetLO(transient,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPtransient)
		If 'transient Continue
		$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPcollection)
		If collection'="" Continue
		$$$comMemberKeyGetLvar(initialexpression,%class,$$$cCLASSinstancevar,ivar,$$$cIVARinitialexpression)
		Set set=set_"i%"_$$$QN(ivar)_"="_initialexpression_","
	}
	If set'="" $$$GENERATE("	Set "_$extract(set,1,*-1))
	$$$GENERATE("	Quit $$$OK")
	Quit $$$OK
}

/// <b>%GetSwizzleObject()</b> is used to obtain the serial value of the object that can 
/// later be used by <b>%SetSerial()</b> to restore the object. It calls <b>%SerializeObject()</b> 
/// which returns the serialized state of the object or the OID (for persistent objects).
/// Before calling <b>%GetSerial()</b>, <b>%GetSwizzleObject()</b> calls <b>%AddToSaveSet([force])</b>
/// which will result in calling the <b>%GetSwizzleObject()</b> method of other referenced objects,
/// passing along the value of <var>force</var>.
/// 
/// <p><METHOD>%GetSwizzleObject</METHOD> automatically detects and handles circular references between objects. 
/// For example, <METHOD>%GetSwizzleObject</METHOD> will detect if object A refers to object B and object B
/// likewise refers to object A. In this case it will avoid falling into an infinite, recursive loop.
/// 
/// <p>Note that either reference attribute, A to B or B to A, can be specified as being 
/// a required attribute but not both of them. If both reference attributes are required 
/// then <METHOD>%GetSwizzleObject</METHOD> will fail.
/// 
/// <p>By default <METHOD>%GetSwizzleObject</METHOD> automatically manages transactions. You can enable and disable 
/// automatic transaction support using the <code>$$SetTransactionMode^%apiOBJ()</code> routine.
/// 
/// <p>When <METHOD>%GetSwizzleObject</METHOD> serializes an object, it initiates one transaction 
/// (by calling TSTART) for the entire set of serializations, including the original object 
/// and any related objects. If the serialization operation is successful, <METHOD>%GetSwizzleObject</METHOD>
/// will issue a TCOMMIT command to commit the transaction and write the data to the database.
/// If <METHOD>%GetSwizzleObject</METHOD> encounters an error during the transaction it rolls back the entire
/// transaction and performs the following actions:
/// <ul>
/// <li>It issues a TROLLBACK command to rollback any changes to the database that may 
/// have occurred. (In the case of persistent objects with system assigned ids changes to the on-disk 
/// counter value, used to determine the next available object id number, are not rolled back.)</li>
/// <li>It attempts to restore the in-memory state of all the objects involved in the transaction to 
/// their pre-transaction state. This includes restoring any modified flags, and 
/// restoring to null ("") any OID values that have been assigned during the course of 
/// the transaction. Additional property values changed during the course of the 
/// transaction are not restored, however.</li>
/// <li>It calls the <METHOD>%RollBack</METHOD> method on each object involved with the transaction. 
/// The order in which the <METHOD>%RollBack</METHOD> methods are called is undefined. <METHOD>%RollBack</METHOD> will 
/// call a user-written <METHOD>%OnRollback</METHOD> method if it is present.</li>
/// </ul>
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %GetSwizzleObject(force As %Integer = 0, ByRef oid As %ObjectIdentity) As %Status [ CodeMode = generator, GenerateAfter = %OnAddToSaveSet, ServerOnly = 1 ]
{
	s %code=0
	Set references = 0 $$$comMemberKeyGetLvar(onadd,%class,$$$cCLASSmethod,"%OnAddToSaveSet",$$$cMETHrunnable)
	s prop="" f  s prop=$$$comMemberNext(%class,$$$cCLASSproperty,prop) q:prop=""  $$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype) i ('$$$classIsDataType(runtimetype)) || ($$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPmultidimensional)) Set references = 1 Quit
	If ('references) && ('onadd) {
		$$$GENERATE("	Set sc=..%ValidateObject(,0) Quit:$$$ISERR(sc) sc")
		$$$GENERATE("	Set sc=..%NormalizeObject() Quit:$$$ISERR(sc) sc")
		$$$GENERATE("	Set id=..%GetSerial(force)")
		$$$GENERATE("	If id="""" { Set oid=$$$NULLOID } Else { Set class=$classname(),class=$$$DenormalizeClassname(class),oid=$$$oidCompose(id,class) }")
		$$$GENERATE("	Set i%""%%OID""=oid Do $system.CLS.SetModified(0)")
		$$$GENERATE("	Quit $$$OK")
	} Else {
		$$$GENERATE("	Set $ZTrap=""%GetSwizzleObjectERR""")
		#; Initialize the transaction state
		#; This method is a transaction itself and isn't called recursively. Therefore, the
		#; transaction state variable - %objTX - is new'ed here.
		$$$GENERATE("	New %objTX If '$data(%objTX2) New %objTX2 Set %objTX2=1")
		#; If already in a SaveSet, just build a shallow graph and serialize the object
		$$$GENERATE("	If $get(%objTX2(+$this)) Set sc=..%BuildObjectGraph(1) Quit:$$$ISERR(sc) sc Set intRef=+$this,objValue=$get(%objTX(1,+$g(%objTX(0,intRef)),1)),sc=..%SerializeObject(.objValue,1) Set:$$$ISOK(sc) %objTX(1,%objTX(0,intRef),1)=objValue Set oid=objValue Quit sc")
		$$$GENERATE("	Set related  = $select(force=2:1,1:0), oid = $$$NULLOID")
		#; %TStart - Start a transaction if one doesn't exist and $zu(115,9) is on
		$$$GENERATE("	Set traninit=0 If $$$txNOTINTRAN {")
		$$$GENERATE("		Set traninit=1 Kill $$$txSTATUS,$$$txLISTroot,$$$txOIDASSIGNEDroot,$$$txMODIFIEDroot")
		#; %TInclude - include this oref in the current transaction...
		$$$GENERATE("		If '$zu(115,9) { Set $$$txSTATUS=1 } Else { Set $$$txSTATUS=2,$$$txLIST($this)="""" TStart }")
		$$$GENERATE("	}")
		$$$GENERATE("	Set sc=..%BuildObjectGraph(related+2) Quit:$$$ISERR(sc) sc")
		$$$GENERATE("	Set %objTX2(+$this)=1")
			#; At this point, %objTX(2) contains a list of all objects that need to be serialized. If the current object is not there, then place it there
			#; because this call to %GetSwizzleObject called for the serialized value of the current object - even if it has not been modified!
		$$$GENERATE("	If '$data(%objTX(11,+$this)) { Set %objTX(2,$i(%objTX(2)))=$lb(+$this,2),%objTX(11,+$this)=%objTX(2) }")
		#; First, examine the objects designated to be saved to see if any have zero predecessors
		$$$GENERATE("	Set %objTX(3)=0,i="""" For  Set i=$order(%objTX(2,i),1,data) Quit:i=""""  Set intRef=$li(data) If '$data(%objTX(1,+$g(%objTX(0,intRef)),2)) Set %objTX(3,$increment(%objTX(3)))=%objTX(1,%objTX(0,intRef)) Kill %objTX(2,i),%objTX(11,intRef)")
		#; Process the AOV. Calls to %SerializeObject here are complete serializations. If one fails, the TX needs to fail
		$$$GENERATE("	For  Quit:%objTX(3)<1  Set ptr=%objTX(3),objRef=%objTX(3,ptr),%objTX(3)=%objTX(3)-1 Kill %objTX(3,ptr) Set intRef=+objRef,objValue=$get(%objTX(1,+$g(%objTX(0,intRef)),1)),sc=objRef.%SerializeObject(.objValue) Do  Set %objTX(1,%objTX(0,intRef),1)=objValue Kill %objTX(1,%objTX(0,intRef),3) Do $system.CLS.SetModified(objRef,0)")
		$$$GENERATE("	. If $$$ISERR(sc) Kill:$$$txON $$$txLIST(objRef),$$$txMODIFIED(objRef) ZTrap ""SG""")
		#; Process the mod bits for potential tx rollback
		$$$GENERATE("	. If $$$txON,objRef.%IsModified() Set $$$txMODIFIED(objRef)=$system.CLS.GetModifiedBits(objRef)")
		#; visit the successors
		$$$GENERATE("	. Set intSucc="""" For  Set intSucc=$order(%objTX(1,%objTX(0,+objRef),3,intSucc)) Quit:intSucc=""""  Kill %objTX(1,%objTX(0,+objRef),3,intSucc),%objTX(1,intSucc,2,%objTX(0,+objRef)) If '$data(%objTX(1,intSucc,2)) Set %objTX(3,$i(%objTX(3)))=%objTX(1,intSucc) Kill:$d(%objTX(11,+%objTX(1,intSucc))) %objTX(2,%objTX(11,+%objTX(1,intSucc))),%objTX(11,+%objTX(1,intSucc))")
		#; If any objects are remaining in the graph then do a 'partial serialization' of the persistent objects that are
		#; designated as 'predecessors'.
		$$$GENERATE("	For  Set pserial=0 Do  Quit:'pserial")
		$$$GENERATE("	. Set i="""" For  Set i=$order(%objTX(2,i),1,data) Quit:i=""""  Set intPred="""",intRef=$li(data) For  Set intPred=$order(%objTX(1,%objTX(0,intRef),2,intPred)) Quit:intPred=""""  If $get(%objTX(1,intPred,6))=1 Set objValue=$get(%objTX(1,intPred,1)),sc=(%objTX(1,intPred)).%SerializeObject(.objValue,1) If $$$ISOK(sc) Set pserial=1,%objTX(1,intPred,1)=objValue Do")
		#; Visit the successors of this 'forced' ID assignment. If all predecessors are visited then add to the stack
		$$$GENERATE("	. . Set intSucc="""" For  Set intSucc=$order(%objTX(1,intPred,3,intSucc)) Quit:intSucc=""""  Kill %objTX(1,intPred,3,intSucc),%objTX(1,intSucc,2,intPred) If '$data(%objTX(1,intSucc,2)) Set %objTX(3,$i(%objTX(3)))=%objTX(1,intSucc) Kill:$d(%objTX(11,%objTX(1,intSucc))) %objTX(2,%objTX(11,%objTX(1,intSucc))),%objTX(11,%objTX(1,intSucc))")
		#; Again, process the AOV. Calls to %SerializeObject here are complete serializations. If one fails, the TX needs to fail
		$$$GENERATE("	. . For  Quit:%objTX(3)<1  Set ptr=%objTX(3),objSerialize=%objTX(3,ptr),%objTX(3)=%objTX(3)-1 Kill %objTX(3,ptr) Set intSerialize=+objSerialize,objValue=$get(%objTX(1,+$g(%objTX(0,intSerialize)),1)),sc=objSerialize.%SerializeObject(.objValue) Do  Set %objTX(1,%objTX(0,intSerialize),1)=objValue Kill %objTX(1,%objTX(0,intSerialize),3) Do $system.CLS.SetModified(objSerialize,0)")
		$$$GENERATE("	. . . If $$$ISERR(sc) Kill:$$$txON $$$txLIST(objSerialize),$$$txMODIFIED(objSerialize) ZTrap ""SG""")
		#; Process the mod bits for potential tx rollback
		$$$GENERATE("	. . . If $$$txON,objSerialize.%IsModified() Set $$$txMODIFIED(objSerialize)=$system.CLS.GetModifiedBits(objSerialize)")
		#; visit the successors
		$$$GENERATE("	. . . Set intSucc="""" For  Set intSucc=$order(%objTX(1,%objTX(0,intSerialize),3,intSucc)) Quit:intSucc=""""  Kill %objTX(1,%objTX(0,intSerialize),3,intSucc),%objTX(1,intSucc,2,%objTX(0,intSerialize)) If '$data(%objTX(1,intSucc,2)) Set %objTX(3,$i(%objTX(3)))=%objTX(1,intSucc) Kill:$d(%objTX(11,+%objTX(1,intSucc))) %objTX(2,%objTX(11,+%objTX(1,intSucc))),%objTX(11,+%objTX(1,intSucc))")
		$$$GENERATE("	If $data(%objTX(2))>2 Set sc=$$$ERROR($$$SaveCyclicDependancy,$classname()) ZTrap ""SG""")
		#; Commit the transaction and cleanup
		$$$GENERATE("	Set cmd="""" For  Set cmd=$order(%objTX(9,cmd)) Quit:cmd=""""  Xecute cmd")
		$$$GENERATE("%GetSwizzleObjectCOMMIT	If traninit {")
		$$$GENERATE("		If $$$txOFF { Kill $$$txSTATUS } Else { TCommit  Kill $$$txSTATUS,$$$txLISTroot,$$$txOIDASSIGNEDroot,$$$txMODIFIEDroot }")
		$$$GENERATE("	}")
		$$$GENERATE("	Set oid = $get(%objTX(1,%objTX(0,+$this),1))")
		$$$GENERATE("	If $$$oidPrimary(oid) = """" Set oid = $$$NULLOID")
		$$$GENERATE("	Set %objTX2(+$this)=0")
		$$$GENERATE("	Quit sc")
		$$$GENERATE("%GetSwizzleObjectERR	Set $ZTrap="""" If $extract($ZError,1,5)'=""<ZSG>"" Set sc=$$$ERROR($$$ObjectScriptError,$ZE)")
		$$$GENERATE("	Set:traninit sc=$$$ADDSC(sc,$$%TRollBack^%occTransaction())")
		$$$GENERATE("	Set %objTX2(+$this)=0")
		$$$GENERATE("	Quit sc")
	}
	QUIT $$$OK
}

Method %GetSerial(force As %Integer = 0) As %String [ CodeMode = generator, Private, ServerOnly = 1 ]
{
		#; This code produces a string of all instance variables
		#; The user often overrides this method.
	set %code=0
	if $$$comMemberNext(%class,$$$cCLASSinstancevar,"")="" $$$GENERATE("	Quit """"") quit $$$OK
	set check="",state="",ivar="",serialdelimiter=%parameter("SERIALDELIMITER")
		#; length delimited pieces
	if serialdelimiter = "" {
		for  set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar) quit:ivar=""  if '$$$comMemberKeyGet(%class,$$$cCLASSproperty,ivar,$$$cPROPtransient) set state=state_",i%"_ivar,check=check_",i%"_ivar_"="""""
		$$$GENERATE("	If "_$extract(check,2,*)_" Quit """"")
		$$$GENERATE("	Quit $listbuild("_$extract(state,2,*)_")")
	}
		#; there's a delimiter character
	else {
		if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"SERIALDELIMITER",$$$cPARAMtype) '= $$$cPARAMTYPECOSEXPRESSION { set serialdelimiter = """"_serialdelimiter_"""" }
		for  set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar) quit:ivar=""  if '$$$comMemberKeyGet(%class,$$$cCLASSproperty,ivar,$$$cPROPtransient) set state=state_"_"_serialdelimiter_"_i%"_ivar,check=check_",i%"_ivar_"="""""
		set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,"")
		while ivar '= "" {
			if '$$$comMemberKeyGet(%class,$$$cCLASSproperty,ivar,$$$cPROPtransient) { set state = state _ "_" _ serialdelimiter _ "_i%" _ ivar, check = check _ ",i%" _ ivar _ "=""""" }
			set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar)
		}
			#; strip first "_delim_"
		$$$GENERATE("	If "_$extract(check,2,*)_" Quit """"")
		$$$GENERATE("	Quit "_$extract(state,$length(serialdelimiter)+3,*))
	}
	QUIT $$$OK
}

Method %SetSerial(val As %String) As %Status [ CodeMode = generator, Private, ServerOnly = 1 ]
{
 #; This code initializes all instance variables based on
 #; the same type of string produced by %GetSerial().
	s %code=0
 #; see if there's any instance variables
	i $$$comMemberNext(%class,$$$cCLASSinstancevar,"")="" $$$GENERATE("	Quit $$$OK") QUIT $$$OK
 #; now parse through each of the instance variables
	s item=0,serialdelimiter=%parameter("SERIALDELIMITER")
	if (serialdelimiter '= "") && ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SERIALDELIMITER",$$$cPARAMtype) '= $$$cPARAMTYPECOSEXPRESSION) { set serialdelimiter = """"_serialdelimiter_"""" }
	s ivar="" f  s ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar) q:ivar=""  d
	. i $$$comMemberKeyGet(%class,$$$cCLASSproperty,ivar,$$$cPROPtransient) q
	. s item=item+1
	. i serialdelimiter="" $$$GENERATE("	Set i%"_ivar_"=$listget(val,"_item_")")
	. e  $$$GENERATE("	Set i%"_ivar_"=$piece(val,"_serialdelimiter_","_item_")")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Converts the serial state of this serial object to a delimited string 
/// using the value of the <var>ODBCDELIMITER</var> parameter as a delimiter.
ClassMethod LogicalToOdbc(val As %String = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	set %code=0
		// see if there's any instance variables
	if $$$comMemberNext(%class,$$$cCLASSinstancevar,"")="" $$$GENERATE("	Quit $$$OK") quit $$$OK
	set odbcdelim=%parameter("ODBCDELIMITER")
		// Quote the delimiter. If odbcdelimiter was not specified, default to ","
	set odbcdelim=""""_$select(odbcdelim'="":odbcdelim,1:",")_""""
		// now count the instance variables in the serialized object
		// and build the result
	set item=0,serialdelimiter=%parameter("SERIALDELIMITER"),odbc=""
	if (serialdelimiter '= "") && ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SERIALDELIMITER",$$$cPARAMtype) '= $$$cPARAMTYPECOSEXPRESSION) { set serialdelimiter = """"_serialdelimiter_"""" }
	set ivar="" for  set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar) quit:ivar=""  do
	. if $$$comMemberKeyGet(%class,$$$cCLASSproperty,ivar,$$$cPROPtransient) quit
	. set item=item+1
	. if serialdelimiter="" set odbc=odbc_"_"_odbcdelim_"_$listget(val,"_item_")"
	. else  set odbc=odbc_"_"_odbcdelim_"_$piece(val,"_serialdelimiter_","_item_")"
	if item set %codemode=$$$cMETHCODEMODEEXPRESSION,%code=$extract(odbc,$length(odbcdelim)+3,*)
	quit $$$OK
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using the value of the <var>ODBCDELIMITER</var> parameter as a delimiter.
ClassMethod OdbcToLogical(val As %String = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	set %code=0
		// see if there's any instance variables
	if $$$comMemberNext(%class,$$$cCLASSinstancevar,"")="" $$$GENERATE(" QUIT $$$OK") quit $$$OK
	set odbcdelim=%parameter("ODBCDELIMITER")
		// Quote the delimiter. If odbcdelimiter was not specified, default to ","
	set odbcdelim=""""_$select(odbcdelim'="":odbcdelim,1:",")_""""
		// now count the instance variables in the serialized object
		// and build the result
	set item=0,serialdelimiter=%parameter("SERIALDELIMITER"),logical=$select(serialdelimiter="":"$listbuild(",1:"")
	if (serialdelimiter '= "") && ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SERIALDELIMITER",$$$cPARAMtype) '= $$$cPARAMTYPECOSEXPRESSION) { set serialdelimiter = """"_serialdelimiter_"""" }
	set ivar="" for  set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar) quit:ivar=""  do
	. if $$$comMemberKeyGet(%class,$$$cCLASSproperty,ivar,$$$cPROPtransient) quit
	. set item=item+1
	. if serialdelimiter="" set logical=logical_"$piece(val,"_odbcdelim_","_item_"),"
	. else  set logical=logical_"$piece(val,"_odbcdelim_","_item_")_"_serialdelimiter_"_"
	if item set $extract(logical,$length(logical))=$select(serialdelimiter="":")",1:"") set %codemode=$$$cMETHCODEMODEEXPRESSION,%code=logical
	quit $$$OK
}

Method %OnOpen() As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

}
