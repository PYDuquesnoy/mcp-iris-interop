/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.Binding.NET Extends %RegisteredObject
{

ClassMethod BuildMetaInfo(classNameList As %List, qspec, pMode, status As %Status) As %List
{
	// convert classname list input to global
	k classes
	for ii=1:1:$listlength(classNameList)
	{
		s classes($list(classNameList, ii))=""
	}
	
	// build meta info
	// TODO: cases that use "gen" instead of "genwd"
	set status=$$BuildMetaInfo^%occMetaInfo(.pOutputData,.classes,qspec,,pMode)
	// quit if there is an error
	quit:$$$ISERR(status) ""
	
	// write out the "meta" nodes for each class
	try {
		set metaInfo = $lb(1)
		set class="" for {
			set class=$o(pOutputData(class)) q:class=""
			for i=1:1:pOutputData(class) {
				s metaInfo = metaInfo_pOutputData(class,i)
			}
		}
	} catch e {
		if (e.Name = "<MAXSTRING>") {
			// populate a global instead of a $list to avoid maxstring error
			kill ^IRIS.Temp.Bindings($j)
			$$$AddTempNode(^IRIS.Temp.Bindings($j))
			merge ^IRIS.Temp.Bindings($j) =pOutputData
		}
		throw e
	}

	quit metaInfo
}

ClassMethod GetClassesDependencies(classNameList As %List, inclSubCls As %Boolean, status As %Status) As %List
{
	// convert classname list input to global
	k node
	for ii=1:1:$listlength(classNameList)
	{
		s node($list(classNameList, ii))=""
	}
	
	s status = $$IncludeClasses^%occLGUtil(.node, .classes, 1, 1, inclSubCls)
	q:$$$ISERR(status) ""
 
 	s classDeps = ""
 	s name = $o(classes(""))
 	while (name '= "")
 	{
	 	s $list(classDeps, *+1) = name
	 	s name = $o(classes(name))
 	}
 	
 	quit classDeps
}

}
