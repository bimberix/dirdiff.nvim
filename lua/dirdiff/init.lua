local buf = nil
local plat = nil
local M = {}

M.diff_dir = function(is_rec, ...)
    plat = plat or require('dirdiff/plat')
    buf = buf or require('dirdiff/buf')

    local ret = plat.parse_arg(...)
    if not ret.ret then
        print("dir err")
        return
    end
    buf:diff_dir(ret.mine, ret.others, is_rec)
end

M.diff_cur = function()
    if not buf then return end
    buf:diff_cur_line()
end

M.cmdcomplete = function(A, L, P)
    plat = plat or require('dirdiff/plat')
    return plat.cmdcomplete(A,L,P)
end

return M
