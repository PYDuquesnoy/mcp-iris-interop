/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Project the XData 'menu' block to the menu table
Class %Studio.Extension.Projection Extends %Projection.AbstractProjection [ System = 2 ]
{

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String) As %Status
{
	Set sc=$$$OK
	#; Remove any existing data
	If ##class(%Studio.Extension.MenuBase).%ExistsId(classname) Do ##class(%Studio.Extension.MenuBase).%DeleteId(classname)
	#; If no XData block called 'Menu' then nothing to do
	If '##class(%Dictionary.CompiledXData).%ExistsId(classname_"||Menu") Quit $$$OK
	Set xdata=##class(%Dictionary.CompiledXData).%OpenId(classname_"||Menu",,.sc) If $$$ISERR(sc) Quit sc
	Set reader = ##class(%XML.Reader).%New()
	Set sc=reader.OpenStream(xdata.Data) If $$$ISERR(sc) Quit sc
	Do reader.Correlate("Menu","%Studio.Extension.Menu")
	Set base=##class(%Studio.Extension.MenuBase).%New()
	Set base.Name=classname
	While reader.Next(.menu,.sc) {
		If $$$ISERR(sc) Quit
		Set menu.MenuBase=base
	}
	If $$$ISERR(sc) Quit sc
	Set sc=base.%Save()
	If $$$ISERR(sc) Quit sc
	Quit ..AddToManifest(classname,$name(^oddStudioMenu(classname))_".gbl")
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
	#; Remove the menus for this class
	If ##class(%Studio.Extension.MenuBase).%ExistsId(classname) Do ##class(%Studio.Extension.MenuBase).%DeleteId(classname)
	Quit $$$OK
}

}
