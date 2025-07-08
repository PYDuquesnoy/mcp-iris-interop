/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The SelectList class is for internal use in the InterSystems MultiValue
/// product.  The internals of this class can be changed by InterSystems
/// without prior notice.  Application code should not inherit this class nor
/// should application code manipulate the properties and methods in this class.
/// The class may be examined for the purpose of debugging MultiValue applications.
///  <br><br>
/// The SelectList class represents an MVBASIC Select variable in various states such as:
///  <br><br>
/// 1) Traversing through values supplied via a dynamic array SELECT var TO list<br>
/// 2) Traversing through the item IDs represented in a Global or a directory<br>
/// 3) Traversing through values taken from a different list SELECT list TO list<br>
/// 4) Traversing through values in an index<br><br>
/// 
/// Because there are various states associated with each type of list, a class with 
/// appropriate properties to track these states is required.
/// 
Class %MV.SelectList Extends %RegisteredObject [ LegacyInstanceContext, OdbcType = LONGVARCHAR, ServerOnly = 1, System = 4 ]
{

/// Indicates what type of select list the object instance is representing:
/// <br><br>
///  0 - Simple dynamic array of attributes, stored herein<br>
///  1 - Item IDs returned from a global<br>
///  2 - Elements, (keys, IDs and MV positions), returned from an index
/// 
Property %Type As %Integer [ InitialExpression = 0 ];

/// Holds the value of the last element read from the list.
/// This is used only by those types of lists that are traversing indexes or files, where
/// the last key used allows us to pick up the next key efficiently
/// 
Property %LastReturnedId As %String;

/// The last offset is the offset within the Values property that should be used 
/// to pick up the next ID. This allows us to optimize the list traversal so that we do
/// not scan from the start of the value list each time we need the next element
/// within it. In order to avoid copying the values in the Values property, we
/// store the values in an mvv variable when first accessed or when another list
/// reference knocks it out of the Last Used SelectList positions.
/// 
Property %NextOffset As %Integer [ InitialExpression = 0 ];

/// When the SelectList is traversing keys in a Global, we need to know
/// the name of the global we are traversing, and so we store it here.
/// 
Property %GlobalName As %String;

/// When the selectlist is being used to traverse a global, we need to know the name
/// space that the global lives in. This property serves that function.
/// 
Property %Namespace As %String;

/// This value is a string containing all the values contained in a list that was initialized
/// from an expression or other dynamic array. It is not normally traversed directly from
/// the object as we would have to keep copying the value onto the stack before
/// looking to the next element in the list. We do not use a ObjectScript $list for this
/// property as it offers little advantage in terms of traversing large lists in sequence.
/// 
Property %Values As %String [ MultiDimensional ];

/// This value is an integer count of the number of elements that the list contains. We
/// don't always know this value (for instance if this is traversing the items in Global
/// representing an MV file we don't want to $order() the lot just to find out we have
/// 6,000,000 elements we can read. However after CMQL statements or if we have done a writelist
/// or readlist or something similar we can count the elements as we go without much of a 
/// penalty and can store the value here. If we know we have elements in the list but not how
/// many then we store -1 in this value, otherwise it is 0 when we create an object.
/// 
Property %Count As %Integer [ InitialExpression = 0 ];

/// When the select list is of Type = 2, then we need to know
/// which index we are traversing so we can construct the global reference.
/// The name of the index that is being traversed is stored here.
/// 
Property %IndexName As %String;

/// When the select list is of Type = 2, then we need to know the type
/// of the index that is being traversed. At the moment, we only allow standard
/// indexes to be traversed (not bitmap and bitslice), but I have specified these
/// types here for future examination. If it were not for the fact that we must
/// be able to traverse the index backwards, we would use SQL cursors to traverse
/// indexes, however, MVBASIC expects to be efficient and so we traverse the structure
/// directly in the associated globals as this is readonly access.
/// 
/// Future enhancements should include returning the associated data stored with
/// the index - IE the data that is stored with the index key that does not form 
/// the actual key.
/// <br><br>
/// Types are:
/// <br><br>
///  1 - Single valued index, no multivalues<br>
///  2 - Multivalued index, no key (MV position stored)<br>
///  4 - Multivalued index, includes key (MV position)<br>
///  8 - This is an index variable generated by SELECTINDEX
/// 
Property %IndexFlags As %Integer [ InitialExpression = 0 ];

/// A select list can represent an index. An index stores the actual keys
/// as oppposed to the key values returned by READNEXT in collated encoding
/// sequence such as MV R or SPACE (equivalant to MV L) etc.
/// This property defines the collation in use for the index.
/// 
Property %IndexColl As %Integer [ InitialExpression = 0 ];

/// A select list can be read forwards or backwards and my change direction
/// at any time. In this case, we have a boundary condition when the first
/// READPREV or READFORWARD is called and when we change direction on some
/// types of selectlist. To cater for this we always return the key that
/// is currently being flagged as the LASTID, if this flag is set to 1 and the
/// operation is a READPREV. The list is so arranged that READNEXT does not need
/// to worry about this as the last ID will always be the one that WAS last
/// returned to a READNEXT.
/// 
Property %InReverse As %Integer [ InitialExpression = 0 ];

/// Multivalue indices must track the last Key, ItemID and MVPOS while traversing
/// the index. Hence we need a property to hold the last MVPos that we returned
/// 
Property %LastReturnedMVPos As %Integer [ InitialExpression = 0 ];

/// Tracks the last index key that was returned when traversing an index
/// 
Property %LastReturnedKey As %String;

/// For dynamic array type select lists, this is the current subscript
/// under Values
/// 
Property %CurSub As %Integer [ InitialExpression = 0 ];

/// For dynamic array type select lists, this is the maximum subscript
/// under Values
/// 
Property %MaxSub As %Integer [ InitialExpression = 0 ];

/// This is 0 for normal select lists, 1 for exploded select lists, and 2 for
/// subvalue exploded select lists
/// 
Property %ExplodeFlag As %Integer [ InitialExpression = 0 ];

Method Dump() As %Status
{
    #; Display all instance variables for this object
    W "Type:"		W:$d(i%%Type) ?18,i%%Type	W !
    W "LastReturnedId:"	W:$d(i%%LastReturnedId) ?18,$$outstr(i%%LastReturnedId) W !
    W "NextOffset:"	W:$d(i%%NextOffset) ?18,i%%NextOffset W !
    W "GlobalName:"	W:$d(i%%GlobalName) ?18,$$outstr(i%%GlobalName) W !
    W "Namespace:"		W:$d(i%%Namespace) ?18,$$outstr(i%%Namespace) W !
    W "Values:"	W:$d(i%%Values) ?18,$$outstr(i%%Values) W !
    W "Count:"	W:$d(i%%Count) ?18,i%%Count W !
    W "IndexName:"	W:$d(i%%IndexName) ?18,$$outstr(i%%IndexName) W !
    W "IndexFlags:"	W:$d(i%%IndexFlags) ?18,i%%IndexFlags W !
    W "IndexColl:"	W:$d(i%%IndexColl) ?18,i%%IndexColl W !
    W "InReverse:"	W:$d(i%%InReverse) ?18,i%%InReverse W !
    W "LastReturnedMVPos:"	W:$d(i%%LastReturnedMVPos) ?18,i%%LastReturnedMVPos W !
    W "LastReturnedKey:"	W:$d(i%%LastReturnedKey) ?18,$$outstr(i%%LastReturnedKey) W !
    W "CurSub:"		W:$d(i%%CurSub) ?18,i%%CurSub W !
    W "MaxSub:"	W:$d(i%%MaxSub) ?18,i%%MaxSub W !
    W "ExplodeFlag:"	W:$d(i%%ExplodeFlag) ?18,i%%ExplodeFlag W !
    Quit $$$OK
outstr(str) 
   Set ret="""" F i=1:1:$l(str) Set ret=ret_$s($e(str,i)="""":"""""",1:$e(str,i))
   Quit ret_""""
}

/// If process private global %MV.SelectTempnnn in use
/// then decrement the use count in %MV.SelectTempnnn and
/// Kill global if the use count goes to 0
Method %OnClose() As %Status [ Private ]
{
	Quit:$This.%Namespace'="^" $$$OK
	Quit:$Extract($This.%GlobalName,1,14)'="%MV.SelectTemp" $$$OK
	Kill:'$I(@("^||"_$This.%GlobalName),-1) @("^||"_$This.%GlobalName)
	Quit $$$OK
}

}
