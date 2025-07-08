/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.Persistent">Working with Persistent Objects</a>.</p>
/// <p>The sample class mentioned here (Sample.Person) is part of <a target="_top" href="https://github.com/intersystems/Samples-Data">https://github.com/intersystems/Samples-Data.</a>
/// See <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=landing+githubsamples">Downloading Samples</a>.</p>
/// The <CLASS>%Persistent</CLASS> class provides the basic mechanism by 
/// which objects are stored to and retrieved from a database. 
Class %Library.Persistent Extends %SwizzleObject [ Abstract, ClassType = persistent, NoExtent, PropertyClass = %Library.PersistentProperty, System = 2 ]
{

/// <p>If a persistent class uses %Storage.Persistent then the <var>DEFAULTGLOBAL</var> parameter is used as the
/// default global root for the values of the storage keywords COUNTERLOCATION, DATALOCATION, IDLOCATION,
/// INDEXLOCATION and STREAMLOCATION in the active storage definition. <var>DEFAULTGLOBAL</var> is only used
/// to generate location keyword values that are not already defined. The location value is constructed by adding
/// a location type to the end of <var>DEFAULTGLOBAL</var>. For example, if <var>DEFAULTGLOBAL</var> = "^GL.Account"
/// the compiler will generate <var>DATALOCATION</var> = ^GL.AccountD.</p>
/// <p>
/// If <parameter>USEEXTENTSET</parameter> is true, then DEFAULTGLOBAL is used as the default extent location. 
/// </p>
/// <br>
/// The location types are:
/// <table>
/// <tr><th align="left">Location</th><th align="left">Type</th>
/// <tr><td>COUNTERLOCATION</td><td align="center">C</td></tr>
/// <tr><td>DATALOCATION</td><td align="center">D</td></tr>
/// <tr><td>IDLOCATION</td><td align="center">D</td></tr>
/// <tr><td>INDEXLOCATION</td><td align="center">I</td></tr>
/// <tr><td>STREAMLOCATION</td><td align="center">S</td></tr>
/// </table>
Parameter DEFAULTGLOBAL As STRING;

/// Global name containing master map data for this class.
/// Used in creating the oref to oid table so we can determine where the data for this class is located.
/// Will normally be set automatically during compile for both default and SQL storage classes so normally
/// there is no need to modify this setting unless you have custom storage and wish to point this at a specific
/// global name. If the value is "" then we will not insert a data global location into the oid->obj
/// table and so will assume if the same class (mapped from a common location) opens the same id in two different
/// namespaces these are referring to the same instance and so the second open will return the first oref.
Parameter DATALOCATIONGLOBAL As STRING = {$$storageGbl^%qarmac(%classname)};

/// If the <var>DSTIME</var> parameter is set to AUTO then the most recent filing operation in the current DSTIME value 
/// for each object will be recorded in a global, ^OBJ.DSTIME: 
/// <br>
/// 	^OBJ.DSTIME(<var>ExtentName</var>,<var>DSTIME</var>,<var>objectID</var>) = <var>filing operation</var> 
/// <br>
/// For DSTIME=AUTO the DSTIME value is recorded in ^OBJ.DSTIME and is set by the consumer of DSTIME data.
/// <br>
/// Refer to %DeepSee documentation for more information on how DSTIME is used by %DeepSee. 
/// <br>
/// The filing operations are:
/// <table>
/// <tr><th align="left">Code</th><th align="left">Operation</th>
/// <tr><td>0</td><td align="center">Update</td></tr>
/// <tr><td>1</td><td align="center">Insert</td></tr>
/// <tr><td>2</td><td align="center">Delete</td></tr>
/// </table>
/// <br>
/// If the <var>DSTIME</var> parameter is set to MANUAL then the user is responsible for journaling object filing operations.
/// If <var>DSTIME</var> is set to "CONDITIONAL", the user is expected to define the parameter DSCONDITION setting it to an expression which 
/// will determine if the actions performed when DSTIME is set to AUTO will execute or not
Parameter DSTIME As STRING [ Constraint = ",AUTO,MANUAL,CONDITIONAL", Flags = ENUM ];

/// DSINTERVAL is the number of seconds between one DSTIME value and the next. The DSTIME value for DSINTERVAL > 0 is computed from $ZTIMESTAMP
/// and is the number of seconds from day 0, time 0 to the nearest interval, rounded down. Using an interval has the effect of grouping
/// all DSTIME entries for the class in some number of seconds.
Parameter DSINTERVAL As INTEGER;

/// DSCONDITION is the expression that will be evaluated before deciding whether certain actions must be taken. These actions are the same as those 
/// performed when DSTIME is set to AUTO - for instance updating ^OBJ.DSTIME on modifying a record.
Parameter DSCONDITION As STRING;

/// The <var>EXTENTQUERYSPEC</var> parameter defines the properties to be retrieved in 
/// addition to the IDKEY value for the built-in <b>Extent</b> query.
/// <p>Persistent classes should define a value of for <var>EXTENTQUERYSPEC</var> if they 
/// wish to include additional properties in their built-in <b>Extent</b> query.
/// <p>For example:
/// <EXAMPLE LANGUAGE=NONE>
/// parameter EXTENTQUERYSPEC = "Name,SSN,Age";
/// </EXAMPLE>
Parameter EXTENTQUERYSPEC As ROWSPEC [ Flags = LIST ];

/// The <var>EXTENTSIZE</var> parameter is used to inform the <i>SQL Query Optimizer</i> 
/// of the approximate number of instances in the extent containing instances of this class.
/// 
/// <p>For example, a class that expects to have about 1,000,000 instances should define:
/// <EXAMPLE LANGUAGE=NONE>
/// parameter EXTENTSIZE = 1000000;
/// </EXAMPLE>
Parameter EXTENTSIZE As INTEGER = 100000;

/// If this parameter is set to 1 then a GUID will be assigned (to the %GUID property) to each new object.
/// When the object is saved for the first time this GUID value will be recorded in a namespace
/// index which will allow GUID to be resolved to OIDs.
Parameter GUIDENABLED = 0;

/// The <var>IDENTIFIEDBY</var> parameter can optionally be set to the name 
/// of a required property whose type is a reference to another class (not a literal). 
/// This property's IDKEY is then used as the prefix for the IDKEY of this class.
/// <br><i><u>Deprecated parameter, use parent/child relationships instead</i></u>
Parameter IDENTIFIEDBY [ Deprecated ];

/// The <var>MANAGEDEXTENT</var> parameter can be set to 0 (zero) to cause the Extent Manager
/// to ignore this class. If set to 1 then the Extent Manager will register globals used by
/// the class and detect collisions. Unmanaged extents (MANAGEDEXTENT = 0) are not checked.
/// Currently, only classes using default storage (%Storage.Persistent) can be managed.
Parameter MANAGEDEXTENT As INTEGER [ Constraint = "0,1", Flags = ENUM ] = 1;

/// <var>READONLY</var> = 1 means that objects can be created, opened but not saved or deleted.
/// Tables are projected to SQL as READONLY.
Parameter READONLY = 0;

/// <var>ROWLEVELSECURITY</var> = 1 | &lt;property&gt; means that row level security is active and the list
/// of users/roles for a given instance/row is contained in a generated property. If
/// the value of this parameter is a valid property name then that property will be
/// used as the reader list and only generated if not already defined.
Parameter ROWLEVELSECURITY;

/// %XCOMPACTANCESTRY can be set to a string to replace the value of the %%CLASSNAME property (x__classname field)
/// with a more compact value that will reduce the size of the data on disk stored for each record.
Parameter %XCOMPACTANCESTRY As STRING;

/// <var>STORAGEDEFAULT</var> defines the default storage allocation to use for properties in this class.
/// The Storage Generator will use this value when building the initial Storage Definition or amending it
/// when new properties have been added to a class. Allowed values are "column" and "". Leaving it
/// undefined ("") means the overall system default row-based storage model will be used when persisting
/// this extent. This value can be overridden for individual properties with the corresponding property-level
/// parameter, where additional values are available for specific property types.
Parameter STORAGEDEFAULT [ Constraint = ",columnar" ];

/// <var>STORAGEDEFAULTTARGET</var> defines the default storage allocation to use for properties in this class following
/// an ALTER TABLE ... CONVERT STORAGETYPE statement. The Storage Generator will use this value when modifying the Storage 
/// Definition Allowed values are "column" and "row". This value should not be set or modified by users.
Parameter STORAGEDEFAULTTARGET [ Constraint = ",row,columnar", Internal ];

/// <p>If a persistent class uses %Storage.Persistent then the <var>USEEXTENTSET</var> parameter is used to 
/// specify the global naming strategy used by the default storage class (<class>%Storage.Persistent</class>). 
/// If TRUE, then global names are generated for each index that is not already allocated a LOCATION in the active 
/// storage definition. 
/// </p>
/// <p>
/// If the storage definition specifies EXTENTLOCATION then that value is used as the base reference for all globals 
/// assigned to indices that do not have an explicit LOCATION assigned. 
/// </p>
/// <p>
/// The global name generator for <var>USEEXTENTSET</var> = TRUE honors the package prefix defined 
/// in the Package Definition. If none is defined then the package prefix is generated using a based-62 encoded integer 
/// produced from CRC32 of the package name. The specific class identifier is generated from the unqualified class name using 
/// the same hash (class->crc32->base62) to form EXTENTLOCATION. Specific index suffixes are produced using a generated 
/// offset that is local to the first persistent class with an enumerated extent in which the index appears (either defined or inherited). 
/// </p>
/// <p>
/// There are several factors that influence the generation of EXTENTLOCATION:
/// <ol type="1">
/// <li>If the EXTENTLOCATION keyword is defined then its value is used,</li>
/// <li>If the DEFAULTGLOBAL class parameter is defined then its value is used,</li>
/// <li>otherwise, the value is generated as two dot delimited segments. The first segment is either the defined package prefix retrieved from 
/// the package definition global or, if none is defined, a hash of the package name. The second segment is generated by a hash of the unqualified 
/// class name. The hash used is a base 62 encoded CRC32 of the value. For example, Sample.Person produces ^EW3K.wPC9 if no package prefix is defined. </li>
/// </ol>
/// The EXTENTLOCATION value is used as the base for specific globals allocated to indices. Each index is assigned an offset that is incremented from 
/// 1 by 1, offset = 1 is reserved for the IDKEY index.
/// </p>
/// <p>
/// EXTENTLOCATION is specific to each class. When a persistent class extends another persistent class, forming a subextent, then the subclass's EXTENTLOCATION 
/// is specific to that subclass. The index location for any inherited index is already defined specifically in the superclass so the subclass's EXTENTLOCATION 
/// will only be used as the base for any index that originates in the subclass. For example, Sample.Employee extends Sample.Person. The EXTENTLOCATION generated for 
/// Sample.Person is ^EW3K.wPC9 and the EXTENTLOCATION for Sample.Employee is ^EW3K.D1Ex. Since Sample.Employee inherits several indices from Sample.Person, the 
/// global name assigned to each of those indices is already defined and inherited by Sample.Employee. However, any index defined in Sample.Employee and not 
/// inherited from Sample.Person will be assigned a global name based on Sample.Employee's EXTENTLOCATION, not on Sample.Person's EXTENTLOCATION. In other words, 
/// the EXTENTLOCATION storage keyword is not inherited. 
/// </p>
/// <p>
/// The following tables show the indices and locations for Sample.Person and Sample.Employee. Notice the last index in the Sample.Employee table: 
/// <table>
/// 	<tr><td align="left">Class = Sample.Person</td></tr>
/// 	<tr>
/// 		<td>
/// 			<table>
/// 				<tr><th align="left">Index</th><th align="left">Location</th>
/// 				<tr><td>IDKEY</td><td>^EW3K.wPC9.1</td></tr>
/// 				 <tr><td>$Person</td><td>^EW3K.wPC9.2</td></tr>
/// 				<tr><td>NameIDX</td><td>^EW3K.wPC9.3</td></tr>
/// 				<tr><td>SSNKey</td><td>^EW3K.wPC9.4</td></tr>
/// 				<tr><td>ZipCode</td><td>^EW3K.wPC9.5</td></tr>
/// 			</table>
/// 		</td>
/// 	</tr>
/// 	<tr></tr>
/// 	<tr><td align="left">Class = Sample.Employee extends Sample.Person</td></tr>
/// 	<tr>
/// 		<td>
/// 			<table>
/// 				<tr><th align="left">Index</th><th align="left">Location</th>
/// 				<tr><td>IDKEY</td><td>^EW3K.wPC9.1</td></tr>
/// 				<tr><td>$Person</td><td>^EW3K.wPC9.2</td></tr>
/// 				<tr><td>NameIDX</td><td>^EW3K.wPC9.3</td></tr>
/// 				<tr><td>SSNKey</td><td>^EW3K.wPC9.4</td></tr>
/// 				<tr><td>ZipCode</td><td>^EW3K.wPC9.5</td></tr>
/// 				<tr><td>$Employee</td><td>^EW3K.D1Ex.2</td></tr>
/// 			</table>
/// 		</td>
/// 	</tr>
/// </table>
/// <p>
/// Any generated global index locations and EXTENTLOCATION are updated back into the active storage definition after the class is 
/// compiled. 
/// </p>
/// <p>
/// If <var>USEEXTENTSET</var> is FALSE, then global names are generated using the package-hash.class-hashSuffix strategy. 
/// For example, ^Sample.PersonD and ^Sample.PersonI("SSNKey") are globals used by Sample.Person and specific index structures 
/// are all stored in ^Sample.PersonI with the index name used as the first subscript. <var>USEEXTENTSET</var> is always treated as
/// FALSE for temporary tables, even if explicitly defined as TRUE in a DDL statement.
/// </p>
/// <br>
Parameter USEEXTENTSET = 0;

/// VERSIONPROPERTY = &lt;property&gt; means that the &lt;property&gt; in memory will be compared to
/// the &lt;property&gt; on disk during an update. If different a concurrency conflict
/// error will be reported and the save will fail.
Parameter VERSIONPROPERTY As STRING;

/// VERSIONCLIENTNAME can be set to a valid CLIENTNAME (see property CLIENTNAME) value. This
/// value will be used for client projections of the %Version property.
Parameter VERSIONCLIENTNAME;

Parameter masterClassName;

/// <p>%Concurrency holds the value of the concurrency setting for this object.
/// </p>
/// 	<TABLE cols=2 border=1>
/// 	<TR>
/// 		<TD valign="top">0:</TD><TD CLASS=Term valign="top">None</TD>
/// 			<TD valign="top">
/// 			Suppress all concurrency controls for this object. No locks are used.
/// 			</TD>
/// 		</TR>
/// 		<TR>
/// 			<TD valign="top">1:</TD><TD CLASS=Term valign="top">Atomic Read</TD>
/// 			<TD valign="top">
/// 				When an object is loaded, <b>%LoadData</B>  will read the entire object from disk without the possibility
/// 			that another process will write any data to this object before the read operation is
/// 			complete. If necessary, a shared lock will be acquired on the object to guarantee an atomic read.
/// 			Any locks acquired during the read operation are released after the read operation is completed.
/// 				No locks are acquired for a new object.
/// 			<b>%SaveData</B> will acquire an exclusive lock during the course of the save.
/// 			</TD>
/// 		</TR>
/// 		<TR>
/// 			<TD valign="top">2:</TD><TD CLASS=Term valign="top">Shared</TD>
/// 			<TD valign="top">
/// 				When an object is loaded, <b>%LoadData</B> will acquire a shared lock on the object and read the entire object from disk.
/// 			The lock is released after the read operation is completed.
/// 				No locks are acquired for a new object.
/// 			<b>%SaveData</B> will acquire an exclusive lock during the course of the save.
/// 			</TD>
/// 		</TR>
/// 		<TR>
/// 			<TD valign="top">3:</TD><TD CLASS=Term valign="top">Shared/Retained</TD>
/// 			<TD valign="top">
/// 			When an object is loaded, <b>%LoadData</B> will acquire a shared lock for the object.
/// 			The lock is released when the object is destructed (removed from memory).<br>
/// 				No locks are initially acquired for a new object.
/// 			<b>%SaveData</B> will acquire an exclusive lock during the course of the save.
/// 			<b>%SaveData</B> will also acquire a shared lock when saving a new object. This lock is retained
/// 				until the object is destructed (removed from memory).
/// 			</TD>
/// 		</TR>
/// 		<TR>
/// 			<TD valign="top">4:</TD><TD CLASS=Term valign="top">Exclusive</TD>
/// 			<TD valign="top">
/// 			When an object is loaded, <b>%LoadData</B> will acquire an exclusive lock for the object.
/// 			The lock is released when the object is destructed (removed from memory).<br>
/// 			<b>%SaveData</B> will acquire an exclusive lock when saving a new object. This lock is retained
/// 				until the object is destructed (removed from memory).
/// 		</TD>
/// 	</TR>
/// </table>
/// 	<p>The only difference between Shared (2) and Atomic Read (1) settings is that Shared concurrency
/// 	triggers a shared lock to always be acquired during read while Atomic Read will only acquire a
/// 	shared lock when required to ensure an atomic read.</p>
Property %Concurrency As %RawString [ Final, InitialExpression = {$zu(115,10)}, Internal, Transient ];

Method %ConcurrencySet(val As %RawString) As %Status [ Internal, Private ]
{
	Set i%%Concurrency=val
	Quit $$$OK
}

/// Deletes the stored version of the object with OID <var>oid</var> from the database. 
/// It does not remove any in-memory versions of the object that may be present.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument.  For classes defined as Sharded=1, concurrency=0 is always used.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// 
/// <p>Internally, <METHOD>%Delete</METHOD> initiates a transaction and then invokes the storage 
/// interface method <METHOD>%DeleteData</METHOD>. If <METHOD>%DeleteData</METHOD> succeeds, the 
/// transaction is committed, otherwise it is rolled back.  No transaction is initiated if this class is defined as Sharded=1
ClassMethod %Delete(oid As %ObjectIdentity = "", concurrency As %Integer = -1) As %Status [ CodeMode = generator, Final, GenerateAfter = (%OnDelete, %OnDeleteFinally, %OnJournalObject), ServerOnly = 0 ]
{
	set %code=0
	set finally = $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnDeleteFinally",$$$cMETHrunnable)
	set sharded=$$$comSharded(%class) // JMM1160=
	if sharded=2 {
		if 'finally {
			$$$GENERATE($c(9)_"RETURN $$$ERROR($$$ClassIsSharded2,$classname())")
		} else {
			$$$GENERATE($c(9)_"set sc=$$$ERROR($$$ClassIsSharded2,$classname()) try { do ..%OnDeleteFinally(oid, sc) } catch {} RETURN sc")
		}
		RETURN $$$OK
	}
	$$$comMemberKeyGetLvar(connection,%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)
	$$$comMemberKeyGetLvar(objectjournal,%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault)
	$$$comMemberKeyGetLvar(tDSTIME,%class,$$$cCLASSparameter,"DSTIME",$$$cPARAMdefault)
		#; for sharded classes, DSTIME is not supported, so this will never be true
	if ($$$ucase(tDSTIME) = "AUTO") {
		$$$comMemberKeyGetLvar(tDSINTERVAL,%class,$$$cCLASSparameter,"DSINTERVAL",$$$cPARAMdefault)
		if tDSINTERVAL '> 0 { set tDSTIME = 1 } else { set tDSTIME = 2 }
	}
	elseif ($$$ucase(tDSTIME) = "CONDITIONAL"){ //DP-404466
		if +$G(tDSINTERVAL) '> 0 { set tDSTIME = 3 } else { set tDSTIME = 4 }
		$$$comMemberKeyGetLvar(tDSCONDITION,%class,$$$cCLASSparameter,"DSCONDITION",$$$cPARAMdefault)
	}
	else { set tDSTIME = 0 }
		#; 'filter' will be true if object journal filtering is true. If so, then the object being deleted must be instantiated and $$$txJournalObjectDelete called instead of $$$txJournalDelete
	$$$comMemberKeyGetLvar(filter,%class,$$$cCLASSmethod,"%OnJournalObject",$$$cMETHrunnable)
	Set storageclass = ""
	if objectjournal + tDSTIME {
		$$$comClassKeyGetLvar(storagename,%class,$$$cCLASSstoragestrategy)
		If storagename '= "" $$$comMemberKeyGetLvar(storageclass,%class,$$$cCLASSstorage,storagename,$$$cSDEFtype)
		if $$$SQLStorageIsSQL(storageclass) { set tDSTIME = 0 }
	}
		#; Build a list of existent dependent items, such as streams (for now, that is all...)...
	Set property = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While property '= "" {
		Kill origin
		$$$comMemberKeyGetLO(relationship,origin,%class,$$$cCLASSproperty,property,$$$cPROPrelationship)
		if relationship {
			$$$comMemberKeyGetLO(cardinality,origin,%class,$$$cCLASSproperty,property,$$$cPROPcardinality)
			if (cardinality = $$$cPROPCARDINALITYCHILDREN) || (cardinality = $$$cPROPCARDINALITYMANY) {
				$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				$$$comMemberKeyGetLO(inverse,origin,%class,$$$cCLASSproperty,property,$$$cPROPinverse)
				set ondelete(property)=$lb(type,inverse)
			}
		} Else {
			$$$comMemberKeyGetLO(storable,origin,%class,$$$cCLASSproperty,property,$$$cPROPstorable)
			If storable {
				$$$comMemberKeyGetLO(proptype,origin,%class,$$$cCLASSproperty,property,$$$cPROPtype)
				Set propclasstype = $$$getClassType(proptype)
				$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,property,$$$cPROPcollection)
				If propclasstype = $$$cCLASSCLASSTYPESTREAM { if connection = "" { Set stream(property) = collection, stream(property,1) = $$$QN(proptype) } }
				ElseIf (propclasstype = $$$cCLASSCLASSTYPESERIAL) && ($$$comMemberKeyGet(proptype,$$$cCLASSmethod,"%Delete",$$$cMETHrunnable)) { Set serial(property) = collection, serial(property,1) = $$$QN(proptype) }
			}
		}
		Set property = $$$comMemberNext(%class,$$$cCLASSproperty,property)
	}
		#; Generate the method...
	if 'finally {
		$$$GENERATE($c(9)_"RETURN:oid="""" $$$ERROR($$$NullOid,$classname())")
		$$$GENERATE($c(9)_"set id=$$$oidPrimary(oid) RETURN:id="""" $$$ERROR($$$NullId,$classname())")
	} else {
		$$$GENERATE($c(9)_"if oid="""" { set sc = $$$ERROR($$$NullOid,$classname()) try { do ..%OnDeleteFinally(oid, sc) } catch {} RETURN sc }")
		$$$GENERATE($c(9)_"set id=$$$oidPrimary(oid) if id="""" { set sc = $$$ERROR($$$NullId,$classname()) try { do ..%OnDeleteFinally(oid, sc) } catch {} RETURN sc }")
	}
	if 'sharded { $$$GENERATE($c(9)_"set traninit=0") }
	$$$GENERATE($c(9)_"set $zt=""%DeleteERR""")
	$$$GENERATE($c(9)_"if concurrency = -1 { set concurrency="_%parameter("DEFAULTCONCURRENCY")_" }")
	if 'finally {
		$$$GENERATE($c(9)_"if (concurrency > 4) || (concurrency < 0) || (concurrency '= (concurrency\1)) { RETURN $$$ERROR($$$ConcurrencyValueInvalid) }")
	} else {
		$$$GENERATE($c(9)_"if (concurrency > 4) || (concurrency < 0) || (concurrency '= (concurrency\1)) { set sc = $$$ERROR($$$ConcurrencyValueInvalid) try { do ..%OnDeleteFinally(oid, sc) } catch {} RETURN sc }")
	}
		#; get class name
	$$$GENERATE($c(9)_"set class=$$$oidClassName(oid)")
	if 'finally {
			#; if class name is not present in oid, we must call the class method %OnDetermineClass
		$$$GENERATE($c(9)_"if class="""" { set sc=..%OnDetermineClass(oid,.class) RETURN:$$$ISERR(sc) sc set oid=$$$oidInsertClassName(oid,class) } else { set class=$$$NormalizeClassname(class) }")
	} else {
			#; if class name is not present in oid, we must call the class method %OnDetermineClass
		$$$GENERATE($c(9)_"if class="""" { set sc=..%OnDetermineClass(oid,.class) if $$$ISERR(sc) { try { do ..%OnDeleteFinally(oid, sc) } catch {} RETURN sc } set oid=$$$oidInsertClassName(oid,class) } else { set class=$$$NormalizeClassname(class) }")
	}
		#; See if we are the correct class. If not, dispatch polymorphically to correct %Delete()
	$$$GENERATE($c(9)_"if $classname()'=class { RETURN $classmethod(class,""%Delete"",oid,concurrency) }")
	if 'sharded {   // transactions not currently supported for sharded classes
			#; If TP is turned on start a transaction...
		if 'objectjournal { $$$GENERATE($c(9)_"if $$$txNOTINTRAN { set traninit=1 $$$txBeginTran }") }
		else { $$$GENERATE($c(9)_"if $$$txNOTINTRAN { set traninit=1 $$$txBeginTranJrn }") }
	}
		#; ##BEGINEVENT: DELETEDATA
		#; TODO: INSERT EVENT PROCESSING HERE
		#; find out if there is a %OnDelete method. If there is, call it
	if $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnDelete",$$$cMETHrunnable) {
		$$$GENERATE($c(9)_"set sc=..%OnDelete(oid) goto:$$$ISERR(sc) %DeleteEnd")
	}
	
	if 'sharded {	// relationships are not supported for sharded classes
			#; Generate relationship referential actions
		set relationship = $Order(ondelete(""))
		while relationship '= "" {
			set rclass=$li(ondelete(relationship)),rinverse=$li(ondelete(relationship),2)
			$$$GENERATE($c(9)_"set sc=##class("_rclass_")."_$$$QN(rinverse_"OnDelete")_"(id,concurrency) goto:$$$ISERR(sc) %DeleteEnd" )
			set relationship = $Order(ondelete(relationship))
		}
		
			// not supported for sharded classes
		$$$comMemberKeyGetLvar(guid,%class,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		if guid { $$$GENERATE($c(9)_"set guid = $get(^OBJ.GUID(1,oid))") }
	}
		#; Check for actions that require swizzling. If any, swizzle and then perform the actions
	if (($Data(serial)) || ($Data(stream)) || (((filter) || (objectjournal = 2)) && ('$$$SQLStorageIsSQL(storageclass)))) {
			#; Open the object being deleted:
		$$$GENERATE($c(9)_"set oref=..%Open(oid,concurrency) if oref=$$$NULLOREF { set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),$$$oidPrimary(oid)) goto %DeleteEnd }")
			#; Delete streams
		If $data(stream) {
			Set property = $Order(stream(""))
			While property '= "" {
				Set qproperty=$$$QN(property)
				if stream(property) = "" { $$$GENERATE($c(9)_"set stream=oref."_qproperty_"GetObject() if stream'="""" { set ^||%isc.strd($i(^||%isc.strd))=$lb(stream,"_stream(property,1)_") }") }
				elseif stream(property) = $$$cPROPCOLLECTIONLIST { $$$GENERATE($c(9)_"set key="""" for ptr=1:1 { set value=oref."_qproperty_".GetObjectNext(.key) quit:key=""""  if value'="""" { set ^||%isc.strd($i(^||%isc.strd))=$lb(value,"_stream(property,1)_") }}")
				} elseif stream(property) = $$$cPROPCOLLECTIONARRAY { $$$GENERATE($c(9)_"set key="""" for  { set value=oref."_qproperty_".GetObjectNext(.key) quit:key=""""  if value'="""" { set ^||%isc.strd($i(^||%isc.strd))=$lb(value,"_stream(property,1)_") }}") }
				Set property = $Order(stream(property))
			}
		}
		If $Data(serial) {
			Set property = $Order(serial(""))
			While property '= "" {
				set qproperty=$$$QN(property)
				if serial(property) = "" { $$$GENERATE($c(9)_"set sc = ##class("_serial(property,1)_").%Delete(oref."_qproperty_"GetObject(0),concurrency) goto:$$$ISERR(sc) %DeleteEnd") }
				elseif serial(property) = $$$cPROPCOLLECTIONLIST { $$$GENERATE($c(9)_"set key="""" for ptr=1:1 { set value=oref."_qproperty_".GetObjectNext(.key) quit:key=""""  set sc = ##class("_serial(property,1)_").%Delete(value,concurrency) goto:$$$ISERR(sc) %DeleteEnd }") }
				elseif serial(property) = $$$cPROPCOLLECTIONARRAY { $$$GENERATE($c(9)_"set key="""" for  { set value=oref."_qproperty_".GetObjectNext(.key) quit:key=""""  set sc = ##class("_serial(property,1)_").%Delete(value,concurrency) goto:$$$ISERR(sc) %DeleteEnd }") }
				Set property = $Order(serial(property))
			}
		}
			#; Journal the delete if journaling turned on and it isn't already journalled by SQL trigger:
		If ('sharded) && (objectjournal) && ('$$$SQLStorageIsSQL(storageclass)) {
			if objectjournal < 3 { $$$GENERATE($c(9)_"$$$txJournalObjectDelete($classname(),jid,id," _ $Select('guid:"""""",1:"guid") _ ",oref,iJrnPtr)") }
			else { $$$GENERATE($c(9)_"$$$txJournal($classname(),jid,id,2)") }
		}
		$$$GENERATE($c(9)_"set oref=$$$NULLOREF")
	}

		// This is where the old relationship referential action of NOACTION was generated!!
		
	$$$GENERATE($c(9)_"set gbl=..#DATALOCATIONGLOBAL $$$ActiveOidSearch(oid,oref,gbl,sfn) if $isobject(oref)=1 { do oref.%DeleteOID() }")
	$$$GENERATE($c(9)_"set sc=..%DeleteData(id,concurrency)")
	If (objectjournal) && ('filter) && ( '$$$SQLStorageIsSQL(storageclass) ) {
		if objectjournal = 1 { $$$GENERATE($c(9)_"if $$$ISOK(sc) { $$$txJournalDelete($classname(),jid,id," _ $Select('guid:"""""",1:"guid") _ ") }") }
		elseif objectjournal = 3 { $$$GENERATE($c(9)_"if $$$ISOK(sc) { $$$txJournal($classname(),jid,id,2) }") }
	}
		#; find out if there is a %OnAfterDelete method. If there is, call it
	If $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnAfterDelete",$$$cMETHrunnable) { $$$GENERATE($c(9)_"if $$$ISOK(sc) { set sc=..%OnAfterDelete(oid) }") }
		#; Generate the streams that were queued up before %DeleteData
	if $Data(stream) {
		$$$GENERATE($Char(9)_"if $$$ISOK(sc) {")
		$$$GENERATE($Char(9,9)_"set tPtr = """" for { set tPtr=$order(^||%isc.strd(tPtr),1,tStreamData) quit:tPtr=""""  set stream=$li(tStreamData,1),cls=$li(tStreamData,2),sc=$classmethod(cls,""%Delete"",stream,concurrency) quit:$$$ISERR(sc) }")
		$$$GENERATE($Char(9,9)_"kill ^||%isc.strd")
		$$$GENERATE($Char(9)_"}")
	}
		#; for sharded classes, DSTIME is not supported, so this will never be true
	if tDSTIME = 1 { $$$GENERATE($Char(9)_"$$$DSTIME($classname(),id,2)") }
	elseif tDSTIME = 2 { $$$GENERATE($Char(9)_"$$$DSTIMEH($classname(),id,2,"_$Select(tDSINTERVAL:tDSINTERVAL,1:1)_",tDST,tDSS)") }
	elseif tDSTIME = 3 { $$$GENERATE($Char(9)_"If ("_tDSCONDITION_") { $$$DSTIME($classname(),id,2) }") } //DP-404466
	elseif tDSTIME = 4 { $$$GENERATE($Char(9)_"If ("_tDSCONDITION_") { $$$DSTIMEH($classname(),id,2,"_$Select(tDSINTERVAL:tDSINTERVAL,1:1)_",tDST,tDSS) }") } //DP-404466
		#; ##ENDEVENT: DELETEDATA
	if 'sharded {
		if objectjournal { $$$GENERATE("%DeleteEnd"_$select($Data(stream):" if $$$ISERR(sc) { kill ^||%isc.strd }",1:"")_" if traninit { if $$$ISOK(sc) { $$$txCommitJrn } else { $$$txRollbackJrn(sc) } }") }
		else { $$$GENERATE("%DeleteEnd"_$select($Data(stream):" if $$$ISERR(sc) { kill ^||%isc.strd }",1:"")_" if traninit { if $$$ISOK(sc) { $$$txCommit } else { $$$txRollback(sc) } }") }
	} else {
		$$$GENERATE("%DeleteEnd")
	}
	if 'finally {
		$$$GENERATE($c(9)_"RETURN sc")
	} else {
		$$$GENERATE($c(9)_"try { do ..%OnDeleteFinally(oid, sc) } catch {} RETURN sc")
	}
	$$$GENERATE("%DeleteERR	set $zt="""",sc=$$$ERROR($$$ObjectScriptError,$ZE)")
	$$$GENERATE($c(9)_"goto %DeleteEnd")
	RETURN $$$OK
}

/// Internal method to remove a previously assigned oid only to be used when deleting an object that is also in memory.
Method %DeleteOID() As %Status [ Internal, Private ]
{
	If i%%Concurrency>2 Set sc=..%ReleaseLock($select(i%%Concurrency=3:"s",1:"e"))
	Set oid=i%"%%OID"
	$$$txUnAssignOIDSaveModState($this,oid) Do $system.CLS.SetModified(1) $$$ActiveOidRemove(oid)
	Quit $$$OK
}

/// Deletes the stored version of the object with ID <var>id</var> from the database. 
/// 
/// <p><METHOD>%DeleteId</METHOD> is identical in operation to the <METHOD>%Delete</METHOD> method except 
/// that it uses an Id value instead of an OID value to find an object.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument.  For classes defined as Sharded=1, concurrency=0 is always used.
ClassMethod %DeleteId(id As %String, concurrency As %Integer = -1) As %Status [ CodeMode = expression, Final, ServerOnly = 0 ]
{
..%Delete($$$oidForm(id),.concurrency)
}

/// Delete all instances of this class from its extent. On exit <var>instancecount</var> 
/// contains the original number of instances while <var>deletecount</var> contains 
/// the number of instances actually deleted.<br>
/// 
/// <p>Internally, <METHOD>%DeleteExtent</METHOD> iterates over the set of instances in the 
/// collection and invokes the <METHOD>%Delete</METHOD> method.<br>
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument.<br>
/// 
/// The option <var>pInitializeExtent</var> argument allows the user to override the default behavior
/// of calling <method>%KillExtent</method> when all instances are successfully deleted. <method>%KillExtent</method>
/// is called by default when the extent is empty so that empty globals can be killed. If <method>%KillExtent</method>
/// is not called then some empty globals can remain as well as the ID counter if it exists. The default value for <var>pInitializeExtent</var>
/// is 1. Unless the caller specifies a false value for <var>pInitializeExtent</var> the globals used by the extent will be killed. If the
/// process' GlobalKillDisabled flag is enabled and not the default of false the process' GlobalKillDisabled flag will be changed temporarily to false
/// to allow the operation to complete without a possible <PROTECT> error.
/// In some cases, the globals used by the extent are not used exclusively by the extent. In those cases it is possible that some globals will still be defined
/// even when pInitializeExtent is true. By default this call to <method>%KillExtent</method> will not delete default stream storage global, but if you pass '2' in
/// <var>pInitializeExtent</var> and if the entire extent was deleted we will call %KillExtent passing the 'killstreams' flag to ask it to remove kill the default
/// storage global.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod %DeleteExtent(concurrency As %Integer = -1, ByRef deletecount, ByRef instancecount, pInitializeExtent As %Integer = 1, Output errorLog As %Status) As %Status [ ServerOnly = 0 ]
{
	Set deletecount=0,instancecount=0,errorLog = $$$OK
	if $$$comSharded($classname())=1 {  // %DeleteExtent calls %DeleteExtent for the shardLocal class on each shard  JMM1160=
		RETURN ##class(%BigData.ShardedSQL).%CallDeleteExtent($classname())
	}
	If $system.CLS.IsMthd("ExtentExecute") {
		Set sc=..ExtentExecute(.qh)
		RETURN:$$$ISERR(sc) sc
	} Else {
		RETURN $$$OK
	}
	For  {
		Set sc=..ExtentFetch(.qh,.row,.atend)
		Quit:$select(row="":1,$$$ISERR(sc):1,1:0)
		Set id=$listget(row)
		If id'="" { 
			Set sc=..%Delete($listbuild(id),concurrency)
			Set instancecount=instancecount+1
			set:$$$ISERR(sc) errorLog=$$$ADDSC(errorLog,sc)
			Set:$$$ISOK(sc) deletecount=deletecount+1
			Quit:atend
		}
	}
	Do ..ExtentClose(qh)
	If instancecount = deletecount { 
		if pInitializeExtent {
			$$$DoWithGlobalKillEnabled(..%KillExtent(0,$select(pInitializeExtent=2:1,1:0)))
		}
		Set sc = $$$OK
	} else { Set sc = $$$ERROR($$$DeleteExtentObjectsRemain,$$$objClass) }
	RETURN sc
}

/// Changes the concurrency level of an instance in memory to a lower level 
/// by changing the lock type specified in the <METHOD>%Open</METHOD> method for the object's 
/// instance. Fails if it cannot lower the concurrency level.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the <var>concurrency</var> argument.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %DowngradeConcurrency(concurrency As %Integer(MINVAL=0,MAXVAL=4) = 0) As %Status [ Final, Internal, ServerOnly = 0 ]
{
	If (concurrency > 4) || (concurrency < 0) || (concurrency '= (concurrency\1)) Quit $$$ERROR($$$ConcurrencyValueInvalid)
	Set current=i%%Concurrency
	#; If the requested setting is greater or equal to the current setting, then do nothing
	If concurrency'<current Quit $$$OK
	#; Locks are not retained for any setting less than 3 and if the old and new
	#; setting are the same, nothing is to done except update the concurrency setting
	If current<3 Set modstate=$system.CLS.GetModifiedBits(),i%%Concurrency=concurrency Do $system.CLS.SetModifiedBits(modstate) Quit $$$OK
	#; Get the new lock if needed
	If concurrency>2 Set sc=..%AcquireLock($select(concurrency=3:"s",1:"e")) Quit:$$$ISERR(sc) sc
	#; the following line releases the old lock which we know must be there
	#; because we process and quit above for current<3
	Do ..%ReleaseLock($select(current=3:"s",1:"e"))
	#; Update the concurrency setting:
	Set modstate=$system.CLS.GetModifiedBits(),i%%Concurrency=concurrency Do $system.CLS.SetModifiedBits(modstate)
	Quit $$$OK
}

/// Returns a %Status value
ClassMethod %ExecuteBeforeTriggers(%oper, pOid As %Library.ObjectIdentity = "", ByRef pNew As %String(MAXLEN=""), ByRef pOld As %Library.Binary) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	if ($$$comMemberNext(%class,$$$cCLASStrigger,"") '= "") && ($$$getClassType(%class) = $$$cCLASSCLASSTYPEPERSISTENT ) && ( '$$$comClassKeyGet(%class,$$$cCLASSnoextent) ) {
		$$$tMetadataUses("PrecompileTriggerCode^%occTrigger(%class)")
		merge %code = $$$tMetadata("c","%ExecuteBeforeTriggers")
	}
	quit $$$OK
}

/// Returns a %Status value
ClassMethod %ExecuteAfterTriggers(%oper, pOid As %Library.ObjectIdentity = "", ByRef pNew As %String(MAXLEN=""), ByRef pOld As %Library.Binary) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	if ($$$comMemberNext(%class,$$$cCLASStrigger,"") '= "") && ($$$getClassType(%class) = $$$cCLASSCLASSTYPEPERSISTENT ) && ( '$$$comClassKeyGet(%class,$$$cCLASSnoextent) ) {
		$$$tMetadataUses("PrecompileTriggerCode^%occTrigger(%class)")
		merge %code = $$$tMetadata("c","%ExecuteAfterTriggers")
	}
	quit $$$OK
}

/// Returns the persistent object Id, if there is one, of this object. 
/// <p>Returns a null string if there is no object Id.
Method %Id() As %String [ CodeMode = expression, Final, ServerOnly = 0 ]
{
$$$idCurrent
}

/// Assigns a persistent object Id value for this object. 
/// This method fails if the object already has an Id value assigned to it.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %IdSet(id As %String) As %Status [ Final, Internal, Private, ServerOnly = 1 ]
{
 	Set class=$classname(),class=$$$DenormalizeClassname(class),oid=$$$oidCompose(id,class)
	#; Check for previously assigned OID
	If i%"%%OID"'="",i%"%%OID"'=oid Quit $$$ERROR($$$OidPreviouslyAssigned,$classname(),id)
	#; store oid and allow lookup based on oid
	$$$ActiveOidInsertNoSFN(oid,oref,gbl,sfn)
	Quit $$$OK
}

/// <METHOD>%GetSwizzleObject</METHOD> is used to obtain a state of the object that can 
/// later be used to restore the object. In the case of a persistent object, it returns the OID.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %GetSwizzleObject(force As %Integer = 0, ByRef oid As %ObjectIdentity) As %Status [ Final, ServerOnly = 1 ]
{
	Set oid="" If force=0 Set oid=i%"%%OID" Quit $$$OK
	If force=2 Set sc=..%Save(1) Set:$$$ISOK(sc) oid=i%"%%OID" Quit sc
	Set oid=i%"%%OID" Quit:oid'="" $$$OK
	Set sc=..%Save(0) Set:$$$ISOK(sc) oid=i%"%%OID"
	Quit sc
}

/// Returns the OID of this object.
Method %Oid() As %ObjectIdentity [ CodeMode = expression, Final, ServerOnly = 0 ]
{
i%"%%OID"
}

/// %ComposeOid()
/// 
/// 		This class method accepts an ID and returns a fully qualified OID, containing the most specific type class of the object identified by the
/// 		<var>id</var> argument. If default storage is used then the %%CLASSNAME value is used to determine the most specific type class, otherwise call
/// 		%OnDetermineClass to determine the most specific type class. If neither case is true then the current class is
/// 		used. If there is a problem determining the most specific type class then null ("") is returned.
ClassMethod %ComposeOid(id As %String(MAXLEN="")) [ CodeMode = generator ]
{
	if ($$$getClassType(%class) '= $$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) { kill %code quit $$$OK }
	set tRoot = $$$EXTrootclass($$$pEXT,%class), package = $$$ClassPackageName(%class), tCLASSNAMEGet = $Get($$$EXTPROPondisk($$$pEXT,%class,"%%CLASSNAME"))
	If tRoot && ($$$comClassKeyGet(%class,$$$cCLASSfinal)) { $$$GENERATE("	Quit $$$oidCompose(id,$classname())") Quit $$$OK }
	if tCLASSNAMEGet '= "" {
		If tRoot { Set tRootpackage = package,tRootclass = %class }
		Else {
			Set tRootclass = $$$EXTroot($$$pEXT,%class)
			While (tRootclass '= "") && ('$$$EXTrootclass($$$pEXT,tRootclass)) {
				Set tRootclass = $Get($$$EXTroot($$$pEXT,tRootclass))
			}
				If tRootclass '= "" { Set tRootpackage = $$$ClassPackageName(tRootclass) }
		}
		$$$GENERATE("	set tCLASSNAME = "_tCLASSNAMEGet)
		if tRoot {
			$$$GENERATE("	if tCLASSNAME="""" { quit $$$oidCompose(id,"""_tRootclass_""") }")
		} else {
			$$$GENERATE("	Set tClass=$classname(),tClass=$select(($extract(tClass,1,5)=""User."")&&($length(tClass,""."")=2):$piece(tClass,""."",2),1:tClass)")
			$$$GENERATE("	if tCLASSNAME'[($extract(tCLASSNAME)_tClass_$extract(tCLASSNAME)) Quit """"")
		}
		$$$GENERATE("	set tClass=$piece(tCLASSNAME,$extract(tCLASSNAME),*-1)")
		$$$GENERATE("	set:tClass'[""."" tClass=""User.""_tClass")
		$$$GENERATE("	quit $$$oidCompose(id,tClass)")
	} else {
		$$$GENERATE("	set tSC = ..%OnDetermineClass(id,.tClass)")
		$$$GENERATE("	quit $Select($$$ISOK(tSC):$$$oidCompose(id,tClass),1:"""")")
	}
	QUIT $$$OK
}

/// Loads an object from the database into memory and returns an OREF referring to the object. 
/// <var>oid</var> is the OID value of the object to load. If <var>oid</var> is a partially-formed OID, 
/// that is it does not include a class name, then <METHOD>%Open</METHOD> does the following: 
/// a) calls the method, <METHOD>%OnDetermineClass</METHOD>, 
/// to determine the class name, otherwise b) it assumes the class name is 
/// the same as the object class on which <METHOD>%Open</METHOD> was called.
/// <p>If a version of the specified object is already in memory, then <METHOD>%Open</METHOD> increments 
/// the object's reference count and returns the OREF value referring to this version.
/// <METHOD>%Open</METHOD> also has an optional concurrency argument which specifies the concurrency setting 
/// for this object (and sets the value of the <var>%Concurrency</var> attribute). If the 
/// <var>concurrency</var> argument is omitted then the system default value (1: <i>Atomic</i>) is used.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument.  For classes defined as Sharded=1, concurrency=0 is always used.
/// 
/// <p><METHOD>%Open</METHOD> returns an OREF value that refers to the in-memory object instance or 
/// a null reference ($$$NULLOREF) if it cannot find or otherwise load the object.
ClassMethod %Open(oid As %ObjectIdentity, concurrency As %Integer = -1, ByRef sc As %Status = {$$$OK}) As %ObjectHandle [ Final, ServerOnly = 0 ]
{
	#; if not passed an initial state, quit with error
	If $$$oidPrimary($g(oid))="" { Set sc = $$$ERROR($$$NullOid,$classname()) try { do ..%OnOpenFinally($get(oid), sc) } catch {} RETURN $$$NULLOREF }
	Set $Ztrap = "Catch"
	Set class=$$$oidClassName(oid)
	If class="" {
		Set sc=..%OnDetermineClass(oid,.class) If $$$ISERR(sc) { try { do ..%OnOpenFinally(oid, sc) } catch {} RETURN $$$NULLOREF }
		Set oid=$$$oidInsertClassName(oid,class)
	} Else {
		Set class=$$$NormalizeClassname(class)
	}
	If concurrency = -1 { Set concurrency=$select(..#DEFAULTCONCURRENCY="$zu(115,10)":$zu(115,10),1:$xecute("Quit "_..#DEFAULTCONCURRENCY)) }
	If (concurrency > 4) || (concurrency < 0) || (concurrency '= (concurrency\1)) { Set sc = $$$ERROR($$$ConcurrencyValueInvalid) try { do ..%OnOpenFinally(oid, sc) } catch {} RETURN $$$NULLOREF }
		#; if class name is not present in oid, we must call the class method %OnDetermineClass
	If class'=$classname() { RETURN $classmethod(class,"%Open",.oid,.concurrency,.sc) }
		#; see if we should reuse an existing object, also sets public variable %sfn which is sfn number of database where data lives
		#; this is used by %LoadInit to insert the new oref into obj->oref table
	Set gbl=..#DATALOCATIONGLOBAL
	$$$ActiveOidSearch(oid,oref,gbl,sfn)
	If $isobject(oref)=1 { If concurrency>oref.%Concurrency { If (oref.%Concurrency<3) && (concurrency > 2) { Set reload = 1 } Else { Set reload = 0 } Set sc=oref.%UpgradeConcurrency(concurrency) If (reload) && ($$$ISOK(sc)) { Set sc=oref.%Reload() } If $$$ISERR(sc) { set oref = $$$NULLOREF } } Else { Set sc = $$$OK } try { do ..%OnOpenFinally(oid, sc) } catch {} RETURN oref }
	Set oref=$$$CreateObject(class) If oref=$$$NULLOREF { Set sc = $$$ERROR($$$AbstractClassNotInstantiable,class) try { do ..%OnOpenFinally(oid, sc) } catch {} RETURN oref }
	Set sc=oref.%LoadInit(oid,concurrency) If $$$ISERR(sc) { try { do ..%OnOpenFinally(oid, sc) } catch {} RETURN $$$NULLOREF }
	Set sc=oref.%LoadData($$$oidPrimary(oid)) If $$$ISERR(sc) { try { do ..%OnOpenFinally(oid, sc) } catch {} RETURN $$$NULLOREF }
		#; set object as not modified
	Do $system.CLS.SetModified(oref,0)
		#; find out if there is a %OnOpen method. If there is a %OnOpen, call it
	If $system.CLS.IsMthd(oref,"%OnOpen") { Set sc=oref.%OnOpen() If $$$ISERR(sc) { try { do ..%OnOpenFinally(oid, sc) } catch {} RETURN $$$NULLOREF }}
	try { do ..%OnOpenFinally(oid, sc) } catch {}
	RETURN oref
Catch	Set $ZTrap = ""
	try {
		If '$$$ISERR($Get(sc)) {
			set sc = $Select($Extract($ZE,1,9)="<PROTECT>":$$$ERROR($$$InsufficientPrivilegeObjectAccess,$get(class,$classname())_"::%Open"),1:$$$ERROR($$$ObjectScriptError,$ZE))
		}
		do ..%OnOpenFinally(oid, sc)
	} catch {}
	RETURN $$$NULLOREF
}

/// Return true if pOID is a null object and false if the object is not null
ClassMethod %ObjectIsNull(pOID As %ObjectIdentity) As %Boolean
{
	If $isobject(pOID)=1 Set pOID=pOID."%%OID"
	if pOID = $$$NULLOID quit 1
	set class = $$$oidClassName(pOID)
	if class = "" { do ..%OnDetermineClass(pOID,.class) }
	if class '= "" {
		set class=$$$NormalizeClassname(class) if $classname()'=class quit $classmethod(class,"%ObjectIsNull",pOID)
	}
	quit $$$oidPrimary(pOID)=""
}

Method %LoadInit(oid As %ObjectIdentity = "", concurrency As %Integer = "", reset As %Boolean = 0) As %Status [ CodeMode = generator, Final, Internal, Private ]
{
	#; We should be somewhat stable now, set the %Concurrency attribute...
	$$$GENERATE("	Set:concurrency'="""" i%%Concurrency=concurrency")
	if $$$comSharded(%class)=1 { // JMM1160=
		$$$GENERATE("	RETURN:i%%Concurrency>0 $$$ERROR($$$ShardClassUnsupportedFeature,$classname(),""Concurrency>0"","""")")
	}	
	Set ivar="" For {
		Set ivar=$$$comMemberNext(%class,$$$cCLASSinstancevar,ivar) Quit:ivar=""
		Set qivar=$$$QN(ivar)
		Kill origin
		$$$comMemberKeyGetLO(multi,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPmultidimensional)
		If multi Set kill($i(kill))="i%"_$$$QN(ivar) Continue
		$$$comMemberKeyGetLO(transient,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPtransient)
		If transient,ivar'="%Concurrency",ivar'="%%OID" {
			$$$comMemberKeyGetLvar(initialexpression,%class,$$$cCLASSinstancevar,ivar,$$$cIVARinitialexpression)
			Set set($i(set))="i%"_qivar_"="_initialexpression
		}
		$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPcollection)
		$$$comMemberKeyGetLO(relationship,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPrelationship)
		If 'relationship,collection=$$$cPROPCOLLECTIONARRAY||(collection=$$$cPROPCOLLECTIONLIST) {
			Set kill($i(kill))="r%"_qivar,set($i(set))="i%"_qivar_"="""""
		}
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,ivar,$$$cPROPruntimetype) 
		If $$$classIsDataType(runtimetype) Continue
		Set kill($i(kill))="i%"_qivar,set($i(set))="r%"_qivar_"="""""
	}
	If $get(kill) {
		$$$GENERATE("	If reset {")
		Set kills=""
		For i=1:1:kill {
			Set kills=kills_kill(i)_","
			If i#10=0 $$$GENERATE("		Kill "_$extract(kills,1,*-1)) Set kills=""
		}
		If kills'="" $$$GENERATE("		Kill "_$extract(kills,1,*-1))
		$$$GENERATE("	}")
	}
	Set sets=""
	For i=1:1:$get(set) {
		Set sets=sets_set(i)_","
		If i#10=0 $$$GENERATE("	Set "_$extract(sets,1,*-1)) Set sets=""
	}
	If sets'="" $$$GENERATE("	Set "_$extract(sets,1,*-1))
	$$$GENERATE("	If 'reset { $$$ActiveOidInsertNoSFN(oid,oref,gbl,sfn) }")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Loads an object from the database into memory or finds existing reference and returns
/// an OREF referring to the object.
/// <var>id</var> is the Id (not a full OID) value of the object to load.
/// <p>If a version of the specified object is already in memory, then <METHOD>%Open</METHOD> increments 
/// the object's reference count and returns the OREF value referring to this version.
/// <METHOD>%Open</METHOD> also has an optional concurrency argument which specifies the concurrency setting 
/// for this object (and sets the value of the <var>%Concurrency</var> attribute). If the 
/// <var>concurrency</var> argument is omitted then the system default value (1: <i>Atomic</i>) is used.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the optional <var>concurrency</var> argument.  For classes defined as Sharded=1, concurrency=0 is always used.
/// 
/// <p><METHOD>%OpenId</METHOD> returns an OREF value that refers to the in-memory object instance or 
/// a null reference ($$$NULLOREF) if it cannot find or otherwise load the object.
ClassMethod %OpenId(id As %String = "", concurrency As %Integer = -1, ByRef sc As %Status = {$$$OK}) As %ObjectHandle [ CodeMode = expression, Final, ServerOnly = 0 ]
{
..%Open($$$oidForm(id),.concurrency,.sc)
}

/// <p>%Reload is an instance method that re-reads an object from disk into the 
/// current instance. Calling %Reload is similar to closing the OREF and then 
/// <METHOD>%Open</METHOD>, but it uses the same OREF. %Open is not called and no %Open callbacks
/// are called.</p>
/// <p>After %Reload is called, there are no swizzled references for the object, 
/// and <METHOD>%IsModified</METHOD> returns 0.
/// </p>
/// <p>%Reload performs the following steps. First, all swizzled objects for the 
/// instance are unswizzled. Then the object is reloaded from disk, using the 
/// <METHOD>%Id</METHOD> of the current object. Finally, the modified bit for each property is 
/// cleared.
/// <p>
Method %Reload() As %Status [ ServerOnly = 0 ]
{
	If $$$idCurrent="" Quit $$$ERROR($$$NullOid,$classname())
	Set cur=i%%Concurrency,i%%Concurrency=0
	Set sc=..%LoadInit(,,1) If $$$ISERR(sc) Quit sc
	Set sc=..%LoadData($$$idCurrent) Set i%%Concurrency=cur If $$$ISERR(sc) quit sc
	if $system.CLS.IsMthd($this,"%OnReload") Set sc=..%OnReload() If $$$ISERR(sc) quit sc
	#; set object as not modified
	Do $system.CLS.SetModified(0)
	Quit $$$OK
}

/// This method is called by <METHOD>%Save</METHOD> when a transaction is rolled back. 
/// It will invoke a user-supplied <METHOD>%OnRollBack</METHOD> method if it exists.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %RollBack() As %Status [ ServerOnly = 1 ]
{
	If $data($$$txOIDASSIGNED(+$this)) Set oid=i%"%%OID" If oid'="" $$$ActiveOidRemove(oid)
	If $data($$$txOIDUNASSIGNED(+$this),oid) $$$ActiveOidInsertNoSFN(oid,oref,gbl,sfn)
	if $Data($$$txVERSION($this)) {
			// Rollback the version property
		if ..#VERSIONPROPERTY '[ "." {
			set $property($this,..#VERSIONPROPERTY) = $$$txVERSION($this)
		} else {
			set versionProperty = $Piece(..#VERSIONPROPERTY,".",1)
			set $property($this,versionProperty) = ""
			do $method($this,versionProperty_"SetObject",$$$txVERSION($this))
		}
	}
	If $data($$$txMODIFIED($this)) Do $system.CLS.SetModifiedBits($$$txMODIFIED($this))
	#; if a %OnRollBack() method exists, return with it's value......
	If $system.CLS.IsMthd("%OnRollBack") Quit ..%OnRollBack()
	QUIT $$$OK
}

/// Stores an in-memory version of an object to disk. If the object was stored 
/// previously (and thus, already has an OID), <METHOD>%Save</METHOD> updates the on-disk version. 
/// Otherwise, <METHOD>%Save</METHOD> assigns a new OID to the object and saves it.
/// 
/// <p>The <var>related</var> argument specifies how <METHOD>%Save</METHOD> handles references to other objects. 
/// It can take the following values:
/// <table cols=2>
/// <tr>
/// <td width="33%" valign="top">0: <i>Shallow Save</i></td>
/// <td valign="top">
/// If this object has been modified then save it. Only save related objects if they have never been saved (do not have an OID value) and must be 
/// saved in order to serialize this object's property values.
/// </td>
/// </tr>
/// 
/// <tr>
/// <td width="33%" valign="top">1: <i>Deep Save</i></td>
/// <td valign="top">
/// Save this object and all "related" objects that have been edited. In this case, 
/// "related" means any in-memory objects it refers to, and any in-memory objects 
/// they in turn refer to, and so on. However, only objects that have been changed 
/// (<METHOD>%IsModified</METHOD> returns true) will actually be saved to the database, including 
/// the object upon which <METHOD>%Save</METHOD> was initially called.
/// </td>
/// </tr>
/// </table>
/// 
/// <p><METHOD>%Save</METHOD> automatically detects and handles circular references between objects. 
/// For example, <METHOD>%Save</METHOD> will detect if object A refers to object B and object B likewise refers to object A.
/// In this case it will avoid falling into an infinite, recursive loop.
/// 
/// <p>Note that either reference attribute, A to B or B to A, can be specified as a required attribute but not both of them.
/// If both reference attributes are required then <METHOD>%Save</METHOD> will fail.
/// 
/// <p>By default <METHOD>%Save</METHOD> automatically manages transactions. You can enable and disable 
/// automatic transaction support using the <code>$$SetTransactionMode^%apiOBJ()</code> routine.
/// 
/// <p>When <METHOD>%Save</METHOD> saves an object to the database, it initiates one transaction 
/// (by calling TSTART) for the entire set of saves, including the original object 
/// and any related objects. If the save operation is successful, <METHOD>%Save</METHOD> will issue a 
/// TCOMMIT command to commit the transaction and write the data to the database.
/// If <METHOD>%Save</METHOD> encounters a problem when saving the original object or any of its 
/// related objects, it rolls back the entire transaction and performs the following actions:
/// <ul>
/// <li>It issues a TROLLBACK command to rollback any changes to the database that may 
/// have occurred. (In the case of the <CLASS>%Storage.Persistent</CLASS> class, changes to the on-disk 
/// counter value, used to determine the next available object id number, are not rolled back.)</li>
/// <li>It restores the in-memory state of all the objects involved in the transaction to 
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
Method %Save(related As %Integer = 1) As %Status [ CodeMode = generator, Final, GenerateAfter = (%OnBeforeSave, %OnAfterSave), ServerOnly = 0 ]
{
	Set %code=0
	If $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT Quit $$$OK
	$$$comMemberKeyGetLvar(objectjournal,%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault)
	$$$comMemberKeyGetLvar(tDSTIME,%class,$$$cCLASSparameter,"DSTIME",$$$cPARAMdefault)
	if ($$$ucase(tDSTIME) = "AUTO") {
		$$$comMemberKeyGetLvar(tDSINTERVAL,%class,$$$cCLASSparameter,"DSINTERVAL",$$$cPARAMdefault)
		if tDSINTERVAL '> 0 { set tDSTIME = 1 } else { set tDSTIME = 2 }
	}
	elseif ($$$ucase(tDSTIME) = "CONDITIONAL"){ //DP-404466
		if +$G(tDSINTERVAL) '> 0 { set tDSTIME = 3 } else { set tDSTIME = 4 }
		$$$comMemberKeyGetLvar(tDSCONDITION,%class,$$$cCLASSparameter,"DSCONDITION",$$$cPARAMdefault)
	}
	else { set tDSTIME = 0 }
	#; Look to see if we need to construct a save set
	If ($$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnAddToSaveSet",$$$cMETHrunnable)) || (objectjournal) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault) {
		Set simple=0
	} Else {
		#; Look to see this this is a 'literal' object with no references to other objects
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,""), simple = 1
		While prop '= "" {
			$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
				#; do nothing if property is a datatype or isn't storable
			If ($$$getClassType(runtimetype) '= $$$cCLASSCLASSTYPEDATATYPE) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPcalculated)) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPmultidimensional)) Set simple=0 Quit
			Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
		}
	}
		#; Initialize the transaction state
		#; This method is a transaction itself and isn't called recursively. Therefore, the
		#; SaveSet state variable - %objTX - is new'ed here.
	$$$GENERATE("	Set $ZTrap=""%SaveERR""")
	$$$GENERATE("	New %objTX Set sc=$$$OK,traninit=0 If '$data(%objTX2) New %objTX2 Set %objTX2=1")
		#; %TStart - Start a transaction if one doesn't exist and $zu(115,9) is on
		#; %TInclude - include this oref in the current transaction...
	$$$GENERATE("	If $$$txNOTINTRAN { Set traninit=1 $$$txBeginTran"_$select(objectjournal:"Jrn",1:"")_" }")
	If simple {
		Set runtimeclasstype=$$$getClassType(%class), tTriggered = 0
		#; If we call %OnBeforeSave/%OnAfterSave we need part of save set created if we are also persistent
		$$$comMemberKeyGetLvar(onAfter,%class,$$$cCLASSmethod,"%OnAfterSave",$$$cMETHrunnable)
		$$$comMemberKeyGetLvar(onBefore,%class,$$$cCLASSmethod,"%OnBeforeSave",$$$cMETHrunnable)
		if (runtimeclasstype=$$$cCLASSCLASSTYPEPERSISTENT) && '(onAfter + onBefore) {
			set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
			While prop '= "" {
				if $$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPsqlcomputed) {
					if $$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPsqlcomputeonchange) [ "%%" { set tTriggered = 1 quit }
				}
				Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
			}
		}
		if (onBefore) || (onAfter) || (tTriggered) || (tDSTIME) {
			If runtimeclasstype=$$$cCLASSCLASSTYPEPERSISTENT {
				If ((tDSTIME=3) || (tDSTIME=4)) { //DP-404466
					$$$GENERATE("	If ("_tDSCONDITION_") {")
					$$$GENERATE("		Set (index,%objTX(0,+$this))=$i(%objTX(1)),%objTX(1,index,1)=i%""%%OID"",%objTX(1,index)=$this,%objTX(1,index,4)=$select(%objTX(1,index,1)="""":1,..%ExistsId($$$oidPrimary(%objTX(1,index,1))):0,1:1)")
					$$$GENERATE("	}")
				} 
				Else {
					$$$GENERATE("	Set (index,%objTX(0,+$this))=$i(%objTX(1)),%objTX(1,index,1)=i%""%%OID"",%objTX(1,index)=$this,%objTX(1,index,4)=$select(%objTX(1,index,1)="""":1,..%ExistsId($$$oidPrimary(%objTX(1,index,1))):0,1:1)")
				}
				
			}
		}
		If runtimeclasstype=$$$cCLASSCLASSTYPEPERSISTENT {
			$$$GENERATE("	If ..%ObjectModified() Set sc=..%SerializeObject(i%""%%OID"") If $$$ISERR(sc) ZTrap ""SG""")
		} ElseIf runtimeclasstype=$$$cCLASSCLASSTYPESERIAL {
			$$$GENERATE("	If ..%ObjectModified() Set sc=..%SerializeObject("""") If $$$ISERR(sc) ZTrap ""SG""")
		} Else {
			$$$GENERATE("	Set sc=..%SerializeObject("""") If $$$ISERR(sc) ZTrap ""SG""")
		}
	} Else {
		#; If already in %Save, just build a shallow graph and serialize the object
		$$$GENERATE("	If $get(%objTX2(+$this)) Set sc=..%BuildObjectGraph(1) If $$$ISERR(sc) { ZTrap ""SG"" } Set intRef=+$this,objValue=$get(%objTX(1,+$g(%objTX(0,intRef)),1)),sc=..%SerializeObject(.objValue,1) If $$$ISERR(sc) { ZTrap ""SG"" } Set %objTX(1,%objTX(0,intRef),1)=objValue GoTo %SaveCOMMIT")
		$$$GENERATE("	Set sc=..%BuildObjectGraph(related+2) If $$$ISERR(sc) ZTrap ""SG""")
			#; At this point, %objTX(2) contains a list of all objects that need to be saved
		$$$GENERATE("	If '$data(%objTX(2)) s sc=$$$OK GoTo %SaveCOMMIT")
			#; First, examine the objects designated to be saved to see if any have zero predecessors
		$$$GENERATE("	Set %objTX(3)=0,i="""" For  Set i=$order(%objTX(2,i),1,data) Quit:i=""""  Set intRef=$li(data) If '$data(%objTX(1,+$g(%objTX(0,intRef)),2)) Set %objTX(3,$increment(%objTX(3)))=%objTX(1,%objTX(0,intRef)) Kill %objTX(2,i),%objTX(11,intRef)")
			#; Process the AOV. Calls to %SerializeObject here are complete serializations. If one fails, the TX needs to fail
		$$$GENERATE("	For ptr=1:1 Quit:ptr>%objTX(3)  Set objRef=%objTX(3,ptr),objValue=$get(%objTX(1,+$g(%objTX(0,+objRef)),1)),sc=objRef.%SerializeObject(.objValue) Do  Set %objTX(1,%objTX(0,+objRef),1)=objValue Kill %objTX(1,%objTX(0,+objRef),3) Do $system.CLS.SetModified(objRef,0)")
		$$$GENERATE("	. If $$$ISERR(sc) ZTrap ""SG""")
			#; Process the mod bits for potential tx rollback
		$$$GENERATE("	. $$$txSaveModState(objRef)")
			#; visit the successors
		$$$GENERATE("	. Set intSucc="""" For  Set intSucc=$order(%objTX(1,%objTX(0,+objRef),3,intSucc)) Quit:intSucc=""""  Kill %objTX(1,%objTX(0,+objRef),3,intSucc),%objTX(1,intSucc,2,%objTX(0,+objRef)) If '$data(%objTX(1,intSucc,2)) Set %objTX(3,$increment(%objTX(3)))=%objTX(1,intSucc) Kill:$d(%objTX(11,+%objTX(1,intSucc))) %objTX(2,%objTX(11,+%objTX(1,intSucc))),%objTX(11,+%objTX(1,intSucc))")
			#; If any objects are remaining in the graph then do a 'partial serialization' of the persistent objects that are
			#; designated as 'predecessors'. Any objects remaining in the graph following partial serialization represent unresolvable cycles. 
		$$$GENERATE("	Kill %objTX(3) Set %objTX(3)=0 For  Set pserial=0 Do  Quit:'pserial")
		$$$GENERATE("	. Set i="""" For  Set i=$order(%objTX(2,i),1,data) Quit:i=""""  Set intPred="""",intRef=$li(data) For  Set intPred=$order(%objTX(1,%objTX(0,intRef),2,intPred)) Quit:intPred=""""  If $get(%objTX(1,intPred,6))=1 Set objValue=$get(%objTX(1,intPred,1)),sc=(%objTX(1,intPred)).%SerializeObject(.objValue,1) If $$$ISERR(sc) { If $d(%objTX(11,+%objTX(1,intPred))) { Set %objTX(2,%objTX(11,+%objTX(1,intPred)),1)=sc } Else { Set %objTX(2,$i(%objTX(2)),1)=sc,%objTX(11,+%objTX(1,intPred))=%objTX(2) } } If $$$ISOK(sc) Set pserial=1,%objTX(1,intPred,1)=objValue Do")
			#; Visit the successors of this 'forced' ID assignment. If all predecessors are visited then add to the stack
		$$$GENERATE("	. . Set intSucc="""" For  Set intSucc=$order(%objTX(1,intPred,3,intSucc)) Quit:intSucc=""""  Kill %objTX(1,intPred,3,intSucc),%objTX(1,intSucc,2,intPred) If '$data(%objTX(1,intSucc,2)) Set %objTX(3,$i(%objTX(3)))=%objTX(1,intSucc) Kill:$d(%objTX(11,+%objTX(1,intSucc))) %objTX(2,%objTX(11,+%objTX(1,intSucc))),%objTX(11,+%objTX(1,intSucc))")
			#; Again, process the AOV. Calls to %SerializeObject here are complete serializations. If one fails, the TX needs to fail
		$$$GENERATE("	. . For ptr=1:1 Quit:ptr>%objTX(3)  Set objSerialize=%objTX(3,ptr),objValue=$get(%objTX(1,+$g(%objTX(0,+objSerialize)),1)),sc=objSerialize.%SerializeObject(.objValue) Do  Set %objTX(1,%objTX(0,+objSerialize),1)=objValue Kill %objTX(1,%objTX(0,+objSerialize),3) Do $system.CLS.SetModified(objSerialize,0)")
		$$$GENERATE("	. . . If $$$ISERR(sc) ZTrap ""SG""")
			#; Process the mod bits for potential tx rollback
		$$$GENERATE("	. . . $$$txSaveModState(objSerialize)")
			#; visit the successors
		$$$GENERATE("	. . . Set intSucc="""" For  Set intSucc=$order(%objTX(1,%objTX(0,+objSerialize),3,intSucc)) Quit:intSucc=""""  Kill %objTX(1,%objTX(0,+objSerialize),3,intSucc),%objTX(1,intSucc,2,%objTX(0,+objSerialize)) If '$data(%objTX(1,intSucc,2)) Set %objTX(3,$i(%objTX(3)))=%objTX(1,intSucc) Kill:$d(%objTX(11,+%objTX(1,intSucc))) %objTX(2,%objTX(11,+%objTX(1,intSucc))),%objTX(11,+%objTX(1,intSucc))")
		$$$GENERATE("	. . Kill %objTX(3) Set %objTX(3)=0")

		$$$GENERATE("	If $data(%objTX(2))>2 {")
		$$$GENERATE("		Set sc=$$$ERROR($$$SaveCyclicDependancy,$classname())")
		$$$GENERATE("		set i="""" for  set i=$order(%objTX(2,i)) quit:i=""""  if $$$ISERR($Get(%objTX(2,i,1),1)) set sc=$$$EMBEDSC(sc,%objTX(2,i,1))")
		$$$GENERATE("	 	ZTrap ""SG""")
		$$$GENERATE("	}")
	}
	$$$GENERATE("	Set cmd="""" For  Set cmd=$order(%objTX(9,cmd)) Quit:cmd=""""  Xecute cmd")
		#; Commit the transaction and cleanup
	set finally = $$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OnSaveFinally",$$$cMETHrunnable)
	$$$GENERATE("%SaveCOMMIT	If traninit { $$$txCommit"_$select(objectjournal:"Jrn",1:"")_" }")
	if 'finally {
		$$$GENERATE("	Do $system.CLS.SetModified(0) Quit sc")
	} else {
		$$$GENERATE("	Do $system.CLS.SetModified(0) try { do ..%OnSaveFinally($this, sc) } catch {} return sc")
	}
	$$$GENERATE("%SaveERR	Set $ZTrap="""" If $extract($zerror,1,5)'=""<ZSG>"" Set sc=$$$ERROR($$$ObjectScriptError,$ZE)")
	$$$GENERATE($Char(9)_"If $get(traninit) { $$$txRollback"_$select(objectjournal:"Jrn",1:"")_"(sc) }")
	if finally {
		$$$GENERATE($char(9) _ "try { do ..%OnSaveFinally($this, sc) } catch {}")
	}
	$$$GENERATE("	Quit sc")
	QUIT $$$OK
}

/// %OnDeleteFinally is an optional user implemented callback. There is no return value and
/// any exceptions are trapped and discarded.
ClassMethod %OnDeleteFinally(oid As %ObjectIdentity, status As %Status) [ Abstract ]
{
}

/// %OnOpenFinally is an optional user implemented callback. There is no return value and
/// any exceptions are trapped and discarded.
ClassMethod %OnOpenFinally(oid As %ObjectIdentity, status As %Status)
{
	#; %OnOpenFinally is not abstract the other %On*Finally callbacks because
	#;     1. %Open() is not a method generator
	#;     2. $system.CLS.IsMthd() checks are 6~7 times slower than just raw invocation
	#;     3. Methods that define only "RETURN N" where N is (+/-)(2**15-1) as the body
	#;        are optimized by the class compiler and specially encoded in the class
	#;        descriptor to behave like a static value.
	#;
	#; Despite the optimization in #3, for consistency with the method signature
	#; we do not put a "RETURN N" in the body.
}

/// %OnSaveFinally is an optional user implemented callback. There is no return value and
/// any exceptions are trapped and discarded.
ClassMethod %OnSaveFinally(oref As %ObjectHandle, status As %Status) [ Abstract ]
{
}

/// Elevates the concurrency level of an instance in memory to a higher level 
/// by changing the lock type specified in the <METHOD>%Open</METHOD> method for the object's 
/// instance. Fails if it cannot elevate the concurrency level.
/// 
/// Refer to <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_concurrency" target="_blank">Object Concurrency Options</a> for more details 
/// on the <var>concurrency</var> argument.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %UpgradeConcurrency(concurrency As %Integer(MINVAL=0,MAXVAL=4) = 0) As %Status [ CodeMode = generator, Final, Internal, ServerOnly = 0 ]
{
	$$$GENERATE($c(9)_"If (concurrency > 4) || (concurrency < 0) || (concurrency '= (concurrency\1)) { RETURN $$$ERROR($$$ConcurrencyValueInvalid) }")
		#; Locks are not retained for any setting
		#; less than 3 and if the old and new
		#; setting are the same, nothing is to done!
	$$$GENERATE($c(9)_"Set current=i%%Concurrency")
	$$$GENERATE($c(9)_"RETURN:concurrency'>current $$$OK")
	if $$$comSharded(%class)=1 {  // Don't let user upgrade concurrency > 0 for sharded class  JMM1160=
		$$$GENERATE($c(9)_"RETURN:concurrency>0 $$$ERROR($$$ShardClassUnsupportedFeature,$classname(),""Concurrency>0"","""")")
	}
	$$$GENERATE($c(9)_"If concurrency<3 { Set modstate=$system.CLS.GetModifiedBits(),i%%Concurrency=concurrency Do $system.CLS.SetModifiedBits(modstate) RETURN $$$OK }")
		#; Get the new lock
	$$$GENERATE($c(9)_"Set sc=..%AcquireLock($select(concurrency=3:""s"",1:""e"")) RETURN:$$$ISERR(sc) sc")
		#; the following line releases the old lock
		#; which must be a shared lock as that is the
		#; only possible condition.
	$$$GENERATE($c(9)_"Do:current=3 ..%ReleaseLock(""s"")")
		#; Update the concurrency setting:
	$$$GENERATE($c(9)_"Set modstate=$system.CLS.GetModifiedBits(),i%%Concurrency=concurrency Do $system.CLS.SetModifiedBits(modstate)")
	$$$GENERATE($c(9)_"RETURN $$$OK")
	RETURN $$$OK
}

/// Acquires a lock for the current instance.
/// 
/// <p>The <var>locktype</var> argument specifies the type of lock to acquire.
/// It can take the following values:
/// <table cols=2>
/// <tr>
/// <td width="33%" valign="top">"e": <i>Exclusive</i></td>
/// <td valign="top">
/// An exclusive lock will prevent any other process from acquiring any type of lock
/// on this object.
/// </td>
/// </tr>
/// 
/// <tr>
/// <td width="33%" valign="top">"s": <i>Shared</i></td>
/// <td valign="top">
/// A shared lock will allow other processes to acquire shared locks but will
/// prevent other processes from acquiring an exclusive lock.
/// </td>
/// </tr>
/// </table>
/// 
/// Fails if the locktype parameter is not one of the values described above.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %AcquireLock(locktype As %String = "") As %Status [ CodeMode = expression, Private, ServerOnly = 1 ]
{
..%LockId($$$idCurrent,$s($e(locktype)="s":1,1:0))
}

/// Releases a lock for the current instance.
/// 
/// <p>The <var>locktype</var> argument specifies the type of lock to release.
/// It can take the following values:
/// <table cols=2>
/// <tr>
/// <td width="33%" valign="top">"e": <i>Exclusive</i></td>
/// <td valign="top">
/// An exclusive lock will prevent any other process from acquiring any type of lock
/// on this object.
/// </td>
/// </tr>
/// 
/// <tr>
/// <td width="33%" valign="top">"s": <i>Shared</i></td>
/// <td valign="top">
/// A shared lock will allow other processes to acquire shared locks but will
/// prevent other processes from acquiring an exclusive lock.
/// </td>
/// </tr>
/// </table>
/// 
/// Fails if the locktype parameter is not one of the values described above.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %ReleaseLock(locktype As %String = "") As %Status [ CodeMode = expression, Private, ServerOnly = 1 ]
{
..%UnlockId($$$idCurrent,$s($e(locktype)="s":1,1:0),$s($e(locktype,2)="i":1,1:0))
}

/// %LockExtent acquires a lock on the entire extent of the class. If <var>shared</var> is true then a shared lock
/// is acquired, otherwise an exclusive lock is acquired. If the requested lock cannot be acquired then a failure
/// %Status value is returned. The default implementation returns an error indicating that the method is not implemented.
/// This method is automatically generated for persistent classes using <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.
ClassMethod %LockExtent(shared As %Boolean = 0) As %Status [ PlaceAfter = %LockId, ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%LockExtent")
}

/// %UnlockExtent releases a lock on the entire extent of the class. The type
/// of lock released is determined by <var>shared</var>. The default implementation returns an error indicating that the method is not implemented.
/// This method is automatically generated for persistent classes using <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.
ClassMethod %UnlockExtent(shared As %Boolean = 0, immediate As %Boolean = 0) As %Status [ PlaceAfter = %LockExtent, ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%UnlockExtent")
}

/// Obtain an exclusive or shared lock on the object identified by <var>id</var>. The type
/// of lock obtained is determined by <var>shared</var>. This method is normally generated by
/// the storage class for persistent classes using <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.
ClassMethod %LockId(id As %String, shared As %Boolean = 0, timeout As %Integer) As %Status [ ServerOnly = 0 ]
{
	Set sc=..%OnDetermineClass($$$oidForm(id),.class) If $$$ISERR(sc) Quit sc
	If class'="",class'=$classname() Quit $classmethod(class,"%LockId",id,shared,.timeout)
	QUIT $$$ERROR($$$MethodNotImplemented,$classname()_"::%LockId")
}

/// Release an exclusive or shared lock on the object identified by <var>id</var>. The type
/// of lock released is determined by <var>shared</var>. If this method is not overridden
/// then the default implementation returns an error. This method is normally generated by
/// the storage class for persistent classes using <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.
ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status [ ServerOnly = 0 ]
{
	Set sc=..%OnDetermineClass($$$oidForm(id),.class) If $$$ISERR(sc) Quit sc
	If class'="",class'=$classname() Quit $classmethod(class,"%UnlockId",id,shared,immediate)
	QUIT $$$ERROR($$$MethodNotImplemented,$classname()_"::%UnlockId")
}

/// This method acquires a lock on the object identified by 'id'. If the number of locks
/// already taken out for this extent is greater than the configured maximum then the lock
/// will be escalated to an extent-level lock. If the lock is successfully obtained a 1 will
/// be returned, 2 will be returned if the lock was escalated to an extent-level lock. A zero, '0',
/// is returned if the method failed to obtain a lock.
ClassMethod %GetLock(id As %String, shared As %Boolean = 0) As %Integer [ ServerOnly = 1 ]
{
	Set sc=..%OnDetermineClass($$$oidForm(id),.class) If $$$ISERR(sc) Quit 0
	If class'="",class'=$classname() Quit $classmethod(class,"%GetLock",id,shared)
	If $tlevel,$increment(%0CacheLock($classname()))>$zutil(115,6) { If $$$ISOK(..%LockExtent(shared)) { Quit 2 } Else { Quit 0 } } Quit:$$$ISOK(..%LockId(id,shared)) 1
	Quit 0
}

/// <p>Builds entries for each index specified in the <var>pIndexList</var> argument.
/// If <var>pIndexList</var> is empty then all indices that originate in the class are rebuilt.
/// If not empty you can specify a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of indexes to build, e.g. $lb("MyIndex1","MyIndex2").
/// If there are other bitmap indexes specified in <var>pIndexList</var> 
/// and there is a bitmap extent index defined for the class
/// then it will be implicitly included in <var>pIndexList</var>. If the bitmap 
/// extent index is included then the bitmap extent index for each subextent is also built. </p>
/// 
/// <p>If <var>pAutoPurge</var> is true then the indices contained in <var>pIndexList</var> will be
/// purged before they are built as long as no range is specified, if a range is specified we will
/// skip any purge. The default is TRUE (1).</p>
/// 
/// <p>If <var>pLockFlag</var> is one (1) then an extent lock will be acquired before the indices
/// are built. If the lock cannot be acquired then an error is returned. The lock is released
/// after the index build is completed. If <var>pLockFlag</var> is two (2) then a lock is acquired prior to filing 
/// indices for that instance and it is released as soon the indices for that instance are filed. 
/// If it is zero (0) then no locks are used while filing the indices. If it is three (3) then a 
/// shared extent lock will be acquired before the indices are built and released upon completion.</p>
/// 
/// <p>If <var>pJournalFlag</var> is 0 then journaling is disabled for the processes used to build the 
/// indices (except where the database is in a Mirror). If this flag is 1 then the journaling is enabled for the
/// process used to build the indicies. The default value of this argument is "" meaning use the current process setting. </p> 
/// 
/// <p><var>pStartID</var> and <var>pEndID</var> define a range of IDs for which indices will be built. 
/// The range is inclusive. If the starting ID is null then the range begins at the 
/// first ID defined in the extent. If the ending ID is null then the range ends at the 
/// last ID defined in the extent. </p>
/// 
/// <p>If <var>pIgnoreIndexList</var> is defined, it should be a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of index names that should not be built.
/// This argument allows you to build all indices except those defined in <var>pIgnoreIndexList</var>.
/// The default value of this argument is "", which means all indices, or all indices specified in <var>pIndexList</var>, will be built. </p> 
/// 
/// <p>If <var>pKeepSelectability</var> is 1, any index maps defined as Not Selectable prior to the <method>%BuildIndices</method> call will remain Not Selectable after the <method>%BuildIndices</method> call. 
/// If <var>pKeepSelectability</var> is 0 any index maps defined as Not Selectable prior to the <method>%BuildIndices</method> call will be set to Selectable after the successful <method>%BuildIndices</method> call.</p> 
/// 
/// <p>If <var>pNumberJobs</var> is defined, the system should use this explicitly specify the number of workers to run <method>%BuildIndices</method>.
/// The default value of this argument is "", which means the system should calculate how many jobs to run <method>%BuildIndices</method>
/// 
/// <p>If <var>pTableConversion</var> is defined, we are using %BuildIndices to convert a table's storage type. 
/// <var>pTableConversion</var> will be "row" if converting to row and "columnar" if converting to columnar</p> 
/// 
/// <p>If <method>%OnBeforeBuildIndices</method> is implemented and is runnable then it will be called
/// just prior to purging and building any index structures. Refer to <method>%OnBeforeBuildIndices</method>
/// for more information.</p>
/// 
/// <p>If <method>%OnAfterBuildIndices</method> is implemented and is runnable then it will be called
/// after all index structures have been built completely. Refer to <method>%OnAfterBuildIndices</method>
/// for more information.</p>
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// This method is normally generated by the storage class for persistent classes using
/// <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.</p>
/// 
/// <p>If your index is corrupt running this function will not fix the corruption unless you rebuild the entire index
/// and purge the existing indexes. If you have inserted some new items but have deferred building the index for these
/// new items then you can run %BuildIndices on this range of IDs to add the index entries for these new items.</p>
ClassMethod %BuildIndices(pIndexList As %RawString = "", pAutoPurge As %Integer = 1, pLockFlag As %Integer = 0, pJournalFlag As %Integer = "", pStartID As %RawString = "", pEndID As %RawString = "", pIgnoreIndexList As %RawString = "", pKeepSelectability As %Integer = 0, pNumberJobs As %Integer = "") As %Status [ ProcedureBlock = 1, ServerOnly = 0 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%BuildIndices")
}

/// <p>
/// 	%BuildIndicesAsync() instantiates a work queue and queues a %BuildIndices() call. The argument list after the output <var>queueToken</var> is the same as 
/// 	for <method>%BuildIndices</method>. 
/// </p>
/// <p>
/// 	This method returns a work queue token as the first argument (output) that can be used to retrieve the status of the %BuildIndices() worker using 
/// 	<method>%BuildIndicesAsyncResponse</method>. 
/// </p>
/// <p>
/// 	The return value is a %Status value indicating success or failure. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>queueToken</td>
/// 			<td>output</td>
/// 			<td>The token identifying the <method>%BuildIndices</method> task. This argument must be passed by reference as it is the identifier 
/// 				of the work queue and it is needed to retrieve the completion status using <method>%BuildIndicesAsyncResponse</method>. 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pIndexList</td>
/// 			<td>input</td>
/// 			<td>
/// 				The names of the indexes to be built. If empty then all indices that originate in the class are built. 
/// 				If not empty you can specify a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of index names to build, e.g. $lb("MyIndex1","MyIndex2").
/// 				If there are other bitmap indexes specified and there is a bitmap extent index defined for the class
/// 				then it will be implicitly included in the list of indexes to build. If the bitmap 
/// 				extent index is included then the bitmap extent index for each subextent is also built. 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pAutoPurge</td>
/// 			<td>input</td>
/// 			<td>
/// 				If true then the indices contained in <var>pIndexList</var> will be
/// 				purged before they are built as long as no range is specified, if a range is specified we will
/// 				skip any purge. The default is TRUE (1). 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pLockFlag</td>
/// 			<td>input</td>
/// 			<td>	
/// 				If one (1) then an extent lock will be acquired before the indexes are built. If the lock cannot be acquired then an error 
/// 				is returned. The lock is released after the index build is completed. If <var>pLockFlag</var> is two (2) then 
/// 					a lock is acquired prior to filing indices for that instance and it is released as soon the indices for that instance are filed. 
/// 				If it is zero (0) then no locks are used while filing the indices. If it is three (3) then a 
/// 				shared extent lock will be acquired before the indices are built and released upon completion. 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pJournalFlag</td>
/// 			<td>input</td>
/// 			<td>
/// 				If false then journaling is disabled for the processes used to build the 
/// 				indices (except where the database is in a Mirror).  If this flag is true then the journaling is enabled for the
///                 process used to build the indicies. The default value of this argument is "" meaning use the current process setting.
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pStartID</td>
/// 			<td>input</td>
/// 			<td>
/// 				The starting ID for the range of ID's for which indices will be built, inclusive. 
/// 				If the starting ID is null then the range begins at the first ID defined in the extent.
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pEndID</td>
/// 			<td>input</td>
/// 			<td>
/// 				Then ending ID for the range of ID's for which indexes will be built, inclusive. 
/// 				 If the ending ID is null then the range ends at the last ID defined in the extent. 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pIgnoreIndexList</td>
/// 			<td>input</td>
/// 			<td>
/// 				A list of index names that should not be built.
/// 				This argument allows you to build all indices except those defined in <var>pIgnoreIndexList</var>.
/// 				The default value of this argument is "", which means all indices, or all indices specified in <var>pIndexList</var>, will be built. </p> 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pTimeout</td>
/// 			<td>input</td>
/// 			<td>
/// 				pTimeout is the number of seconds to pass for the %SYSTEM.WorkMgr.Detach() method's timeout argument.
/// 				The default timeout is 86400s (24 hours).  If the %BuildIndices time is expected to be more than 24 hours and you don't want the build to timeout, increase this value to an appropriate number of seconds.</p> 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>pKeepSelectability</td>
/// 			<td>input</td>
/// 			<td>
/// 				If pKeepSelectability is 1, any index maps defined as Not Selectable prior to the %BuildIndices</method> call will remain Not Selectable after the <method>%BuildIndices</method> call. 
/// 					If pKeepSelectability is 0 any index maps defined as Not Selectable prior to the <method>%BuildIndices</method> call will be set to Selectable after the successful <method>%BuildIndices</method> call.</p> 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>
/// 				The <class>%Status</class> value indicates success or failure. If <var>queueToken</var> is null then the return status value can indicate an 
/// 				error involving the work queue or it can be the completion status from the <method>%BuildIndicesAsync</method> task. 
/// 			</td>
/// 		</tr>
/// 	</table>
/// </p>
ClassMethod %BuildIndicesAsync(Output queueToken As %String, pIndexList As %RawString = "", pAutoPurge As %Integer = 1, pLockFlag As %Integer = 0, pJournalFlag As %Integer = "", pStartID As %RawString = "", pEndID As %RawString = "", pIgnoreIndexList As %RawString = "", pTimeout As %Integer = 86400, pKeepSelectability As %Integer = 0) As %Status [ ProcedureBlock = 1, ServerOnly = 0 ]
{
	#dim queue As %SYSTEM.WorkMgr
	try {
		set statusCode = $$$OK
		set queueToken = ""
		new %objlasterror
		set queue = $SYSTEM.WorkMgr.%New("",1,"Utility")
		set:queue=$$$NULLOREF statusCode=$s($g(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$GeneralError,"Unknown error creating work queue group $zerror="_$ze))
		if $$$ISERR(statusCode) return statusCode
		set statusCode = queue.Queue("##class("_$classname()_").%BuildIndices",pIndexList,pAutoPurge,pLockFlag,pJournalFlag,pStartID,pEndID,pIgnoreIndexList,pKeepSelectability)
		if $$$ISOK(statusCode) set statusCode = queue.Detach(.queueToken,pTimeout)
		return statusCode
	} catch exception {
		set statusCode = exception.AsStatus()
	}
	return statusCode
}

/// <p>
/// Return the completion status of a %BuildIndicesAsync task, identified by <var>queueToken</var>. The global array node reference is defined by a <var>globalName</var> and a variable number of <var>subscripts</var>. 
/// </p>
/// <p>
/// This method returns a <class>%Status</class> value. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>queueToken</td>
/// 			<td>byref</td>
/// 			<td>The token identifying the <method>%BuildIndicesAsync</method> task. This argument must be passed by reference as it is the identifier 
/// 				of the work queue and it can be changed by this method. If the returned <var>queueToken</var> is not null (should only happen if <var>wait</var> 
/// 				is false) then the task is not yet complete and the new token value can be used to call this method again to check and possibly return the 
/// 				completion status. If this value is null on return then the task has completed or cannot be located and the return status value is the final 
/// 				status (completion status). 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>wait</td>
/// 			<td>input</td>
/// 			<td>
/// 				<p>A boolean value indicating whether or not %BuildIndicesAsyncResponse should wait for the <method>%BuildIndicesAsync</method> task to complete before 
/// 				returning. </p>
/// 				<p>If this value is <var>true</var> then this method will wait until the task identified by <var>queueToken</var> is complete before returning. </p>
/// 				<p>
/// 					If it is false, then this method will return as quickly as possible. In that case, if the task is not yet complete then <var>queueToken</var> 
/// 					will not be null on return and can be used to invoke this method again.
/// 				</p>
/// 				<p>
/// 					If this method detects an error reported by the task identified by the token then this method will wait for 
/// 					the final completion of the task before returning. 
/// 				</p>
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>The <class>%Status</class> value indicating success or failure. If <var>queueToken</var> is null then the return status value can indicate an 
/// 				error involving the work queue or it can be the completion status from the <method>%BuildIndicesAsync</method> task. 
/// 			</td>
/// 		</tr>
/// 	</table>
/// </p>
ClassMethod %BuildIndicesAsyncResponse(ByRef queueToken, wait As %Boolean = 1) As %Status
{
	set queue = $system.WorkMgr.Attach(queueToken, .indexStatus)
	set queueToken = ""
	if $$$ISOK(indexStatus) {
		if wait {
			set indexStatus = queue.Sync()
			set queueToken = ""
		} else {
			set indexStatus = queue.Wait(,.atEnd,0)
			if 'atEnd {
				if $$$ISERR(indexStatus) {
						// collector, revert to sync call
					set endStatus = queue.Sync()
					// set indexStatus = $$$ADDSC(indexStatus, endStatus)
					set queueToken = ""
				} else {
					set indexStatus = queue.Detach(.queueToken)
				}
			}
		}
	}
	return indexStatus
}

/// <p>Builds index entries for all defined indexes for each object contained in the Deferred Indexing Index. 
/// <p>If <var>pLockFlag</var> is one (1) then an extent lock will be acquired before the indices
/// are built. If the lock cannot be acquired then an error is returned. The lock is released
/// after the index build is completed. If <var>pLockFlag</var> is two (2) then a lock is acquired prior to filing 
/// indices for that instance and it is released as soon the indices for that instance are filed. 
/// If it is zero (0) then no locks are used while filing the indices. If it is three (3) then a 
/// shared extent lock will be acquired before the indices are built and released upon completion.</p>
/// 
/// <p>If <var>pJournalFlag</var> is 0 then journaling is disabled for the processes used to build the 
/// indices (except where the database is in a Mirror). If this flag is 1 then the journaling is enabled for the
/// process used to build the indices. The default value of this argument is "" meaning use the current process setting. </p> 
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// This method is normally generated by the storage class for persistent classes using
/// <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.</p>
/// 
/// <p>If your index is corrupt running this function will not fix the corruption unless you rebuild the entire index
/// and purge the existing indexes.</p>
ClassMethod %BuildDeferredIndices(pLockFlag As %Integer = 0, pJournalFlag As %Integer = "") As %Status [ ProcedureBlock = 1, ServerOnly = 0 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%BuildDeferredIndices")
}

/// On return, <var>bmeName</var> contains the name of the bitmap extent index for this class.
/// <p>Returns <CLASS>%Boolean</CLASS> TRUE is the bitmap extent has been built, FALSE if not.
ClassMethod %BMEBuilt(ByRef bmeName As %String) As %Boolean [ CodeMode = expression, Internal, ServerOnly = 1 ]
{
1
}

/// <p>
/// This method will loop over each object in the extent of the current class and invoke <method>%CheckConstraints</method>. 
/// If only selected constraints are to be checked then <var>pConstraintList</var> can be passed as a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of the 
/// names of the constraints to be checked. All constraint failures are included in the returned %Status value, subject 
/// to the maximum <class>%Status</class> size. In addition, the output parameter <var>pErrorLog</var> contains up to 1,000 entries 
/// containing the object ID and the values of all properties that are referenced by constraints defined for the current class. 
/// The error log also adds the %Status value returned by %CheckConstraints() as the last $list element.
/// </p>
/// <p>
/// <pre>
/// SAMPLES>set status = ##class(Sample.Person).%CheckConstraintsForExtent(,,.errorlog)
/// 
/// SAMPLES>do $system.OBJ.DisplayError(status)                                       
/// 
/// ERROR #5808: Key not unique: Sample.Person.SSNKey
/// ERROR #5808: Key not unique: Sample.Person.SSNKey
/// SAMPLES>zw errorlog
/// errorlog=2
/// errorlog(1)=$lb(1,"798-92-1974","0 "_$lb($lb(5808,"Sample.Person.SSNKey",,,,,,,,"%CheckConstraints+7^Sample.Person.1:SAMPLES"))/* ERROR #5808: Key not unique: Sample.Person.SSNKey [%CheckConstraints+7^Sample.Person.1:SAMPLES] */)
/// errorlog(2)=$lb(100,"798-92-1974","0 "_$lb($lb(5808,"Sample.Person.SSNKey",,,,,,,,"%CheckConstraints+7^Sample.Person.1:SAMPLES"))/* ERROR #5808: Key not unique: Sample.Person.SSNKey [%CheckConstraints+7^Sample.Person.1:SAMPLES] */)
/// </pre>
/// </p>
/// <p>
/// <table border=1>
/// 	<tr>
/// 		<th colspan=3>
/// 			Parameters
/// 		</th>
/// 	</tr>
/// 	<tr>
/// 		<th>Name</th>
/// 		<th>Direction</th>
/// 		<th>Description</th>
/// 	</tr>
/// 	<tr>
/// 		<td>pConstraintList</td>
/// 		<td>Input</td>
/// 		<td>A <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of constraints to be checked. If null then all constraints defined for the most specific type class 
/// 			of each object will be checked. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pCheckDisabled</td>
/// 		<td>Input</td>
/// 		<td>If this value is passed as a true value (1) then %CheckConstraints will also check any constraints that are 
/// 			defined as %NOCHECK. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pErrorLog</td>
/// 		<td>Output</td>
/// 		<td>
/// 			This is an array of up to 1,000 entries containing error information reported by <method>%CheckConstraints</method>.
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td></td>
/// 		<td>Return</td>
/// 		<td>
/// 			%Status return value. This value contains %Status values for each constraint that failed. If no errors are 
/// 			reported then %Status will be $$$OK. 
/// 		</td>
/// 	</tr>
/// </table>
/// </p>
ClassMethod %CheckConstraintsForExtent(pConstraintList As %String(MAXLEN="") = "", pCheckDisabled As %Integer = 0, Output pErrorLog As %String(MAXLEN="")) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	try {
		kill %code
		if ($$$getClassType(%class) = $$$cCLASSCLASSTYPEPERSISTENT) && ('$$$comClassKeyGet(%class,$$$cCLASSnoextent)) {
			do generateCheckExtent^%occConstraint(%class,.%code)
		}
		set tStatus = $$$OK
	}
	catch tException {
		set tStatus = tException.AsStatus()
	}
	QUIT tStatus
}

/// <p>
/// This method checks the constraints defined in the current class for one object, identified by <var>pID</var>. 
/// If only selected constraints are to be checked, then <var>pConstraintList</var> can be passed as a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of the 
/// names of the constraints to be checked. If any constraint fails then the failure status will be included in the 
/// returned %Status value. In addition, the output parameter <var>pErrorInfo</var> will contain the object ID and 
/// the values of all properties that are referenced by constraints defined for the current class. 
/// </p>
/// <p>
/// If the current class is not the most specific type class (MSTC) of the object identified by <var>pID</var>, then this method 
/// will dispatch to the object's most specific type class. Note that if you do not pass a constraint list then all 
/// constraints present for the MSTC are checked, which may include others in addition to those present for the current class. 
/// </p>
/// <p>
/// <pre>
/// SAMPLES>set status = ##class(Sample.Person).%CheckConstraints(1,,,.errorinfo)
/// 
/// SAMPLES>do $system.OBJ.DisplayError(status)                                 
/// 
/// ERROR #5808: Key not unique: Sample.Person.SSNKey
/// SAMPLES>zw errorinfo                                                        
/// errorinfo=$lb(1,"798-92-1974")
/// </pre>
/// </p>
/// <p>
/// <table border=1>
/// 	<tr>
/// 		<th colspan=3>
/// 			Parameters
/// 		</th>
/// 	</tr>
/// 	<tr>
/// 		<th>Name</th>
/// 		<th>Direction</th>
/// 		<th>Description</th>
/// 	</tr>
/// 	<tr>
/// 		<td>pID</td>
/// 		<td>Input</td>
/// 		<td>The ID of the object to be checked.</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pConstraintList</td>
/// 		<td>Input</td>
/// 		<td>A <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of constraints to be checked. If null then all constraints defined for this class will be checked. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pCheckDisabled</td>
/// 		<td>Input</td>
/// 		<td>If this value is passed as a true value (1) then %CheckConstraints will also check any constraints that are 
/// 			defined as %NOCHECK. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pErrorInfo</td>
/// 		<td>Output</td>
/// 		<td>
/// 			If an error is reported then <var>pErrorInfo</var> will contain the object's ID and all property values 
/// 			that are referenced by constraints defined for this class. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td></td>
/// 		<td>Return</td>
/// 		<td>
/// 			%Status return value. This value contains %Status values for each constraint that failed. If no errors are 
/// 			reported then %Status will be $$$OK. 
/// 		</td>
/// 	</tr>
/// </table>
/// </p>
ClassMethod %CheckConstraints(pID As %String(MAXLEN=""), pConstraintList As %List = "", pCheckDisabled As %Integer = 0, Output pErrorInfo As %List) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	try {
		kill %code
		if ($$$getClassType(%class) = $$$cCLASSCLASSTYPEPERSISTENT) && ('$$$comClassKeyGet(%class,$$$cCLASSnoextent)) {
			do generateCheckConstraints^%occConstraint(%class,.%code)
		}
		set tStatus = $$$OK
	}
	catch tException {
		set tStatus = tException.AsStatus()
	}
	QUIT tStatus
}

/// Checks to see if the object identified by the OID <var>oid</var> exists in the extent.
/// 
/// <p>Returns <CLASS>%Boolean</CLASS> TRUE if it exists, FALSE if it does not.
ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean [ CodeMode = generator, ServerOnly = 0 ]
{
	If $$$getClassType(%class) '= $$$cCLASSCLASSTYPEPERSISTENT {
		$$$GENERATE("	Set classname = $$$oidClassName(oid) If classname="""" Quit 0")
		$$$GENERATE("	Set $ZTrap = ""CatchExistsError""")
		$$$GENERATE("	If classname '= $classname() Quit $classmethod(classname,""%Exists"",oid)")
		$$$GENERATE("	Quit $isobject(..%Open(oid,0))=1")
		$$$GENERATE("CatchExistsError	Set $ZTrap = """"")
		$$$GENERATE("	Quit 0")
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$isobject(..%Open(oid,0))=1"
	}
	Quit $$$OK
}

/// Checks to see if the object identified by the ID <var>id</var> exists in the extent.
/// 
/// <p>Returns <CLASS>%Boolean</CLASS> TRUE is it exists, FALSE if it does not.
ClassMethod %ExistsId(id As %String) As %Boolean [ ServerOnly = 0 ]
{
	Quit ..%Exists($listbuild(id))
}

/// %1Check()
/// 	This is a method that corresponds the the '%1' key (a convention introduced in the SQL filer).
/// 	The '%1' key is a synonym for the %Id() value. The general description of &lt;candidatekey&gt;Check()
/// 
/// &lt;key&gt;Check()
/// 	This method checks for the existence of the key and locks the object associated with that key.
/// 		The lock is released but will be retained for the duration of the transaction.
/// 
/// 	The optional lockonly parameter is used by callers wishing only to validate the key. If lockonly is true
/// 		then success is returned if the key does not exists. If the key exists then an attempt is made to
/// 		lock the corresponding object. That status from the lock call is then returned.
/// 
/// 		If lockonly is false then an error is returned if the key does not exist. If the key does exist then
/// 		the corresponding object is locked and released. If the lock cannot be acquired then an error is returned.
/// 		Otherwise the key is checked for existence again and an error is returned if it doesn't exist.
ClassMethod %1Check(id As %String = "", lockonly As %Boolean = 0, concurrency As %Integer = -1) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	$$$GENERATE($c(9)_"Set exists=..%ExistsId(id)")
	$$$GENERATE($c(9)_"RETURN:'exists $select('lockonly:$$$ERROR($$$KeyNotFound,$classname(),id),1:$$$OK)")
	$$$GENERATE($c(9)_"Set:concurrency=-1 concurrency=$select(..#DEFAULTCONCURRENCY=""$zu(115,10)"":$zu(115,10),1:$xecute(""q ""_..#DEFAULTCONCURRENCY))")
	if $$$comSharded(%class)=1 {  // Don't let user use concurrency > 0 for sharded class  JMM1160=
		$$$GENERATE($c(9)_"RETURN:concurrency>0 $$$ERROR($$$ShardClassUnsupportedFeature,$classname(),""Concurrency>0"","""")")
	}
	$$$GENERATE($c(9)_"If concurrency { Set status=..%LockId(id,1) RETURN:$$$ISERR(status) status }")
	$$$GENERATE($c(9)_"If 'lockonly { Set exists=..%ExistsId(id) If concurrency { Do ..%UnlockId(id,1,0) } RETURN $select('exists:$$$ERROR($$$KeyNotFound,$classname(),id),1:$$$OK) }")
	$$$GENERATE($c(9)_"Do:concurrency ..%UnlockId(id,1,0)")
	$$$GENERATE($c(9)_"RETURN $$$OK")
	RETURN $$$OK
}

/// Files each index for the object identified by <var>id</var>. <var>pIndexHandle</var> is for internal use only.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// This method is normally generated by the storage class for persistent classes using
/// <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.
ClassMethod %FileIndices(id As %String(MAXLEN=""), ByRef pIndexHandle As %Binary) As %Status [ Internal, ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%FileIndices")
}

/// This method returns the GUID assigned to &lt;oid&gt;. This method is only runnable if the GUIDENABLED parameter is TRUE.
/// This method will dispatch polymorphically and will determine the most-specific-type class if the oid does not contain that information.
/// If pDeepSearch is true and no GUID is found for the object then a deep search of the GUID registry will be performed, starting with the
/// current class. This is useful if the most specific type class cannot be determined, such as in the case of an object that has been deleted.
ClassMethod %GUID(oid As %ObjectIdentity, pDeepSearch As %Integer = 0) As %String [ ServerOnly = 1 ]
{
	If $$$oidPrimary($Get(oid)) = "" Quit ""
	#; Optimize for the full-oid,no polymorphic case:
	If $classname()=$$$oidClassName(oid) Quit $Get(^OBJ.GUID(1,oid))
	Set class=$$$oidClassName(oid)
	#; if class name is not present in oid, we must call the class method %OnDetermineClass
	If class="" { Set sc=..%OnDetermineClass(oid,.class) if $$$ISOK(sc) { set oid=$$$oidInsertClassName(oid,class) } elseif pDeepSearch { quit ##class(%Library.GUID).%FindGUID($classname(),$$$oidPrimary(oid)) } else { quit "" } } Else { set class=$$$NormalizeClassname(class) }
	#; See if we are the correct class. If not, dispatch polymorphically to correct %GUID()
	If $classname()'=class Quit $classmethod(class,"%GUID",oid,pDeepSearch)
	If 'pDeepSearch { Quit $Get(^OBJ.GUID(1,oid)) } else { set tGUID = $Get(^OBJ.GUID(1,oid)) if tGUID'="" { quit tGUID } else { quit ##class(%Library.GUID).%FindGUID($classname(),$$$oidPrimary(oid)) } }
}

ClassMethod %GUIDSet(oid As %ObjectIdentity, guid As %String = "") As %String [ ServerOnly = 1 ]
{
	If '..#GUIDENABLED Quit ""
	If $$$oidPrimary($Get(oid)) = "" Quit ""
	#; Optimize for the full-oid,no polymorphic case:
	If ($classname()=$$$oidClassName(oid)) && ($Data(^OBJ.GUID(1,oid),guid)) Quit guid
	Set class=$$$oidClassName(oid)
	#; if class name is not present in oid, we must call the class method %OnDetermineClass
	If class="" { Set sc=..%OnDetermineClass(oid,.class) Quit:$$$ISERR(sc) "" Set oid=$$$oidInsertClassName(oid,class) } Else { Set class=$$$NormalizeClassname(class) }
	#; See if we are the correct class. If not, dispatch polymorphically to correct %GUID()
	If $classname()'=class Quit $classmethod(class,"%GUIDSet",oid,guid)
	#; If guid already assigned to this oid just return it
	If $Data(^OBJ.GUID(1,oid),guid) Quit guid
	If ($Get(guid) = "") { Set guid = $System.Util.CreateGUID()}
	If '$Data(^OBJ.GUID(0,guid)) { Set ^OBJ.GUID(0,guid)=oid,^OBJ.GUID(1,oid)=guid } Else { Set guid = "" }
	Quit guid
}

/// %KillExtent performs a physical kill of the extent. No constraints are enforced. This method should not be
/// used in place of %DeleteExtent. Only physical storage occupied by this extent will be killed. If this extent
/// is a subextent of another class then no data is killed. Indexes that originate with this extent will be killed.
/// %KillExtent will be called on any subextents and on any child extents (the extent of the type class of a
/// relationship whose cardinality = children is a 'child' extent) of this extent.<br>
/// 
/// This method is not meant for production applications. It is meant to be a development utility to quickly clear
/// extent physical data. Also this will not remove stream data associated with these instances.<br>
/// If <var>killstreams</var> is true (default is false) it will also kill the default stream storage global.
ClassMethod %KillExtent(pDirect As %Integer = 1, killstreams As %Boolean = 0) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"READONLY",$$$cPARAMdefault) {
		$$$GENERATE($c(9)_"RETURN $$$ERROR($$$ClassIsReadOnly,$classname())")
		RETURN $$$OK
	}
	if $$$comSharded(%class)=1 {  // override %KillExtent to call %KillExtent for the shardLocal class on each shard  JMM1160=
		$$$GENERATE($c(9)_"RETURN ##class(%BigData.ShardedSQL).%CallClassMethod($classname(),""%KillExtent"",$lb(pDirect,killStreams))")
		RETURN $$$OK
	}
		#; 1. Invoke %KillExtent in all child extents.
	set tProperty = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	while tProperty '= "" {
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,tProperty,$$$cXXXXorigin)
		if ($$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,tProperty,$$$cPROPrelationship)) && ($$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,tProperty,$$$cPROPcardinality) = $$$cPROPCARDINALITYCHILDREN) {
			$$$comMemberKeyGetLO(tChildType,origin,%class,$$$cCLASSproperty,tProperty,$$$cPROPtype)
				// Only invoke %KillExtent on the child if the CHILDREN relationship originates in this class
				// or this class is the root class of the concrete extent.
			if ($$$getClassType(tChildType) = $$$cCLASSCLASSTYPEPERSISTENT) && (($Get($$$EXTrootclass($$$pEXT,%class))) || (origin = %class)) {
				$$$GENERATE($Char(9)_"if $system.CLS.IsMthd("""_tChildType_""",""%KillExtent"") { set sc=$select(killstreams:##class("_tChildType_").%KillExtent(.pDirect,1),1:##class("_tChildType_").%KillExtent(.pDirect)) }")
			}
		}
		set tProperty = $$$comMemberNext(%class,$$$cCLASSproperty,tProperty)
	}
		#; 2. Invoke %KillExtent in all subextents. While this doesn't delete any data it does delete the indices
	$$$GENERATE($c(9)_"set CLASS=$$$ucase($classname()),SUBEXTENT=$order(^rINDEXEXT(""S"",CLASS,""""),1,extentMD) While SUBEXTENT'="""" { set subextent = $lg(extentMD,2) if $system.CLS.IsMthd(subextent,""%KillExtent"") { Set sc=$select(killstreams:$classmethod(subextent,""%KillExtent"",.pDirect,1),1:$classmethod(subextent,""%KillExtent"",.pDirect)) If $$$ISERR(sc) { Goto Exit } } Set SUBEXTENT=$order(^rINDEXEXT(""S"",CLASS,SUBEXTENT),1,extentMD) }")
		#; 3. Delete all indices originating in this class
	$$$GENERATE($c(9)_"set sc=..%PurgeIndices()")
		#; 4. Invoke the storage method, %KillExtentData
	$$$GENERATE($c(9)_"If $$$ISOK(sc) { Set sc=$select(killstreams:..%KillExtentData(1),1:..%KillExtentData()) }")
		// 5. if DSTIME is auto then kill the DSTIME index for this class
	$$$comMemberKeyGetLvar(tDSTIME,%class,$$$cCLASSparameter,"DSTIME",$$$cPARAMdefault)
	if ($$$ucase(tDSTIME) = "AUTO") || ($$$ucase(tDSTIME) = "TIME") {
		$$$GENERATE($Char(9)_"if pDirect { kill ^OBJ.DSTIME($classname()) }")
	}
	elseif ($$$ucase(tDSTIME) = "CONDITIONAL"){ //DP-404466
		$$$comMemberKeyGetLvar(tDSCONDITION,%class,$$$cCLASSparameter,"DSCONDITION",$$$cPARAMdefault)
		$$$GENERATE($Char(9)_"if ( ("_tDSCONDITION_") && (pDirect) ) { kill ^OBJ.DSTIME($classname()) }")
	}
	$$$GENERATE("Exit"_$c(9)_"RETURN sc")
	RETURN $$$OK
}

/// Files the indices for all objects whose ID is in the range defined by <var>pStartId</var> and <var>pEndId</var>.
/// If <var>pEndId</var> is null then it defaults to <var>pStartId</var>. If <var>pStartId</var> is null then the
/// range is empty and no filing will occur.
/// 
/// If <var>lockExtent</var> is true then an extent lock will be acquired before the indices
/// are built. If the lock cannot be acquired then an error is returned. The lock is released
/// after the index filing is completed.
/// 
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod %SaveIndices(pStartId As %String(MAXLEN="") = "", pEndId As %String(MAXLEN="") = "", lockExtent As %Boolean = 0) As %Status [ Internal, ServerOnly = 0 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%SaveIndices")
}

ClassMethod %AddJrnObjToSyncSet(objSS As %SYNC.SyncSet, fileop As %Integer = 0, oid As %ObjectIdentity, ByRef object As %String, changed As %List = "", guid As %String = "", originSystem As %String = "", originNS As %String = "") As %Integer [ Internal, ServerOnly = 1 ]
{
	If '..#OBJJOURNAL Quit ""
	Set objRef = ..%LoadFromMemory($$$oidPrimary(oid),.object)
	If $isobject(objRef)=0 { set objRef = ..%Open(oid) }
	Quit $Select($isobject(objRef)=1:..%AddToSyncSet(objSS, objRef, fileop, oid, changed, guid, originSystem, originNS),1:"")
}

/// Internal helper method for <method>%BuildIndicies</method>
ClassMethod %BuildIndexInternal(pLockFlag, pAutoPurge, pStartID, pEndID, pIndexList, pBuildFlags, pGLVN, pBMEIndexPtr, pJournalFlag, pCompositeKey, pUseBME = 0, pKeepSelectability = 0, pNumberJobs = "", pTableConversion = "") As %Status [ Internal, Private ]
{
	Set sc=$$$OK,class=$classname()
	Set journal=$$$JournalState
	Try {
		If pLockFlag=1||(pLockFlag=3) {
			$$$THROWONERROR(sc,..%LockExtent($s(pLockFlag=1:0,1:1)))
			Set tLocked=1
		}
		If pJournalFlag'="" {
			Try {
				If pJournalFlag=0,journal Do DISABLE^%SYS.NOJRN()
				If pJournalFlag=1,'journal Do ENABLE^%SYS.NOJRN()
			} Catch {
				Set sc=$$$ERROR($$$UserInsufficientPrivsDisableJournal) Goto exit
			}
		}
		If $system.CLS.IsMthd("%OnBeforeBuildIndices"), ($g(pTableConversion)="") {
			$$$THROWONERROR(sc,..%OnBeforeBuildIndices(.pIndexList))
			if ($listlength(pIndexList)=1)&&($listget(pIndexList,1)="") {
				If $Get(tLocked) {
					Do ..%UnlockExtent($s(pLockFlag=1:0,1:1))
				}
				RETURN $$$OK
			}
		}

		// get all indices for the class, if specific indices weren't listed in pIndexList
		$$$comClassKeyGetLvar(table,class,$$$cCLASSsqlqualifiednameQ)
		set indices=pIndexList
		if indices="" {
			if $g(pTableConversion)'="" {
				RETURN $$$ERROR($$$SQLError, -400, "Could not transfer data for table conversion; no  map specified")
			}
			set isRoot=$get($$$EXTrootclass($$$pEXT,class))
			set index=""
			set index=$$$comMemberNext(class,$$$cCLASSindex,index)
			while index'="" {
				//index must originate in this class, if the class is not the root extent
				if isRoot||('isRoot&&($$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXorigin)=class)) {
					//*** skip BME indexes for selectability $$$EXTADDRtype($$$pEXT,pClassName,tAddress)
					if $$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXextent)=1,$$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXtype)=$$$cINDEXTYPEBITMAP { }	// Don't build BME for columnar storage classes set indices=indices_$lb(index)
					else { set indices=indices_$lb(index) }
				}
				set index=$$$comMemberNext(class,$$$cCLASSindex,index)
			}
		} 

		// disable selectability for each (currently selectable) index's map
		TSTART
		set selectableMaps="",notselectableMaps=""
		try {
			set ptr=0
			while $listnext(indices,ptr,index) {
				continue:((index="")||($g(pTableConversion)'=""))
				set map=$$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXsqlname)
				set:map="" map=index
				set selectable=$SYSTEM.SQL.Util.GetMapSelectability(table,map) 
				if selectable { set selectableMaps=selectableMaps_$lb(map) } else { set notselectableMaps=notselectableMaps_$lb(map) }
			}
			if selectableMaps '="" {
				set sc=$SYSTEM.SQL.Util.SetMapSelectability(table,selectableMaps,0)	// Maps defined as Selectible are not Not Selectable
				if $$$ISERR(sc) { TROLLBACK 1 goto exit }
			}
		} catch ex { 
			set sc=ex.AsStatus()
			TROLLBACK 1 
			goto exit 
		}
		TCOMMIT

		If pAutoPurge,pStartID="",pEndID="" {
			Set sc=..%PurgeIndices(.pIndexList)
			If $$$ISERR(sc) Goto exit
		}
		
		Set splits = $$calcJobs^%SYS.WorkQueueMgr(pNumberJobs,,"Utility")
		Set oldsubnode=pStartID,split=""
		If splits>1 {
			if pUseBME {	// We are using the BME for the ID traversal, so we need to split on chunks if pStartID/pEndID were given
				if pStartID,pEndID,pEndID'>pStartID { goto exit }
				if pStartID'="",pStartID<1 { set pStartID=1 }
				if pEndID'="",pEndID<1 { set pEndID=1 }
				if pStartID { set startchunk=pStartID\64000+1,oldsubnode=startchunk } else { set startchunk="" }
				if pEndID { set endchunk=pEndID\64000+1 } else { set endchunk="" }
				set splitlist=$$SplitSize^%GSIZE(pGLVN,"N",splits,startchunk,endchunk)
			} else {
				set splitlist=$$SplitSize^%GSIZE(pGLVN,"N",splits,$select(pCompositeKey:$piece(pStartID,"||"),1:pStartID),$select(pCompositeKey:$piece(pEndID,"||"),1:pEndID))
			}
			Set status=$listget(splitlist,1)
			if status=1 {
				set split=$listget(splitlist,2)
					#; If the split point is also the start point remove it to avoid potential issue where same node is processed twice
				if pStartID'="" {
					if pUseBME { } //if $listget(split)=startchunk { set split=$list(split,2,*) }}
					else { if $listget(split)=pStartID { set split=$list(split,2,*) }}
				}
			}
		} elseif pUseBME {
			if pStartID,pEndID,pEndID'>pStartID { goto exit }
			if pStartID'="",pStartID<1 { set pStartID=1 }
			if pEndID'="",pEndID<1 { set pEndID=1 }
		}
		Set numbersplits=$s($ll(split)>1: $ll(split)+1, 1:1)
		new %objlasterror
		Set queue = $SYSTEM.WorkMgr.%New("",numbersplits,"Utility")
		Set:queue=$$$NULLOREF sc=$s($g(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$GeneralError,"Unknown error creating work queue group $zerror="_$ze))
		If $$$ISERR(sc) { Goto exit }
		Kill ^IRIS.TempIndexBuild($job)
		if numbersplits=1 {	// only one entry in the SubscriptList, just use a single process...
				#; one process will build entire index
				#; We saw this case with Jira DP-425181 on a system with 2 CPUs and 2 nodes defined in the EMB global
			if pUseBME,splits>1 {	// Only use this block if SplitSize was called
				if oldsubnode'="" {
					if oldsubnode=1 { set startid=pStartID }	// First chunk of BME, begin at id=pStartID
					else { set startid=oldsubnode-1*64000 }		// First position of first chunk will be startid
				} else {	// starting at the beginning
					set startid=""
				}
				if $g(endchunk) {
					set endid=endchunk-1*64000+64000-1 if pEndID'="",endid>pEndID { set endid=pEndID }
				} else {	// ending at the end
					set endid=""
				}
			} else {
				set startid=pStartID,endid=pEndID
			}
			set sc=queue.Queue("##class("_class_").%BuildIndicesSegment",startid,endid,.pBuildFlags,pLockFlag,$select(pStartID'=""&&(oldsubnode=pStartID):1,1:0),$job)
			if $$$ISERR(sc) { goto exit }
		} else {
			Set ptr=0,cnt=0
			While $listnext(split,ptr,subnode) {
				if pUseBME {
					set cnt=cnt+1
					if cnt=1,oldsubnode=1 { set startid=pStartID }	// First chunk of BME, begin at id=pStartID
					else { set startid=oldsubnode-1*64000 }			// First position of first chunk will be startid
					set endid=subnode-1*64000+64000-1 if pEndID'="",endid>pEndID { set endid=pEndID }
					Set sc=queue.Queue("##class("_class_").%BuildIndicesSegment",startid,endid,.pBuildFlags,pLockFlag,$select(pStartID'=""&&(oldsubnode=pStartID):1,1:0),$job)
				} else {
					Set sc=queue.Queue("##class("_class_").%BuildIndicesSegment",oldsubnode,subnode,.pBuildFlags,pLockFlag,$select(pStartID'=""&&(oldsubnode=pStartID):1,1:0),$job)
				}
				if $$$ISERR(sc) { goto exit }
				Set oldsubnode=subnode
			}
		}
		#; Queue the last range
		if numbersplits > 1 { // Nothing to do if only one split
			if pUseBME {
				set startid=oldsubnode-1*64000			// First position of first chunk will be startid
				set sc=queue.Queue("##class("_class_").%BuildIndicesSegment",startid,pEndID,.pBuildFlags,pLockFlag,$select(pStartID'=""&&(oldsubnode=pStartID):1,1:0),$job)		
			} else {
				set sc=queue.Queue("##class("_class_").%BuildIndicesSegment",oldsubnode,pEndID,.pBuildFlags,pLockFlag,$select(pStartID'=""&&(oldsubnode=pStartID):1,1:0),$job)		
			}
		}
		If $$$ISOK(sc) { Set sc=queue.Sync() }
		If $$$ISERR(sc) { Goto exit }
		
			// Cascade the BME build to subextents
		If pBMEIndexPtr,$Ascii(pBuildFlags(class),pBMEIndexPtr) {
			Set SUBEXTENT="", CLASS = $$$ucase(class)
			For {
				Set SUBEXTENT=$o(^rINDEXEXT("S",CLASS,SUBEXTENT),1,extentMD)
				Quit:SUBEXTENT=""
				set subextent = $listGet(extentMD,2)
				Set tSubBuilt=$classmethod(subextent,"%BMEBuilt",.subbme)
				Set sc=$classmethod(subextent,"%BuildIndices",$listbuild(subbme),pAutoPurge,pLockFlag,pJournalFlag,.pStartID,.pEndID)
				If $$$ISERR(sc) { Goto exit }
			}
		}

			#; Define maps that were previously Selectable as Selectable again
		if selectableMaps '="" {
			set sc=$$$ADDSC(sc,$SYSTEM.SQL.Util.SetMapSelectability(table,selectableMaps,1))
			// If %OnAfterBuildIndices fails after this, we don't want to do reenable selectability again in exit 
			// if we did it (or tried it) here, so reset selectableMaps to ""
			set selectableMaps = ""
			if $$$ISERR(sc) { goto exit }
		}
			#; Define maps that were previously NOT Selectable as Selectable again as long as we are not retaining the previous Selectability setting
		if 'pKeepSelectability,notselectableMaps'="" {
			set sc=$$$ADDSC(sc,$SYSTEM.SQL.Util.SetMapSelectability(table,notselectableMaps,1))
			if $$$ISERR(sc) { goto exit }
		}

		If $system.CLS.IsMthd("%OnAfterBuildIndices"), ($g(pTableConversion)="") {
			Set sc=..%OnAfterBuildIndices(.pIndexList)
			If $$$ISERR(sc) Goto exit
		}
	} Catch tException {
		Set sc=tException.AsStatus()
	}
exit
	// Re-enable selectability for each (previously selectable) index's map if an error was thrown/bad status brought us to exit
	// If status is ok this was already done, likewise if error comes from %OnAfterBuildIndices then selectableMaps should be "" again
	if $$$ISERR(sc), $g(selectableMaps) '="" {
		set sc=$$$ADDSC(sc,$SYSTEM.SQL.Util.SetMapSelectability(table,selectableMaps,1))
	}
	If $Get(tLocked) {
		Do ..%UnlockExtent($s(pLockFlag=1:0,1:1))
	}
	Set i=""
	For {
		Set i=$order(^IRIS.TempIndexBuild($job,i),1,val) Quit:i=""
		If val'=0 Do $system.Event.Delete($name(^IRIS.TempIndexBuild($job,i)))
	}
	Kill ^IRIS.TempIndexBuild($job)
	If $$$JournalState'=journal {
		If journal { Do ENABLE^%SYS.NOJRN() } Else { Do DISABLE^%SYS.NOJRN() }
	}
	Quit sc
}

ClassMethod %BuildCDMConversion(pLockFlag, pAutoPurge, pStartID, pEndID, pIndexList, pBuildFlags, pGLVN, pBMEIndexPtr, pJournalFlag, pCompositeKey, pUseBME = 0, pKeepSelectability = 0, pNumberJobs = "", pTableConversion = "") As %Status [ Internal ]
{
	RETURN ..%BuildIndexInternal(pLockFlag, pAutoPurge, pStartID, pEndID, .pIndexList, .pBuildFlags, pGLVN, pBMEIndexPtr, pJournalFlag, pCompositeKey, pUseBME, pKeepSelectability, pNumberJobs, pTableConversion)
}

/// This method is normally generated by the storage class for persistent classes using
/// <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>. Persistent
/// classes using some other storage class, such as <class>%Library.CustomStorage</class> must override this
/// method.
ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%DeleteData")
}

/// %InitExtentData() - Initializes extent data in storage. 
/// This method is implemented by the storage class.  It simply sets the root node of the data global to ""
ClassMethod %InitExtentData() As %Status [ Private, ServerOnly = 1 ]
{
	RETURN $$$ERROR($$$MethodNotImplemented,"%Persistent::%InitExtentData")
}

/// %KillExtentData() - kills extent data in storage. This method is
/// implemented by the storage class. 
/// If <var>killstreams</var> is true (default is false) it will also kill the default stream storage global.
/// If <var>reinitialize</var> is true (default is false) it will also call %InitExtent to re-define the globals.
ClassMethod %KillExtentData(killstreams As %Boolean = 0, reinitialize As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
	RETURN $$$ERROR($$$MethodNotImplemented,"%Persistent::%KillExtentData")
}

/// %LoadData() - loads an object from storage. This method is
/// implemented by the storage class.
Method %LoadData(id As %String) As %Status [ Private, ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%LoadData")
}

/// <p>Deletes all entries from each index specified in the <var>idxlist</var> argument.
/// If <var>idxlist</var> is empty then all indices that originate
/// in the class are purged. The index definition remains intact.</p>
/// 
/// <p>If <var>pIgnoreIndexList</var> is defined, it should be a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> of index names that should not be purged.
/// This argument allows you to purge all indices except those defined in <var>pIgnoreIndexList</var>.
/// The default value of this argument is "", which means all indices, or all indices specified in <var>pIndexList</var>, will be purged. </p> 
/// 
/// <p>If <var>pJournalFlag</var> is set to 1, journaling will be enabled (if not already) for the duration of the purge. If it is set to 0, journaling
/// will be disabled (if not already) for the duration of the purge.
/// The default value of this argument is "", which means journaling behavior will not be altered.</p>
/// 
/// <p>If <method>%OnBeforePurgeIndices</method> is implemented and is runnable, then it will be called
/// just after acquiring the extent lock, if one is requested, and just prior to performing the
/// purge. If <method>%OnBeforePurgeIndices</method> returns an error status
/// then %PurgeIndices will exit immediately, no indices will be purged and that error status
/// will be returned to the caller of %PurgeIndices.</p>
/// 
/// <p>If <method>%OnAfterPurgeIndices</method> is implemented and is runnable, then it will be called
/// just prior to releasing the extent lock, if one is requested. cAll index structures have been purged
/// prior to calling <method>%OnAfterPurgeIndices</method>. If <method>%OnAfterPurgeIndices</method> returns
/// and error status then that status will be returned to the caller of %PurgeIndices but all structures will
/// still have been purged.
/// </p>
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// This method is normally generated by the storage class for persistent classes using
/// <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>. Persistent
/// classes using some other storage class, such as <class>%Library.CustomStorage</class> must override this
/// method.</p>
ClassMethod %PurgeIndices(idxlist As %List = "", lockExtent As %Boolean = 0, pIgnoreIndexList As %RawString = "", pJournalFlag As %Library.Integer = "") As %Status [ ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%PurgeIndices")
}

/// %SaveData() - saves an object to disk, checks uniqueness and referential
/// integrity constraints, and maintains index structures. This method is
/// implemented by the storage class.
Method %SaveData(id As %String) As %Status [ Private, ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%SaveData")
}

/// %SaveDirect() - saves an object to disk, checks uniqueness and referential
/// integrity constraints, and maintains index structures. The state of the object
/// is passed to this method in three arguments.
/// <var>id</var> contains the ID value if the object has been previously saved.
/// <var>idList</var> is a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> value containing the IDKEY components. If the class is a child
/// class (contains a relationship with CARDINALITY = PARENT) then the first value in the list is the parent reference.
/// If the ID is system assigned the next value (or only value if the class is not a child class) is the system assigned ID value.
/// If the ID is based on a user-defined IDKEY, then there is a $list element corresponding to each property in the same order as
/// defined in the IDKEY index.
/// <br>
/// <var>data</var> is a structure that mirrors the disk structure of the object. The root value (unsubscripted) contains the properties stored in the
/// data node from the storage definition with a null subscript. Additional entries in the <var>data</var> structure correspond to any additional data nodes
/// defined in the storage definition.
/// <br>
/// This method is not commonly called directly.
/// <br>
/// This method is implemented by the storage class.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod %SaveDirect(ByRef id As %String = "", idList As %List = "", ByRef data As %Binary, concurrency As %Integer = -1) As %Status [ ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%Persistent::%SaveDirect")
}

/// Executes a $SortBegin for the base global reference of each index specified in the <var>idxlist</var> argument.
/// If <var>idxlist</var> is empty then a $SortBegin is executed for all indices that originate
/// in the class.
/// 
/// <p>The <var>excludeunique</var> argument, if TRUE, causes any index defined as UNIQUE or PRIMARY KEY to be ignored.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod %SortBegin(idxlist As %List = "", excludeunique As %Integer = 0) As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
$$$OK
}

/// Executes a $SortEnd for the base global reference of each index specified in the <var>idxlist</var> argument.
/// If <var>idxlist</var> is empty then a $SortEnd is executed for all indices that originate
/// in the class.
/// 
/// <p>The <var>commit</var> argument, if FALSE, causes the data to be discarded. Otherwise, all data placed in
/// the global since the $SortBegin is committed.
/// <p>The <var>excludeunique</var> argument, if TRUE, causes any index defined as UNIQUE or PRIMARY KEY to be ignored.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod %SortEnd(idxlist As %List = "", commit As %Integer = 1, excludeunique As %Integer = 0) As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
$$$OK
}

/// <p>This is a system provided query that returns a row for each instance within this extent. The first column of the row is the
/// object ID. Additional columns can be included in the select list by adding the desired columns to the <parameter>EXTENTQUERYSPEC</parameter> parameter.</p>
/// <p>
/// The Extent query default implementation is generated by <class>%Library.ExtentSQLQuery</class>. That class
/// supports the <var>COMPILEMODE</var> parameter with possible values of IMMEDIATE and DYNAMIC. If DYNAMIC is specified
/// then the SQL statement used to implement the query will be generated as a dynamic SQL statement. If IMMEDIATE is specified
/// then the statement is generated as an embedded SQL statement.</p>
/// <br><p>This query can be overridden by a subclass so long as two requirements are met. The list of columns must include %ID as the first column and
/// it must return a row corresponding to each instance/row in the extent.</p>
Query Extent() As %ExtentSQLQuery(CONTAINID = 1) [ SqlProc ]
{
}

/// <p>
/// This callback method is invoked by the <METHOD>%BuildIndices</METHOD> method. 
/// </p>
/// <p>
/// It is called prior to modifying any index structures. If an extent lock is requested by the 
/// %BuildIndices caller then %OnBeforeBuildIndices is called after the extent lock is acquired. 
/// <P>If this method returns an error then %BuildIndices will exit immediately without 
/// purging and building any index structures, returning the error to the caller of %BuildIndices. 
/// </p>
/// <p>
/// <table border=1>
/// <tr>
/// 	<th colspan=3>Parameters</th>
/// </tr>
/// <tr>
/// <th>
/// Name
/// </th>
/// <th>
/// Type
/// </th>
/// <th>
/// Description
/// </th>
/// </tr>
/// <tr>
/// 		<td>indexlist</td>
/// 		<td>Input/output</td>
/// 		<td>
/// 			A <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> value containing the names of the indexes to be built. This parameter is 
/// 			passed by reference. If the implementation of %OnBeforeBuildIndices alters this value, 
/// 			then %BuildIndices will honor those changes.
/// 		</td>
/// </tr>
/// </table>
/// </p>
ClassMethod %OnBeforeBuildIndices(ByRef indexlist As %String(MAXLEN="") = "") As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%BuildIndices</METHOD> method after all work is completed.
/// <P>If this method returns an error then %BuildIndices will return that error but all normal processing is
/// completed. This call occurs just prior to releasing the extent lock if one was requested by the %BuildIndices caller.
/// All index structures have been built and SortEnd executed.</p>
ClassMethod %OnAfterBuildIndices(indexlist As %String(MAXLEN="") = "") As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Delete</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being deleted.
/// 
/// <P>If this method returns an error then the object will not be deleted.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Delete</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> has been deleted.
/// The callback occurs immediately after %DeleteData has been called. If %DeleteData returns
/// an error then %OnAfterDelete is not called.
/// 
/// <P>If %OnAfterDelete returns an error (%Status) then the transaction is rolled back.
ClassMethod %OnAfterDelete(oid As %ObjectIdentity) As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called before 
/// any data is written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnBeforeSave(insert As %Boolean) As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called after 
/// the object's data has been successfully written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnAfterSave(insert As %Boolean) As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Open</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being opened.
/// 
/// <P>If this method returns an error then the object will not be opened.
Method %OnOpen() As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// <p>
/// This callback method is invoked by the <METHOD>%PurgeIndices</METHOD> method. 
/// </p>
/// <p>
/// If this method returns an error then %PurgeIndices will exit immediately without
/// purging any index structures, returning the error to the caller of %PurgeIndices.
/// </p>
/// <p>
/// <table border=1>
/// <tr>
/// <th colspan=3>Parameters</th>
/// </tr>
/// <tr>
/// <th>
/// Name
/// </th>
/// <th>
/// Type
/// </th>
/// <th>
/// Description
/// </th>
/// </tr>
/// <tr>
/// 		<td>indexlist</td>
/// 		<td>Input/output</td>
/// 		<td>
/// 			A <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> value containing the names of the indexes to be built. This parameter is 
/// 			passed by reference. If the implementation of %OnBeforePurgeIndices alters this value, 
/// 			then %PurgeIndices will honor those changes.
/// 		</td>
/// </tr>
/// </table>
/// </p>
ClassMethod %OnBeforePurgeIndices(ByRef indexlist As %String(MAXLEN="") = "") As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%PurgeIndices</METHOD> method after all work is completed.
/// <P>If this method returns an error then %PurgeIndices will return that error but all normal processing is
/// completed. This call occurs just prior to releasing the extent lock.</p>
ClassMethod %OnAfterPurgeIndices(indexlist As %String(MAXLEN="") = "") As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Reload</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> was reloaded.
/// <method>%Reload</method> is invoked by %Open when the object identified by the OID 
/// is already in memory. 
/// <br>
/// <P>If this method returns an error then the object will not be opened.
Method %OnReload() As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that a save transaction is being rolled back.
/// 
/// <P>If this method returns an error then the rollback operation will be aborted.
Method %OnRollBack() As %Status [ Abstract, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

ClassMethod %OnDetermineClass(oid As %ObjectIdentity, ByRef class As %String) As %Status [ ServerOnly = 1 ]
{
	Set class=$classname()
	Quit $$$OK
}

Trigger %OBJJRNIU [ CodeMode = generator, Event = INSERT/UPDATE, Foreach = row, Order = 2, Time = AFTER ]
{
	if ($$$getClassType(%class) '= $$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) { kill %code quit $$$OK }
	set journal = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault)
	set guid = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
	if journal {
		if journal < 3 {
			$$$GENERATE($Char(9)_"if %oper=""INSERT"" { n %e,iJrnPtr,jid,oref s i=$o(%d("""")) while i'="""" { set $e(%e,i)=$c(1),i=$o(%d(i)) } Set oref=##class({%%CLASSNAME}).%OpenId({%%ID}) $$$txJournalSQLSave({%%CLASSNAMEQ},jid,{%%ID},1"_$select('guid:",""""",1:",##class({%%CLASSNAME}).%GUID($$$oidCompose({%%ID},{%%CLASSNAMEQ}))")_",oref,iJrnPtr) }")
			$$$GENERATE($Char(9)_"elseif %oper=""UPDATE"" { n iJrnPtr,jid,oref set oref=##class({%%CLASSNAME}).%OpenId({%%ID}) $$$txJournalSQLSave($classname(oref),jid,{%%ID},0"_$select('guid:",""""",1:",oref.%GUID($$$oidCompose({%%ID},$classname(oref)))")_",oref,iJrnPtr) }")
		}
		else {
			$$$GENERATE($Char(9)_"if %oper=""INSERT"" { n jid $$$txJournal({%%CLASSNAMEQ},jid,{%%ID},1)")
			$$$GENERATE($Char(9)_"elseif %oper=""UPDATE"" { n jid $$$txJournal({%%CLASSNAMEQ},jid,{%%ID},0)")
		}
	}
	quit $$$OK
}

Trigger %OBJJRND [ CodeMode = generator, Event = DELETE, Foreach = row, Order = 1 ]
{
	if ($$$getClassType(%class) '= $$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) { kill %code quit $$$OK }
	set journal = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"OBJJOURNAL",$$$cPARAMdefault)
	set guid = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
	if journal {
		if journal < 3 {
			$$$GENERATE($Char(9)_"n iJrnPtr,jid,oref Set oref=##class({%%CLASSNAME}).%OpenId({%%ID}) $$$txJournalSQLDelete($classname(oref),jid,{%%ID}"_$select('guid:",""""",1:",oref.%GUID($$$oidCompose({%%ID},$classname(oref)))")_",oref,iJrnPtr)")
		}
		else {
			$$$GENERATE($Char(9)_"n jid $$$txJournal({%%CLASSNAMEQ},jid,{%%ID},2)")
		}
	}
	quit $$$OK
}

Trigger %OBJGUID [ CodeMode = generator, Event = INSERT, Foreach = row, Order = 1, Time = AFTER ]
{
	if ($$$getClassType(%class) '= $$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) { kill %code quit $$$OK }
	set guid = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		// For GUIDENABLED classes this trigger assigns a GUID to inserted rows.
	if guid {
		$$$GENERATE($Char(9)_"if '$a(%check,6) { do ##class({%%CLASSNAME}).%GUIDSet($$$oidCompose({%%ID},{%%CLASSNAMEQ}),{%GUID}) }")
	}
	quit $$$OK
}

}
