package main

import "github.com/Shougo/goda-cmp.vim/cmp"

func configure(b *cmp.Builder) {
	b.PatchGlobal(cmp.Config{
		UI:      "pum",
		Sources: []string{"skkelua", "nvim_lsp", "nvim_lua", "buffer", "file"},
		SourceOptions: map[string]cmp.SourceOption{
			"_": {
				MinAutoCompleteLength: new(1),
				MaxItems:              new(1000),
				Matchers:              []string{"matcherhead"},
				Sorters:               []string{"sorterrank"},
				Converters:            []string{"converterremoveoverlap", "convertertruncateabbr"},
			},
			"skkelua": {
				Mark:                  "skk",
				MinAutoCompleteLength: new(0),
				IsVolatile:            new(true),
				Matchers:              []string{},
				Sorters:               []string{},
			},
			"nvim_lsp": {
				Mark:                   "LSP",
				ForceCompletionPattern: `\.\w*`,
				IsVolatile:             new(true),
				Matchers:               []string{},
				Sorters:                []string{"sortertext"},
			},
			"nvim_lua": {
				Mark:                   "Lua",
				ForceCompletionPattern: `\.\w*`,
				Matchers:               []string{},
				Sorters:                []string{},
			},
			"buffer": {
				Mark:                  "B",
				MinAutoCompleteLength: new(3),
			},
			"file": {
				Mark:                   "F",
				ForceCompletionPattern: `\S/\S*`,
				IsVolatile:             new(true),
			},
			"cmdline": {
				Mark: "cmd",
			},
			"cmdlinehistory": {
				Mark: "hist",
			},
		},
		CmdlineSources: map[string][]string{
			":": {"cmdline", "cmdlinehistory"},
			"/": {"cmdlinehistory"},
			"?": {"cmdlinehistory"},
		},
		PostFilters:       []string{"skkeluafirst"},
		AutoCompleteDelay: new(60),
	})
}
