Locales = Locales or {}

Locales['zh'] = {
    -- 权限
    ['permission_denied'] = '权限不足，无法执行此操作',
    ['permission_no_group'] = '无法获取你的权限组',

    -- 玩家管理
    ['player_not_found'] = '目标玩家不存在',
    ['player_kicked'] = '玩家 %s 已被踢出，理由: %s',
    ['player_frozen'] = '玩家 %s 已被冻结',
    ['player_unfrozen'] = '玩家 %s 已被解冻',
    ['player_muted'] = '玩家 %s 已被禁言',
    ['player_unmuted'] = '玩家 %s 已被解除禁言',
    ['player_teleported'] = '已传送到玩家 %s',
    ['player_brought'] = '已将玩家 %s 召唤到身边',
    ['player_spectating'] = '正在旁观玩家 %s',
    ['player_spectate_stop'] = '已停止旁观',

    -- 封禁
    ['player_banned'] = '玩家 %s 已被封禁，时长: %s，理由: %s',
    ['player_unbanned'] = '已解封标识符 %s',
    ['ban_permanent'] = '永久',
    ['ban_days'] = '%d 天',
    ['ban_not_found'] = '未找到该封禁记录',
    ['kick_ban_reason'] = '你已被封禁\n理由: %s\n到期: %s\n管理员: %s',

    -- 经济
    ['money_set'] = '已将 %s 的 %s 设置为 $%d',
    ['money_given'] = '已给予 %s $%d (%s)',
    ['money_removed'] = '已扣除 %s $%d (%s)',
    ['money_invalid_type'] = '无效的金钱类型',

    -- 职业
    ['job_set'] = '已将 %s 的职业设置为 %s - %s',

    -- 车辆
    ['vehicle_spawned'] = '已生成车辆 %s',
    ['vehicle_deleted'] = '已删除附近车辆',
    ['vehicle_repaired'] = '已修复车辆',
    ['vehicle_not_found'] = '附近没有车辆',

    -- 世界
    ['weather_set'] = '天气已设置为 %s',
    ['time_set'] = '时间已设置为 %02d:%02d',
    ['noclip_enabled'] = '穿墙模式已开启',
    ['noclip_disabled'] = '穿墙模式已关闭',
    ['godmode_enabled'] = '无敌模式已开启',
    ['godmode_disabled'] = '无敌模式已关闭',
    ['announce'] = '[管理员公告] %s',

    -- 资源
    ['resource_started'] = '资源 %s 已启动',
    ['resource_stopped'] = '资源 %s 已停止',
    ['resource_restarted'] = '资源 %s 已重启',

    -- 审计
    ['audit_log_recorded'] = '操作已记录',

    -- 冷却
    ['cooldown_active'] = '操作过于频繁，请等待 %d 秒后再试',

    -- 面板
    ['panel_title'] = 'ESX 管理面板',
    ['tab_players'] = '玩家列表',
    ['tab_bans'] = '封禁管理',
    ['tab_audit'] = '审计日志',
    ['tab_world'] = '世界控制',
    ['tab_resources'] = '资源监控',

    -- 通用
    ['confirm'] = '确认',
    ['cancel'] = '取消',
    ['search'] = '搜索...',
    ['reason'] = '理由',
    ['duration'] = '时长',
    ['close'] = '关闭',
    ['refresh'] = '刷新',
    ['no_results'] = '无结果',
}
