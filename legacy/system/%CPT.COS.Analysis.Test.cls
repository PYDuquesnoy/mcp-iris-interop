/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occCPT, %occCPTCOSanalysis, %occCPTHPT)

Class %CPT.COS.Analysis.Test [ Abstract ]
{

ClassMethod Test(INTRoutineName As %String, EntryPoints As %List) [ Internal ]
{
	#Dim bdot,bdotreference,ddot,ddotreference,dotpath,gdot,gdotreference,sdot,sdotreference,sc,edot,edotreference
	#Dim blockdictionary As %CPT.COS.Analysis.BlockDictionary
	#Dim symboltable As %CPT.COS.Analysis.SSA.SymbolTable
	#Dim err As %Exception.AbstractException
	#Dim graph As %CPT.COS.Analysis.Graph
	
	If $Get(INTRoutineName)="" {Write "Test: routine name argument is mandatory",! Quit}
	If '##class(%Routine).Exists(INTRoutineName) {Write "Test: routine ",INTRoutineName," not found",! Quit}

	Write "Analysing ",INTRoutineName,!
	
	// get entry points
	If $Get(EntryPoints)="" {
		Set EntryPoints=##class(%CPT.COS.Analysis.API).GetINTEntryPoints(INTRoutineName)
		If EntryPoints="" {Write "Test: entry-points argument is mandatory unless the routine has a %EXTERNAL line",! Quit}
	}
	$$$CPTCAREPORT("N","Entry points: "_$ListToString(EntryPoints))
	
	// open the routine
	Set source=##class(%Routine).%OpenId(INTRoutineName_".INT") If '$IsObject(source) {Set sc=%objlasterror Goto err}
		
	Set %BREAK=""
	
	// make basic blocks
	Set sc=##class(%CPT.COS.Analysis.API).MakeBasicBlocks(INTRoutineName,source,EntryPoints,.blockdictionary,.symboltable) If $$$ISERR(sc) {Goto err}
			
	// maybe show statistics
	If $$$CPTCAREPORTIF("N") {
		Do ..ShowStatistics(blockdictionary.GetTreeIndex())
	}
	
	// make graphs
	Set dotpath=$$$GETCONFIG(0,"DOTPATH") // if this is empty the current directory will be used
	Set sc=..TestRenderDigraphs(dotpath,INTRoutineName,blockdictionary,symboltable,.bdot,.gdot,.ddot,.sdot,.edot) If $$$ISERR(sc) {Goto err}

	// compare with reference files (if any)
	$$$HPTASSERT((bdot'="") && (gdot'="") && (ddot'="")) // we selected all the graphs
	Set bdotreference=##class(%CPT.COS.Analysis.API).DotReferenceFilePath(dotpath,INTRoutineName,"B")
	Set gdotreference=##class(%CPT.COS.Analysis.API).DotReferenceFilePath(dotpath,INTRoutineName,"G")
	Set ddotreference=##class(%CPT.COS.Analysis.API).DotReferenceFilePath(dotpath,INTRoutineName,"D")
	Set sdotreference=##class(%CPT.COS.Analysis.API).DotReferenceFilePath(dotpath,INTRoutineName,"S")
	Set edotreference=##class(%CPT.COS.Analysis.API).DotReferenceFilePath(dotpath,INTRoutineName,"E")
	Do ..CompareDot(bdot,bdotreference)
	Do ..CompareDot(gdot,gdotreference)
	Do ..CompareDot(ddot,ddotreference)
	Do ..CompareDot(sdot,sdotreference)
	Do ..CompareDot(edot,edotreference)
	
	Quit
	
err
	Do $System.OBJ.DisplayError(sc)
	BREAK
}

ClassMethod TestRenderDigraphs(DotPath As %String, ProgramName As %String, BlockDictionary As %CPT.COS.Analysis.BlockDictionary, SymbolTable As %CPT.COS.Analysis.SSA.SymbolTable, Output BDot, Output GDot, Output DDot, Output SDot, Output EDot) As %Status [ Internal, Private ]
{
	#Dim sc
	
	New %CPTCONFIGTEMP
	Merge %CPTCONFIGTEMP=%CPTCONFIG
	New %CPTCONFIG
	Merge %CPTCONFIG=%CPTCONFIGTEMP
	Set %CPTCONFIG("COS","CAREPORTCONFIG")=$$SetGConfig($Get(%CPTCONFIG("COS","CAREPORTCONFIG")))
	
	// make graphs
	Set BDot=##class(%CPT.COS.Analysis.API).DotFilePath(DotPath,ProgramName,"B")
	Set GDot=##class(%CPT.COS.Analysis.API).DotFilePath(DotPath,ProgramName,"G")
	Set DDot=##class(%CPT.COS.Analysis.API).DotFilePath(DotPath,ProgramName,"D")
	Set SDot=##class(%CPT.COS.Analysis.API).DotFilePath(DotPath,ProgramName,"S")
	Set EDot=##class(%CPT.COS.Analysis.API).DotFilePath(DotPath,ProgramName,"E")
	Set sc=##class(%CPT.COS.Analysis.API).RenderDigraphs(ProgramName,BlockDictionary,SymbolTable,BDot,GDot,DDot,SDot,EDot) If $$$ISERR(sc) {Quit sc}
	
	Quit $$$OK
	
SetGConfig(str)
	#Dim str,str1
	Set str1=","_str_","
	If str1'[",GEC," {Set str=str_",GEC"}
	If str1'[",GNC," {Set str=str_",GNC"}
	Quit str
}

ClassMethod CompareDot(Dot, ReferenceFile As %String) [ Internal, Private ]
{
	#Dim err
	
	Set err=##class(%CPT.COS.Analysis.Util).CompareReferenceIfAny(Dot,ReferenceFile)
	If err="" {
		Write "Matched reference file: "_Dot,!
	}
	Else {
		Write err,!
	}
}

ClassMethod ShowStatistics(TreeIndex As %Integer) [ Internal, Private ]
{
	#Dim treenodecount
	
	// in non HPT-debug mode the langnodes will have already been deleted by MakeBasicBlocks
	If $Data($$$CPTLANGNODESCOUNT)#10 {
		
		// assumes contiguous parse tree node sequence
		Set treenodecount=$Order($$$CPTNODE(TreeIndex,""),-1)
		Write "Tree has ",treenodecount," nodes, converted ",$$$CPTLANGNODESCOUNT," to langnodes (",$Piece(($$$CPTLANGNODESCOUNT/treenodecount)*100,"."),"%)",!
	}
}

}
