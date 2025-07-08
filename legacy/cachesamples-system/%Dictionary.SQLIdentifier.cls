/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.SQLIdentifier Extends %DataType [ System = 2 ]
{

ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = expression ]
{
$select($system.SQL.IsValidRegularIdentifier(%val):$$$OK,1:$$$ERROR($$$DatatypeValidationError,"%Dictionary.SQLIdentifier",%val))
}

}
