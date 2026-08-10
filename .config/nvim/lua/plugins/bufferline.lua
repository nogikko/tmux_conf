return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = true,
        separator_style = "slant",
        -- 無名の空バッファ([No Name])はタブに出さない(未保存の変更があるものは表示)
        custom_filter = function(buf)
          return vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified
        end,
      },
      highlights = {
        buffer_selected = {
          fg = "#ff9e64",
          bold = true,
          italic = false,
        },
      },
    },
  },
}
