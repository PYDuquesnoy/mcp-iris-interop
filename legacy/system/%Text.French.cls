/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// See <CLASS>%Text.Text</CLASS>
/// <p>
/// The <CLASS>%Text.French</CLASS> class implements the French language-specific stemming algorithm
/// and initializes the language-specific list of noise words.</p>
/// 
Class %Text.French Extends %Text.Text [ System = 4 ]
{

Parameter DICTIONARY = 3;

Parameter SOURCELANGUAGE = "fr";

Parameter NOISEWORDS100 = "de à et a dans est il vous cela était pour sur soyez avec sien ils soyez un ayez ceci de ou eu par chaud mot mais ce qui certains nous bidon hors autre étaient tous là quand vers le haut employez votre comment dit chacun elle quel leur temps si volonté manière au sujet beaucoup puis écrivez comme ainsi ceux ci elle long faites chose voyez deux regard plus jour pourrait allez venez nombre bruit non les plupart les gens mon savez l'eau que appel d'abord qui pouvez vers le bas côté été maintenant trouvaille";

Parameter NOISEWORDS200 = "quels nouveau travail partie prise obtenez endroit fait phase ensuite dos peu seulement rond homme année soyez venu exposition chaque bon je élasticité notre sous nom très travers juste forme phrase grand pensez parole aide bas ligne différez tour cause beaucoup moyen avant mouvement droite garçon vieux aussi mêmes dites ensemble trois voulez air puits aussi jeu petit extrémité mis maison lu main port grand charme ajoutez égalisez terre ici nécessité grand haut tels suivez acte pourquoi demandez hommes changement allé lumière aimable outre besoin maison image essai nous encore animal point mère monde près construction portrait terre père";

Parameter NOISEWORDS300 = "tête stand posséder page si pays trouvé réponse école développez étude toujours apprenez usine couverture nourriture soleil quatre entre état subsistance oeil jamais bout laissé pensée ville arbre croix ferme dur début force histoire scie loin mer aspiration gauche tard course pas tandis pression fin nuit vrai vie peu nord ouvert semblez ensemble après blanc enfants commencez obtenu promenade exemple facilité papier groupe toujours musique ceux tous marque souvent lettre jusque mille fleuve voiture pieds soin second livre portez pris science mangez pièce ami commencé idée poissons montagne arrêt fois base entendez cheval coupe sûr montre couleur visage bois principal";

/// Remove plural and feminine form of French words 
ClassMethod stemWord(ByRef b As %String) As %String
{
	s k = $l(b),j=""
	if (k>5)
	{ if ..ends(b, k, 3, "aux", .j) && ($e(b,k-4)'="e") { d ..setto(.b, "al", j, .k) }
	  elseif $e(b,k)="x" { s k=k-1 }
	}
	s:((k>3)&&($e(b,k)="x")) k=k-1
	s:((k>3)&&($e(b,k)="s")) k=k-1
	if (k>9)&&..ends(b, k, 8, "issement", .j) { d ..setto(.b, "ir", j, .k) }
	elseif (k>8)&&..ends(b, k, 6, "issant", .j) { d ..setto(.b, "ir", j, .k) }
	elseif (k>9)&&..ends(b, k, 6, "ivement", .j) { d ..setto(.b, "if", j, .k) }
	elseif (k>6)&&..ends(b, k, 5, "ement", .j) { d ..setto(.b, "e", j, .k) }
	elseif (k>11)&&..ends(b, k, 9, "ficatrice", .j) { d ..setto(.b, "fier", j, .k) }
	elseif (k>10)&&..ends(b, k, 8, "ficateur", .j) { d ..setto(.b, "fier", j, .k) }
	elseif (k>9)&&..ends(b, k, 7, "catrice", .j) { d ..setto(.b, "quer", j, .k) }
	elseif (k>8)&&..ends(b, k, 6, "cateur", .j) { d ..setto(.b, "quer", j, .k) }
	elseif (k>8)&&..ends(b, k, 6, "atrice", .j) { d ..setto(.b, "er", j, .k) }
	elseif (k>7)&&..ends(b, k, 5, "ateur", .j) { d ..setto(.b, "er", j, .k) }
	elseif (k>6)&&..ends(b, k, 5, "trice", .j) { d ..setto(.b, "teur", j, .k) }
	elseif (k>5)&&..ends(b, k, 4, "ième", .j) { d ..setto(.b, "", j, .k) }
	elseif (k>7)&&..ends(b, k, 5, "teuse", .j) { d ..setto(.b, "ter", j, .k) }
	elseif (k>6)&&..ends(b, k, 4, "teur", .j) { d ..setto(.b, "ter", j, .k) }
	elseif (k>5)&&..ends(b, k, 4, "euse", .j) { d ..setto(.b, "eu", j, .k) }
	elseif (k>8)&&..ends(b, k, 3, "ère", .j) { d ..setto(.b, "er", j, .k) }
	elseif (k>7)&&..ends(b, k, 3, "ive", .j) { d ..setto(.b, "if", j, .k) }
	elseif (k>4)&&..ends(b, k, 5, "folle", .j) { d ..setto(.b, "fou", j, .k) }
	elseif (k>4)&&..ends(b, k, 5, "molle", .j) { d ..setto(.b, "mou", j, .k) }
	elseif (k>9)&&..ends(b, k, 6, "nnelle", .j) { d ..setto(.b, "n", j, .k) }
	elseif (k>9)&&..ends(b, k, 6, "nnel", .j) { d ..setto(.b, "n", j, .k) }
	elseif (k>4)&&..ends(b, k, 3, "ète", .j) { d ..setto(.b, "et", j, .k) }
	elseif (k>8)&&..ends(b, k, 4, "ique", .j) { d ..setto(.b, "", j, .k) }
	elseif (k>8)&&..ends(b, k, 4, "esse", .j) { d ..setto(.b, "e", j, .k) }
	elseif (k>7)&&..ends(b, k, 5, "inage", .j) { d ..setto(.b, "in", j, .k) }
	elseif (k>9)&&..ends(b, k, 10, "ualisation", .j) { d ..setto(.b, "uel", j, .k) }
	elseif (k>9)&&..ends(b, k, 7, "isation", .j) { d ..setto(.b, "", j, .k) }
	elseif (k>9)&&..ends(b, k, 7, "isateur", .j) { d ..setto(.b, "", j, .k) }
	elseif (k>8)&&..ends(b, k, 5, "ation", .j) { d ..setto(.b, "", j, .k) }
	elseif (k>8)&&..ends(b, k, 5, "ition", .j) { d ..setto(.b, "", j, .k) }
	
	d ..normFrenchWord(.b, .k)
	s b=$e(b,1,k)
	quit b
}

ClassMethod normFrenchWord(ByRef b As %String, ByRef k As %Integer)
{
	d ..removeAllAccents(.b, .k)
	d ..removeDoublet(.b, .k)
	if (k>4) && ..ends(b, k, 2, "ie", .j) { s k=k-2 }
	if (k>4)
	{ s:$e(b,k)="r" k=k-1
	  s:$e(b,k)="e" k=k-1
	  s:$e(b,k)="e" k=k-1
	  s:$e(b,k)=$e(b,k-1) k=k-1
	}
	quit
}

ClassMethod removeAllAccents(ByRef b As %String, ByRef k As %Integer)
{
	s b=$tr(b,"àáâêéèîùûôçÀÂÄÈÉÊËÎÏÔÙÛÜ","aaaeeeiuuocAAAEEEEIIOUUU")
	// for i=1:1:k
	// { s:("àáâ"[$e(b,i)) $e(b,i)="a"
	//   s:("êéè"[$e(b,i)) $e(b,i)="e"
	//   s:("î"[$e(b,i)) $e(b,i)="i"
	//   s:("ùû"[$e(b,i)) $e(b,i)="u"
	//   s:("ô"[$e(b,i)) $e(b,i)="o"
	//   s:("ç"[$e(b,i)) $e(b,i)="c"
	// }
}

ClassMethod removeDoublet(ByRef b As %String, ByRef k As %Integer)
{
	i k>4
	{ s ch=$e(b,1)
	  for pos=2:1:k
	  { if ch = $e(b, pos) { s $e(b,pos-1,k-1)=$e(b,pos,k),k=k-1 } 
	    else { s ch = $e(b, pos) }
	  }
	}
	quit
}

}
