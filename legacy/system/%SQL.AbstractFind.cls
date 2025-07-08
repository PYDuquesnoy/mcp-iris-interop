/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <class>%SQL.AbstractFind</class> defines the interface used by the SQL %FIND and 
/// %INSET filter conditions. <br> <br>
/// <!doctype html public "-//w3c//dtd html 4.0 transitional//en">
/// <html>
/// <head>
///    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
///    <meta name="GENERATOR" content="Mozilla/4.77 [en] (Windows NT 5.0; U) [Netscape]">
///    <title>SQL %FIND and other filters</title>
/// </head>
/// 	<body>
/// 	<h1>SQL Filter Interface</h1>
/// 	<h2>Overview</h2>
/// <p>
/// This class defines the interface used for %FIND and %INSET SQL filter
/// conditions, which use the following syntax:
/// <pre>
///     f &lt;filter&gt; x
/// </pre>
/// where &lt;filter&gt; is either %FIND or %INSET, and x represents a set 
/// of values S used as a filter for f, or more precisely, the condition is 
/// satisfied if and only if f is a member of S. 
/// </p>
/// <p>
/// x is an expression that evaluates at run-time to the oref of an object 
/// that provides an abstract representation encapsulating the set S of non-NULL 
/// values (often IDs), by implementing the interface specified in this class. 
/// This interface consists of methods called at query run-time, that represent S's 
/// contents.  The interface differs based on which of the 
/// two filter conditions is used. 
/// </p>
/// <p>
/// These conditions enable filtering using a given abstract, programmatically 
/// specified set of values, and in particular, enable filtering of the rowid 
/// field using an abstract, programmatically specified temp-file or bitmap 
/// index, where x behaves similarly to the last subscript 
/// layer of a bitmap index. 
/// </p>
/// <p>
/// %INSET requires x to support the simplest and most general interface, 
/// consisting of the single method <METHOD>ContainsItem</METHOD>, which returns 1 if and only if the item is in 
/// the set. 
/// </p>
/// <p>
/// This method must also be supported by x for %FIND. 
/// </p>
/// <p>
/// %FIND requires x to support an interface that emulates a set S of positive 
/// integers as if being stored in a standard bitmap index.  When 
/// t.%ID is used for f, this interface allows the query processor to use x 
/// in various capacities as if it were an index of t, including driving the 
/// processing of table t, or as part of a complex multi-index strategy for t. 
/// </p>
/// <p>
/// In addition to <METHOD>ContainsItem()</METHOD>, the %FIND interface includes the three methods 
/// <METHOD>GetChunk()</METHOD>, <METHOD>NextChunk()</METHOD>, and <METHOD>PreviousChunk()</METHOD>, which emulate the usage of 
/// <FUNCTION>$ORDER()</FUNCTION>/<function>$DATA()</function> to access and iterate over bitmap chunks storing the set S of positive integer values, 
/// much the same way as a set of ID's is stored in a  
/// bitmap index, where an item i in S corresponds to a single bit being on. 
/// More specifically, S can be considered stored in a sequence of bitmap 
/// chunks b of up to 64,000 bits each, each stored within an array under a 
/// subscripted positive integer chunk number c, say bm(c)=b, where for any 
/// positive integer i, i is in S if and only if  <function>$BIT</function>(bm(i\64000+1),i#64000+1)=1 . 
/// Equivalently, <function>$BIT</function>(bm(c),p)=1 if and only if the integer (c-1)*64000+p-1 is in S. 
/// </p>
/// <p>
/// The method <METHOD>GetChunk</METHOD> returns the bitmap chunk b corresponding
/// with the provided chunk number, if there is any ("" otherwise), with bit positions 1 to 64000 
/// within b representing which of the integers (c-1)*64000 to c*64000-1 are 
/// or are not in S. 
/// </p>
/// <p>
/// The methods <METHOD>NextChunk</METHOD> and <METHOD>PreviousChunk</METHOD> project a sequence of ordered 
/// (but not necessarily consecutive) chunk numbers, each with its 
/// corresponding bitmap chunk b of up to 64000 bits.  The chunk number 
/// is input/output, proceeding in order starting and ending with "", 
/// exactly as in <function>$ORDER()</function>.  When the returned chunk number
/// is non-NULL, then the method return value is b, the bitmap chunk itself. 
/// </p>
/// <p>
/// Note that it's OK for the returned bitmap chunk b to have no bits set to 1, 
/// including b="" , even when the returned c is not NULL, just as when using 
/// <function>$ORDER()</function> to iterate over the bitmap layer of an actual bitmap 
/// index. On the other hand, it's also OK for the method implementation to skip 
/// such a chunk and proceed to the next c . 
/// </p>
/// <p>
/// For the condtition (t.%ID %FIND x) to use this bitmap interface, t.%ID must 
/// be "bitmap-eligible", i.e. declared or implied to be a positive integer, and t 
/// must also have an extent bitmap index.  If either of these does not hold, then 
/// %FIND is automatically "downgraded" to %INSET, i.e. only the x.<METHOD>ContainsItem()</METHOD> 
/// of the %INSET interface for x is used by the run-time query instead of the 
/// %FIND bitmap interface. 
/// </p>
/// <p>
/// For example, a bitmap produced in a previous processing step, e.g. in a 
/// BI/OLAP or a report-generating context, can be used as an input filter for 
/// the next query by using this interface with %FIND. 
/// </p>
/// <p>
/// As another example, for a given table, in order to support specialized 
/// algorithms for searching through geographic data, or to support specialized 
/// iKnow searches, one can imagine defining an abstract index, one that is 
/// not structured like a standard index type, but rather defined 
/// programmatically.  The search parameters could be specified in the query as 
/// part of the second argument of %FIND, in a call to a user-defined function 
/// which would compute the resulting set of rows, and which would return an 
/// object that represents that set by supporting the interface required by the 
/// query. 
/// </p>
/// <p>
/// Note that all of the method calls are, in principle, "stateless" - no 
/// assumptions can be made regarding the order or sequence of these calls, and 
/// no internal "previous state" can affect the external behavior and the 
/// returned values of any method call.  Of course in programming these methods 
/// internally one may optimize the internal behavior in any way, including 
/// maintaining an internal state (e.g. a cache), or anticipating certain call 
/// profiles. 
/// </p>
/// <p>
/// For example, a class TempBitmap could be defined to store data in a PPG, in 
/// a bitmap structure similar to the temp-files normally produced by generated 
/// SQL queries for storing just a list of IDs, e.g.: 
/// <pre>
///     ^||%sql.bitmap(..loc,0,chunk#)=&lt;bit-map&gt;
/// </pre>
/// </p>
/// <p>
/// The formal syntax for the filter condition is: 
/// <pre>
/// 	&lt;cond&gt; ::= &lt;scalx&gt; &lt;filter&gt; &lt;scalx&gt; [ &lt;sizehint&gt; ]
/// 	&lt;filter&gt; ::= %INSET | %FIND
/// 	&lt;sizehint&gt; ::= SIZE &lt;pconst&gt;
/// 	&lt;pconst&gt; ::= ( &lt;pconst&gt; ) | &lt;const&gt;
/// </pre>
/// </p>
Class %SQL.AbstractFind Extends %Library.RegisteredObject [ Abstract, System = 2 ]
{

/// 	At minimum, <METHOD>ContainsItem()</METHOD> must always be supported.
/// 	It returns 1 if and only if the given pItem is in the set S.
Method ContainsItem(pItem As %String) As %Boolean
{
}

/// <p>
/// The <METHOD>NextItem</METHOD>, <METHOD>NextItemInclusive</METHOD>, <METHOD>PreviousItem</METHOD>, and <METHOD>PreviousItemInclusive</METHOD> methods are required when %INSUB is used.
/// They emulate the usage of <function>$ORDER()</function> to iterate over the set of values S as if it was stored in
/// a subscript, similar to a subscript layer in a regular index.  The input
/// parameter pItem and the returned item iterate in a sequence through all the
/// elements of S, following the normal global subscript order ( "]]" ), starting
/// and ending with "", exactly as <function>$ORDER()</function> does.
/// </p>
/// <p>
/// For a given pItem, return the first item &gt; pItem
/// </p>
Method NextItem(pItem As %String = "") As %String [ Internal ]
{
}

/// <p>
/// The <METHOD>NextItem</METHOD>, <METHOD>NextItemInclusive</METHOD>, <METHOD>PreviousItem</METHOD>, and <METHOD>PreviousItemInclusive</METHOD> methods are required when %INSUB is used.
/// </p>
/// <p>
/// For a given pItem, return the first item &gt;= pItem
/// </p>
Method NextItemInclusive(pItem As %String = "") As %String [ Internal ]
{
	QUIT:..ContainsItem(pItem) pItem
	QUIT ..NextItem(pItem)
}

/// <p>
/// The <METHOD>NextItem</METHOD>, <METHOD>NextItemInclusive</METHOD>, <METHOD>PreviousItem</METHOD>, and <METHOD>PreviousItemInclusive</METHOD> methods are required when %INSUB is used.
/// </p>
/// <p>
/// For a given pItem, return the first item &lt; pItem
/// </p>
Method PreviousItem(pItem As %String = "") As %String [ Internal ]
{
}

/// <p>
/// The <METHOD>NextItem</METHOD>, <METHOD>NextItemInclusive</METHOD>, <METHOD>PreviousItem</METHOD>, and <METHOD>PreviousItemInclusive</METHOD> methods are required when %INSUB is used.
/// </p>
/// <p>
/// For a given pItem, return the first item &lt;= pItem
/// </p>
Method PreviousItemInclusive(pItem As %String = "") As %String [ Internal ]
{
	QUIT:..ContainsItem(pItem) pItem
	QUIT ..PreviousItem(pItem)
}

/// <p>
/// This method simulates the usage of <function>$ORDER()</function> to 
/// traverse through the chunks of a bitmap index or a bitmap temp-file that 
/// would represent the set S. 
/// </p>
/// <p>
/// For a given chunk number pChunk, find the first chunk 
/// number &gt; pChunk and return it in .pChunk, with the method return value being the corresponding actual bitmap string. 
/// Return .pChunk="" if none found.
/// </p>
/// <p>
/// Note that when returning a positive .pChunk, it's OK for the returned bitmap b 
/// to have no bits set to 1, including b="" .  On the other hand, it's also OK 
/// for the method implementation to skip such a chunk and proceed to the next pChunk. 
/// </p>
/// <p>
/// This method must be implemented when %FIND is used. 
/// </p>
Method NextChunk(ByRef pChunk As %Integer = "") As %Binary
{
}

/// <p>
/// This method simulates the usage of <function>$ORDER()</function> to 
/// traverse backwards through the chunks of a bitmap index or a bitmap temp-file 
/// that would represent the set S. 
/// </p>
/// <p>
/// For a given chunk number pChunk, find the first chunk 
/// number &lt; pChunk and return it in .pChunk, with the method return value being the corresponding actual bitmap string. 
/// Return .pChunk="" if none found.
/// </p>
/// <p>
/// Note that when returning a positive .pChunk, it's OK for the returned bitmap b 
/// to have no bits set to 1, including b="" .  On the other hand, it's also OK 
/// for the method implementation to skip such a chunk and proceed to the next pChunk. 
/// </p>
/// <p>
/// This method must be implemented when %FIND is used. 
/// </p>
Method PreviousChunk(ByRef pChunk As %Integer = "") As %Binary
{
}

/// <p>
/// For a given chunk number pChunk, return the corresponding actual bitmap string. 
/// </p>
/// <p>
/// This method must be implemented when %FIND is used. 
/// </p>
Method GetChunk(pChunk As %Integer) As %Binary
{
}

/// Copy all of the results into a process private global 
Method GetResult() [ Internal ]
{
	kill ^||ISC.iFind(+$this)
	set tBits = ..GetChunk(.tChunk)
	while tChunk '= "" {
		set ^||ISC.iFind(+$this,tChunk) = tBits
		set tBits = ..GetChunk(.tChunk)
	}
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Internal, Private, ServerOnly = 1 ]
{
	kill ^||ISC.iFind(+$this)
	Quit $$$OK
}

ClassMethod ResultContainsItem(pResultID As %Integer, pItemID As %Binary) As %Boolean [ Internal ]
{
}

/// <p>
/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created. 
/// </p>
/// <p>
/// If this method returns an error then the object will not be created. 
/// </p>
/// <p>
/// It is passed the arguments provided in the %New call. 
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New(). 
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be: 
/// <pre>
/// Method %OnNew(dob as %Date = "", name as %Name = "") as %Status 
/// </pre>
/// If instead of returning a %Status code this method returns an oref and this oref is a subclass of the current 
/// class, then this oref will be the one returned to the caller of the %New method. 
/// </p>
Method %OnNew() As %Status [ Internal, Private, ServerOnly = 1 ]
{
	kill ^||ISC.iFind(+$this)
	Quit $$$OK
}

}
