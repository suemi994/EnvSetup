local load_modules = function()
    require('modules.completion').setup()
    require('modules.editor').setup()
end

load_modules()
