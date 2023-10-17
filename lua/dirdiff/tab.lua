local api = vim.api

local M = {
    navi_win_id = 0,
    mine_win_id = 0,
    other_win_id = 0,
}

function M:create_tab(buf_id)
    api.nvim_command("tabnew")
    local cur_tab = api.nvim_get_current_tabpage()
    self.navi_win_id = api.nvim_get_current_win()
    local width = api.nvim_win_get_width(self.navi_win_id)
    api.nvim_command("set nowrap")
    api.nvim_command("set nonumber")
    api.nvim_command("set showbreak=")
    api.nvim_command("set listchars=")

    api.nvim_command("vs")
    self.mine_win_id = api.nvim_get_current_win()

    api.nvim_command("vs")
    self.other_win_id = api.nvim_get_current_win()

    api.nvim_command("wincmd t")
    api.nvim_win_set_buf(self.navi_win_id, buf_id)
    api.nvim_win_set_width(self.navi_win_id, 24)

    local column_width = math.floor((width - 24) / 2)

    api.nvim_win_set_width(self.other_win_id, column_width)
end

function M:create_diff_view(mine, other)
    api.nvim_win_call(self.mine_win_id, function()
        api.nvim_command("diffoff")
        api.nvim_command("e " .. mine)
        api.nvim_command("diffthis")
    end)
    api.nvim_win_call(self.other_win_id, function()
        api.nvim_command("diffoff")
        api.nvim_command("e " .. other)
        api.nvim_command("diffthis")
    end)
end

return M
