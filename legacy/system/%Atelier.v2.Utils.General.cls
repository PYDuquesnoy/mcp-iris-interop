/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Atelier.v2.Utils.General Extends %RegisteredObject
{

/// <b>ValidType</b>(pType,pKeyword) checks that a Type attribute is valid.
/// If the type is valid then it is changed to upper case, inserted into the pKeywords
/// array (passsed by reference) and returned as the result of <b>ValidType</b>
/// <p>
/// If the type is invalid then <b>ValidType</b> returns "".
/// <p>
/// Note: If the pKeywords array contains a conflicting Type value or
/// a conflicting LanguageMode value then the Type attribute is invalid.
/// 
ClassMethod ValidType(pType As %String, ByRef pKeywords As %String) As %String
{
        Quit $$ValidType^%apiSRC(.pType,.pKeywords)
}

/// <b>ValidLANG</b>(pMode,pKeyword) checks that a LanguageMode attribute
/// is valid. If the mode is valid then it is inserted into the pKeywords
/// array (passed by reference) and returned as the result of <b>ValidLANG</b>
/// <p>
/// If the mode is invalid then <b>ValidLANG</b> returns "".
/// <p>
/// Note: If the pKeywords array contains a conflicting Type value or
/// a conflicting LanguageMode value then the mode attribute is invalid.
/// 
ClassMethod ValidLANG(pMode As %String, ByRef pKeywords As %String) As %String
{
        Quit $$ValidLANG^%apiSRC(.pMode,.pKeywords)
}

}
