/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dummy superclass that just inherits from %Collection.AbstractList so we do not
/// change the name of %AbstractList in case existing code uses it. You should use
/// the %Collection.AbstractList in your code.
Class %Library.AbstractList Extends %Collection.AbstractList [ Abstract, System = 3 ]
{

}
