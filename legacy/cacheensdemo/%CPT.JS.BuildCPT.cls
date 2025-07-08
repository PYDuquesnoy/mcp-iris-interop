/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occCPT, %occCPTJSruntime, %occCPTmeasure)

Class %CPT.JS.BuildCPT Extends %ZEN.proxyObjectEnumeratee [ System = 4 ]
{

Property Stack As list Of %CPT.JS.Node.Abstract [ Internal, Private ];

Property Editor As %CPT.Tree.Editor [ Internal, Private ];

/// "" => no node tracing
/// "T" => trace only
/// "B" => both 
Property TraceNode As %String [ Internal, Private ];

ClassMethod Build(SourceStream As %Stream.Object, Tree As %ZEN.proxyObject, TraceNode As %String = "", TraceEnum As %String = "") As %Status [ Internal ]
{
	#Dim sc
	#Dim client As %ZEN.proxyObjectEnumeratee
	
	// build CPT metadata for JS
	Set sc=##class(%CPT.CalloutCommon).BuildAllIndices("JS") If $$$ISERR(sc) {Quit sc}
	
	// enumerate the parse tree
	Set client=..Enumeratee(SourceStream,TraceNode,TraceEnum)
	Set sc=Tree.Enumerate(client) If $$$ISERR(sc) {Quit sc}
	
	// complete missing extents
	Do ##class(%CPT.Tree.Extents).CompleteExtents($$$CPTLASTTREE)
	
	Quit $$$OK
}

Method %OnNew(TraceNode As %String = "", SourceStream As %Stream.Object) As %Status
{
	#Dim treeindex
	
	Set treeindex=##class(%CPT.CalloutCommon).NextTreeIndex()
	Set $$$CPT(treeindex)=$ListBuild($Horolog,"1","","JS")

	// write source to private global
	Do ##class(%CPT.CalloutCommon).SourceToPrivateGlobal(SourceStream,treeindex)

	Kill %objlasterror Set ..Editor=##class(%CPT.Tree.Editor).%New(treeindex) If '$IsObject(..Editor) {Quit %objlasterror}
	
	Set ..TraceNode=TraceNode
	
	Quit $$$OK
}

Method PropertyName(Prop As %String) [ Internal ]
{
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	Do ..WriteProp(..MaybeFixName(..MaybeUnquote(Prop)))
}

Method BeginNested() [ Internal ]
{
	#Dim currentnode
	
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	Set currentnode=..Top()
	Do ..Push(..NewNodeObject(currentnode))
}

Method EndNested() [ Internal ]
{
	#Dim endingnode,secondnode

	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	If ..Stack.Count()'=0 {
		
		Set endingnode=..Top()
		BREAK:'$IsObject(endingnode)
		Do endingnode.Finalize()
		Do ..Pop()
		
		If ..Stack.Count()'=0 {
			Set secondnode=..Top()
			BREAK:'$IsObject(secondnode)
			Do secondnode.Child(endingnode)
		}
	}
}

/// NOTE: We always expect contiguous lists so we don't bother to implement the ListIndex callback
Method ListIndex(Index) [ Internal ]
{
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD
}

Method BeginList() [ Internal ]
{
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	Do ..Top().FieldIsList()
}

Method EndList() [ Internal ]
{
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD
}

Method CacheObject(Obj As %RegisteredObject) [ Internal ]
{
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	If $$$JSISNULL(Obj) {
		Do ..Top().Child(##class(%CPT.JS.Node.CPT).NullNode(..Editor))
	}
	Else {
		$$$CPTTHROW($Classname()_": CacheObject - expected 'null', got "_$$$JSTOSTRING(Obj))
	}
}

Method Simple(Item) [ Internal ]
{
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	Do ..Top().Annotation(Item)
}

Method MaybeUnquote(Prop As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$Select(Prop?1""""1A1.AN1"""":$Extract(Prop,2,*-1),1:Prop)
}

Method Top() As %CPT.JS.Node.Abstract [ CodeMode = expression, Internal, Private ]
{
..Stack.GetAt(..Stack.Count())
}

Method Push(Node As %CPT.JS.Node.Abstract) [ Internal, Private ]
{
	#Dim sc
		
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD
	
	Set sc=..Stack.Insert(Node) If $$$ISERR(sc) {$$$ThrowStatus(sc)}
}

Method Pop() [ Internal, Private ]
{
	#Dim sc

	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	Do ..Stack.RemoveAt(..Stack.Count())
}

Method WriteProp(Prop As %String) [ Internal, Private ]
{
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	Do ..Top().FieldName(..FixName(Prop))
}

ClassMethod MaybeFixName(Name As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$Select(Name?1A.AN:..FixName(Name),1:Name)
}

ClassMethod FixName(Name As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$ZCvt($Extract(Name),"U")_$Extract(Name,2,*)
}

ClassMethod Enumeratee(SourceStream As %Stream.Object, TraceNode As %String, TraceEnum As %String = "") As %ZEN.proxyObjectEnumeratee [ Internal, Private ]
{
	#Dim client
		
	Kill %objlasterror
	Set client=$Case(TraceEnum,
		"":..%New(TraceNode,SourceStream),
		"T":##class(%CPT.JS.TracingEnumeratee).%New(),
		"B":##class(%CPT.JS.ComposeEnumeratees).%New(##class(%CPT.JS.TracingEnumeratee).%New(),..%New(TraceNode,SourceStream))
		)
	If '$IsObject(client) {$$$ThrowStatus(%objlasterror)}
	
	Quit client
}

Method NewNodeObject(CurrentNode As %CPT.JS.Node.Abstract) As %CPT.JS.Node.Abstract [ Internal, Private ]
{
	#Dim initiallevel,client
	
	$$$COUNTMETHOD
	
	$$$TIMEMETHOD

	Set initiallevel=$Select($IsObject(CurrentNode) && ($Classname(CurrentNode)[".Tracing"):CurrentNode.Level,1:0)
	
	Kill %objlasterror
	Set client=$Case(..TraceNode,
		"":##class(%CPT.JS.Node.CPT).%New(..Editor),
		"T":##class(%CPT.JS.Node.Tracing).%New(initiallevel),
		"B":##class(%CPT.JS.Node.Compose).%New(##class(%CPT.JS.Node.Tracing).%New(initiallevel),##class(%CPT.JS.Node.CPT).%New(..Editor))
		)
	If '$IsObject(client) {$$$ThrowStatus(%objlasterror)}
	
	Quit client
}

}
