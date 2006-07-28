<cfsilent>
<cfparam name="form.thisLocale" type="string" default="th_TH">
<cfparam name="form.thisCalendar" type="string" default="buddhist">
<cfparam name="form.dateF" type="numeric" default="0">
<cfparam name="form.timeF" type="numeric" default="2">

<cfscript>
	thisNumber=10101.45;
	if (form.thisCalendar NEQ "none")
		form.thisLocale="#form.thisLocale#@calendar=#form.thisCalendar#"; 
	i18nUtils=createObject("component","i18nUtil").init();
	now=i18nUtils.toEpoch(now());
	locales=i18nUtils.getLocales();
	lang=i18nUtils.showLanguage(form.thisLocale);
	bestLocale=i18nUtils.acceptLanguage(CGI.HTTP_ACCEPT_LANGUAGE,arrayToList(locales));
	country=i18nUtils.showCountry(form.thisLocale);
	c=i18nUtils.showISOCountry(form.thisLocale);
	if (c NEQ "")
		timeZones=i18nUtils.getTZByCountry(c);
	else 	
		timeZones=listToArray(i18nUtils.getServerTZ());
	thisTZ=timezones[randRange(1,arrayLen(timeZones))];
	tDate=i18nUtils.i18nDateFormat(now,form.thisLocale,form.dateF,thisTZ);
	tDateTime=i18nUtils.i18nDateTimeFormat(now,form.thisLocale,form.dateF,form.timeF,thisTZ);
	thisFormattedNumber=i18nUtils.i18nCurrencyFormat(thisNumber,form.thisLocale);
	spelledOut=i18nUtils.i18nRuleBasedFormat(thisNumber,form.thisLocale);
	paperSize=i18nUtils.getPaperSize(form.thisLocale);
	version=i18nUtils.getVersion();
	tzOffset=i18nUtils.getTZOffset(now,thisTZ);
</cfscript>
</cfsilent>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<!--- yes i know, no directionality, language hints --->
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
	<title>i18n util Explorer</title>
</head>

<body>
<cfoutput>
<form action="i18nUtilTB.cfm" method="post">
<table border="1" cellspacing="1" cellpadding="1" bgcolor="##b0c4de" style="{font-size:85%;}">
<tr valign="top"><td align="right" valign="top"><b>choose locale</b>:</td>
<td><select name="thisLocale" size="1">
<cfloop index="i" from="1" to="#arrayLen(locales)#">
	<option value="#locales[i].toString()#">#locales[i].toString()#</option>
</cfloop>	
</select>
</td>
<td align="right" valign="top"><b>calendar:</b></td>
<td>
<select name="thisCalendar" size="1">
	<option value="none" SELECTED>--none--</option>
	<option value="buddhist">buddhist</option>
	<option value="chinese">chinese</option>	
	<option value="gregorian">gregorian</option>	
	<option value="japanese">japanese</option>
	<option value="islamic-civil">islamic-civil</option>
	<option value="islamic">islamic</option>	
	<option value="hebrew">hebrew</option>	
</select>
</td>
<td align="right" valign="top"><b>time format:</b></td>
<td>
<select name="timeF" size="1">
	<option value="0">Long</option>
	<option value="1">Full</option>
	<option value="2" SELECTED>Medium</option>
	<option value="3">Short</option>
</select>
</td>
<td align="right" valign="top"><b>date format:</b></td>
<td>
<select name="dateF" size="1">
	<option value="0" SELECTED>Long</option>
	<option value="1">Full</option>
	<option value="2">Medium</option>
	<option value="3">Short</option>
</select>
</td>
<td align="center">&nbsp;&nbsp;<input type="submit" value="test">&nbsp;&nbsp;</td>
</tr>
</form>
<tr valign="top">
<td align="center" colspan="10" bgcolor="##b0c4de">&nbsp;<b>Results</b>&nbsp;</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>Locale:</b></td>
<td colspan="10" bgcolor="##87ceeb">#form.thisLocale#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>acceptable locale:</b></td>
<td colspan="10" bgcolor="##87ceeb">#bestLocale.locale# <font size="-1">(derived from accept language)</font></td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>Timezone(s):</b></td>
<td colspan="10" bgcolor="##87ceeb">
<select name="tz" size="1">
<cfloop index="i" from="1" to="#arrayLen(timezones)#">
	<option value="#timezones[i]#">#timezones[i]#</option>
</cfloop>	
</select>
&nbsp;&nbsp;
<cfif arrayLen(timezones) GT 1>
using: <b>#thisTZ#</b>
</cfif>
&nbsp;<font size="-1">(timezone derived from country or server if no country)</font>
</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>timezone offset:</b></td>
<td colspan="10" bgcolor="##87ceeb">#tzOffset# hours</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>isBidi:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.isBIDI(form.thisLocale)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>showLanguage:</b></td>
<td colspan="10" bgcolor="##87ceeb">#lang#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>showCountry:</b></td>
<td colspan="10" bgcolor="##87ceeb"><cfif len(trim(country))>#country#<cfelse>&nbsp;</cfif></td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nIntegerFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nIntegerFormat(thisNumber,form.thisLocale)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nDecimalFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nDecimalFormat(thisNumber,form.thisLocale)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nBigDecimalFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nBigDecimalFormat(thisNumber*1000000000,form.thisLocale)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nCurrencyFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nCurrencyFormat(thisNumber,form.thisLocale)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nPercentFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nPercentFormat(0.145,form.thisLocale)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nParseNumber:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nParseNumber(thisFormattedNumber,form.thisLocale)# (original value: #thisFormattedNumber#)</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nRuleBasedFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#spelledOut# (spellout)</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nRuleBasedParse:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nRuleBasedParse(spelledOut,form.thisLocale)# (original value: #spelledout#)</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nDateTimeFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nDateTimeFormat(now,form.thisLocale,dateF,timeF,thisTZ)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nDateFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nDateFormat(now,form.thisLocale,form.dateF,thisTZ)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nTimeFormat:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nTimeFormat(now,form.thisLocale,form.timeF)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nDateParse:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nDateParse(tDate,form.thisLocale)# (original date: #tDate#)</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>i18nDateTimeParse:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.i18nDateTimeParse(tDateTime,form.thisLocale)# (original datetime: #tDateTime#)</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>getDateTimePattern:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.getDateTimePattern(form.thisLocale)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>formatDateTime:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.formatDateTime(now,form.thisLocale,"d MMMM yyyy")# (using "d MMMM yyyy")</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>isMetric:</b></td>
<td colspan="10" bgcolor="##87ceeb">#i18nUtils.isMetric(form.thisLocale)#</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>paper size:</b></td>
<td colspan="10" bgcolor="##87ceeb">
page size:=#paperSize.size#<br>width:=#paperSize.width#<br>height:=#paperSize.height#
</td>
</tr>
<tr valign="top">
<td align="right" valign="top"><b>version:</b></td>
<td colspan="10" bgcolor="##87ceeb">
I18NUtilVersion:=#version.I18NUtilVersion#<br>
I18NUtilDate:=#version.I18NUtilDate#<br>
icu4jVersion:=#version.icu4jVersion#<br>
icu4jRuntime:=#version.icu4jRuntime#<br>
icu4jCollation:=#version.icu4jCollation#
</td>
</tr>
</table>
</cfoutput>
</body>
</html>
