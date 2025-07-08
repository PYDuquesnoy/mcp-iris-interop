/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator (%systemInclude, %occUtility)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.Populate">Using the Populate Utility</a>.</p>
/// <CLASS>%Populate</CLASS> is a utility class that provides the ability to 
/// create instances of an object populated with random data.
/// 
/// <p>To use the <CLASS>%Populate</CLASS> class do the following:
/// <ol>
/// <li>Create a persistent object class, such as <b>Employee</b>.</li>
/// <li>Add <CLASS>%Populate</CLASS> to the end of the class' superclass list:<br>
/// <example>super = %Persistent,%Populate</example></li>
/// <li>Save and compile the class.</li>
/// <li><CLASS>%Populate</CLASS> will add a class method, <b>Populate()</b>, to your class.</li>
/// </ol>
/// Run this method to create instances of your class in the database:<br>
/// <example>Do ##class(Employee).Populate(100)</example>
Class %Library.Populate [ Abstract, Not ProcedureBlock, PropertyClass = %Compiler.Type.Populate, System = 2 ]
{

/// The <i>POPSPEC</i> parameter provides a way to control how 
/// <CLASS>%Populate</CLASS> generates data for properties.
/// 
/// <p><b>For details</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.Populate">Using the Populate Utility</a>.</p>
Parameter POPSPEC;

/// Creates up to <var>count</var> instances an object and stores 
/// them in the database.
/// 
/// <p>If <var>verbose</var> is true, then details are echoed to the console.
/// <p>If <var>DeferIndices</var> is true, then indices are sorted at the end of the operation.
/// <p>If <var>objects</var> is true, then each object that is created is returned in the objects array
/// <p>If <var>tune</var> is true, then $SYSTEM.SQL.TuneTable is called after the instances of the class have been created. 
/// If tune>1, then $SYSTEM.SQL.TuneTable is also called for any tables projected by persistent superclasses of this class
/// <p>If <var>deterministic</var> is true, then the set of objects produced by identical calls to Populate at different times will be identical. 
/// 
/// <P>Returns the number of instances successfully created.
/// 
/// <p><b>For details</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.Populate">Using the Populate Utility</a>.</p>
ClassMethod Populate(count As %Integer = 10, verbose As %Integer = 0, DeferIndices As %Integer = 1, ByRef objects As %Integer = 0, tune As %Integer = 1, deterministic As %Integer = 0) As %Integer [ CodeMode = generator, GenerateAfter = OnPopulate ]
{
	Set %code=0
	QUIT:'($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT) $$$OK
	QUIT:($$$CLASSabstract($$$gMGINFO,%class)) $$$OK
	QUIT:($$$CLASSnoextent($$$gMGINFO,%class)) $$$OK
	New assignvals,attrib,buildinstances,buildsamples,cardinality,classtype,closing,collection,concrete,dt,dts,i,initcode,keepobj,lvars,max,min,p,popspec,populate,properties,references,relationship,saveobj,spec,specatom,set,sett,sql,typecategory,unordered,val,vallist,scale,order,prop,required,ccount
	Set popspec=%parameter("POPSPEC")
	Set spec="" If popspec'="" QUIT:'$$ParseNestedString^%occStorageUtil(popspec,",",,.spec)
	For i=1:1:spec {
		Kill specatom
		If $$ParseNestedString^%occStorageUtil(spec(i),":",,.specatom)
		Set attrib=$Piece($Get(specatom(1)),":")
		If attrib '= "" {
			Set attrib(attrib)=$Select("#."'[$Extract(specatom(2),1):"##class(%PopulateUtils)."_specatom(2),$Extract(specatom(2))=".":"obj"_specatom(2),1:specatom(2))
			Set:specatom>2 attrib(attrib,"count")=specatom(3)
			Set:specatom>3 attrib(attrib,"key")=$Select("#."'[$Extract(specatom(4),1):"##class(%PopulateUtils)."_specatom(4),$Extract(specatom(4))=".":"obj"_specatom(4),1:specatom(4))
			Set:specatom>4 attrib(attrib,"concrete") = specatom(5)
			Set:specatom>5 attrib(attrib,"sqltable")=specatom(6)
			Set:specatom>6 attrib(attrib,"sqlcolumn")=specatom(7)
		}
	}
	Set references = 0, concrete = 0, sql = 0
		#; Set up the code generation structure...
	Do InitializeFlowGraph^%occStorageUtil(.populate)
		#; Initialize and generate the top level code blocks
	Set initcode = $$NewCodeBlock^%occStorageUtil(.populate,0,0)
	Do DefineLocalVariables^%occStorageUtil(.populate,initcode,"errcnt,i,keepobjects,obj,save,saved,id")

	Set buildsamples = $$NewCodeBlock^%occStorageUtil(.populate,initcode,0)
	Set buildinstances = $$NewCodeBlock^%occStorageUtil(.populate,initcode,0)
	Set assignvals = $$NewCodeBlock^%occStorageUtil(.populate,buildinstances,1)
	Set saveobj = $$NewCodeBlock^%occStorageUtil(.populate,assignvals,1)
	Set keepobj = $$NewCodeBlock^%occStorageUtil(.populate,assignvals,0)
	Set closing = $$NewCodeBlock^%occStorageUtil(.populate,initcode,0)

	Do QueueCodeLine^%occStorageUtil(.populate,initcode,"#class "_%class_" obj")
	Do QueueCodeLine^%occStorageUtil(.populate,initcode,"#import "_$$$ClassPackageName(%class))
	Do QueueCodeLine^%occStorageUtil(.populate,initcode,"Set saved=0,keepobjects=0,errcnt=0")
	//Seed the $ZU(165 RNG with a constnat if we want deterministic results
	Do QueueCodeLine^%occStorageUtil(.populate,initcode,"Do $ZU(165,0,$S(deterministic:481516,1:$RANDOM(99999999)))")
	Do QueueCodeLine^%occStorageUtil(.populate,initcode,"If objects Set keepobjects=1,objects=0")
	Do QueueCodeLine^%occStorageUtil(.populate,initcode,"If DeferIndices Do ..%SortBegin("""",1)")

	Do QueueCodeLine^%occStorageUtil(.populate,buildinstances,"For i=1:1:count Do  if errcnt>1000 write:verbose !,""over 1,000 errors encountered with no successful save - exiting"" quit")
	Do QueueCodeLine^%occStorageUtil(.populate,assignvals,"Set obj=##class("_%class_").%New()")

	$$$comMemberKeyGetLvar(versionProperty,%class,$$$cCLASSparameter,"VERSIONPROPERTY",$$$cPARAMdefault)
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		If (versionProperty '= prop) && (prop '= "%%GUID") && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPprivate)) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPreadonly)) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPcalculated)) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPidentity)) {
				#; suppress populate if POPORDER is less than zero!!
			set poporder = $$$comMemberArrayGet(%class,$$$cCLASSproperty,prop,$$$cPROPparameter,"POPORDER")
			if poporder '< 0 {
				$$$comMemberKeyGetLvar(dt,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
				if $$$getClassType(dt) '= "" {
					$$$comMemberKeyGetLvar(relationship,%class,$$$cCLASSproperty,prop,$$$cPROPrelationship)
					$$$comMemberKeyGetLvar(cardinality,%class,$$$cCLASSproperty,prop,$$$cPROPcardinality)
					If ('relationship) || ((cardinality '= $$$cPROPCARDINALITYCHILDREN) && (cardinality '= $$$cPROPCARDINALITYMANY)) {
						$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
						$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
						If (collection = "") || (collection = $$$cPROPCOLLECTIONLIST) || (collection = $$$cPROPCOLLECTIONARRAY) {
								#; The following check quits if the initialexpression is set because
								#; default values always override randomly generated values. In the case of a collection,
								#; the initialexpression applies to the collection object - not to the elements.
							If (collection '= "") || ($$$IVARinitialexpression($$$gMGINFO,%class,prop) = """""") {
								If (poporder) && ('$Data(properties(poporder))) { Set properties(poporder) = prop } Else { Set unordered(prop) = "" }
							}
						}
					}
				}
			}
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
	Set max = $Order(properties(""),-1)
	Set prop = $Order(unordered(""))
	While prop '= "" {
		Set properties($Increment(max)) = prop
		Set prop = $Order(unordered(prop))
	}
	Set p = $Order(properties(""))
	While p '= "" {
		Set prop = properties(p)
		$$$comMemberKeyGetLvar(dt,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
		Set classtype = $$$getClassType(dt)
		Set spec = $$$PROPPARAM($$$gMGINFO,%class,prop,"POPSPEC")
			#; Is there a property parameter POPSPEC? If so, process this and discard any class POPSPEC info that might be around.
		If spec '= "" {
			Kill specatom, attrib(prop)
			If $$ParseNestedString^%occStorageUtil(spec,":",,.specatom)
				#; Prefix the value generator specified:
			Set attrib(prop) = $Select("#."'[$Extract(specatom(1),1):"##class(%PopulateUtils)."_specatom(1),$Extract(specatom(1))=".":"obj"_specatom(1),1:specatom(1))
				#; This is the collection element count
			Set:specatom>1 attrib(prop,"count") = specatom(2)
				#; and the collection key generator
			Set:specatom>2 attrib(prop,"key")=$Select("#."'[$Extract(specatom(3),1):"##class(%PopulateUtils)."_specatom(3),$Extract(specatom(3))=".":"obj"_specatom(3),1:specatom(3))
				#; and the size of a subdomain (extent)
			If specatom>3 Set attrib(prop,"concrete") = specatom(4)
			Set:specatom>4 attrib(prop,"sqltable") = specatom(5)
			Set:specatom>5 attrib(prop,"sqlcolumn") = specatom(6)
		}
		 	#; typecategory is set based on collection because collections do not behave nicely. The typecategory for collections
		 	#; is based on the collection class, not the defined type class.
		Set typecategory = $Case(classtype,$$$cCLASSCLASSTYPEDATATYPE:"literal",$$$cCLASSCLASSTYPEPERSISTENT:"reference",$$$cCLASSCLASSTYPESTREAM:"stream",:"serial")
		$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
		If collection = "" {
			If (typecategory = "literal") || (typecategory = "stream")  {
				Set set = "Set obj."_$$$QN(prop)_"="
				Set sett = ""
			}
			ElseIf typecategory = "reference" {
				Set set = "Set id="
				Set sett = " If id'="""",##class("_dt_").%ExistsId(id) Do obj."_$$$QN(prop_"SetObjectId")_"(id)"
			}
			Else {
				Set set = "Do obj."_$$$QN(prop_"SetObject")_"("
				Set sett = ")"
			}
		}
		Else {
			Set lvars = "elem,cval"
			$$$comMemberKeyGetLvar(required,%class,$$$cCLASSproperty,prop,$$$cPROPrequired)
			Set ccount=$Select('$Get(attrib(prop,"count")):"10",1:attrib(prop,"count"))
			Set set = "f elem=1:1:$$$PRand("_$select(required:ccount,1:ccount+1)_")"_$select(required:"+1",1:"")_" s cval="
			If collection = $$$cPROPCOLLECTIONARRAY {
				Set lvars = lvars_",key"
				Set sett=" s key="_$Select($Get(attrib(prop,"key"))="":"##class(%PopulateUtils).String(4)",1:attrib(prop,"key"))_" d obj."_$$$QN(prop)_$Select(typecategory="literal":".SetAt(",typecategory="reference":".SetObjectIdAt(",1:".SetObjectAt(")_"cval,key)"
			}
			ElseIf collection = $$$cPROPCOLLECTIONLIST {
				Set sett = " d obj."_$$$QN(prop)_$Select(typecategory="literal":".Insert(",typecategory="reference":".InsertObjectId(",1:".InsertObject(")_"cval)"
			}
			Set:typecategory="reference" sett = " If (cval'=""""),(##class("_dt_").%ExistsId(cval))"_sett
			Do DefineLocalVariables^%occStorageUtil(.populate,initcode,lvars)
		}
			#; If an override value generator was specified in POPSPEC, use it now!
		Set val = $Get(attrib(prop))
		If val = "" {
				#; If there is a value list, pick a value from it...
			Set vallist = $$$PROPPARAM($$$gMGINFO,%class,prop,"VALUELIST")
			if vallist = "" { set vallist = $$$PROPPARAM($$$gMGINFO,%class,prop,"DISPLAYLIST") }
			If vallist '= "" { set val = "##class(%PopulateUtils).ValueList("""_vallist_""")" }
				#; If the property's type class is SERIAL then check to see if it can be populated
				#; if it can then generate a call to dt.PopulateSerial
			ElseIf typecategory = "serial" {
				If $$$comMemberKeyGet(dt,$$$cCLASSmethod,"PopulateSerial",$$$cMETHrunnable) { Set val = "##class("_dt_").PopulateSerial()" }
			}
			ElseIf typecategory = "reference" {
					#; can't generate a reference if the target does not have an extent...
				If ($$$getClassType(dt) = $$$cCLASSCLASSTYPEPERSISTENT), '$$$comClassKeyGet(dt,$$$cCLASSnoextent) {
					If $Get(references(dt)) = "" {
						Set references=references+1,references(dt)="rss"_references
						Do DefineLocalVariables^%occStorageUtil(.populate,initcode,"rss"_references)
						Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"d ##class(%PopulateUtils).BuildReferenceSample("""_dt_""",."_references(dt)_")")
					}
					Set val = "##class(%PopulateUtils).ArrayElement(."_references(dt)_")"
				}
			}
			ElseIf typecategory = "literal" {
				Set val = ""
				Set dts = $$$ClassShortName(dt), ucProp = $$$ucase(prop)
				Set val = $Case(ucProp,
							"NAME":		"##class(%PopulateUtils).Name()",
							"SSN":		"##class(%PopulateUtils).SSN()",
							"COMPANY":	"##class(%PopulateUtils).Company()",
							"TITLE":	"##class(%PopulateUtils).Title()",
							"PHONE":	"##class(%PopulateUtils).USPhone()",
							"CITY":		"##class(%PopulateUtils).City()",
							"STREET":	"##class(%PopulateUtils).Street()",
							"ZIP":		"##class(%PopulateUtils).USZip()",
							"MISSION":	"##class(%PopulateUtils).Mission()",
							"STATE":	"##class(%PopulateUtils).USState()",
							"COLOR":	"##class(%PopulateUtils).Color()",
							"PRODUCT":	"##class(%PopulateUtils).Product()",
							:"")
					#; If no value generator is assigned by the property name rule then proceed with the property type rule:
				If val = "" {
					set minlen = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINLEN"), maxlen = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXLEN")
					if (dts = "String") && (minlen > 1) { set val = "##class(%PopulateUtils).StringMin("_minlen_","_maxlen_")" }
					else {
						Set val = $Case(dts,
							"String":		"##class(%PopulateUtils).String("_maxlen_")",
							"Integer":		"##class(%PopulateUtils).Integer("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							"Date":			"##class(%PopulateUtils).Date("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							"Binary":		"##class(%PopulateUtils).String("_maxlen_")",
							"Double":		"##class(%PopulateUtils).Float("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"SCALE"))_")",
							"Name":			"##class(%PopulateUtils).Name()",
							"Boolean":		"$$$PRand(2)",
							"Currency":		"##class(%PopulateUtils).Currency("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							"Float":		"##class(%PopulateUtils).Float("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"SCALE"))_")",
							"Numeric":		"##class(%PopulateUtils).Float("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"SCALE"))_")",
							"Decimal":		"##class(%PopulateUtils).Float("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"SCALE"))_")",
							"PosixTime":		"##class(%PopulateUtils).PosixTime("_$$$quote($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_$$$quote($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							"TimeStamp":		"##class(%PopulateUtils).TimeStamp("_$$$quote($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_$$$quote($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							:			"")
					}
						#; None of the above? try SmallInt and Time:
					If val = "" {
						If dts="SmallInt" {
							Set min = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL")
							Set max = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL")
							Set max = $Select(max="":32767,max>32767:32767,1:max)
							Set min = $Select(min="":-32768,min<-32768:-32768,1:min)
							Set val = "##class(%PopulateUtils).Integer("_min_","_max_")"
						}
						ElseIf dts = "Time" {
							Set min = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL")
							Set max = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL")
							Set max = $Select(max="":86399,max>86399:86399,1:max)
							Set min = $Select(min="":0,min<0:0,1:min)
							Set val = "##class(%PopulateUtils).Integer("_min_","_max_")"
						}
						elseif dts="TinyInt" {
							Set min = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL")
							Set max = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL")
							Set max = $Select(max="":127,max>127:127,1:max)
							Set min = $Select(min="":-128,min<-128:-128,1:min)
							Set val = "##class(%PopulateUtils).Integer("_min_","_max_")"
						}
						elseif dts="BigInt" {
							Set min = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL")
							Set max = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL")
							Set max = $Select(max="":100000000000000000,max>100000000000000000:100000000000000000,1:max)
							Set min = $Select(min="":-100000000000000000,min<-100000000000000000:-100000000000000000,1:min)
							Set val = "##class(%PopulateUtils).Integer("_min_","_max_")"
						}
					}
				}
			}
		}
		If $Get(attrib(prop,"concrete")) && (val '= "") {
			Set concrete = concrete + 1
			Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"If verbose { Write !,""Constructing value set for " _ prop _ ":"" }")
			If ($Get(attrib(prop,"sqltable")) = "") || ($Get(attrib(prop,"sqlcolumn")) = "") {
				Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"Set ^IRIS.Temp(cptr,"_concrete _ ") = " _ attrib(prop,"concrete") _", cextcnt = 0")
				Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"While cextcnt < " _ attrib(prop,"concrete") _ " { Set val = " _ val _ " If '$d(^IRIS.Temp(cptr,"_concrete _ ",""u"",val)) { Set cextcnt = cextcnt + 1, ^IRIS.Temp(cptr," _ concrete _ ",""u"",val) = cextcnt, ^IRIS.Temp(cptr," _ concrete _ ",cextcnt) = val If verbose && ('(cextcnt#1000)) { Write ""."" } } }")
				Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"Kill ^IRIS.Temp(cptr," _ concrete _ ",""u"")")
			}
			Else {
				set sql = 1
				Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"Set sc = ##class(%Library.PopulateUtils).BuildValueSetSQL(cptr," _ concrete _ "," _ $$$quote(attrib(prop,"sqltable")) _ "," _ $$$quote(attrib(prop,"sqlcolumn")) _ "," _  attrib(prop,"concrete") _ ",verbose)")
			}
			Set val = "##class(%PopulateUtils).ExtentValue(cptr," _ concrete _ ")"
		}
		If val = "" { Set val = """""" }
		Do QueueCodeLine^%occStorageUtil(.populate,assignvals,set_val_sett)
		Set p = $Order(properties(p))
	}
 		#; concrete is a local array of the concrete literal subextents. When it exists it means that some
 		#; value extents must be made concrete and a random selection from that concrete set is used.
 		#; The parameters affecting value generation are considered when the concrete set is built. Value selection
 		#; is simply a random choice. Here we will allocate space in ^IRIS.Temp
 	If concrete {
		Do DefineLocalVariables^%occStorageUtil(.populate,initcode,"cptr,cextcnt,val" _ $select(sql:",sc,%ROWCOUNT",1:""))
		Do QueueCodeLine^%occStorageUtil(.populate,initcode,"Set cptr = $Increment(^IRIS.Temp)")
		Do QueueCodeLine^%occStorageUtil(.populate,initcode,"$$$AddTempNode(^IRIS.Temp(cptr))")
		Do QueueCodeLine^%occStorageUtil(.populate,closing,"$$$RemoveTempNode(^IRIS.Temp(cptr))")
 	}
	Do QueueCodeLine^%occStorageUtil(.populate,initcode,"Kill ^||%Populate")
	Do QueueCodeLine^%occStorageUtil(.populate,closing,"Kill ^||%Populate")
	If ($$$METHrunnable($$$gMGINFO,%class,"OnPopulate")) Do QueueCodeLine^%occStorageUtil(.populate,assignvals,"s save=obj.OnPopulate() i $$$ISERR(save) Do:verbose DisplayError^%apiOBJ(save) s obj="""" q")
	Do QueueCodeLine^%occStorageUtil(.populate,assignvals,"If 'keepobjects Do")
	Do QueueCodeLine^%occStorageUtil(.populate,saveobj,"Set save=obj.%Save()")
	Do QueueCodeLine^%occStorageUtil(.populate,saveobj,"If $$$ISOK(save) Set saved=saved+1,errcnt=0 If verbose Write !,""Object saved..."",saved")
	Do QueueCodeLine^%occStorageUtil(.populate,saveobj,"If $$$ISERR(save) set errcnt=errcnt+1 if verbose Do DisplayError^%apiOBJ(save)")
	Do QueueCodeLine^%occStorageUtil(.populate,keepobj,"If keepobjects Set objects($Increment(objects))=obj")
	Do QueueCodeLine^%occStorageUtil(.populate,keepobj,"Set obj=""""")

	Do QueueCodeLine^%occStorageUtil(.populate,closing,"If DeferIndices Do ..%SortEnd(,,1)")
	$$$comClassKeyGetLvar(schemaTableQ,%class,$$$cCLASSsqlqualifiednameQ)
	Do QueueCodeLine^%occStorageUtil(.populate,closing,"If tune Do TuneTable^%apiSQL("_$$quoter^%occClass(schemaTableQ)_",1,verbose,.%msg,1)")
		#; Here will will potentially also call TuneTable on the suprt extents of the class.
		#; First get a list of SuperExtents up to the RootExtent
	#; Determine the root extent class of this class from DEF
	set tSuperClasses=..GetSuperExtents(%class)
	if tSuperClasses'="" {
		Do QueueCodeLine^%occStorageUtil(.populate,closing,"If tune>1 {")
		for i=1:1:$l(tSuperClasses,"~") {
			$$$comClassKeyGetLvar(schemaTableQ,$p(tSuperClasses,"~",i),$$$cCLASSsqlqualifiednameQ)
			do QueueCodeLine^%occStorageUtil(.populate,closing,$c(9)_"do TuneTable^%apiSQL("_$$quoter^%occClass(schemaTableQ)_",1,verbose,.%msg,1)")
		}
		Do QueueCodeLine^%occStorageUtil(.populate,closing,"}")
	}

	Do QueueCodeLine^%occStorageUtil(.populate,closing,"Quit saved")

	Do DequeueFlowGraph^%occStorageUtil(.populate,.%code)

	QUIT $$$OK
}

/// Given a class, return a '~' delimited list of the class's super extents
ClassMethod GetSuperExtents(pClass) As %String [ Internal, ServerOnly = 1 ]
{
	set tSuperList="",tClass=pClass
loop	set tPrimarySuper=$piece($listget($get(^rINDEXCLASS($zconvert(tClass,"U"))),7),",")
	$$$NormalizeClassnameByDef(tPrimarySuper,tClass) if $$$ISERR(sc) { QUIT tSuperList }
	QUIT:tPrimarySuper="" tSuperList						// No super class
	if $$$comClassKeyGet(tPrimarySuper,$$$cCLASSnoextent) { QUIT tSuperList }	// Primary SuperClass is NoExtent	
	set tClassType = $$$getClassType(tPrimarySuper)
	if tClassType '= $$$cCLASSCLASSTYPEPERSISTENT { QUIT tSuperList }		// Primary super is not a persistent class
	QUIT:$e(tPrimarySuper,1)="%" tSuperList						// Hit a system class, don't want to return %Library.Persistent
	set tSuperList=tSuperList_$e("~",tSuperList'="")_tPrimarySuper
	set tClass=tPrimarySuper
	goto loop
}

/// Create a single instance of a serial object.
ClassMethod PopulateSerial() As %String [ CodeMode = generator, GenerateAfter = OnPopulate ]
{
	Set %code=0
	QUIT:'($$$getClassType(%class)=$$$cCLASSCLASSTYPESERIAL) $$$OK
	QUIT:($$$CLASSabstract($$$gMGINFO,%class)) $$$OK
	New assignvals,attrib,buildinstances,buildsamples,cardinality,classtype,closing,collection,concrete,dt,dts,i,initcode,max,min,p,popspec,populate,properties,references,relationship,spec,specatom,set,sett,sql,typecategory,unordered,val,vallist,prop,order
	Set popspec=%parameter("POPSPEC")
	Set spec="" If popspec'="" QUIT:'$$ParseNestedString^%occStorageUtil(popspec,",",,.spec)
	For i=1:1:spec {
		Kill specatom
		If $$ParseNestedString^%occStorageUtil(spec(i),":",,.specatom)
		Set attrib=$Piece($Get(specatom(1)),":")
		If attrib '= "" {
			Set attrib(attrib)=$Select("#."'[$Extract(specatom(2),1):"##class(%PopulateUtils)."_specatom(2),$Extract(specatom(2))=".":"obj"_specatom(2),1:specatom(2))
			Set:specatom>2 attrib(attrib,"count")=specatom(3)
			Set:specatom>3 attrib(attrib,"key")=$Select("#."'[$Extract(specatom(4),1):"##class(%PopulateUtils)."_specatom(4),$Extract(specatom(4))=".":"obj"_specatom(4),1:specatom(4))
			Set:specatom>4 attrib(attrib,"concrete")=specatom(5)
			Set:specatom>5 attrib(attrib,"sqltable")=specatom(6)
			Set:specatom>6 attrib(attrib,"sqlcolumn")=specatom(7)
		}
	}
	Set references = 0, concrete = 0, sql = 0
		#; Set up the code generation structure...
	Do InitializeFlowGraph^%occStorageUtil(.populate)
		#; Initialize and generate the top level code blocks
	Set initcode = $$NewCodeBlock^%occStorageUtil(.populate,0,0)
	Do DefineLocalVariables^%occStorageUtil(.populate,initcode,"i,obj,save")

	Set buildsamples = $$NewCodeBlock^%occStorageUtil(.populate,initcode,0)
	Set assignvals = $$NewCodeBlock^%occStorageUtil(.populate,initcode,0)
	Set closing = $$NewCodeBlock^%occStorageUtil(.populate,initcode,0)
	Do QueueCodeLine^%occStorageUtil(.populate,initcode,"#class "_%class_" obj")
	Do QueueCodeLine^%occStorageUtil(.populate,assignvals,"Set obj=##class("_%class_").%New()")
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		If ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPprivate)) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPreadonly)) && ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,prop,$$$cPROPcalculated)) {
				#; suppress populate if POPORDER is less than zero!!
			set poporder = $$$comMemberArrayGet(%class,$$$cCLASSproperty,prop,$$$cPROPparameter,"POPORDER")
			if poporder '< 0 {
				$$$comMemberKeyGetLvar(relationship,%class,$$$cCLASSproperty,prop,$$$cPROPrelationship)
				$$$comMemberKeyGetLvar(cardinality,%class,$$$cCLASSproperty,prop,$$$cPROPcardinality)
				If ('relationship) || ((cardinality '= $$$cPROPCARDINALITYCHILDREN) && (cardinality '= $$$cPROPCARDINALITYMANY)) {
					$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
					If (collection = "") || (collection = $$$cPROPCOLLECTIONLIST) || (collection = $$$cPROPCOLLECTIONARRAY) {
							#; The following check quits if the initialexpression is set because
							#; default values always override randomly generated values. In the case of a collection,
							#; the initialexpression applies to the collection object - not to the elements.
						If (collection '= "") || ($$$IVARinitialexpression($$$gMGINFO,%class,prop) = """""") {
							If (poporder) && ('$Data(properties(poporder))) { Set properties(poporder) = prop } Else { Set unordered(prop) = "" }
						}
					}
				}
			}
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
	Set max = $Order(properties(""),-1)
	Set prop = $Order(unordered(""))
	While prop '= "" {
		Set properties($Increment(max)) = prop
		Set prop = $Order(unordered(prop))
	}
	Set p = $Order(properties(""))
	While p '= "" {
		Set prop = properties(p)
		$$$comMemberKeyGetLvar(dt,%class,$$$cCLASSproperty,prop,$$$cPROPtype)
		Set classtype = $$$getClassType(dt)
		Set spec = $$$PROPPARAM($$$gMGINFO,%class,prop,"POPSPEC")
			#; Is there a property parameter POPSPEC? If so, process this and discard any class POPSPEC info that might be around.
		If spec '= "" {
			Kill specatom, attrib(prop)
			If $$ParseNestedString^%occStorageUtil(spec,":",,.specatom)
				#; Prefix the value generator specified:
			Set attrib(prop) = $Select("#."'[$Extract(specatom(1),1):"##class(%PopulateUtils)."_specatom(1),$Extract(specatom(1))=".":"obj"_specatom(1),1:specatom(1))
				#; This is the collection element count
			Set:specatom>1 attrib(prop,"count") = specatom(2)
				#; and the collection key generator
			Set:specatom>2 attrib(prop,"key")=$Select("#."'[$Extract(specatom(3),1):"##class(%PopulateUtils)."_specatom(3),$Extract(specatom(3))=".":"obj"_specatom(3),1:specatom(3))
				#; and the size of a subdomain (extent)
			If specatom>3 Set attrib(prop,"concrete")=specatom(4)
			Set:specatom>4 attrib(prop,"sqltable")=specatom(5)
			Set:specatom>5 attrib(prop,"sqlcolumn")=specatom(6)
		}
		 	#; typecategory is set based on collection because collections do not behave nicely. The typecategory for collections
		 	#; is based on the collection class, not the defined type class.
		Set typecategory = $Case(classtype,$$$cCLASSCLASSTYPEDATATYPE:"literal",$$$cCLASSCLASSTYPEPERSISTENT:"reference",$$$cCLASSCLASSTYPESTREAM:"stream",:"serial")
		$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,prop,$$$cPROPcollection)
		If collection = "" {
			If (typecategory = "literal") || (typecategory = "stream")  {
				Set set = "Set obj."_$$$QN(prop)_"="
				Set sett = ""
			}
			ElseIf typecategory = "reference" {
				Set set = "Set id="
				Set sett = " If (id'=""""),(##class("_dt_").%ExistsId(id)) Do obj."_$$$QN(prop_"SetObjectId")_"(id)"
			}
			Else {
				Set set = "Do obj."_$$$QN(prop_"SetObject")_"("
				Set sett = ")"
			}
		}
		Else {
			Set lvars = "elem,cval"
			Set set = "f elem=1:1:$$$PRand("_($Select('$Get(attrib(prop,"count")):"10",1:attrib(prop,"count"))+1)_") s cval="
			If collection = $$$cPROPCOLLECTIONARRAY {
				Set lvars = lvars_",key"
				Set sett=" s key="_$Select($Get(attrib(prop,"key"))="":"##class(%PopulateUtils).String(4)",1:attrib(prop,"key"))_" d obj."_$$$QN(prop)_$Select(typecategory="literal":".SetAt(",typecategory="reference":".SetObjectIdAt(",1:".SetObjectAt(")_"cval,key)"
			}
			ElseIf collection = $$$cPROPCOLLECTIONLIST {
				Set sett = " d obj."_$$$QN(prop)_$Select(typecategory="literal":".Insert(",typecategory="reference":".InsertObjectId(",1:".InsertObject(")_"cval)"
			}
			Set:typecategory="reference" sett = " If (cval'=""""),(##class("_dt_").%ExistsId(cval))"_sett
			Do DefineLocalVariables^%occStorageUtil(.populate,initcode,lvars)
		}
			#; If an override value generator was specified in POPSPEC, use it now!
		Set val = $Get(attrib(prop))
		If val = "" {
				#; If there is a value list, pick a value from it...
			Set vallist = $$$PROPPARAM($$$gMGINFO,%class,prop,"VALUELIST")
			if vallist = "" { set vallist = $$$PROPPARAM($$$gMGINFO,%class,prop,"DISPLAYLIST") }
			If vallist '= "" { Set val = "##class(%PopulateUtils).ValueList("""_vallist_""")" }
				#; If the property's type class is SERIAL then check to see if it can be populated
				#; if it can then generate a call to dt.PopulateSerial
			ElseIf typecategory = "serial" {
				If $$$comMemberKeyGet(dt,$$$cCLASSmethod,"PopulateSerial",$$$cMETHrunnable) { Set val = "##class("_dt_").PopulateSerial()" }
			}
			ElseIf typecategory = "reference" {
					#; can't generate a reference if the target does not have an extent...
				If ($$$getClassType(dt) = $$$cCLASSCLASSTYPEPERSISTENT), '$$$comClassKeyGet(dt,$$$cCLASSnoextent) {
					If $Get(references(dt)) = "" {
						Set references=references+1,references(dt)="rss"_references
						Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"d ##class(%PopulateUtils).BuildReferenceSample("""_dt_""",."_references(dt)_")")
						Do DefineLocalVariables^%occStorageUtil(.populate,initcode,references(dt)_",ref,id")
					}
					Set val = "##class(%PopulateUtils).ArrayElement(."_references(dt)_") "
				}
			}
			ElseIf typecategory = "literal" {
				Set val = ""
				Set dts = $$$ClassShortName(dt), ucProp = $$$ucase(prop)
				Set val = $Case(ucProp,
							"NAME":		"##class(%PopulateUtils).Name()",
							"SSN":		"##class(%PopulateUtils).SSN()",
							"COMPANY":	"##class(%PopulateUtils).Company()",
							"TITLE":	"##class(%PopulateUtils).Title()",
							"PHONE":	"##class(%PopulateUtils).USPhone()",
							"CITY":		"##class(%PopulateUtils).City()",
							"STREET":	"##class(%PopulateUtils).Street()",
							"ZIP":		"##class(%PopulateUtils).USZip()",
							"MISSION":	"##class(%PopulateUtils).Mission()",
							"STATE":	"##class(%PopulateUtils).USState()",
							:"")
					#; If no value generator is assigned by the property name rule then proceed with the property type rule:
				If val = "" {
					set minlen = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINLEN"), maxlen = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXLEN")
					if (dts = "String") && (minlen > 1) { set val = "##class(%PopulateUtils).StringMin("_minlen_","_maxlen_")" }
					else {
						Set val = $Case(dts,
							"String":		"##class(%PopulateUtils).String("_maxlen_")",
							"Integer":		"##class(%PopulateUtils).Integer("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							"Date":			"##class(%PopulateUtils).Date("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							"Binary":		"##class(%PopulateUtils).String("_maxlen_")",
							"Double":		"##class(%PopulateUtils).Float("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"SCALE"))_")",
							"Name":			"##class(%PopulateUtils).Name()",
							"Boolean":		"$$$PRand(2)",
							"Currency":		"##class(%PopulateUtils).Currency("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							"Float":		"##class(%PopulateUtils).Float("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"SCALE"))_")",
							"Numeric":		"##class(%PopulateUtils).Float("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"SCALE"))_")",
							"Decimal":		"##class(%PopulateUtils).Float("_($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_","_($$$PROPPARAM($$$gMGINFO,%class,prop,"SCALE"))_")",
							"PosixTime":		"##class(%PopulateUtils).PosixTime("_$$$quote($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_$$$quote($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							"TimeStamp":		"##class(%PopulateUtils).TimeStamp("_$$$quote($$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL"))_","_$$$quote($$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL"))_")",
							:				"")
					}
						#; None of the above? try SmallInt and Time:
					If val = "" {
						If dts="SmallInt" {
							Set min = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL")
							Set max = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL")
							Set max = $Select(max="":32767,max>32767:32767,1:max)
							Set min = $Select(min="":-32768,min<-32768:-32768,1:min)
							Set val = "##class(%PopulateUtils).Integer("_min_","_max_")"
						}
						ElseIf dts = "Time" {
							Set min = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL")
							Set max = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL")
							Set max = $Select(max="":86399,max>86399:86399,1:max)
							Set min = $Select(min="":0,min<0:0,1:min)
							Set val = "##class(%PopulateUtils).Integer("_min_","_max_")"
						}
						elseif dts="TinyInt" {
							Set min = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL")
							Set max = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL")
							Set max = $Select(max="":127,max>127:127,1:max)
							Set min = $Select(min="":-128,min<-128:-128,1:min)
							Set val = "##class(%PopulateUtils).Integer("_min_","_max_")"
						}
						elseif dts="BigInt" {
							Set min = $$$PROPPARAM($$$gMGINFO,%class,prop,"MINVAL")
							Set max = $$$PROPPARAM($$$gMGINFO,%class,prop,"MAXVAL")
							Set max = $Select(max="":100000000000000000,max>100000000000000000:100000000000000000,1:max)
							Set min = $Select(min="":-100000000000000000,min<-100000000000000000:-100000000000000000,1:min)
							Set val = "##class(%PopulateUtils).Integer("_min_","_max_")"
						}
					}
				}
			}
		}
		If $Get(attrib(prop,"concrete")) && (val '= "") {
			Set concrete = concrete + 1
			If ($Get(attrib(prop,"sqltable")) = "") || ($Get(attrib(prop,"sqlcolumn")) = "") {
				Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"Set ^IRIS.Temp(cptr,"_concrete _ ") = " _ attrib(prop,"concrete") _", cextcnt = 0")
				Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"While cextcnt < " _ attrib(prop,"concrete") _ " { Set val = " _ val _ " If '$d(^IRIS.Temp(cptr,"_concrete _ ",""u"",val)) { Set cextcnt = cextcnt + 1, ^IRIS.Temp(cptr," _ concrete _ ",""u"",val) = cextcnt, ^IRIS.Temp(cptr," _ concrete _ ",cextcnt) = val } }")
				Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"Kill ^IRIS.Temp(cptr," _ concrete _ ",""u"")")
			}
			Else {
				set sql = 1
				Do QueueCodeLine^%occStorageUtil(.populate,buildsamples,"Set sc = ##class(%Library.PopulateUtils).BuildValueSetSQL(cptr," _ concrete _ "," _ $$$quote(attrib(prop,"sqltable")) _ "," _ $$$quote(attrib(prop,"sqlcolumn")) _ "," _  attrib(prop,"concrete") _ ")")
			}
			Set val = "##class(%PopulateUtils).ExtentValue(cptr," _ concrete _ ")"
		}
		If val = "" { Set val = """""" }
		Do QueueCodeLine^%occStorageUtil(.populate,assignvals,set_val_sett)
		Set p = $Order(properties(p))
	}
 		#; concrete is a local array of the concrete literal subextents. When it exists it means that some
 		#; value extents must be made concrete and a random selection from that concrete set is used.
 		#; The parameters affecting value generation are considered when the concrete set is built. Value selection
 		#; is simply a random choice. Here we will allocate space in ^IRIS.Temp
	If concrete {
		Do DefineLocalVariables^%occStorageUtil(.populate,initcode,"cptr,cextcnt,val" _ $select(sql:",sc,%ROWCOUNT",1:""))
		Do QueueCodeLine^%occStorageUtil(.populate,initcode,"Set cptr = $Increment(^IRIS.Temp)")
		Do QueueCodeLine^%occStorageUtil(.populate,initcode,"$$$AddTempNode(^IRIS.Temp(cptr))")

		Do QueueCodeLine^%occStorageUtil(.populate,closing,"$$$RemoveTempNode(^IRIS.Temp(cptr))")
	}

	If ($$$METHrunnable($$$gMGINFO,%class,"OnPopulate")) Do QueueCodeLine^%occStorageUtil(.populate,closing,"s save=obj.OnPopulate() i $$$ISERR(save) Do:verbose DisplayError^%apiOBJ(save) s obj="""" q")
	Do QueueCodeLine^%occStorageUtil(.populate,closing,"If obj.%GetSwizzleObject(1,.save)")
	Do QueueCodeLine^%occStorageUtil(.populate,closing,"Set obj=""""")
	Do QueueCodeLine^%occStorageUtil(.populate,closing,"Quit save")
	Do DequeueFlowGraph^%occStorageUtil(.populate,.%code)

	QUIT $$$OK
}

Method OnPopulate() As %Status [ Abstract, ServerOnly = 1 ]
{
}

/// Return a random number from 0-<var>n</var> using a seeded RNG. Identical to $$$PRand
ClassMethod Random(n As %Integer) As %Integer [ Internal, ProcedureBlock = 1 ]
{
	//$ZU(165 was seeded in Populate()
	Quit $$$PRand(n)
}

}
