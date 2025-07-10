/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Contains list of functions that can be used within RuleSet expressions
Class Ens.Rule.FunctionSet Extends Ens.Util.FunctionSet [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

Projection FunctionSetProjection As Ens.Projection.FunctionSet;

}
