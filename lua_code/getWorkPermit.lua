local key = KEYS[1];
local value = ARGV[1];
local timeout = ARGV[2];

local ret = {};
local retPTTL1 = '';
local retPTTL2 = '';
local retSetNx = 0;
local retOwner = '';
local retExpire = 0;
local retSelect = 0;

local function getWorkerPermit()
    retPTTL1  = redis.call('PTTL', key);
    retSetNx  = redis.call('setnx', key, value);
    retOwner  = redis.call('get', key);
    retPTTL2  = redis.call('PTTL', key);

    if retSetNx == 1
    then retExpire = redis.call('pexpire', key, timeout);
        ret[0] = 1;
        ret[1] = retOwner;
        ret[2] = retPTTL1;
        ret[3] = retPTTL2;
        ret[4] = 0;
        print(ret);
        return {1, retOwner, retPTTL1, retPTTL2, 0};
    end;
    
    if retOwner == value or retOwner == nil
    then
        retExpire = redis.call('pexpire', key, timeout);
        ret[0] = 1;
        ret[1] = retOwner;
        ret[2] = retPTTL1;
        ret[3] = retPTTL2;
        ret[4] = 1;
        print(ret);
        return {1, retOwner, retPTTL1, retPTTL2, 1};
    end;

    ret[0] = 0;
    ret[1] = retOwner;
    ret[2] = retPTTL1;
    ret[3] = retPTTL2;
    ret[4] = 2;
    print(ret);
    return {0, retOwner, retPTTL1, retPTTL2, 2};
end; 

ret = getWorkerPermit(); 
return ret;
