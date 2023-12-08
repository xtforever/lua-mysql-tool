LUAMYSQL SUPPORT TOOL: 

REQUIREMENTS: https://github.com/ouonline/lua-mysql

TL;DR: sql-tool.lua --> function sql2(c,s,...)

The Idea: Make it simple to retrieve one item from an MYSQL SERVER

Very often i have to lookup one name or number from my Databases,
so i created a lua function that can do this and also can return
multiple values.

currently the function sql2() has four interfaces:

1) -- single value, no variable expansion
   s = sql2( c, "select @@version" )

2) -- single value, first row, variable expansion
   s = "select cn from users where uid='${uid}'"
   cn = sql2( c, s, { uid='jeh' } )

3) -- many values, single row
   s = "select cn,dn from users where uid='${uid}'"
   cn,dn = sql2( c, s , { uid='jeh', ret="cn,dn" } )

4) -- many values, manny rows
   s = "select cn,dn from users where uid like '${uid}' limit 100"
   cn,dn = sql2( c, s , { uid='s%', ret="cn,dn", rows = 100 } )

   for i=1,#cn do
      echo( "cn:", cn[i], " dn:", dn[i] )
   end
