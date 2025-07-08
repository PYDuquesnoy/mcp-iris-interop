/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This abstract class defines the Projection interface which is implemented
/// by one of the various subclasses of this class.<BR>
/// A class definition may include one or more Projection definitions; each one 
/// of which refers to a specific Projection class (a subclass of this class). 
/// The Projection interface defines methods that are invoked by the 
/// Class Compiler at certain points within a class compilation. Specifically,
/// there is a method, <METHOD>CreateProjection</METHOD> that is called when a 
/// class has been compiled, and another, <METHOD>RemoveProjection</METHOD> that is called 
/// when a class is about to be recompiled or deleted.<BR>
/// The expected use of a Projection class is to provide a way to automatically 
/// generate associated files (such as those used by the Java Binding) 
/// whenever a class is compiled.
/// If the projection creates globals or other items that need to be packaged with
/// this class in the event we wish to move this class in a deployment package then
/// add these items in the <method>AddToManifest</method> call.
Class %Projection.AbstractProjection Extends %Library.Base [ Abstract, System = 1 ]
{

/// If true then do not create this projection using the class compiler multicompile
/// jobs but create it in the main process. Used to allow projections that do not function
/// in the multicompile environement to disable this feature.
Parameter DisableMulticompile As BOOLEAN = 0;

/// This method is called by the Class Compiler whenever an associated 
/// class has finished compiling. <var>classname</var> contains the name of 
/// the associated class while <var>parameters</var> contains an array of the 
/// projection parameters subscripted by parameter name. Also the special parameter value
/// parameters("%qstruct") contains a merge of the qstruct array this projection is being
/// compiled with. The <var>modified</var> is always blank.<br>
/// Any errors reported by this method are reported by the Class Compiler but
/// do not effect class compilation in any way.
ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
	QUIT $$$OK
}

/// This is called as close to the end of the compile as possible so it can do cleanup work or more
/// usefully it can avoid doing work multiple times. For example if class User.A would modify MyFile.txt
/// normally in the <method>CreateProjection</method> method and class User.B would normally modify the same
/// file when it is compiled and you compile both these classes together then you may end up generating
/// MyFile.txt twice and so doing duplicate work. By changing this so <method>CreateProjection</method> just
/// adds 'MyFile.txt' to the queue of things to be done and then processing this list in this method, making
/// sure to only do each piece of work once, you can process the fully up to date state of User.A and User.B
/// to create the correct MyFile.txt just once.<p>
/// Note that this method will be called just once per projection subclass, so <method>CreateProjection</method>
/// may be called multiple times for each class with this projection type, but this method will only be called
/// once at the end of the compile.
ClassMethod EndCompile(qstruct) As %Status
{
	Quit $$$OK
}

/// This method is called by the Class Compiler whenever an associated 
/// class is either a) about to be recompiled, or b) about to be deleted.
/// <var>classname</var> contains the name of the associated class while 
/// <var>parameters</var> contains an array of the projection parameters 
/// subscripted by parameter name.  Also the special parameter value
/// parameters("%qstruct") contains a merge of the qstruct array this projection is being
/// compiled with. <var>recompile</var> is true (1) if the
/// associated class is about to be recompiled. The <var>modified</var> is always blank.<br>
/// Any errors reported by this method are reported by the Class Compiler but
/// do not effect class compilation in any way.
ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
	QUIT $$$OK
}

/// This is a helper method for implementors of projection classes. This
/// method provides a mechanism for to make sure additional classes are compiled.
/// Typically these would be new classes created by the projection itself.<br>
/// You should not directly invoke the Class Compiler 
/// from a projection method, instead, invoke this method to request that the 
/// class <var>classname</var> be placed in a queue of classes that will be compiled 
/// at the end of the current compilation operation.
ClassMethod QueueClass(classname)
{
	Do QueueClass^%occCompile(classname)
}

/// Can be called to remove a queued class from the queued class list created with
/// <method>QueueClass</method>
ClassMethod RemoveFromQueue(classname)
{
	Do RemoveFromQueue^%occCompile(classname)
}

ClassMethod SetQueueFlag(flag)
{
	Do SetQueueFlag^%occCompile(flag)
}

ClassMethod getDefaultParam(parameters, type, paramname, default) As %String
{
	Set value=$get(parameters(paramname))
	If value="" Set value=$get(^%SYS("projections",$namespace,type,paramname))
	If value="" Set value=$get(default)
	QUIT value
}

ClassMethod getROOTDIR(parameters, type) As %String
{
	Set rootdir=..getDefaultParam(.parameters,type,"ROOTDIR")
	If rootdir="" {
		set rootdir=$system.Util.DataDirectory()
		set rootdir=##class(%File).SubDirectoryName(rootdir,"devuser")
		set rootdir=##class(%File).SubDirectoryName(rootdir,type)
		set rootdir=##class(%File).SubDirectoryName(rootdir,$namespace)
	}
	QUIT rootdir
}

/// Call this helper method to add a component to the class manifest. For example if the projection of
/// a class creates ^gbl(classname) nodes that describe some data about the projected class then you
/// should add 'gbl("classname").gbl' to the manifest so if we create a deployment package of this class
/// we will also include any items in the manifest automatically.
ClassMethod AddToManifest(classname, item) As %Status
{
	$$$comClassArraySet(classname,$$$cCLASSmanifest,item,"")
	Quit $$$OK
}

/// Called when you remove a projected item to remove this from the manifest.
ClassMethod RemoveFromManifest(classname, item) As %Status
{
	$$$comClassArrayKill(classname,$$$cCLASSmanifest,item)
	Quit $$$OK
}

}
