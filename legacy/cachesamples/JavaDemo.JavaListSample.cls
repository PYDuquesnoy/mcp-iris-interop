/// 
/// Caché classes for Java List Demo 
/// Version: $Revision: 1.1 $
/// Author:  Gerd Nachtsheim
Class JavaDemo.JavaListSample
{

/// Get a list of names<br> 
/// in: $list of IDs<br>
/// out: $list of names<br>
ClassMethod GetListOfNames(pList As %List) As %List [ SqlName = GetListOfNames, SqlProc ]
{
	set tList = ""
	for tID = 1 : 1 : $ll(pList)
	{
		&sql(SELECT Name INTO :tName FROM Sample.Person WHERE ID = :tID)
		if (SQLCODE=0) set tList = tList _ $lb(tName)
	}
	quit tList
}

/// Get a list of names by reference<br> 
/// in: $list of IDs by ref<br>
/// out: # of names<br>
///      list of names in pList as $list
ClassMethod GetListOfNamesByRef(ByRef pList As %List) As %Integer [ SqlName = GetListOfNamesByRef, SqlProc ]
{
	set tList = ""
	for tID = 1 : 1 : $ll(pList)
	{
		&sql(SELECT Name INTO :tName FROM Sample.Person WHERE ID = :tID)
		if (SQLCODE=0) set tList = tList _ $lb(tName)
	}
	set pList = tList
	quit $ll(pList)
}

}

