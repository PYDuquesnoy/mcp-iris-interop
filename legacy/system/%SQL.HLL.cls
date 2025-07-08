/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// ObjectScript API for building Hyper Log Log estimates of the number of unique elements (cardinality) in a group of data.<br><br>
/// The estimates are kept in containers called sketches. The containers are identified by the <property>id</property> of this class.<br>
/// Lets assume you have 1 million pieces of data and want to know how many of those pieces are unique:<br>
/// 1) Use <method>%New</method> to instantiate a new HLL object:<br><pre>
///    set hll= ##class(%SQL.HLL).%New()</pre><br>
/// 2) Feed one million pieces of data into the sketch with <method>update</method>:<br><pre>
///    for i=1:1:1000000 {do hll.update(i)}</pre><br>
/// 3) Get an estimate of the cardinality by calling <method>estimate</method><br><pre>
///    write hll.estimate()</pre><br><pre>
///    996537</pre><br><br>
/// Notes: We test this class at Intersystems by using murmur hash with a seed of hll.#SEED:<br>
///        $zcrc(yourdata,9,2059198193) or $zcrc(yourdata,9,hll.#SEED)<br>
///        The underlying library uses 64 bits of this 128 bit hash.<br><br>
/// Estimate Partitioning: pass an existing sketch into <method>%New</method> to initialize its state<br>
/// from the standard serialized form (optionally Base64 encoded).<br>
/// To combine estimates <method>get</method> and <method>merge</method> your sketches, if your data is distributed<br>
/// across many processes.
Class %SQL.HLL Extends %RegisteredObject
{

/// Whether or not to Base64 encode/decode by default during <method>get</method> and <method>%New</method> 
Parameter ENCODE = 1;

/// Murmur hash seed to use for $zcrc(,9,)
Parameter SEED = 2059198193;

Parameter %MODULENAME [ Internal ] = 15;

/// Internal identifier of allocated memory for this HLL sketch's representation as managed by the callout library
Property id As %Integer [ Internal, ReadOnly ];

/// Whether the estimator is currently sparse or dense
Property type As %String [ Calculated, ReadOnly ];

/// Precision of the estimator
Property precision As %Integer [ Calculated, ReadOnly ];

/// Index of $zf(-4) addresses
Property libIndex As %Integer [ Internal, MultiDimensional, Private ];

Method getFunctionID(function As %String) As %Integer [ Internal ]
{
    if '$d(..libIndex(function), functionID) {
        set (functionID, ..libIndex(function)) = $zf(-4, 3, ..libIndex, function)
    }
    quit functionID
}

ClassMethod getLibraryID() As %Integer [ Internal ]
{
    quit $zf(-4, 1, $SYSTEM.Util.BinaryDirectory()_$s($$$isWINDOWS:"libirisHLL.dll", 1:"libirisHLL.so"))
}

/// Creates the memory and sets <property>id</property> for a new sketch. If you pass the sketch parameter, the new sketch will be initialized with the serialized sketch you passed in.
Method %OnNew(sketch As %Binary = "", decode As %Boolean = {..#ENCODE}, Output err As %String = "") As %Status
{
    // initialize library ID
    set i%libIndex = ..getLibraryID()

    if (sketch="") {

        // ZFENTRY("ZFhll_iris_new",  "8PC",  CASTAWAYARGS(hll_iris_new))
        set output = $zf(-5, ..libIndex, ..getFunctionID("ZFhll_iris_new")),
            i%id = +$piece(output,",",1),
            err = $piece(output,",",2)

    } else {

        set:decode sketch = $SYSTEM.Encryption.Base64Decode(sketch)

        // ZFENTRY("ZFhll_iris_load", "b8PC", CASTAWAYARGS(hll_iris_load))
        set output = $zf(-5, ..libIndex, ..getFunctionID("ZFhll_iris_load"), sketch),
            i%id = +$piece(output,",",1),
            err = $piece(output,",",2)

    }
    quit $$$OK //$case(err, "Success":$$$OK, :$$$ERROR($$$HyperLogLogError, err))
}

/// Updates this sketch with the user supplied hash value<br>
/// Use $zcrc(yourdata,9,2059198193) or $zcrc(yourdata,9,hll.#SEED) to get the hash.<br>
Method updateHash(hash As %Binary) As %Integer [ Language = cpp ]
{
}

/// Updates this sketch with the $zcrc(,9,) hash of the stringdata. Hash done inside API.<br>
Method update(stringdata As %Binary) As %Integer [ Language = cpp ]
{
}

/// Merges the supplied sketch object into the current one. This merges the cardinality estimates.
Method merge(other As %SQL.HLL, Output err As %String = "") As %Status
{
    // ZFENTRY("ZFhll_iris_merge", "8i8iC", CASTAWAYARGS(hll_iris_merge))
    set err = $zf(-5, ..libIndex, ..getFunctionID("ZFhll_iris_merge"), ..id, other.id)
    
    quit $case(err, "Success":$$$OK, :$$$ERROR($$$HyperLogLogError, err))
}

/// Returns the current unique value estimate (cardinality) for this sketch.
Method estimate(Output err As %String = "") As %Integer
{
    // ZFENTRY("ZFhll_iris_estimate", "8i8PC", CASTAWAYARGS(hll_iris_estimate))
    set output = $zf(-5, ..libIndex, ..getFunctionID("ZFhll_iris_estimate"), ..id),
        estimate = $piece(output,",",1),
        err = $piece(output,",",2)

    quit estimate
}

/// Returns the serialized form of the current sketch so that multiple sketches can be merged.
/// Potentially you might obtain the sketch from a different process.
Method get(encode As %Boolean = {..#ENCODE}, Output err As %String = "") As %Binary
{
    // ZFENTRY("ZFhll_iris_get",  "8iBPC", CASTAWAYARGS(hll_iris_get))
    set output = $zf(-5, ..libIndex, ..getFunctionID("ZFhll_iris_get"), ..id),
        raw = $piece(output,",",1,*-2),
        length = $piece(output,",",*-1),
        err = $piece(output,",",*)

    quit $s(encode:$SYSTEM.Encryption.Base64Encode(raw, 1), 1:raw)
}

/// Frees up the memory associated with this sketch. 
/// After this method has been called, subsequent calls for this sketch will yield a <FUNCTION>
/// error. This method is called implicitly by the object destructor.
Method releaseSketch(Output err As %String = "") As %Status [ Internal ]
{
    // ZFENTRY("ZFhll_iris_free", "8iC", CASTAWAYARGS(hll_iris_free))
    set err = $zf(-5, ..libIndex, ..getFunctionID("ZFhll_iris_free"), ..id)

    set i%id = ""
    
    quit $case(err, "Success":$$$OK, :$$$ERROR($$$HyperLogLogError, err))
}

/// Helper method to retrieve metadata for the current sketch.
Method info(Output type As %String, Output precision As %String, Output err As %String) As %Status [ Internal ]
{
    // ZFENTRY("ZFhll_iris_estimator_type", "8iPPC", hll_iris_estimator_type)
    set output = $zf(-5, ..libIndex, ..getFunctionID("ZFhll_iris_estimator_type"), ..id),
        type = $s($piece(output,",",1)=1:"sparse", 1:"dense"),
        precision = $piece(output,",",2),
        err = $piece(output,",",3)
        
    quit $case(err, "Success":$$$OK, :$$$ERROR($$$HyperLogLogError, err))
}

Method typeGet() As %String [ Internal, ServerOnly = 1 ]
{
    do ..info(.type)
    quit type
}

Method precisionGet() As %Integer [ Internal, ServerOnly = 1 ]
{
    do ..info(,.precision)
    quit precision
}

Method %OnClose() As %Status
{
    quit:..id ..releaseSketch()
    quit $$$OK
}

/// Returns the version of the underlying callout library.
ClassMethod version() As %Integer
{
    try {
        set libID = ..getLibraryID(), 
            functionID = $zf(-4,3, libID, "ZFhll_iris_get_version")

        // ZFENTRY("ZFhll_iris_get_version", "P", hll_iris_get_version)
        return $zf(-5, libID, functionID)

    } catch {
        return -1
    }
}

}
