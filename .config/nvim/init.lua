-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- WezTerm のクリックから `nvim --remote-send` で開けるよう固定ソケットで待ち受ける
-- （複数インスタンス起動時は最初の1つだけが取得し、以降は pcall で無視される）
pcall(vim.fn.serverstart, "/tmp/nvim.sock")
