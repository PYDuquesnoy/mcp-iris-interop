/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %KNNIndexInclude

IncludeGenerator %KNNIndexInclude

/// Hierarchical Navigable Small World (HNSW), implemented based on https://arxiv.org/abs/1603.09320
Class %SQL.Index.HNSW Extends %Library.FunctionalIndex [ System = 2 ]
{

Parameter ProjectMap = 1;

/// The number of bi-directional links created for every new element during construction
Parameter M As INTEGER = 16;

Parameter efConstruction As Integer = 64;

Parameter Distance As String = "Cosine";

ClassMethod InsertIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
	// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {

		Set classname = %classname,indexname = %member

		// get the sql name of the property of this functional index
		Set property = $$$comMemberKeyGet(%classname,$$$cCLASSindex,%member,$$$cINDEXproperties)
		Set dim = $$$comMemberArrayGet(%classname,$$$cCLASSproperty,property,$$$cPROPparameter,"LEN")

		// get the sql name of the data fields of this functional index
		Set data = $$$comMemberKeyGet(%classname,$$$cCLASSindex,%member,$$$cINDEXdata)

		// use an instance of %SQL.VectorIndex.HNSWIndexer to adding the point to the graphical index
		$$$GENERATE($c(9)_"set oref = ##class(%SQL.VectorIndex.HNSWIndexer).%New("_$$$AddQuote(classname)_","_$$$AddQuote(indexname)_","_$$$AddQuote(%parameter("Distance"))_","_$$$AddQuote(property)_","_$$$AddQuote(dim)_","_$$$AddQuote(data)_")")
		$$$GENERATE($c(9)_"Set oref.M = "_%parameter("M"))
		$$$GENERATE($c(9)_"Set oref.mL = 1/$ZLN("_%parameter("M")_")")
		$$$GENERATE($c(9)_"Set oref.efConstruction = "_$s(%parameter("efConstruction")>0:%parameter("efConstruction"),1:3*dim))
		$$$GENERATE($c(9)_"Do oref.Insert(pID, .pArg, .status)")
		$$$GENERATE($c(9)_"If $$$ISERR(status) throw status")
	}
	quit $$$OK
}

/// This method is invoked when an existing instance of a class is updated.
ClassMethod UpdateIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
		Set classname = %classname,indexname = %member

		// get the sql name of the property of this functional index
		Set property = $$$comMemberKeyGet(%classname,$$$cCLASSindex,%member,$$$cINDEXproperties)
		Set dim = $$$comMemberArrayGet(%classname,$$$cCLASSproperty,property,$$$cPROPparameter,"LEN")

		// get the sql name of the data fields of this functional index
		Set data = $$$comMemberKeyGet(%classname,$$$cCLASSindex,%member,$$$cINDEXdata)

		// use an instance of %SQL.VectorIndex.HNSWIndexer to adding the point to the graphical index
		$$$GENERATE($c(9)_"set oref = ##class(%SQL.VectorIndex.HNSWIndexer).%New("_$$$AddQuote(classname)_","_$$$AddQuote(indexname)_","_$$$AddQuote(%parameter("Distance"))_","_$$$AddQuote(property)_","_$$$AddQuote(dim)_","_$$$AddQuote(data)_")")
		$$$GENERATE($c(9)_"Set oref.M = "_%parameter("M"))
		$$$GENERATE($c(9)_"Set oref.efConstruction = "_$s(%parameter("efConstruction")>0:%parameter("efConstruction"),1:3*dim))

		$$$GENERATE($c(9)_"do oref.Update(pID, .pArg)")
	}
	quit $$$OK
}

/// This method is invoked when an existing instance of a class is deleted.
ClassMethod DeleteIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
		Set classname = %classname, indexname = %member
		$$$GENERATE($c(9)_"set oref = ##class(%SQL.VectorIndex.HNSWIndexer).%New("_$$$AddQuote(classname)_","_$$$AddQuote(indexname)_","_$$$AddQuote(%parameter("Distance"))_")")
		$$$GENERATE($c(9)_"do oref.Delete(pID, .pArg)")
	}
	quit $$$OK
}

ClassMethod PurgeIndex() [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {

		Set classname = %classname, indexname = %member

		$$$GENERATE($c(9)_"set oref = ##class(%SQL.VectorIndex.HNSWIndexer).%New("_$$$AddQuote(classname)_","_$$$AddQuote(indexname)_","_$$$AddQuote(%parameter("Distance"))_")")
		$$$GENERATE($c(9)_"do oref.Purge()")

	}
	quit $$$OK
}

ClassMethod SortBeginIndex() [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
		$$$GENERATE(" Return")
			// Generate specific code for <index>SortBeginIndex here
	}
	quit $$$OK
}

ClassMethod SortEndIndex(pCommit As %Integer = 1) [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
		$$$GENERATE(" Return")
			// Generate specific code for <index>SortBeginIndex here
	}
	quit $$$OK
}

/// This method is called by the parallel index build to initialize an index segment when constructing
/// index entries for one segment of the extent. Parallel index builds typically construct indexes in memory
/// for segments of 64k instances/rows.
ClassMethod SegmentInitialize(ByRef pIndexBuffer As %RawString, pStartID As %RawString, pEndID As %RawString)
{
	quit 1
}

ClassMethod SegmentInsert(ByRef pIndexBuffer As %RawString, pID As %RawString, pArg... As %Binary) [ CodeMode = generator ]
{
	$$$GENERATE($Char(9)_"do .."_$$$QN(%member_"InsertIndex")_"(pID, pArg...)")
}

}
