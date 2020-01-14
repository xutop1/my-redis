--限价合约卖单
local res = '';
--code transationid
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

local function append_str(user_id,saAccount_id,order_id,order_type,order_price,order_num,order_total_num,order_freeze_balance,lever)
    return user_id..','..saAccount_id..','..order_id .. ','..order_type..',' .. order_price .. ',' .. order_num..','
            ..order_total_num..','..order_freeze_balance..','..lever;
end
--Redis Value
local redisValue = append_str(user_id,saAccount_id,order_id,order_type,order_price,order_num,order_num,order_freeze_balance,lever)
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
local function insertselllist()
    local i = 0;

    while (true)
    do
        --循环取出卖单数据
        local aa = redis.call('LINDEX', sell_redis_key, i);
        if (aa == false) then
            if (i == 0) then
                --根据索引i=0找不到数据放头部
                redis.call('LPUSH', sell_redis_key, redisValue);
            else
                --根据索引i>0找不到放尾部
                redis.call('RPUSH', sell_redis_key, redisValue);
            end ;
            break ;
        end ;

        local content = split(aa, ',');
        --res = res..price..content[1];
        if (tonumber(order_price) >= tonumber(content[5])) then
            --按卖单价格最高到价格最低排序
            redis.call('LINSERT', sell_redis_key, 'BEFORE', aa, redisValue);
            break ;

        end ;
        i = i + 1;
    end ;
end;

local function findnum(arr_result)
    local _order_num = arr_result[6];
    if (tonumber(order_num) < tonumber(_order_num)) then
        --卖单数量<买单数量
        local left = _order_num - order_num;
        redis.call('LPUSH', buy_redis_key, updatedStr(arr_result,string.format("%.0f", left)));
        res = res .. ',' ..updatedStr(arr_result,string.format("%.0f", order_num));
        order_num = 0;
        lasthasleft = 1;
    else
        res = res .. ',' .. updatedStr(arr_result);
        --卖单数量-买单数量
        order_num = order_num - _order_num;
        redisValue = append_str(user_id,saAccount_id,order_id,order_type,order_price,order_num,order_num,order_freeze_balance,lever)
    end ;

end;

--根据买单价/格数量匹配卖单
local function findprice(arr_result)
    local _order_price = arr_result[5];
    if (tonumber(order_price) <= tonumber(_order_price)) then
        --卖单价格<=买单价格
        findnum(arr_result);
    else
        --卖单价格>排好序的最大买单价格，订单无法成交num=0退出程序
        redis.call('LPUSH', buy_redis_key,updatedStr(arr_result));
        insertselllist();
        order_num = 0;
    end
end;

local function limitsell()
    while true do
        local str_result = redis.call('LPOP', buy_redis_key);
        if (str_result == false) then
            --没有买单列表,插入卖单，退出
            insertselllist();
            break ;
        end ;
        local arr_result = split(str_result, ',');
        findprice(arr_result);
        if (order_num == 0) then
            break ;
        end ;
    end ;
end;

limitsell();
res = res .. ',' .. lasthasleft;
return res;
