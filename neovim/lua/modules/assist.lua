return {
	{
		'jackMort/ChatGPT.nvim',
		dependencies = {
      		"MunifTanjim/nui.nvim",
      		"nvim-lua/plenary.nvim",
      		"folke/trouble.nvim",
      		"nvim-telescope/telescope.nvim"
		},
		enabled = false,
		-- event = 'VeryLazy',
		cmd = {'ChatGPT', 'ChatGPTRun', 'ChatGPTEditWithInstruction'},
		opts = function()
			local home = vim.fn.expand("$HOME")
			return {
				-- api_host_cmd = 'echo "https://api.chatanywhere.tech"',
				-- api_key_cmd = "gpg --decrypt " .. home .. "/.config/chatgpt.gpg",
				openai_params = {
					model = "gpt-4o-mini",
				    frequency_penalty = 0,
        			presence_penalty = 0,
        			max_tokens = 4095,
        			temperature = 0.2,
        			top_p = 0.1,
        			n = 1,
				}
			}
		end
	},
	{
	  "yetone/avante.nvim",
	  event = "VeryLazy",
	  enabled = false,
	  opts = {
		provider = 'openai',
		openai = {
			endpoint = 'https://api.chatanywhere.tech',
			model = 'gpt-4o-mini',
			temperature = 0,
			max_tokens = 4096,
		}
	  },
	  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	  build = "make",
	  dependencies = {
	  	"nvim-treesitter/nvim-treesitter",
	    "stevearc/dressing.nvim",
	    "nvim-lua/plenary.nvim",
	    "MunifTanjim/nui.nvim",
	    --- The below dependencies are optional,
	    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
	    {
	      -- support for image pasting
	      "HakonHarnes/img-clip.nvim",
	      event = "VeryLazy",
	      opts = {
	        -- recommended settings
	        default = {
	          embed_image_as_base64 = false,
	          prompt_for_file_name = false,
	          drag_and_drop = {
	            insert_mode = true,
	          },
	          -- required for Windows users
	          use_absolute_path = true,
	        },
	      },
	    },
	    {
	      -- Make sure to set this up properly if you have lazy=true
	      'MeanderingProgrammer/render-markdown.nvim',
	      opts = {
	        file_types = { "markdown", "Avante" },
	      },
	      ft = { "markdown", "Avante" },
	    },
	  },
	}
}
