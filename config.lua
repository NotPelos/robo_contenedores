-- config.lua
Config = {}

Config.Contenedores = {
    ['tchumane'] = {
        {label = 'Caja 1', items = {'weed_purplehaze_seed'}, count = math.random(5, 10), coords = vector3(-11.440755844116,-2495.4306640625,6.2036867141724)},
        {label = 'Caja 2', items = {'weed_whitewidow_seed', 'weed_ogkush_seed'}, count = math.random(5, 10), coords = vector3(-13.635901451111,-2494.013671875,6.2036867141724)},
        {label = 'Caja 3', items = {'weed_skunk_seed'}, count = math.random(5, 10), coords = vector3(-9.4140024185181,-2497.3171386719,6.2036867141724)}
    },
    ['tcarmeria'] = {
        {label = 'Caja 1', items = {'weapon_pistol', 'weapon_vintagepistol', 'weapon_ceramicpistol', 'weapon_snspistol', 'weapon_heavypistol'}, count = math.random(4, 8), coords = vector3(-11.440755844116,-2495.4306640625,6.2036867141724)},
        {label = 'Caja 2', items = {'pistol_ammo'}, count = math.random(30, 40), coords = vector3(-13.635901451111,-2494.013671875,6.2036867141724)},
        {label = 'Caja 3', items = {'armor', 'heavyarmor'}, count = math.random(4, 10), coords = vector3(-9.4140024185181,-2497.3171386719,6.2036867141724)}
    },
    ['tcjoyeria'] = {
        {label = 'Caja 1', items = {'diamond'}, count = math.random(5, 10), coords = vector3(-11.440755844116,-2495.4306640625,6.2036867141724)},
        {label = 'Caja 2', items = {'goldbar'}, count = math.random(5, 10), coords = vector3(-13.635901451111,-2494.013671875,6.2036867141724)}
    }
}
