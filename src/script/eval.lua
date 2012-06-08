module(..., package.seeall)
function eval(db, script, ...)
    return db:command("eval",script,0,...);
end
