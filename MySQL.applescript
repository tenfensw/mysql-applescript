-- MySQL Connector/AppleScript
-- Copyright (C) Tim K 2019-2020 <timprogrammer@rambler.ru>
use framework "Foundation"
use AppleScript version "2.3"
use scripting additions

on _mySQLCLIWrapper(hostname, username, passwordv, queryv)
	set mysqlExecutable to "mysql"
	set mysqlAttrExecutable to system attribute "MYSQL"
	set workbenchPresent to false
	set serverPresent to false
	tell application "System Events"
		set workbenchPresent to exists file "/Applications/MySQLWorkbench.app/Contents/MacOS/mysql"
		set serverPresent to exists file "/usr/local/mysql/bin/mysql"
	end tell
	if (length of mysqlAttrExecutable) is greater than 0 then
		set mysqlExecutable to mysqlAttrExecutable
	else if serverPresent then
		set mysqlExecutable to "/usr/local/mysql/bin/mysql"
	else if workbenchPresent then
		set mysqlExecutable to "/Applications/MySQLWorkbench.app/Contents/MacOS/mysql"
	end if
	set hostname to quoted form of hostname
	set username to quoted form of username
	set queryv to quoted form of queryv
	set cmd to (quoted form of mysqlExecutable) & " -h" & hostname & " -u" & username & " -e" & queryv
	if (length of passwordv) is greater than 0 then
		set passwordv to "-p" & quoted form of passwordv
	else
		set passwordv to ""
	end if
	set cmd to cmd & " " & passwordv
	set resultat to do shell script cmd
	if resultat starts with "ERROR " then
		error ("MySQL " & resultat) number 9998
	end if
	return resultat
end _mySQLCLIWrapper

on _mySQLReplaceInString(instr, whatstr, repstr)
	return ((current application's NSString's stringWithString:instr)'s stringByReplacingOccurencesOfString:whatstr withString:repstr) as text
end _mySQLReplaceInString

on _mySQLSecurifyArgument(strArg)
	set resultat to "\"" & _mySQLReplaceInString(strArg, "\"", "\\\"") & "\""
	return resultat
end _mySQLSecurifyArgument

on connect into hostname given username:username, password:passwordv
	set conver to {host:hostname, usern:username, password:passwordv}
	_mySQLCLIWrapper(hostname, usern of conver, password of conver, "SELECT 1")
	return conver
end connect

on _mySQLJoinStringList(listing, sepv)
	if class of listing is not list then
		return listing as text
	end if
	set resultat to ""
	set firstv to true
	repeat with itm in listing
		set itm to itm as text
		if firstv then
			set resultat to itm
			set firstv to false
		else
			set resultat to resultat & sepv & " " & itm
		end if
	end repeat
	return resultat
end _mySQLJoinStringList

on _mySQLReallyFastSplit(str, delims)
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delims
	set resultat to every text item of str
	set AppleScript's text item delimiters to oldDelims
	return resultat
end _mySQLReallyFastSplit

on select of table given connection:serverConfig, database:dbName, columns:columnsList, filter:whereConditionsList
	set query to "SELECT " & _mySQLJoinStringList(columnsList, ",") & " FROM `" & dbName & "`.`" & table & "`"
	if (length of whereConditionsList) is greater than 1 then
		set query to query & " WHERE " & _mySQLJoinStringList(columnsList, " AND")
	end if
	set wrapperOut to _mySQLCLIWrapper(host of serverConfig, usern of serverConfig, password of serverConfig, query)
	set resultatTmp to _mySQLReallyFastSplit(wrapperOut, {(ASCII character 10), (ASCII character 13)})
	set resultat to {}
	set columnsAvailable to {}
	set firstv to true
	set rowCount to -1
	repeat with ln in resultatTmp
		set rowCount to rowCount + 1
		set splitLn to _mySQLReallyFastSplit(ln, tab)
		if firstv then
			set columnsAvailable to splitLn
			set firstv to false
		else
			set outputEval to "{"
			repeat with i from 1 to (length of splitLn)
				set vv to ((item i of splitLn) as text)
				set pair to ((item i of columnsAvailable) as text) & ":\"" & vv & "\","
				if vv is not equal to "NULL" then
					set outputEval to outputEval & pair
				end if
			end repeat
			set outputEval to outputEval & "__mysqlConnector_row:" & rowCount & "}"
			set recordv to run script outputEval
			set end of resultat to recordv
		end if
	end repeat
	return resultat
end select

on _mySQLConvertIntoCorrectArguments(mvls)
	if class of mvls is not list then
		return ""
	end if
	-- display alert "mvls = " & _mySQLJoinStringList(mvls, ",")
	set resultat to {}
	repeat with itm in mvls
		if (class of itm) is integer or (class of itm) is real then
			set end of resultat to itm as text
		else
			set end of resultat to "\"" & _mySQLSecurifyArgument(itm as text) & "\""
		end if
	end repeat
	set resultat2 to _mySQLJoinStringList(resultat, ",")
	-- display alert "resultat2 = " & resultat2
	return resultat2
end _mySQLConvertIntoCorrectArguments

on insert into table given connection:connection, database:dbName, columns:columnsAvailable, values:matchingValues
	-- display alert _mySQLJoinStringList(matchingValues, ",")
	set query to "INSERT INTO `" & dbName & "`.`" & table & "` (" & _mySQLJoinStringList(columnsAvailable, ",") & ") VALUES (" & _mySQLConvertIntoCorrectArguments(matchingValues) & ")"
	_mySQLCLIWrapper(host of connection, usern of connection, password of connection, query)
end insert

on query given connection:connection, query:query
	return _mySQLCLIWrapper(host of connection, usern of connection, password of connection, query)
end query
