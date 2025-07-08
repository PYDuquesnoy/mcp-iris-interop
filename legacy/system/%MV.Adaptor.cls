/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %MV.Adaptor [ Abstract, CompileAfter = %MV.PropertyParameters, Not ProcedureBlock, PropertyClass = %MV.PropertyParameters, ServerOnly = 1, System = 4 ]
{

/// MVENABLED controls storage compiler and MV projection behavior. If MVENABLED is
/// not true then storage will not use mv storage by default and no MV projection will
/// be built. Generally, MVENABLED is true when inherited from %MV.Adaptor although some classes
/// that extend %MV.Adaptor might opt to override it.
/// 
Parameter MVENABLED = 1;

/// This is the name of the file in the multvalue account/namespace
/// where the class containing this projection should project itself.
/// The DICTionary of this file will be populated with the dictionary
/// elements described by the properties of the class according to their
/// types (A,D,S) and conversions , attribute 8, itype and so on.
/// 
Parameter MVFILENAME As STRING;

/// Set this parameter to True if a recompile of the class that contains
/// the projection should cause the DICT of the projected file to be cleared
/// before it is repopulated. This parameter has no effect if the parameter
/// REPOPULATE is set to False.
/// 
Parameter MVCLEARDICT As BOOLEAN = 0;

/// Set this parameter to True if the DICT of the file that this projection
/// models should be repopulated with the dictionary elements described by
/// the class, if that class is recompiled. The parameter CLEARDICT is only
/// considered if this parameter is set to True.
/// 
/// The effect of setting this parameter to True and CLEARDICT to False
/// (the default settings) is that any existing dictionary
/// elements that correspond to properties in the class containing this projection,
/// will be overwritten by definitions produced from the properties of the class.
/// Any existing entries in the DICTionary will be left in tact providing their
/// names do not conflict with the property names (or the paramaeter MVNAME of the
/// property if this is defined).
/// 
Parameter MVREPOPULATE As BOOLEAN = 1;

/// Set this parameter to True if the file that this projection represents
/// should be created via CREATE-FILE if it does not yet exist in the namespace
/// defined by the MVNAMESPACE parameter.
/// 
Parameter MVCREATE As BOOLEAN = 1;

/// Set this parameter to True to prevent the modification of this class by
/// the MultiValue Utilities: CREATE.INDEX, DELETE.INDEX and PROTOCLASS.
/// 
Parameter MVAUTOLOCK As BOOLEAN = 0;

Projection MVProjection As %Projection.MV;

Property %RECORD As %RawString [ Private, SqlComputeCode = { set {*}=##class({%%CLASSNAME}).%RECORDGetStored({%%ID})}, SqlComputed, Transient ];

ClassMethod %RECORDGetStored(id As %String) As %RawString [ CodeMode = generator ]
{
	set %code=0
	if ($$$comClassKeyGet(%class,$$$cCLASSclasstype) = $$$cCLASSCLASSTYPEPERSISTENT) {
		set defaultData = $Get($$$EXTdefaultdata($$$pEXT,%class))
		if defaultData '= "" {
			Set strStored = $Get($$$EXTPROPondisk($$$pEXT,%class,defaultData))
			If (strStored '= "") { Set %code="$Select(id'="""":"_strStored_",1:"""")", %codemode = $$$cMETHCODEMODEEXPRESSION }
			else  { Set %code="""""", %codemode = $$$cMETHCODEMODEEXPRESSION }
		}
		else  { Set %code="""""", %codemode = $$$cMETHCODEMODEEXPRESSION }
	}
	QUIT $$$OK
}

ClassMethod %GetMVIndex(indexName As %String) As %RawString [ CodeMode = generator ]
{
	set %code=0
	
	
	if ($$$comClassKeyGet(%class,$$$cCLASSclasstype) = $$$cCLASSCLASSTYPEPERSISTENT) {
		set defaultData = $Get($$$EXTdefaultdata($$$pEXT,%class))
		if defaultData '= "" {
			Set strStored = $Get($$$EXTPROPondisk($$$pEXT,%class,defaultData))
			If (strStored '= "") {
				Set idxname="",inames="",mvnames=""
				For {
					Set idxname = $$$comMemberNext(%class,$$$cCLASSindex,idxname)
					Quit:idxname=""
					Continue:$$$comMemberKeyGet(%class,$$$cCLASSindex,idxname,$$$cINDEXtype)'="index"
					$$$comSubMemberKeyGetLvar(property,%class,$$$cCLASSindex,idxname,$$$cINDEXproperty,1,$$$cINDEXPROPproperty)
					$$$comMemberArrayGetLvar(mvname,%class,$$$cCLASSproperty,$P(property,"("),$$$cPROPparameter,"MVNAME")
					Set:inames'="" inames=inames_","
					Set inames = inames_""""_idxname_""""
					Set:mvnames'="" mvnames=mvnames_","
					Set mvnames = mvnames_""""_mvname_""""
				}
				if inames'="" {
					$$$GENERATE("    New indexNamesList,indexMVNames,idxNo")
					$$$GENERATE("    Set indexNamesList = $lb("_inames_")")
					$$$GENERATE("    Quit:$lf(indexNamesList,indexName) indexName")
					$$$GENERATE("    Set indexMVNames = $lb("_mvnames_")")
					$$$GENERATE("    Set idxNo = $lf(indexMVNames,indexName)")
					$$$GENERATE("    Quit:idxNo=0 """"")
					$$$GENERATE("    Quit $Lg(indexNamesList,idxNo)")
				} else { Set %code="""""", %codemode = $$$cMETHCODEMODEEXPRESSION }
			}
			else  { Set %code="""""", %codemode = $$$cMETHCODEMODEEXPRESSION }
		}
		else  { Set %code="""""", %codemode = $$$cMETHCODEMODEEXPRESSION }
	}
	QUIT $$$OK
}

}
