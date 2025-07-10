/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Rule.GeneralBusinessRuleAssist Extends Ens.Rule.Assist [ Abstract, System = 4 ]
{

ClassMethod GetDescription() As %String
{
	quit $$$Text("General Business Rule","Ensemble")
}

}
