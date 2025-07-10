/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.BusinessOperationDuplex Extends Ens.BusinessDuplex [ Abstract, System = 4 ]
{

ClassMethod OnBusinessType(pItem As Ens.Config.Item) As %Integer
{
	Quit $$$eHostTypeOperation
}

}
