local load_modules = function()
    require('modules.completion').setup()
    require('modules.editor').setup()
    require('modules.ui').setup()
    require('modules.keymap').setup()
end

load_modules()
