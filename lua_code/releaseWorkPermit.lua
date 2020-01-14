local key = KEYS[1];
local value = ARGV[1];

local ret = {};
local retOwner = '';
local retSelect = 0;
local retDel = 0;
local retPTTL1 = 0;

local function releaseWorkerPermit()
    retPTTL1  = redis.call('PTTL', key);
    retOwner  = redis.call('get', key);

    if (retOwner == nil or retOwner == '')
    then
        return {0, -1, -1};  
    end;

    if (retOwner == value)
    then
        retDel = redis.call('del', key);
        ret    = 0;
        return {0, 0, retPTTL1};
    else
        return {0, 1, retPTTL1};
    end;
end;

ret = releaseWorkerPermit();
return ret;

