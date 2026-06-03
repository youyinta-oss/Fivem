Config = {}

-- 通用设置
Config.Locale = 'zh'
Config.Debug = false
Config.AdminKey = 'F1' -- 打开管理面板的快捷键
Config.CooldownHighRisk = 300 -- 高危操作冷却时间（秒）
Config.MaxHighRiskActions = 3 -- 冷却期内最大高危操作次数

-- 权限分级
Config.Permissions = {
    ['user'] = {},
    ['helper'] = {
        'players.list',
        'reports.view',
    },
    ['mod'] = {
        'players.list',
        'reports.view',
        'player.kick',
        'player.freeze',
        'player.teleport',
        'player.mute',
        'player.spectate',
    },
    ['admin'] = {
        'players.list',
        'reports.view',
        'player.kick',
        'player.freeze',
        'player.teleport',
        'player.mute',
        'player.spectate',
        'player.ban',
        'player.unban',
        'player.money.set',
        'player.money.give',
        'player.money.remove',
        'player.job.set',
        'player.group.set',
        'vehicle.spawn',
        'vehicle.delete',
        'vehicle.repair',
        'world.weather',
        'world.time',
        'world.noclip',
        'server.announce',
        'audit.view',
    },
    ['superadmin'] = {
        'players.list',
        'reports.view',
        'player.kick',
        'player.freeze',
        'player.teleport',
        'player.mute',
        'player.spectate',
        'player.ban',
        'player.unban',
        'player.money.set',
        'player.money.give',
        'player.money.remove',
        'player.job.set',
        'player.group.set',
        'player.data.wipe',
        'vehicle.spawn',
        'vehicle.delete',
        'vehicle.repair',
        'world.weather',
        'world.time',
        'world.noclip',
        'world.godmode',
        'server.announce',
        'server.restart',
        'audit.view',
        'permissions.manage',
        'resource.start',
        'resource.stop',
        'resource.restart',
    },
}

-- 权限继承：上级自动拥有下级所有权限
Config.InheritPermissions = true
Config.PermissionHierarchy = { 'user', 'helper', 'mod', 'admin', 'superadmin' }

-- Discord Webhook 配置
Config.Webhooks = {
    ban = '',
    kick = '',
    audit = '',
}

Config.WebhookColors = {
    ban = 16711680,     -- 红色
    kick = 16776960,    -- 黄色
    audit = 65280,      -- 绿色
    default = 3447003,  -- 蓝色
}

-- 封禁时长选项（天）
Config.BanDurations = {
    { label = '1 天',   value = 1 },
    { label = '3 天',   value = 3 },
    { label = '7 天',   value = 7 },
    { label = '30 天',  value = 30 },
    { label = '永久',   value = 0 },
}

-- 天气选项
Config.WeatherTypes = {
    'CLEAR',
    'EXTRASUNNY',
    'CLOUDS',
    'OVERCAST',
    'RAIN',
    'CLEARING',
    'THUNDER',
    'SMOG',
    'FOGGY',
    'XMAS',
    'SNOWLIGHT',
    'BLIZZARD',
}

-- NUI 面板刷新间隔（毫秒）
Config.PlayerListRefreshInterval = 5000

-- 资源监控设置
Config.ResourceMonitor = {
    Enabled = true,
    RefreshInterval = 10000, -- 毫秒
    CpuThreshold = 80,       -- CPU 使用率告警阈值
    MemoryThreshold = 80,    -- 内存使用率告警阈值
}
