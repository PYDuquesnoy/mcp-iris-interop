/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.BPLJanitor Extends %Projection.AbstractProjection [ System = 4 ]
{

/// This method is called by the Class Compiler whenever an associated 
/// class is either a) about to be recompiled, or b) about to be deleted.
/// <var>classname</var> contains the name of the associated class while 
/// <var>parameters</var> contains an array of the projection parameters 
/// subscripted by parameter name.  Also the special parameter value
/// parameters("%qstruct") contains a merge of the qstruct array this projection is being
/// compiled with. <var>recompile</var> is true (1) if the
/// associated class is about to be recompiled. The <var>modified</var>
/// for an incremental compile will contain the comma separated list of methods that
/// were modified and will be blank for a full compiler.<BR>
/// Any errors reported by this method are reported by the Class Compiler but
/// do not effect class compilation in any way.
ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String) As %Status
{
    #; Don't run on the base class
    If classname'="Ens.BusinessProcessBPL" {
        If recompile=0 Do $System.OBJ.DeletePackage(classname,$get(parameters("%qstruct")))
    }
    QUIT $$$OK
}

}
