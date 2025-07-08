/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The GlobalIdentifier class implements the %%GUID override property. This class is not for
/// general use. It is automatically included in the super class list of a persistent class that
/// is GUIDENABLED.
Class %Library.GlobalIdentifier [ Abstract, ClassType = persistent, NoExtent, System = 3 ]
{

/// This is the GUID value assigned to the object. It can only be changed prior to insert or through the
/// GUID assignment utility methods.
Property "%%GUID" As %Library.RawString [ Internal, Private, ServerOnly = 1, SqlComputeCode = { s {*}=$Select($Get(%oper)="INSERT":$Get({%GUID}),{%%ID}="":"",1:$Get(^OBJ.GUID(1,$$$oidCompose({%%ID},{%%CLASSNAMEQ})))) }, SqlComputed, SqlFieldName = %GUID, Transient ];

Method "%%GUIDGet"() [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	$$$GENERATE($Char(9)_"If i%""%%GUID"" = """" { Set ..""%%GUID""=..""%%GUIDCompute""("_$Select($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT:"$$$idCurrent",1:"""""")_",i%""%%GUID"") } Quit i%""%%GUID""")
}

/// If a persistent class is GUIDENABLED then this method can be called to override the default GUID assignment.
/// This method accepts a guid value and returns the override value currently assigned. The return value will only
/// differ from the supplied value if the override is unsuccessful. It is only valid to call this method on a new object.
/// The guid value passed to this method is not validated. It is up to the user to make sure the guid is properly formed.
/// The guid assignment does not actually occur until the object is saved. If the object has already been assigned a GUID
/// or if the GUID override value has already been assigned to another object then the GUID override value will be discarded.
/// The check for GUID value uniqueness and a GUID value previously assigned is done only at the time the object is saved and is
/// not performed by this method.
Method %OverrideGuidAssignment(pGUID As %Library.RawString) As %Library.RawString
{
	set i%"%%GUID" = pGUID
	quit i%"%%GUID"
}

}
