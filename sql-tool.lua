local mysql = require('luamysql')

dry_run=1
loglevel = 2

dbarg = {
    -- host = "127.0.0.1", -- required
    -- port = 3306, -- required
    --user = "ben", -- optional
    --password = "123test", -- optional
    --db = "acme", -- optional
}

function mysql_default()
   local k,v,line
   local home = os.getenv( "HOME" ) 
   local file = io.open( home .. "/.my.cnf", "r");
   if not file then return end
   for line in file:lines() do
      if  not string.find(line, "%s*#" )  then
	 _,_,k,v = string.find(line, "%s*(%S+)%s*=%s*(%S+)" )
	 if k then
	    dbarg[k]=v
	 end
      end
   end
end

	 

 
function exit(s)
  return os.exit(s)
end	 

function print(...)
    io.write(...)
end

function echo(...)
  args={...}
  table.insert(args, "\n" )
  print( table.unpack(args) )  
end

function debug(...)
  if loglevel > 1 then
    echo(...)
  end
end



function interp(s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

function sql_connect()
   local client, errmsg = mysql.newclient(dbarg)
   if errmsg ~= nil then
      io.write("connect to mysql error: ", errmsg, "\n")
      return nil
   end

   local p = dbarg.db or dbarg.database
   if p then
      errmsg = client:selectdb(p)
      if errmsg ~= nil then
	 io.write("selectdb error: ", errmsg, "\n")
	 return nil
      end
   end

   errmsg = client:setcharset("utf8")
   if errmsg ~= nil then
      io.write("setcharset error: ", errmsg, "\n")
      return nil
   end

   errmsg = client:ping()
   if errmsg ~= nil then
      io.write("ping: ", errmsg, "\n")
      return nil
   end
   
   result, errmsg = client:escape("'ouonline'")
   if errmsg ~= nil then
      io.write("escape error: ", errmsg, "\n")
      return nil
   end

   return client   
end

function sql(c,s,tab)
  i=interp(s,tab)
  debug(i)
  result, errmsg = c:execute( interp(s,tab) )
  if errmsg ~= nil then
    print("execute error: ", errmsg, "\n")
    exit(1)
  end
  return result
end

-- returns the first element of the first result row
-- if ret is defined it returns the mentioned values from the first result row
-- if rows and ret defined it returns multiple values and multiple rows
function sql2(c,s,...)
  local args={...}
  local tab={}
  local vars={}
  local ret={}
  local vals={}
  local fieldn = {}
  
  if #args > 0 then
     tab = args[1]
  else
     tab = {}
  end   
  r=sql(c,s,tab)
  if r:size() < 1 then
     	return nil
  end
  local fetch_row = r:recordlist()

  vals = fetch_row()
  vars =  tab["ret"]
  if vars == nil then
        return vals[1]
  end

  -- map field name to index
  for k,v in pairs(r:fieldnamelist()) do
    fieldn[v]=k
  end

  local rows = tab["rows"] or 1

  if rows < 2 then
     -- map str to fieldname to index to sql result
     for str in string.gmatch(vars, "([^,]+)") do
     	local n = fieldn[str]
     	if n ~= nil then
       	   n = vals[n]
     	else
           n = ""
	end
	table.insert( ret, n )
     end
     return table.unpack(ret)
  end
  
  -- create a table for each returned row
  local i=0
  local var_cnt=0
  local varname={}
  for str in string.gmatch(vars, "([^,]+)") do
     var_cnt = var_cnt + 1
     varname[var_cnt] = fieldn[str]
     ret[ var_cnt ] = {}
  end

  while( vals ~= nil and rows > 0 ) do
     for i = 1,var_cnt do
	local v = vals[ varname[i] ]
	table.insert( ret[i], v )
     end
     vals = fetch_row()
     rows = rows -1
  end
  return table.unpack(ret)
  

end


function demo1()
   local c,cn,dn,s
   
   mysql_default()
   c = sql_connect()
   if not c  then
      exit(1)
   end
   -- single value, no variable expansion
   s = sql2( c, "select @@version" )
   echo( "Version is: ", s )
   
   -- single value, single row
   s = "select cn from users where uid='${uid}'"
   cn = sql2( c, s, { uid='jeh' } )
   echo( "common name is: ", cn )

   -- many values, single row
   s = "select cn,dn from users where uid='${uid}'"
   cn,dn = sql2( c, s , { uid='jeh', ret="cn,dn" } )
   echo( "common name is: ", cn, " dn:", dn )

   -- many values, manny rows
   s = "select cn,dn from users where uid like '${uid}' limit 100"
   cn,dn = sql2( c, s , { uid='s%', ret="cn,dn", rows = 100 } )

   for i=1,#cn do
      echo( "cn:", cn[i], " dn:", dn[i] )
   end

end

--
-- MAIN
--
demo1()


