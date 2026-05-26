Config = {}

Config.Framework = 'ESX'

Config.Database = {
    table_prefix = 'gift_system_'
}

Config.Web = {
    port = 3000,
    admin_password = 'admin123'
}

Config.GiftTypes = {
    money = {
        enabled = true,
        label = '货币'
    }
}

Config.RedPacket = {
    max_players = 100,
    timeout = 300, -- 秒
    modes = {
        random = {
            label = '随机分配',
            description = '金额随机分给抢到的玩家'
        },
        equal = {
            label = '平均分配',
            description = '金额平均分给抢到的玩家'
        },
        first_come = {
            label = '先到先得',
            description = '前N个玩家抢到全额'
        }
    }
}

Config.MoneyTypes = {
    money = { label = '现金', account = 'money' },
    bank = { label = '银行', account = 'bank' },
    black_money = { label = '黑钱', account = 'black_money' }
}
