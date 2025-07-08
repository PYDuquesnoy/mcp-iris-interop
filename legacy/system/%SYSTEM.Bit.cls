/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides various $bit support functions.
/// 
/// <p>You can use it via the special <b>$system</b> object:
/// <example>
/// Set x=$system.Bit.StringToBit($c(1,5))
/// </example>
Class %SYSTEM.Bit Extends Help [ Abstract, System = 4 ]
{

/// Converts a string to a $bit string
/// 
ClassMethod StringToBit(val) As %String
{
    #; Throw error if string is > 32763 bytes long, or has unicode characters
    Quit:val="" ""
    If $l(val)<32764,'$ziswide(val) { Quit $zwc(128,$l(val))_val }
    Do $zu(96,3,78)
}

/// Converts a legacy DTM-style $zbit* string to a $bit string
/// 
ClassMethod ZBitToBit(val) As %String
{
    #; Throw error if string is "", is > 32762 bytes long, or has unicode characters
    Quit:$l(val)=1 ""
    If val'="",$l(val)<32763,'$ziswide(val) { Quit $zwc($A(val)#8+128,$l(val)-1)_$e(val,2,*) }
    Do $zu(96,3,78)
}

}
