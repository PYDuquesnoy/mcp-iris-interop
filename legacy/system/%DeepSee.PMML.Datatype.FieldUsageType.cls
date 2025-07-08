/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %PMML

Class %DeepSee.PMML.Datatype.FieldUsageType Extends String [ System = 3 ]
{

Parameter VALUELIST = {$lts($lb("",$$$PMMLusageTypePredicted, $$$PMMLusageTypeTarget, $$$PMMLusageTypeActive, $$$PMMLusageTypeSupplementary, $$$PMMLusageTypeGroup, $$$PMMLusageTypeOrder, $$$PMMLusageTypeFrequencyWeight, $$$PMMLusageTypeAnalysisWeight))};

}
