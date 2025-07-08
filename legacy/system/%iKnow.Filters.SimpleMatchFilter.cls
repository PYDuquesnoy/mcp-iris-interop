/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>NOTE: This class is deprecated; use <method>%iKnow.Filters.DictionaryMatchFilter</method> instead</p>
/// 
/// <p><class>%iKnow.Filters.Filter</class> implementation selecting sources based on whether they
/// contain a minimum and/or maximum number or total score of dictionary matches.</p>
/// 
/// <p><b>NOTE:</b> by default, this filter only uses existing match results and will only ensure
///   all sources are fully matched when the ensureMatched parameter is enabled!</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>domainId</b> As <class>%Integer</class></li>
/// 	<li><b>dictIds</b> As <class>%List</class> - target dictionaries (ORed together)</li>
/// 	<li><b>min</b> As <class>%Numeric</class> (default 1) - minimum count or total score (-1 = no minimum)</li>
/// 	<li><b>max</b> As <class>%Numeric</class> (default -1) - maximum count or total score (-1 = no maximum)</li>
/// 	<li><b>metric</b> As <class>%String</class> (["COUNT"|"SCORE"], default "COUNT") - whether to take the 
/// 								number of matches (default) or their aggregated score.</li>
/// 	<li><b>ensureMatched</b> As <class>%Integer</class> - controls whether or not 
/// 									all sources in the domain are matched through an explicit call to 
/// 									MatchingAPI.MatchSources() as follows:<ul>
/// 				<li>0 - no explicit matching, use current matching results (default)</li>
/// 				<li>1 - match before every invocation of the filter (warning: significant performance impact!)</li>
/// 				<li>2 - match once when the filter is instantiated</li></ul></li>
/// </ol>
Class %iKnow.Filters.SimpleMatchFilter Extends %iKnow.Filters.DictionaryMatchFilter [ Deprecated, System = 4 ]
{

}
