/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The generic Monitor data type. This class provides the parameters to define a Monitored metric.
/// Only Properties which use one of the data classes which inherit from this class, will be sampled in 
/// in user-defined Application Monitor classes (and reported through SNMP).
Class %Monitor.AbstractType [ Abstract, System = 3 ]
{

/// a text description of the units for the data
Parameter Units As STRING;

/// Method to be invoked during sampling
Parameter GETMETHOD As STRING;

}
