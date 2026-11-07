package main

import (
	"context"
	"unicode/utf8"

	"github.com/Shougo/goda-cmp.vim/cmp"
)

var lspkindSymbols = map[string]string{
	"Text":          "󰉿",
	"Method":        "󰆧",
	"Function":      "󰊕",
	"Constructor":   "",
	"Field":         "󰜢",
	"Variable":      "󰀫",
	"Class":         "󰠱",
	"Interface":     "",
	"Module":        "",
	"Property":      "󰜢",
	"Unit":          "󰑭",
	"Value":         "󰎠",
	"Enum":          "",
	"Keyword":       "󰌋",
	"Snippet":       "",
	"Color":         "󰏘",
	"File":          "󰈙",
	"Reference":     "󰈇",
	"Folder":        "󰉋",
	"EnumMember":    "",
	"Constant":      "󰏿",
	"Struct":        "󰙅",
	"Event":         "",
	"Operator":      "󰆕",
	"TypeParameter": "",
}

type converterLspkind struct {
	maxWidth int
	ellipsis string
}

func (converterLspkind) Name() string { return "converterlspkind" }

func (c converterLspkind) Filter(_ context.Context, in cmp.FilterInput) ([]cmp.Item, error) {
	out := append([]cmp.Item(nil), in.Items...)
	for i, item := range out {
		if symbol, ok := lspkindSymbols[item.Kind]; ok {
			out[i].Kind = symbol
		}
		display := []rune(item.Display())
		if len(display) <= c.maxWidth {
			continue
		}
		keep := c.maxWidth - utf8.RuneCountInString(c.ellipsis)
		if keep < 0 {
			keep = 0
		}
		out[i].Abbr = string(display[:keep]) + c.ellipsis
	}
	return out, nil
}
