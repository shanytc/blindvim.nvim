vim.api.nvim_create_user_command("Blindvim",function(opts)
    local cmd = opts.args

    if cmd == "on" then
        require("blindvim").start()
        return
    end

    if cmd == "off" then
        require("blindvim").stop()
        return
    end

    if cmd == "flash" then
        require("blindvim").mark()
        return
    end

    if cmd == "reflash" then
        require("blindvim").clear_marks()
        return
    end

    if cmd == "unflash" then
        require("blindvim").unmark()
        return
    end

    if cmd == "hide" then
        require("blindvim").hide()
        return
    end

    if cmd == "unhide" then
        require("blindvim").unhide()
        return
    end

    if cmd == "hideSelectedLines" then
        require("blindvim").hideSelectedLines()
        return
    end

    if cmd == "blind" then
        require("blindvim").blind()
        return
    end
end, {
    nargs="?",
    complete = function ()
        return {
            "on","off",
            "blind",
            "flash", "unflash", "reflash",
            "hide", "hideSelectedLines", "unhide"
        }
    end
})
