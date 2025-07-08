/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a generic datatype to use whenever a more specific type is not applicable.
/// Use this type in situations like the following:
/// <ul>
/// <li>The value can be any type of data.</li>
/// <li>IRIS does not include a class that describes the type. This applies, for example,
/// if the value is an opaque structure that is not native to ObjectScript.</li>
/// <li>The value can be one of several different types of data, and 
/// if you specify a type, that will confuse users of your code. For example, if a method
/// can return either an object or a string, it is best for the method signature to 
/// have only a generic statement about the return value.
/// </li>
/// <li>The value being passed is a multidimensional array.</li>
/// </ul>
Class %Library.RawString Extends %Library.Any [ ClassType = datatype, System = 1 ]
{

}
