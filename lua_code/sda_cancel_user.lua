local sdaId = KEYS[1];
--类型buy or sell
local orderType = ARGV[1];
local userId = ARGV[2];
--eg:sda_sell_15
local redis_key = 'sda_'..orderType..'_'..sdaId;
--返回结果
local arr_return = {};


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

--撤销订单
local arr_list = redis.call('LRANGE', redis_key, "0","-1");
for i=1,#arr_list do
    local index = string.find(arr_list[i],userId);

    if(index ~= nil) then
        --存在用户订单，撤销,因为有订单id所以内容不会重复
        local arr_result = split(arr_list[i], ',');
        local user_id = arr_result[1]
        if(user_id == userId) then
            local num = redis.call("LREM",redis_key,'0',arr_list[i]);
            for i= 1, num do
                --拼接爆仓列表
                table.insert(arr_return, arr_list[i]);
            end
        end
    end
end

return arr_return;


