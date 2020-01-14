--市价合约买单
local res = '';
--sdaId
local code = KEYS[1];
--用户余额
local allprice = ARGV[1];
--下单数量
local targetnumber = ARGV[2];
local canbuynum = 0;
local lasthasleft = 0;
--transtionCurrencyUnitMin
local numunit = ARGV[3];
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
    local actualnum = canbuynum;
    local _order_price = arr_result[5];
    local _order_num = arr_result[6];
    if (tonumber(targetnumber) < actualnum) then
        actualnum = tonumber(targetnumber);
    end ;
    if (actualnum < tonumber(_order_num)) then
        local left = _order_num - actualnum;
        redis.call('RPUSH', sell_redis_key, append_str(arr_result,string.format("%.0f", left)));
        res = res .. ',' .. append_str(arr_result,string.format("%.0f", actualnum));
        allprice = allprice - actualnum * _order_price;
        targetnumber = targetnumber - actualnum;
        lasthasleft = 1;
    else
        res = res .. ',' ..append_str(arr_result);
        allprice = allprice - _order_num * _order_price;
        targetnumber = targetnumber - _order_num;
    end ;
end;

local function findfit()
    while true do
        --卖单最后一条数据，即价格最低数据
        local str_result = redis.call('RPOP', sell_redis_key);
        if (str_result == false) then
            break ;
        end ;

        local arr_result = split(str_result, ',');
        local _order_price = arr_result[5];
        canbuynum = math.floor(math.floor(allprice / _order_price) / numunit) * 100000000;
        if (canbuynum <= 0) then
            redis.call('RPUSH', sell_redis_key, str_result);
            break ;
        end ;

        findprice_num(arr_result);

        if (allprice <= 0 or targetnumber <= 0) then
            break ;
        end ;
    end ;
end;

findfit();
res = res .. ',' .. lasthasleft;
return res;
