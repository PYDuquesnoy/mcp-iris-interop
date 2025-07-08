/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// See <CLASS>%Text.Text</CLASS>
/// <p>
/// The <CLASS>%Text.German</CLASS> class implements the German language-specific stemming algorithm
/// and initializes the language-specific list of noise words.</p>
/// 
Class %Text.German Extends %Text.Text [ System = 4 ]
{

Parameter DICTIONARY = 4;

Parameter SOURCELANGUAGE = "de";

Parameter NOISEWORDS100 = "von zu und a in ist es Sie das er war für auf seien mit wie seins sie seien an ein haben dieses von oder hatte durch heiß Wort aber was einige wir Dose aus anderes waren alle dort wenn herauf verwenden Ihr wie besagt jedes sie welches ihr Zeit wenn Wille Weise über viele dann sie schreiben wurde wie so diese sie lang bilden Sache sehen er zwei hat Blick mehr Tag könnte gehen gekommen Zahl Ton nein meisten Leute mein rüber wissen Wasser als Anruf zuerst wer können unten Seite gewesen jetzt Entdeckung irgendwelche neu Arbeit Teil Nehmen erhalten";

Parameter NOISEWORDS200 = "Platz gebildet Phasen wo nachher Rückseite wenig nur rund Mann Jahr kam Erscheinen jedes gut ich Geben unser unter Name sehr durch gerade Form Satz groß denken Sagen Hilfe niedrig Linie unterscheiden Umdrehung Ursache viel Mittel vorher Bewegung Recht Junge alt auch selben sagen Sie Satz drei wünschen Luft Brunnen auch Spiel klein Ende gesetzt Haupt gelesen Hand Tor groß Bann fügen hinzu glätten Land hier Muß groß hoch so folgen Tat warum bitten Männer Änderung ging Licht freundlich weg Notwendigkeit Haus Abbildung Versuch wir wieder Tier Punkt Mutter Welt nahe Bau Selbst Masse Vater Kopf Standplatz besitzen Seite wenn Land gefunden Antwort Schule";

Parameter NOISEWORDS300 = "wachsen Studie noch erlernen Betrieb Abdeckung Nahrung Sonne vier zwischen Zustand Unterhalt Auge nie Letztes gelassen Gedanke Stadt Baum Kreuz Bauernhof stark Anfang Macht Geschichte Säge weit Meer abgehobener Betrag link spät Durchlauf nicht während Presse Ende Nacht real Leben wenige Nord geöffnet scheinen zusammen zunächst weiß Kinder fangen erhalten Weg Beispiel Mühelosigkeit Papier Gruppe immer Musik die beide Markierung häufig Buchstabe bis Meile Fluß Auto Füße Obacht zweitens Buch tragen Sie nahm Wissenschaft essen Raum Freund fing an Idee Fische Berg Anschlag sobald Unterseite hören Pferd Schnitt sicher Uhr Farbe Gesicht Holz hauptsächlich genug Ebene Mädchen üblich jung bereiten über überhaupt rot Liste obwohl Gefühl";

ClassMethod removeAllAccents(ByRef b As %String, ByRef k As %Integer)
{
	s b=$tr(b,"äöü","aou")
	// for i=1:1:k
	// { s:($e(b,i)="ä") $e(b,i)="a"
	//   s:($e(b,i)="ö") $e(b,i)="o"
	//   s:($e(b,i)="ü") $e(b,i)="u"
	// }
}

/// Simple German stemmer.  See http://www.unine.ch/info/clef/germanStemmer.txt
ClassMethod stemWord(ByRef b As %String) As %String
{
	s k = $l(b)
	quit:k<=4 b				; don't stem if the word has length <= 4
	s j=""
	do ..removeAllAccents(.b, .k)
	if k>6 {if ..ends(b, k, 3, "nen", .j) {d ..setto(.b, "", j, .k) s b=$e(b,1,k) q b}}
	if k>5
	{ if (..ends(b, k, 2, "en", .j) ||
	     (..ends(b, k, 2, "se", .j)) ||
	     (..ends(b, k, 2, "es", .j)) ||
	     (..ends(b, k, 2, "er", .j)) ) { d ..setto(.b, "", j, .k) s b=$e(b,1,k) q b}
	}
	s:($e(b,k)="n") k=k-1
	s:($e(b,k)="s") k=k-1
	s:($e(b,k)="r") k=k-1
	s:($e(b,k)="e") k=k-1
	s b=$e(b,1,k)
	quit b
}

}
