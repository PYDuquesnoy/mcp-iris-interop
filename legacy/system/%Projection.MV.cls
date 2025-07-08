/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include LANG11

Class %Projection.MV Extends %Projection.AbstractProjection [ System = 4 ]
{

/// This method is called by the Class Compiler whenever an associated 
/// class has finished compiling. <var>classname</var> contains the name of 
/// the associated class while <var>parameters</var> contains an array of the 
/// projection parameters subscripted by parameter name.<BR>
/// Any errors reported by this method are reported by the Class Compiler but
/// do not affect class compilation in any way. Errors thrown here may well prevent
/// the projection from creating a file or populating the dictionary of the file.
/// 
ClassMethod CreateProjection(classname As %String, ByRef parameters As %String) As %Status
{
	set $ZTrap        = "Catch"
	#; Abstract classes do not have a projection - mainly this is to suppress the projection for %MV.Adaptor itself.
	#; If ABSTRACT classes do need a projection then we will have to alter this condition and test for the Adaptor differently.
	if '($$$comMemberKeyGet(classname,$$$cCLASSparameter,"MVENABLED",$$$cPARAMdefault)) || ($$$comClassKeyGet(classname,$$$cCLASSabstract)) { QUIT $$$OK }
	#;
	#; Assume a good result
	#; 
	set status        = $$$OK
	#;
	#; Interrogate qualifies to see if we are going to write status
	#; information to the current device (though we use the MVP staement
	#; in case this is happening in an MV shell)
	#; 
	Set qSpec	= $Get(parameters("%qstruct"))
	Set sc		= $$$qualifierParse("Compiler",.qSpec,.qstruct)
	if ($$$ISERR(sc)) {
		#;
		set status = $$$ERROR($$$GeneralError,"Internal error: Unable to find compile options for the class!")
		goto Catch
	}
	#; We can now see if we should be reporting the progress or not
	#; 
	Set progressReport = $$$qualifierGetValue(qstruct,"displaylog")
	#;
	#;
	MVP:progressReport !,"Processing MV projection...",!
	#; First we need to protect against a class that has no extent
	#; I.E. it does not extend %Persistent
	#;
	If '$$$SQLStorageIsDefault($Get($$$EXTtype($$$pEXT,classname))) {
		#;
		#; Check that we have a valid extent for the class that contains
		#; this projection.
		#;
		set status = $$$ERROR($$$GeneralError,"Cannot project '"_classname_"' as it does not extend class %Persistent")
		goto Catch
	}
	#;
	#; Ensure that the file name is configured to something meaningful
	#; 
	Set fileName = $$$comMemberKeyGet(classname,$$$cCLASSparameter,"MVFILENAME",$$$cPARAMdefault)
	Set:fileName="" fileName = classname
	MVP:progressReport "MV file name is '"_fileName_"'",!
	#;
	#;
	#; Work out the global name that the data is stored in. If we create the
	#; data file, then we will supply this to the MV CreateFile call.
	#; 
	set dataAddress = $$$EXTdataaddress($$$pEXT,classname)
	#;
	#; globalName should never be null - the persistent class wouldn't compile if it is.
	#; This is also based on default storage (%MV.Storage). If this is an SQL mapped class
	#; then we'll have to update this.
	#; 
	if dataAddress '= "" { 
		set globalName = $Get($$$EXTADDRbasereference($$$pEXT,classname,dataAddress))
		#; global name is returned with a namespace qualifier
		#; remove it if it is our namespace
		Set:$P(globalName,"""",2)=$namespace globalName = "^"_$P(globalName,"|",3) 
		#;
	} else { 
		set globalName = "" 
	}
	set data =  $Order($$$EXTMAPDATA($$$pEXT, classname, dataAddress, ""))
	if data '= "" {
		#;
		#; Pick up the property descriptions
		#; 
		set value = $$$EXTMAPDATAvalue($$$pEXT, classname ,dataAddress, data)
		#;
		#; Pick up the first property
		#; 
		set position = $Order($$$EXTPROPSLOT($$$pEXT,classname,value,""))
		#;
		#; Now to iterate all properties that have been assigned storage slots
		#; 
		while position '= "" {
			#;
			#; Pick up the property definition at the current slot position
			#; 
			Set element     = $$$EXTPROPSLOT($$$pEXT, classname, value, position)
			#;
			#; Pick up whether this is a collection and therefore multivalued or
			#; just a single valued attribute
			#; 
			Set serialType  = $Get($$$EXTPROPserialtype($$$pEXT,classname,element))
			if $Extract(serialType)="c" {
				#;
				#; Property is a collection and is therefore multivalued
				#; 
				set property   = $Get($$$EXTPROPSLOT($$$pEXT, classname, element, 1)) 
				#;
			} Else {
				set property    = element
			}
			#;
			#; Now we see if it was a real property with a definition in the class
			#; that we wish to project.
			#; 
			if $$$comMemberDefined(classname, $$$cCLASSinstancevar, property) {
				#;
				#; Start with a new property parameter list
				#; 
				kill propertyParams
				#;
				#; Pick up the property parameters 
				#; 
				Merge propertyParams=$$$comMemberKeyRaw(classname,$$$cCLASSproperty,property,$$$cPROPparameter)
				Set attrno = $Get(propertyParams("MVATTRIBUTE"))
				If attrno '="" {
					if attrno'=position {
					set status = $$$ERROR($$$GeneralError,"Property '"_property_"'. Storage slot "_position_" does not match MVATTRIBUTE "_attrno) 
					goto Catch
					}
				}
			}
			#;
			#; Move to the next slot (if any)
			#; 
			set position = $Order($$$EXTPROPSLOT($$$pEXT,classname,value,position))
		}
	}
	#;
	#; Before we do any MV operations - ensure that the workspace is setup for MV
	#; and MV is initialized
	#; 
	Do MVEnableInit^%SYS.MV()
	#; assume this is a new class or we have have MVREPOPULATE 
	Set populateDict=1
	#; Now we can see if we are able to open the file.
	#; If we can then we don't need to create it, but may need
	#; to clear the target dictionary
	#; 
	$$$MVOPEN(rc,mvFile,"",fileName,0)
	if (rc) {
		set status = $$$ERROR($$$GeneralError,"Error ("_rc_") trying to open MV file '"_fileName_"' projected from class '"_classname) 
		goto Catch 
	}
	set mvDict = $$OpenDict^%SYS.MV(fileName)
	if $isobject(mvDict) { 
		#;
		#; The dictionary was opened succcessfully, and was already
		#; in existance, hence we need to see if the projection requires
		#; us to clear the existing dictionary elements or just overwrite
		#; those that the class defines. This is because a user may keep
		#; lots of duplicate and utility definitions in the dictionary
		#; that they do not wish projected into SQL or XML or objects
		#; and so on but keep around for use from the MV shell
		#; 
		If '$$$comMemberKeyGet(classname,$$$cCLASSparameter,"MVREPOPULATE",$$$cPARAMdefault) {
			MVP:progressReport "MVREPOPULATE is False, skipping DICT update",!
			Set populateDict=0
		} elseif $$$comMemberKeyGet(classname,$$$cCLASSparameter,"MVCLEARDICT",$$$cPARAMdefault) {
			#;
			MVP:progressReport "Clearing existing MV dictionary - class is master DICT definition!",!
			Set rc=$zu(24,13,mvDict) ; Equiv: $$$MVCLEARFILE(rc,mvDict) 
		}
	}
	#; We need to do one thing before populating the dictionary and that is
	#; to configure the global to indicate whether there are indexes or not.
	#;
	Set haveIndexes=0   ; Assume no indexes
	#;
	#; Iterate the indexes
	#;
	Set index = $$$comMemberNext(classname,$$$cCLASSindex,"")
	While index '= "" {
		#;
		Set isidkey = $$$comMemberKeyGet(classname,$$$cCLASSindex,index,$$$cINDEXidkey)
		#;
		if ('isidkey) {
			#;
			Set haveIndexes=1
		} else {
			Set idKeyProp = $Piece($$$comSubMemberKeyGet(classname,$$$cCLASSindex,index,$$$cINDEXproperty,1,$$$cINDEXPROPproperty),".",1)
			Set systemassigned = +($$$comMemberKeyGet(classname,$$$cCLASSindex,index,$$$cINDEXsystemassigned))
		}
		#;
		#; Looks like that was the index for the ID, look for the next one
		#;
		Set index = $$$comMemberNext(classname,$$$cCLASSindex,index)
	}
	#;
	#; Update the index indicator in the global
	#;
	Set $LIST(@globalName,2) = haveIndexes
	#;
	#; If we have any indexes, then we need to work out the global that they are stored in
	#;
	Set firstI = $Order($$$EXTADDR($$$pEXT,classname,""))
	Set indexGlobal = ""
	While (firstI '= "") {
		#;
		
		Set indexAddr = $Get($$$EXTADDRindex($$$pEXT,classname,firstI))
		if (indexAddr '= "") {
			Set indexGlobal = $Get($$$EXTADDRbasereference($$$pEXT,classname,indexAddr))
			Set indexGlobal = $piece($piece(indexGlobal,"(",1),"^",2)
			Quit
		}
		Set firstI = $Order($$$EXTADDR($$$pEXT,classname,firstI))
	}
	Set $LIST(@globalName,3) = indexGlobal
	#;
	#; Assuming that the dictionary is open correctly at this point
	#; then we are ready to populate it with the D, A or S elements
	#; that consitute the dictionary as the MV query engine sees it.
	#; 
	if '$isobject(mvDict) {
		#;
		#; We were not able to open the dictionary for this file
		#; error out of the projection
		#; 
		Quit $$$ERROR($$$GeneralError,"Error opening dictionary file for class '"_classname_"', file: "_fileName) 
	}
	If populateDict {
		#;
		#; Write the D records for each property that is stored
		#; in the DATAADDRESS. 
		#; 
		#; Here we look at all defined properties of the class so long
		#; as they have parameters that are defined as being projected
		#; to the MV file (Parameter MVPROJECTED of the property is True).
		#; 
		#; Another assumption is that all properties are stored in a single node whose
		#; structure is $piece delimited by the character stored in $mvv(1), which is
		#; usually $c(254).
		#; 
		#; Pick up the external map data for traversal
		#; 
		MVP:progressReport "Scanning class property definitions for projected properties",!
		Set projectedCount=0
		Set assoctbl=0
		set data =  $Order($$$EXTMAPDATA($$$pEXT, classname, dataAddress, ""))
		if data '= "" {
			#;
			#; Pick up the property descriptions
			#; 
			set value = $$$EXTMAPDATAvalue($$$pEXT, classname ,dataAddress, data)
			#;
			#; Pick up the first property
			#; 
			set position = $Order($$$EXTPROPSLOT($$$pEXT,classname,value,""))
			#;
			#; Now to iterate all properties that have been assigned storage slots and see if we should
			#; project them to the MV DICT
			#; 
			while position '= "" {
				#;
				#; Pick up the property definition at the current slot position
				#; 
				Set element     = $$$EXTPROPSLOT($$$pEXT, classname, value, position)
				#;
				#; Pick up whether this is a collection and therefore multivalued or
				#; just a single valued attribute
				#; 
				Set serialType  = $Get($$$EXTPROPserialtype($$$pEXT,classname,element))
				if $Extract(serialType)="c" {
					#;
					#; Property is a collection and is therefore multivalued
					#; 
					set property   = $Get($$$EXTPROPSLOT($$$pEXT, classname, element, 1)) 
					set multiValue = "M" 
					#;
				} ElseIf serialType = "p" { 
					#;
					#; The slot is a property and is single valued
					#; 
					Set multiValue  = "S"
					set property    = element
					#;
				} Else {
					#;
					#; Not sure what else could be here but "p" or "c" so we assume
					#; that whatever it is, it is single valued :-)
					#; 
					Set multiValue  = "S"
					set property    = element
				}
				#;
				#; Now we see if it was a real property with a definition in the class
				#; that we wish to project.
				#; 
				if $$$comMemberDefined(classname, $$$cCLASSinstancevar, property) {
					#;
					#; Start with a new property parameter list
					#; 
					kill propertyParams
					#;
					#; Pick up the property parameters 
					#; 
					Merge propertyParams=$$$comMemberKeyRaw(classname,$$$cCLASSproperty,property,$$$cPROPparameter)
					#;
					#; see if this is a SQL Computed field
					#;
					Set sqlcomputed = $$$comMemberKeyGet(classname,$$$cCLASSproperty,property,$$$cPROPsqlcomputed)

					Set mvtype = $Get(propertyParams("MVTYPE"))
					If $E(mvtype) ="I" {
						set status = $$$ERROR($$$GeneralError,"Property '"_property_"'. Itypes must be defined as Calculated") 
						goto Catch
					}
					Set project = $Get(propertyParams("MVPROJECTED"),1)
					If project,'sqlcomputed {
						Set status=..genDictitem(classname,.property,.propertyParams,position,multiValue,progressReport,mvDict,.assoctbl)
						goto:'$$$ISOK(status) Catch
						Set projectedCount=projectedCount+1
					}
				}
				#;
				#; Move to the next slot (if any)
				#; 
				set position = $Order($$$EXTPROPSLOT($$$pEXT,classname,value,position))
			}
			#;
			#; Now iterate through all the defined properties to locate those that do not have storage assigned
			#; but we want to generate a dict item for
			MVP:progressReport "Scanning class property definitions for computed properties",!
			Set prop = $$$comMemberNext(classname,$$$cCLASSproperty,"")
			While prop '= "" {
				kill propertyParams
				#;
				#; Pick up the property parameters 
				#; 
				Merge propertyParams=$$$comMemberKeyRaw(classname,$$$cCLASSproperty,prop,$$$cPROPparameter)
				If prop=idKeyProp {
					Set status=..genDictitem(classname,.prop,.propertyParams,0,"S",progressReport,mvDict,.assoctbl)
					goto:'$$$ISOK(status) Catch
					Set projectedCount=projectedCount+1
					#; ensure there is an @ID element in the DICT
					$$$MVREAD(retCode,record,mvDict,"@ID",0,0)
					if retCode {
						Set propertyParams("MVNAME") ="@ID"
						Set status=..genDictitem(classname,.prop,.propertyParams,0,"S",progressReport,mvDict,.assoctbl)
						goto:'$$$ISOK(status) Catch
						Set projectedCount=projectedCount+1
					}
				}
				Set transient = '($$$comMemberKeyGet(classname,$$$cCLASSproperty,prop,$$$cPROPstorable))
				If transient && $Get(propertyParams("MVPROJECTED"),1) {
					Set mvitype = $Get(propertyParams("MVITYPE"))
					Set mvtype = $Get(propertyParams("MVTYPE"),"D")
					Set collection = $$$comMemberKeyGet(classname,$$$cCLASSproperty,prop,$$$cPROPcollection)
					set multiValue = $S(collection="list":"M",1:"S") 
					If $E(mvtype) ="I" {
						If mvitype="" {
							set status = $$$ERROR($$$GeneralError,"Property '"_prop_"' missing MVITYPE parameter") 
							goto Catch
						}
						Set status=..genDictitem(classname,.prop,.propertyParams,0,multiValue,progressReport,mvDict,.assoctbl)
						goto:'$$$ISOK(status) Catch
						Set projectedCount=projectedCount+1
					} elseIf mvitype '="" {
						set status = $$$ERROR($$$GeneralError,"Property '"_prop_"' specifies MVITYPE, MVTYPE must be specified as 'I'") 
						goto Catch 
					} elseIf (mvtype?1(1"A",1"a",1"S",1"s",1"x",1"X")) {
						Set status=..genDictitem(classname,.prop,.propertyParams,0,multiValue,progressReport,mvDict,.assoctbl)
						goto:'$$$ISOK(status) Catch
						Set projectedCount=projectedCount+1					
					}

				}
			Set prop = $$$comMemberNext(classname,$$$cCLASSproperty,prop)
			}
		}
		Set assocName=""
		For {
			Set assocName=$O(assoctbl(assocName))
			Quit:assocName=""
			Set assocEntry=""
			Set phrase=""
			For {
				Set assocEntry=$O(assoctbl(assocName,assocEntry))
				If assocEntry'="" {
					Set:phrase'="" phrase=phrase_" "
					Set phrase=phrase_assocEntry
				} else {
					MVP:progressReport "Defining Association Phrase '",assocName,"'",!
					$$$MVWRITE(retCode,mvDict,assocName, "PH"_$mvam_phrase,0,0)
					if retCode { 
						set status = $$$ERROR($$$GeneralError,"Error writing MV Dictionary record for association '"_assocName_"' to file: "_fileName) 
					}
					Quit
				}
			}
		}
			
	 	If ##class(%Dictionary.CompiledXData).%ExistsId(classname_"||MVAdditionalDictItems") {
			Set xdata=##class(%Dictionary.CompiledXData).%OpenId(classname_"||MVAdditionalDictItems",,.sc) If $$$ISERR(sc) Quit sc
		 	Set Status = ##class(%XML.TextReader).ParseStream(xdata.Data,.reader,,,,^%SYS("bindir")_"mvdictitems.xsd",1)
		 	Quit:$$$ISERR(Status) Status
			MVP:progressReport "Adding DICT items from XDATA",!
	 		while reader.Read() {
			// Read all elements within the document
				If reader.NodeType="element" {
					If reader.Name="DictItem"{
					Set record="",id="",delim=""
					If reader.MoveToAttributeName("Name") Set id=reader.Value
					}
				} ElseIf reader.NodeType="chars" {
					Set record=record_reader.Value
				} ElseIf reader.NodeType="endelement" {
					If reader.Name="DictItem"{				
						MVP:progressReport "Defining DICT element '",id,"'",!
						Set projectedCount=projectedCount+1
						$$$MVWRITE(retCode,mvDict,id, $e(record,1,*-1),0,0)
						if retCode { W "error writing item"_id_" to DICT" }
					} ElseIf reader.Name="Attr"{
						Set delim=$c(254)
						Set record=record_$c(254)
					}
				} ElseIf reader.NodeType="error" {
					w reader.Value,!
					Quit
				}
	 		}
		}
		#;
		#; We are all complete and return the result status to the class compiler
		#; 
		MVP:progressReport projectedCount," DICT entries were updated.",!
		MVP:progressReport "MV projection complete.",!
	}
	QUIT status
	#;
	#; --------------------------------------------------------------
Catch	set $Ztrap = ""
	#;
	#; If our status variable is an OK status, then we want to signal
	#; the Cache/COS error that happened instead.
	#; 
	if $$$ISOK(status) { 
		set status = $$$ERROR($$$ObjectScriptError,$ZE) 
		}
	quit status
}

ClassMethod genDictitem(classname As %String, ByRef property As %String, ByRef propertyParams, position, multiValue, progressReport, mvDict, ByRef assoctbl) As %Status [ Private ]
{
	$$$comMemberKeyGetLvar(dataType,classname,$$$cCLASSproperty,property,$$$cPROPtype)
	Do GetODBCColInfo^%ourODBC(dataType,.propertyParams,.propODBCTypeName,.propODBCType,.maxLen,.precision,.scale)
	#;
	#; We have an array of all the parameters now, so we can construct the
	#; particular dictionary element.
	#;
	#; JI - I am leaving this code here for now, as I can see what it is trying to do
	#; but do not know what the types are that it is checking. This may be a reasonable
	#; thing to do, but I cannot be sure here. For now we are going to revert to the 
	#; standard MV parameters, then gradually revisit each one of them to see if they
	#; are required or not.
	#; 
	if ((propODBCType>1) && (propODBCType<9)) || (propODBCType = -5) || (propODBCType = -6) { 
		set widthJust = precision _ "R" 
	} else { 
		set widthJust = precision _ "L" 
	}
	#; Build the required entry from the property parameters
	#; 
	set dType = $Get(propertyParams("MVTYPE"), "D")
	#;
	#; We have two styles, being the UniVerse/Prime D type and
	#; the Pick/Reality/jBASE/etc A and S types. The first attribute
	#; is always the type, which, if it is D, may be followed directly by
	#; a description string. The second attribute is always the attribute 
	#; number (which may be zero or some impossible value), there is also I
	#; which is an Itype.
	#; 
	Set record = dType
	
	Set id = $Get(propertyParams("MVNAME"))
	if (id = "") {
		#;
		#; No MV name override, so just the name of the property is used
		#; 
		Set id = property
	}
	#;
	#; We use the slot number if no other indication of the attribute
	#; number is given to us. We need to change the storage compiler
	#; to pick up this value (MVATTRIBUTE) if it is defined and use that
	#; to define the storage, even if the slot position is not the same.
	#; 
	set attrNo = propertyParams("MVATTRIBUTE")
	If attrNo=""{
		Set attrNo= position 
	}
	Set $mv(record, 2) = attrNo
	Set just = propertyParams("MVJUSTIFICATION")
	if (just = "") {
		#;
		#;Default justification is L
		Set just = "L"
	}
	#;
	If (dType?1(1"A",1"a",1"S",1"s",1"x",1"X")) {
		#; 
		#; Reality/Pick style
		#; 
		Set $mv(record, 3)  = propertyParams("MVHEADING")
		Set assoc = $Get(propertyParams("MVASSOCIATION"))
		If assoc'="" {
			Set $mv(record, 4) = assoc
			Set assoctbl(assoc,id)=1
		}
		Set $mv(record, 5)  = multiValue
		Set $mv(record, 7)  = propertyParams("MVTODISPLAY")
		Set $mv(record, 8)  = propertyParams("MVTOLOGICAL")
		Set $mv(record, 9)  = just
		Set $mv(record, 10) = $S(propertyParams("MVWIDTH")="":10,1:propertyParams("MVWIDTH"))
		#;
	} Else {
		#;
		#; UniVerse/Prime style
		#; If an Itype then we must replace the attribute number
		#; which instead contains the Itype code.
		#; 
		if ($Extract(dType,1) = "I") {
			#;
			Set $mv(record, 2)  = $Get(propertyParams("MVITYPE"))
		}
		#;
		#; Conversion code (LogicalToDisplay and Back) at attribute 3
		#;
		Set $mv(record, 3) = $Get(propertyParams("MVTODISPLAY"))
		#;
		#; Heading is always set, it defaults to the dictionary name 
		#; rather than being set to the property name explicitly
		#; 
		Set $mv(record, 4) = $Get(propertyParams("MVHEADING"))
		#;
		#; Reconstruct the formatting and justification code for sttr 5
		#;
		Set $mv(record, 5) = $S(propertyParams("MVWIDTH")="":10,1:propertyParams("MVWIDTH"))_just_$Get(propertyParams("MVFORMAT"))
		#;
		#; Multi/Single value indication
		#; 
		Set $mv(record, 6) = multiValue
		#;
		#; Association name at attribute 7
		#; 
		Set assoc = $Get(propertyParams("MVASSOCIATION"))
		If assoc'="" {
			Set $mv(record, 7) = assoc
			Set assoctbl(assoc,id)=1
		}
	}
	#;
	#; Now we can project this element in to the dictionary
	#; 
	MVP:progressReport "Defining DICT element '",id,"'",!
	$$$MVWRITE(retCode,mvDict,id, record,0,0)
	if retCode { 
		set status = $$$ERROR($$$GeneralError,"Error writing MV Dictionary record for property '"_classname_"::"_property_"' to file: "_fileName) 
		Quit status
	}
	quit $$$OK
}

/// This method is called by the Class Compiler whenever an associated 
/// class is either a) about to be recompiled, or b) about to be deleted.
/// <var>classname</var> contains the name of the associated class while 
/// <var>parameters</var> contains an array of the projection parameters 
/// subscripted by parameter name. <var>recompile</var> is true (1) if the
/// associated class is about to be recompiled.<BR>
/// Any errors reported by this method are reported by the Class Compiler but
/// do not effect class compilation in any way.
ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean) As %Status
{
		#; For now, we aren't removing projections.
		#; If this code is reenabled then the DeleteFile routine needs 
		#; some work to ensure it's properly deleting files
	quit $$$OK
	; set status = $$$OK
	; set fileName = $Get(parameters("FILENAME"))
	; if fileName = "" { set fileName = classname }
	; set rc = $$DeleteFile^%SYS.MV(fileName)
		#; Do we care if it failed? I guess only if it failed for reasons other than it doesn't exist.
	; if rc { set status = $$$ERROR($$$GeneralError,"Error deleting MV file for class '"_classname_"': "_fileName) }
	; QUIT status
}

}
