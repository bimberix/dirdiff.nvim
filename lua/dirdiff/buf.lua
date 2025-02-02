local api = vim.api
local dir_diff = require('dirdiff/diff')
local diff_tab = require('dirdiff/tab')
local plat = require('dirdiff/plat')

local M = {
    navi_buf_id = 0,
    select_offset = 0,
    showed_diff = "",
    diff_info = {},
}

function M:create_diff_view(fname)
    local p = self:get_path(fname)
    if p.mine_ft == p.other_ft and p.mine_ft == "dir" then
        self:diff_sub_dir(fname)
        return
    end
    diff_tab:create_diff_view(p.mine, p.other)
end

function M:get_fname()
    local diff = self.diff_info.diff
    if self.showed_diff ~= "" then
        diff = self.diff_info.sub[self.showed_diff]
    end
    local cur_line = self.select_offset - 1
    if cur_line <= #diff.dirs then
        return diff.dirs[cur_line].file
    end
    --if cur_line <= #diff.change + #diff.add then
        --return diff.add[cur_line - #diff.change]
    --end
    return diff.files[cur_line - #diff.dirs].file
end

function M:diff_cur_line()
    -- 1-based line num
    local cur_line = api.nvim_win_get_cursor(0)[1]
    self.select_offset = cur_line
    if self.select_offset == 1 then
        self:back_parent_dir()
        return
    end
    self:create_diff_view(self:get_fname())
end

function M:back_parent_dir()
    if self.showed_diff == "" then
        return
    end

    local parent = plat.path_parent(self.showed_diff)
    self:update_to(parent)
end

function M:init_navi_buf()
    if self.navi_buf_id == 0 then
        self.navi_buf_id = api.nvim_create_buf(false, true)
        api.nvim_buf_set_keymap(self.navi_buf_id, 'n', '<cr>', 
            ":lua require('dirdiff').diff_cur()<cr>", {silent = true})
        --api.nvim_buf_set_keymap(self.navi_buf_id, 'n', '<esc>', 
            --":lua require('dirdiff').close_win()<cr>", {silent = true})
        self.mine_buf_id = api.nvim_create_buf(true, false)
        self.other_buf_id = api.nvim_create_buf(true, false)
    else
        api.nvim_buf_clear_namespace(self.navi_buf_id, -1, 0, -1)
        api.nvim_buf_set_lines(self.navi_buf_id, 0, -1, false, {})
    end

end

function M:set_navi_buf()
    self:init_navi_buf()
    local buf_lines = {"../"}
    local diff = self.diff_info.diff
    if self.showed_diff ~= "" then
        diff = self.diff_info.sub[self.showed_diff]
    end
    self:add_lines(buf_lines, diff.dirs)
    self:add_lines(buf_lines, diff.files)
    --self:add_lines(buf_lines, diff.add, "+")
    --self:add_lines(buf_lines, diff.delete, "-")
    api.nvim_buf_set_lines(self.navi_buf_id, 0, -1, false, buf_lines)
end

function M:add_lines(dst, src)
    for _, line in ipairs(src) do
        local p = self:get_path(line.file)
        local prefix = ""
        if p.mine_ft == "file" and p.other_ft == "file" then
            prefix = " "
        elseif p.mine_ft == "dir" and p.other_ft == "dir" then
            prefix = "▸"
        else
            prefix = "x"
        end
        table.insert(dst, prefix .. " " .. line.file .. line.state)
    end
end

function M:get_path(fname)
    local real_fname = fname
    if self.showed_diff ~= "" then
        real_fname = plat.path_concat(self.showed_diff, fname)
    end
    local mine = plat.path_concat(self.diff_info.mine_root, real_fname)
    local other = plat.path_concat(self.diff_info.others_root, real_fname)
    local mine_ft = vim.fn.getftype(mine)
    local other_ft = vim.fn.getftype(other)
    if mine_ft == "" then
        mine_ft = other_ft
    end
    if other_ft == "" then
        other_ft = mine_ft
    end
    return {mine = mine, other = other, mine_ft = mine_ft, other_ft = other_ft}
end

function M:update_to(sub_dir)
    self.select_offset = 0
    self.showed_diff = sub_dir
    self:set_navi_buf()
end

-- param {mine_root = "", others_root = "", diff = {}, sub = { f1 = {}, f2 = {}, f1/f3 = {} }}
function M:update(diff)
    self.diff_info = diff
    self.navi_buf_id = 0
    self:update_to("")
end

function M:diff_dir(mine, others, is_rec)
    self:update(dir_diff.diff_dir(mine, others, is_rec))
    diff_tab:create_tab(self.navi_buf_id)
end

function M:diff_sub_dir(fname)
    local sub_dir = fname
    if self.showed_diff ~= "" then
        sub_dir = plat.path_concat(self.showed_diff, fname)
    end
    if not self.diff_info.sub or not self.diff_info.sub[sub_dir] then
        local mine_dir = plat.path_concat(self.diff_info.mine_root, sub_dir)
        local others_dir = plat.path_concat(self.diff_info.others_root, sub_dir)
        local diff_info = dir_diff.diff_dir(mine_dir, others_dir, true)
        self.diff_info.sub = self.diff_info.sub or {}
        self.diff_info.sub[sub_dir] = diff_info.diff
    end
    self:update_to(sub_dir)
end

return M
