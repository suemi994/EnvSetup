local load_modules = function()
    require('modules.completion').setup()
    require('modules.editor').setup()
    require('modules.ui').setup()
end

load_modules()
