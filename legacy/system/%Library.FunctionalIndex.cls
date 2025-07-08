/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <h1>Functional Indexing</h1>
/// <h2>Overview</h2>
/// <p>
/// An index is a structure maintained by a persistent class that is intended to be used to optimize certain queries 
/// and other functions. objects supports three primary types of indexes - regular, bitmap and key structures. 
/// The index type is defined by two index keywords, TYPE and EXTENT.
/// It is also possible to declare a type class for an index. This index type class is expected to implement the index 
/// type class interface as defined by this class. The classtype of the index type class is expected to be INDEX. 
/// </p>
/// <p>
/// Functional Indexing is the feature in InterSystems IRIS Objects that allows a user to implement a class that maintains an 
/// index structure and a function that can be used by SQL to resolve certain SQL query operators. A Functional Index 
/// class must implement two interfaces. The first interface is the index filing interface, the second is the query interface 
/// used by SQL.
/// </p>
/// <h2>Index Filing Interface</h2>
/// <p>
/// The Index Filing Interface consists of six methods. The three methods that implement instance filing, <method>InsertIndex</method>, 
/// <method>UpdateIndex</method>, and <method>DeleteIndex</method> accept a formal argument corresponding to the ID of the 
/// object (ROWID of the row) being filed and a variable number of arguments corresponding to the indexed properties and 
/// clustered data properties. The UpdateIndex method accepts two sets of indexed properties as arguments, the first set corresponds to the new 
/// indexed property values and the second the existing set of indexed property values. All arguments other than the ID are 
/// accessed using the formal argument pArg with a subscript corresponding to the actual argument's position.
/// For example, the following index:
/// <example>
/// index x1F on (Name, DOB, Home_City) as User.MyIndexClass [ data=(Name,BirthPlace)];
/// </example>
/// will result in Name passed as pArg(1), DOB passed as pArg(2) and Home_City passed as pArg(3). 
/// For InsertIndex, the data values corresponding to Name and BirthPlace are passed as pArg(4) and pArg(5) respectively. 
/// Keep in mind that any index on a persistent class that is not final will cause the %%CLASSNAME property to be implicitly 
/// clustered as the first property. If that is the case in the above example, %%CLASSNAME becomes pArg(4) and the defined 
/// properties will be pArg(5) and pArg(6) respectively. For UpdateIndex, the arguments 4, 5, and 6 will correspond to 
/// the existing values of Name, DOB, and Home_City and the arguments 7, 8, and 9 correspond to %%CLASSNAME, Name and BirthPlace. 
/// All argument values are passed as uncollated values. It is the responsibility of the functional index class to 
/// properly collate the values.
/// </p>
/// <p>
/// Three additional methods are included in the Index Filing Interface. They are <method>PurgeIndex</method>, 
/// <method>SortBeginIndex</method>, and <method>SortEndIndex</method>.
/// </p>
/// <h2>Query Interface</h2>
/// <p>
/// The Query Interface consists of at least one method that is projected to SQL as a function. Arguments of this function
/// should be limited to the set of index properties.
/// </p>
/// <br>
/// <h2>Index Dictionary Metadata</h2>
/// <p>
/// When implementing a functional index class it is sometimes necessary to access the compiled class 
/// dictionary metadata.
/// 
/// The class compiler will not have generated a specific global location for the functional index. 
/// That is the responsibility of the functional index class. When you need a global location for a functional 
/// index the convention is to use the defined global location values from the storage definition but the details 
/// of exactly what global location will be used by the index are left to the functional index class. 
/// </p>
/// <br>
/// <h2>Subvalue Indexing</h2>
/// Subvalue indexing occurs when an index property specification includes either (ELEMENTS) or (KEYS). 
/// These references trigger the filers to determine the set of subvalues, either by the fact that the 
/// property involved is a collection or there is a user-implemented BuildValueArray method. The filers 
/// then iterate over the subvalues and file the index. In the case of an update, the set of existing 
/// subvalues are first deleted from the index and the set of new subvalues is filed.</p>
/// <p>
/// Functional Indexes continue with this behavior with the index filing method simply performing the work 
/// needed to place one subvalue into the index. The Objects and SQL filers will continue to determine the 
/// set of subvalues, both existing and new, and call the Functional Index interface iteratively. 
/// </p>
/// <p>
/// When the index structure includes subvalues but there is no declaration in the index property specifications 
/// then it is entirely up to the Functional Index implementation to determine the set of subvalues and to provide 
/// the necessary subvalue iterators. The Objects and SQL filers will invoke the Functional Index filer with 
/// existing and new values as if the index is on the entire property value.
/// </p>
Class %Library.FunctionalIndex [ Abstract, ClassType = index, System = 2 ]
{

/// This parameter can be set to 1 if the implementation of the filing interface and the SQL query interface can be 
/// executed on a shard server.  The default is 0.  If a sharded class attempts to use a functional index where 
/// SUPPORTSSHARDING = 0, a class compiler error will be returned.
Parameter SUPPORTSSHARDING = 0;

/// Internal parameter.
Parameter ProjectMap = 0;

/// This method is invoked when a new instance of a class is inserted into the database.
ClassMethod InsertIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
			// Generate specific code for <index>Insert here
	}
	quit $$$OK
}

/// This method is invoked when an existing instance of a class is updated.
ClassMethod UpdateIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
			// Generate specific code for <index>Update here
	}
	quit $$$OK
}

/// This method is invoked when an existing instance of a class is deleted.
ClassMethod DeleteIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
			// Generate specific code for <index>Delete here
	}
	quit $$$OK
}

ClassMethod PurgeIndex() [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
			// Generate specific code for <index>PurgeIndex here
	}
	quit $$$OK
}

ClassMethod SortBeginIndex() [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
			// Generate specific code for <index>SortBeginIndex here
	}
	quit $$$OK
}

ClassMethod SortEndIndex(pCommit As %Integer = 1) [ CodeMode = generator, ServerOnly = 1 ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
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

/// This method is called when the index builder is finalizing a segment. Use this method to implement any segment
/// cleanup work or to complete the filing of the segment. Parallel index builds typically construct segments of the 
/// index in memory and this method is a good place to copy temporary structures to the permanent index structure.  
ClassMethod SegmentFinalize(ByRef pIndexBuffer As %RawString, pStartID As %RawString, pEndID As %RawString)
{
	quit 1
}

ClassMethod Find(pSearch As %Binary) As %Library.Binary [ CodeMode = generator, ServerOnly = 1, SqlProc ]
{
		// don't generate any code if it not for an index. %member is the index name.
	if %mode '= "method" {
			// Generate specific code for <index>Find here
	}
	quit $$$OK
}

}
