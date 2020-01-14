--合约市价平空
local res = '';
local code = KEYS[1];
local sell_redis_key = 'sda_sell_'..code;
--订单数量
local order_num = ARGV[1];
local lasthasleft = 0;

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
--拼接redisValue
local function append_str(arr_result,order_num)
    local orderNum = '';
    if (order_num == nil) then
        orderNum = arr_result[6];
    else
        orderNum = order_num;
    end
    return arr_result[1]..','..arr_result[2]..','..arr_result[3] .. ','..arr_result[4]..',' .. arr_result[5] .. ','
            .. orderNum ..','..arr_result[7]..','..arr_result[8]..','..arr_result[9];
end

local function findprice_num(arr_result)
    local _order_num = arr_result[6];
    local left = order_num - _order_num;
    if (left >= 0) then
        res = res .. ',' .. append_str(arr_result,string.format("%.0f", _order_num));
        order_num = left;
    else
        res = res .. ',' .. append_str(arr_result,string.format("%.0f", order_num));
        order_num = 0;
        redis.call('RPUSH', sell_redis_key,append_str(arr_result,string.format("%.0f", (0 - left))));
        lasthasleft = 1;
    end ;
end;

local function findfit()
    while true do
        local str_result = redis.call('RPOP', sell_redis_key);
        if (str_result == false) then
            break ;
        end ;
        local arr_result = split(str_result, ',');
        findprice_num(arr_result);
        if (order_num == 0) then
            break ;
        end ;
    end ;
end;


findfit();
res = res .. ',' .. lasthasleft;
return res;
