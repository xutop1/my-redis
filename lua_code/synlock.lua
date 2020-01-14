local aa = redis.call('hmget', 'lock_time', KEYS[1])[1];
if (aa == nil or aa == false)
then
    redis.call('hmset', 'lock_time', KEYS[1], ARGV[1]);
    return 1;
else
    local bb = ARGV[1] - aa;

    if (bb >= tonumber(ARGV[2]) - 2) then
        redis.call('hmset', 'lock_time', KEYS[1], ARGV[1]);
        return 1;
    else
        return 0;
    end ;

end ;


