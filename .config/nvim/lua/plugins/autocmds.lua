return {
  {
    "AstroNvim/astrocore",
    opts = {
      autocmds = {
        cursor_style = {
          {
            event = { "VimEnter", "VimResume" },
            desc = "Set fancy guicursor when entering or resuming",
            callback = function()
              vim.opt.guicursor = {
                "n-v-c:block",
                "i-ci-ve:ver25",
                "r-cr:hor20",
                "o:hor50",
                "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
                "sm:block-blinkwait175-blinkoff150-blinkon175",
              }
            end,
          },
          {
            event = { "VimLeave", "VimSuspend" },
            desc = "Reset cursor to blinking beam on exit",
            callback = function() vim.opt.guicursor = { "a:ver25-blinkwait700-blinkon400-blinkoff250" } end,
          },
        },
      },
    },
  },
}
