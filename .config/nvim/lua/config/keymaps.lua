-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ===== PR ワークフロー(octo.nvim 中心) =====

-- カレントディレクトリ直下(＋自身)の Git リポジトリを走査し、owner/repo → ローカルパスを解決する
local repo_paths ---@type table<string, string>?
local function repo_local_path(repo)
  if not repo_paths then
    repo_paths = {}
    local cwd = vim.fn.getcwd()
    local function add_repo(path)
      local out = vim.system({ "git", "-C", path, "remote", "get-url", "origin" }, { text = true }):wait()
      local org, name = (out.stdout or ""):match("github%.com[:/]+([^/]+)/([^/%s]+)")
      if out.code == 0 and org then
        repo_paths[("%s/%s"):format(org, (name:gsub("%.git$", "")))] = path
      end
    end
    if vim.uv.fs_stat(cwd .. "/.git") then
      add_repo(cwd)
    end
    for dir_name, t in vim.fs.dir(cwd) do
      if t == "directory" and vim.uv.fs_stat(("%s/%s/.git"):format(cwd, dir_name)) then
        add_repo(cwd .. "/" .. dir_name)
      end
    end
  end
  return repo_paths[repo]
end

-- リポジトリがローカルにない場合のフォールバック: unified diff をバッファ表示
local function open_pr_diff_buffer(repo, number)
  vim.system(
    { "gh", "pr", "diff", tostring(number), "--repo", repo },
    { text = true },
    vim.schedule_wrap(function(out)
      if out.code ~= 0 then
        vim.notify("gh pr diff に失敗しました: " .. (out.stderr or ""), vim.log.levels.ERROR)
        return
      end
      -- ターミナルや explorer ではなく通常の編集ウィンドウに表示する
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
      local name = ("prdiff://%s/%d"):format(repo, number)
      local existing = vim.fn.bufnr("^" .. vim.fn.fnameescape(name) .. "$")
      if existing ~= -1 then
        vim.api.nvim_buf_delete(existing, { force = true })
      end
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(out.stdout, "\n"))
      vim.api.nvim_buf_set_name(buf, name)
      vim.bo[buf].filetype = "diff"
      vim.bo[buf].modifiable = false
      vim.api.nvim_win_set_buf(0, buf)
    end)
  )
end

-- PR の差分を開く。ローカルクローンがあれば PR ブランチを fetch して
-- diffview(ファイルツリー+左右分割)、なければ unified diff バッファにフォールバック
local function open_pr_diffview(repo, number)
  local path = repo_local_path(repo)
  if not path then
    open_pr_diff_buffer(repo, number)
    return
  end
  vim.system(
    { "gh", "pr", "view", tostring(number), "--repo", repo, "--json", "baseRefName", "-q", ".baseRefName" },
    { text = true },
    vim.schedule_wrap(function(view)
      if view.code ~= 0 then
        open_pr_diff_buffer(repo, number)
        return
      end
      local base = vim.trim(view.stdout)
      vim.system(
        { "git", "-C", path, "fetch", "--quiet", "origin", base, ("+refs/pull/%d/head:refs/prdiff/%d"):format(number, number) },
        { text = true },
        vim.schedule_wrap(function(fetch)
          if fetch.code ~= 0 then
            vim.notify("git fetch に失敗しました: " .. (fetch.stderr or ""), vim.log.levels.ERROR)
            return
          end
          vim.cmd(("DiffviewOpen -C%s origin/%s...refs/prdiff/%d"):format(path, base, number))
        end)
      )
    end)
  )
end

-- octo の PR バッファで D → その PR の差分を diffview で開く
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("octo_pr_diffview", { clear = true }),
  pattern = "octo",
  callback = function(ev)
    local repo, number = vim.api.nvim_buf_get_name(ev.buf):match("^octo://([^/]+/[^/]+)/pull/(%d+)$")
    if repo then
      vim.keymap.set("n", "D", function()
        open_pr_diffview(repo, tonumber(number))
      end, { buffer = ev.buf, desc = "PR の差分を diffview で開く" })
    end
  end,
})

-- PR 一覧バッファの行の色分け
vim.api.nvim_set_hl(0, "PrlistNumber", { link = "Number", default = true })
vim.api.nvim_set_hl(0, "PrlistAuthor", { link = "Comment", default = true })

-- ===== PR 一覧パネル =====
-- 下部の専用パネルに PR 一覧を表示し、パネル上端(winbar)のリポジトリタブで切り替える。
-- 編集画面は上に残り、Enter で octo の PR バッファが編集ウィンドウに開く

local prlist = { win = nil, bufs = {}, repos = {} }

local function prlist_winbar(active_idx)
  local parts = {}
  for i, r in ipairs(prlist.repos) do
    local hl = i == active_idx and "%#TabLineSel#" or "%#TabLine#"
    parts[#parts + 1] = ("%s%%%d@v:lua.PrlistTabClick@ %s %%X%%*"):format(hl, i, r)
  end
  return table.concat(parts, " ")
end

local function prlist_show(idx)
  if not (prlist.win and vim.api.nvim_win_is_valid(prlist.win)) then
    return
  end
  local buf = prlist.bufs[idx]
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_win_set_buf(prlist.win, buf)
    vim.wo[prlist.win].winbar = prlist_winbar(idx)
  end
end

-- winbar のタブクリックハンドラ(クリック項目から呼ばれるためグローバル)
function _G.PrlistTabClick(idx)
  prlist_show(idx)
end

local function prlist_close()
  if prlist.win and vim.api.nvim_win_is_valid(prlist.win) then
    vim.api.nvim_win_close(prlist.win, true)
  end
  for _, b in ipairs(prlist.bufs) do
    if vim.api.nvim_buf_is_valid(b) then
      vim.api.nvim_buf_delete(b, { force = true })
    end
  end
  prlist.win, prlist.bufs, prlist.repos = nil, {}, {}
end

local pr_dashboard
pr_dashboard = function()
  vim.system(
    {
      "gh", "search", "prs",
      "--state", "open",
      "--limit", "100",
      "--json", "repository,number,title,author",
    },
    { text = true },
    vim.schedule_wrap(function(out)
      if out.code ~= 0 then
        vim.notify("gh search prs に失敗しました: " .. (out.stderr or ""), vim.log.levels.ERROR)
        return
      end
      local groups = {} ---@type table<string, {number: integer, title: string, author: string}[]>
      for _, pr in ipairs(vim.json.decode(out.stdout)) do
        local repo = pr.repository.nameWithOwner
        groups[repo] = groups[repo] or {}
        table.insert(groups[repo], {
          number = pr.number,
          title = pr.title,
          author = pr.author and pr.author.login or "",
        })
      end
      local repo_names = vim.tbl_keys(groups) ---@type string[]
      table.sort(repo_names)
      if #repo_names == 0 then
        vim.notify("オープン PR はありません", vim.log.levels.INFO)
        return
      end

      prlist_close()
      local prev_win = vim.api.nvim_get_current_win()
      local function focus_editor_win()
        if vim.api.nvim_win_is_valid(prev_win) and prev_win ~= prlist.win then
          vim.api.nvim_set_current_win(prev_win)
          return
        end
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if win ~= prlist.win and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        vim.cmd("wincmd p")
      end

      for i, repo in ipairs(repo_names) do
        local prs = groups[repo]
        table.sort(prs, function(a, b)
          return a.number < b.number
        end)
        local lines = {}
        for j, p in ipairs(prs) do
          lines[j] = ("#%-5d %s  @%s"):format(p.number, p.title, p.author)
        end
        local buf = vim.api.nvim_create_buf(false, true) -- unlisted: bufferline には出さない
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_name(buf, "prlist://" .. repo)
        vim.bo[buf].modifiable = false
        vim.api.nvim_buf_call(buf, function()
          vim.cmd([[syntax match PrlistNumber /^#\d\+/]])
          vim.cmd([[syntax match PrlistAuthor /@\S\+$/]])
        end)
        prlist.bufs[i] = buf
        prlist.repos[i] = repo

        local function pr_at_cursor()
          return prs[vim.fn.line(".")]
        end
        local function open_current()
          local p = pr_at_cursor()
          if not p then
            return
          end
          require("lazy").load({ plugins = { "octo.nvim" } })
          focus_editor_win()
          vim.cmd.edit(("octo://%s/pull/%d"):format(repo, p.number))
        end
        vim.keymap.set("n", "<CR>", open_current, { buffer = buf, desc = "PR を開く" })
        vim.keymap.set("n", "<2-LeftMouse>", open_current, { buffer = buf, desc = "PR を開く" })
        vim.keymap.set("n", "D", function()
          local p = pr_at_cursor()
          if p then
            open_pr_diffview(repo, p.number)
          end
        end, { buffer = buf, desc = "diffview で差分" })
        vim.keymap.set("n", "H", function()
          prlist_show(((i - 2) % #prlist.bufs) + 1)
        end, { buffer = buf, desc = "前のリポジトリタブ" })
        vim.keymap.set("n", "L", function()
          prlist_show((i % #prlist.bufs) + 1)
        end, { buffer = buf, desc = "次のリポジトリタブ" })
        vim.keymap.set("n", "r", pr_dashboard, { buffer = buf, desc = "再読み込み" })
        vim.keymap.set("n", "q", prlist_close, { buffer = buf, desc = "パネルを閉じる" })
      end

      vim.cmd("botright 12split")
      prlist.win = vim.api.nvim_get_current_win()
      vim.wo.cursorline = true
      vim.wo.wrap = false
      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.signcolumn = "no"
      prlist_show(1)
    end)
  )
end
vim.keymap.set("n", "<leader>gD", pr_dashboard, { desc = "PR 一覧パネル" })

