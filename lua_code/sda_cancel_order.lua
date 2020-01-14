local res = '';
--sdaId
local code = KEYS[1];
--类型buy or sell
local type = ARGV[1];
--订单id
local id = ARGV[2];
local i = 0;
local buy_redis_key = 'sda_buy_'..code;
local sell_redis_key = 'sda_sell_'..code;

local function split(str, delimiter)
    if str == nil or str == '' or delimiter == nil then
        return nil
    end

    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local ret = -100;

if (type == 'buy')
then
    while true do
        local aa = redis.call('LINDEX', buy_redis_key, i);
        i = i + 1;
        if (aa == false) then
            return -1;  -- buy order isn't exist
        end ;
        local bb = split(aa, ',');
        local _id = bb[3];
        bb = nil;
        if (_id == id)
        then
            ret = redis.call('LREM', buy_redis_key, 1, aa);
            return ret; -- num buy order deleted
        end ;
    end ;
elseif (type == 'sell')
then
    while true do
        local aa = redis.call('LINDEX', sell_redis_key, i);
        i = i + 1;
        if (aa == false) then
            return -2;  -- sell order isn't exist
        end ;
        local bb = split(aa, ',');
        local _id = bb[3];
        bb = nil;
        if (_id == id)
        then
            ret = redis.call('LREM', sell_redis_key, 1, aa);
            return ret; -- num sell order deleted
        end ;
    end ;
else
    return -100;  -- invalid type (not 'buy' and 'sell')
end ;
