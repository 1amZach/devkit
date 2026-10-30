lib.callback.register('devkit:canUse', function(source)
    return IsPlayerAceAllowed(source, Config.ace)
end)
