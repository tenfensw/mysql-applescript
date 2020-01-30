# MySQL Connector/AppleScript (an unofficial one)

*Copyright (C) Tim K 2019-2020 <timprogrammer@rambler.ru>*

I know this is something unusual for me to publish an AppleScript library, but I needed a way to interface with MySQL from AS, so I made this. The connector is really basic and requires either a full MySQL installation on your Mac or MySQL Workbench to be installed.

## Usage

```
-- Our example table has the following columns:
-- username, password, chatPoints


set mySQLServerIP to "localhost" -- the server to connect to. Must be a valid MySQL Server 5.5+ powered DB server
set mySQLUser to "root" -- the user to use for the connection. root might be okay for testing purposes, but I would use another user if I were you
set mySQLPassword to "meowiemeow" -- the plain text password for the specified user. If the user does not have a password, just use an empty string.
set mySQLDatabase to "catchat" -- the name of your database. While not needed during connection, will be absolutely required when running INSERT/SELECT queries.
set mySQLTable to "users" -- the name of your table.

tell script "MySQL"
	set mySQLConnection to connect into mySQLServerIP given username:mySQLUser, password:mySQLPassword -- this will establish the connection to the remote MySQL server with the specified credentials and will return a connection record
	set allUserNames to {}
	
	set selectQueryResult to select in mySQLTable given database:mySQLDatabase, filter:{}, connection:mySQLConnection, columns:{"username"}
	-- the above line will run a select query on the specified table
	-- it will return a list of records
	-- the above line will run this query:
	-- SELECT username FROM catchat.users;
	repeat with recordPtr in selectQueryResult
		set end of allUserNames to (username of recordPtr) as text
	end repeat

	set whatToDo to button returned of (display dialog "What would you like to do?" buttons {"View all users", "Add a new one"}
	if whatToDo starts with "View all" then
		choose from list allUserNames with prompt "Available users"
	else
		set un to display dialog "Username" default answer ""
		set pswd to display dialog "Password hash" default answer ""
		set points to 10
		if allUserNames contains un then
			display alert "User '" & un & "' already exists!"
		else
			insert into mySQLTable given database:mySQLDatabase, connection:mySQLConnection, columns:{"username", "password", "chatPoints"}, values:{un, pswd, points}
			-- will insert into table
			display alert "Success!"
		end if
	end if
end tell
```

Of course, you can run custom queries to:
```
tell script "MySQL"
	set mySQLConnection to connect into "localhost" given username:"root", password:""
	display alert query given connection:mySQLConnection, query:"SELECT 1"
end tell
```

## Installation
Grab a .scpt compiled copy of MySQL Connector/AppleScript from the releases page and put it into ``/Library/Script Libraries``.

Notice, that MySQL Connector/AppleScript requires macOS 10.9 or newer. A Snow Leopard-compatible release might be coming soon.

## License
0BSD

	
