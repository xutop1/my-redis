--限价合约平空
local res = '';
--sdaId
local code = KEYS[1];
local order_id = ARGV[1];
local order_price = ARGV[2];
--下单数量
local order_num = ARGV[3];
--合约订单类型
local order_type = ARGV[4];
local user_id = ARGV[5];
--合约账户id
local saAccount_id = ARGV[6];
--订单冻结金额
local order_freeze_balance = ARGV[7];
--杠杆倍数
local lever = ARGV[8];
local buy_redis_key = 'sda_buy_'..code;
local sell_redis_key = 'sda_sell_'..code;

--是否部分交易
local lasthasleft = 0;

--最基本的原理，从哪个方向拿出来，从哪个方向塞回去
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

local function append_str(user_id,saAccount_id,order_id,order_type,order_price,order_num,order_total_num,order_freeze_balance,lever)
    return user_id..','..saAccount_id..','..order_id .. ','..order_type..',' .. order_price ..','.. order_num..','
            ..order_total_num..','..order_freeze_balance..','..lever;
end;
--Redis Value
local redisValue = append_str(user_id,saAccount_id,order_id,order_type,order_price,order_num,order_num,order_freeze_balance,lever);
local function updatedStr(arr_result,order_num)
    local orderNum = '';
    if (order_num == nil) then
        orderNum = arr_result[6];
    else
        orderNum = order_num;
    end
    return arr_result[1]..','..arr_result[2]..','..arr_result[3] .. ','..arr_result[4]..',' .. arr_result[5] .. ','
            .. orderNum ..','..arr_result[7]..','..arr_result[8]..','..arr_result[9];
end
--排序方式为从大到小，从最价格最高到价格最低
local function insert_buylist()
    local i = 0;
    while (true)
    do
        local aa = redis.call('LINDEX', buy_redis_key, i);
        if (aa == false) then
            if (i == 0) then
                --买单列表为空
                redis.call('LPUSH', buy_redis_key, redisValue);
            else
                --买单列表非空，插到结尾
                redis.call('RPUSH', buy_redis_key, redisValue);
            end ;
            break ;
        end ;

        local content = split(aa, ',');
        if (tonumber(order_price) > tonumber(content[5])) then
            redis.call('LINSERT', buy_redis_key, 'BEFORE', aa, redisValue);
            break ;
        end ;
        i = i + 1;
    end ;
end;

local function findnum(arr_result)
    local _order_num = arr_result[6];
    if (tonumber(order_num) < tonumber(_order_num)) then
        --限价买单，买单数量小于卖单数量，造成部分成交
        local left = _order_num - order_num;
        redis.call('RPUSH', sell_redis_key,updatedStr(arr_result,string.format("%.0f", left)));
        res = res .. ',' .. updatedStr(arr_result,string.format("%.0f", order_num));
        order_num = 0;
        lasthasleft = 1;
    else
        res = res .. ',' ..updatedStr(arr_result);
        order_num = order_num - _order_num;
        redisValue = append_str(user_id,saAccount_id,order_id,order_type,order_price,order_num,order_num,order_freeze_balance,lever);
    end ;

end;

local function findprice(arr_result)
    local _order_price = arr_result[5];
    if (tonumber(order_price) >= tonumber(_order_price)) then
        findnum(arr_result);
    else
        --买单价格小于卖单价格。不成交将取出的数据重新放入redis列表
        redis.call('RPUSH', sell_redis_key, updatedStr(arr_result));
        insert_buylist();
        order_num = 0;
    end
end;

local function limit_buy()
    while true do
        --取出列表最后的元素，即最低的卖价
        local str_result = redis.call('RPOP', sell_redis_key);
        if (str_result == false) then
            insert_buylist();
            break ;
        end ;
        local arr_result = split(str_result, ',');
        findprice(arr_result);
        if (order_num == 0) then
            break ;
        end ;
    end ;
end;

limit_buy();
res = res .. ',' .. lasthasleft;
return res;