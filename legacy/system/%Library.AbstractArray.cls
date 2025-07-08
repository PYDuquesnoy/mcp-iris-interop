/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dummy superclass that just inherits from %Collection.AbstractArray so we do not change
/// the name of %AbstractArray in case existing code uses this. You should use the new
/// %Collection.AbstractArray class in your code.
Class %Library.AbstractArray Extends %Collection.AbstractArray [ System = 3 ]
{

}
