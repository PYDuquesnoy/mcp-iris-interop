/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A reference to a registered Bonjour service that can be used
/// to update the registration or remove it.
Class %Net.BonjourServiceReference Extends %RegisteredObject [ System = 4 ]
{

Property Handle As %Integer;

/// Unregister this service
Method Unregister()
{
	Do ##class(BonjourLibrary).Delist(..Handle)
}

}
